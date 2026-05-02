const fs = require("fs");
const path = require("path");
const Database = require("better-sqlite3");

function nowIso() {
  return new Date().toISOString();
}

function ensureParentDir(filePath) {
  const dirPath = path.dirname(filePath);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

class AuditStore {
  constructor(options = {}) {
    this.dbPath = options.dbPath || path.join(process.cwd(), "data", "roulette_audit.sqlite");
    this.auditLogPath = options.auditLogPath || path.join(process.cwd(), "data", "audit-log.jsonl");
    ensureParentDir(this.dbPath);
    ensureParentDir(this.auditLogPath);
    this.db = new Database(this.dbPath);
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");
    this.init();
  }

  init() {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS rounds (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        external_id TEXT NOT NULL,
        game_type TEXT NOT NULL,
        wager INTEGER NOT NULL,
        payout INTEGER NOT NULL DEFAULT 0,
        state TEXT NOT NULL,
        result TEXT DEFAULT NULL,
        client_seed TEXT NOT NULL,
        server_seed_hash TEXT NOT NULL,
        server_seed TEXT DEFAULT NULL,
        nonce INTEGER NOT NULL,
        metadata_json TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        settled_at TEXT DEFAULT NULL
      );

      CREATE TABLE IF NOT EXISTS external_money_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        round_id TEXT DEFAULT NULL,
        user_id TEXT NOT NULL,
        external_id TEXT NOT NULL,
        op_type TEXT NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        external_tx_id TEXT DEFAULT NULL,
        amount INTEGER NOT NULL,
        status TEXT NOT NULL,
        reconciliation_status TEXT NOT NULL DEFAULT 'pending',
        last_error TEXT DEFAULT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        request_json TEXT NOT NULL,
        response_json TEXT DEFAULT NULL,
        response_status INTEGER DEFAULT NULL,
        retry_at TEXT DEFAULT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_external_money_ops_status
      ON external_money_ops(status, retry_at);

      CREATE INDEX IF NOT EXISTS idx_external_money_ops_external
      ON external_money_ops(external_id, created_at DESC);

      CREATE TABLE IF NOT EXISTS webhook_events (
        event_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        received_at TEXT NOT NULL,
        processed_at TEXT DEFAULT NULL,
        status TEXT NOT NULL,
        payload_hash TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        last_error TEXT DEFAULT NULL
      );

      CREATE TABLE IF NOT EXISTS limits (
        user_id TEXT PRIMARY KEY,
        daily_wager_cap INTEGER NOT NULL,
        daily_loss_cap INTEGER NOT NULL,
        cooldown_until TEXT DEFAULT NULL,
        max_bet INTEGER DEFAULT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS risk_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        score INTEGER NOT NULL,
        metadata_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS system_state (
        key TEXT PRIMARY KEY,
        value_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    `);

    this.insertRoundStmt = this.db.prepare(`
      INSERT INTO rounds (
        id, user_id, external_id, game_type, wager, payout, state, result,
        client_seed, server_seed_hash, server_seed, nonce, metadata_json,
        created_at, settled_at
      ) VALUES (
        @id, @user_id, @external_id, @game_type, @wager, @payout, @state, @result,
        @client_seed, @server_seed_hash, @server_seed, @nonce, @metadata_json,
        @created_at, @settled_at
      )
    `);

    this.updateRoundSettlementStmt = this.db.prepare(`
      UPDATE rounds
      SET payout = @payout,
          state = @state,
          result = @result,
          server_seed = COALESCE(@server_seed, server_seed),
          metadata_json = @metadata_json,
          settled_at = @settled_at
      WHERE id = @id
    `);

    this.updateRoundStateStmt = this.db.prepare(`
      UPDATE rounds
      SET state = @state,
          metadata_json = @metadata_json,
          settled_at = COALESCE(@settled_at, settled_at)
      WHERE id = @id
    `);

    this.getRoundStmt = this.db.prepare(`SELECT * FROM rounds WHERE id = ?`);

    this.insertMoneyOpStmt = this.db.prepare(`
      INSERT INTO external_money_ops (
        round_id, user_id, external_id, op_type, idempotency_key, external_tx_id,
        amount, status, reconciliation_status, last_error, attempts,
        request_json, response_json, response_status, retry_at,
        created_at, updated_at
      ) VALUES (
        @round_id, @user_id, @external_id, @op_type, @idempotency_key, @external_tx_id,
        @amount, @status, @reconciliation_status, @last_error, @attempts,
        @request_json, @response_json, @response_status, @retry_at,
        @created_at, @updated_at
      )
    `);

    this.updateMoneyOpStmt = this.db.prepare(`
      UPDATE external_money_ops
      SET external_tx_id = @external_tx_id,
          status = @status,
          reconciliation_status = @reconciliation_status,
          last_error = @last_error,
          attempts = @attempts,
          response_json = @response_json,
          response_status = @response_status,
          retry_at = @retry_at,
          updated_at = @updated_at
      WHERE idempotency_key = @idempotency_key
    `);

    this.getMoneyOpStmt = this.db.prepare(`SELECT * FROM external_money_ops WHERE idempotency_key = ?`);
    this.getPendingMoneyOpsStmt = this.db.prepare(`
      SELECT * FROM external_money_ops
      WHERE status IN ('retry_pending', 'verify_pending')
        AND (retry_at IS NULL OR retry_at <= @now)
      ORDER BY created_at ASC
      LIMIT @limit
    `);

    this.listMoneyOpsForUserStmt = this.db.prepare(`
      SELECT * FROM external_money_ops
      WHERE external_id = ?
      ORDER BY created_at DESC
      LIMIT ?
    `);

    this.getUnreconciledOpsStmt = this.db.prepare(`
      SELECT * FROM external_money_ops
      WHERE status = 'succeeded' AND reconciliation_status != 'matched'
      ORDER BY created_at ASC
      LIMIT ?
    `);

    this.insertWebhookEventStmt = this.db.prepare(`
      INSERT INTO webhook_events (
        event_id, type, received_at, processed_at, status, payload_hash, payload_json, last_error
      ) VALUES (
        @event_id, @type, @received_at, @processed_at, @status, @payload_hash, @payload_json, @last_error
      )
    `);

    this.updateWebhookEventStmt = this.db.prepare(`
      UPDATE webhook_events
      SET processed_at = @processed_at,
          status = @status,
          last_error = @last_error
      WHERE event_id = @event_id
    `);

    this.getWebhookEventStmt = this.db.prepare(`SELECT * FROM webhook_events WHERE event_id = ?`);

    this.getLimitsStmt = this.db.prepare(`SELECT * FROM limits WHERE user_id = ?`);
    this.upsertLimitsStmt = this.db.prepare(`
      INSERT INTO limits (
        user_id, daily_wager_cap, daily_loss_cap, cooldown_until, max_bet, created_at, updated_at
      ) VALUES (
        @user_id, @daily_wager_cap, @daily_loss_cap, @cooldown_until, @max_bet, @created_at, @updated_at
      )
      ON CONFLICT(user_id) DO UPDATE SET
        daily_wager_cap = excluded.daily_wager_cap,
        daily_loss_cap = excluded.daily_loss_cap,
        cooldown_until = excluded.cooldown_until,
        max_bet = excluded.max_bet,
        updated_at = excluded.updated_at
    `);

    this.insertRiskEventStmt = this.db.prepare(`
      INSERT INTO risk_events (user_id, type, score, metadata_json, created_at)
      VALUES (@user_id, @type, @score, @metadata_json, @created_at)
    `);

    this.dailyTotalsStmt = this.db.prepare(`
      SELECT
        COALESCE(SUM(wager), 0) AS wager_total,
        COALESCE(SUM(CASE WHEN payout < wager THEN wager - payout ELSE 0 END), 0) AS loss_total
      FROM rounds
      WHERE external_id = @external_id
        AND created_at >= @start_of_day
    `);

    this.getSystemStateStmt = this.db.prepare(`SELECT value_json FROM system_state WHERE key = ?`);
    this.setSystemStateStmt = this.db.prepare(`
      INSERT INTO system_state (key, value_json, updated_at)
      VALUES (@key, @value_json, @updated_at)
      ON CONFLICT(key) DO UPDATE SET
        value_json = excluded.value_json,
        updated_at = excluded.updated_at
    `);
  }

  close() {
    this.db.close();
  }

  appendAudit(kind, payload) {
    const line = JSON.stringify({ ts: nowIso(), kind, payload });
    fs.appendFileSync(this.auditLogPath, `${line}\n`, "utf8");
  }

  createRound(round) {
    const record = {
      payout: 0,
      result: null,
      server_seed: null,
      metadata_json: JSON.stringify(round.metadata || {}),
      created_at: round.created_at || nowIso(),
      settled_at: null,
      ...round,
    };
    this.insertRoundStmt.run(record);
    this.appendAudit("round.created", record);
    return record;
  }

  updateRoundSettlement(roundId, patch) {
    const round = this.getRound(roundId);
    if (!round) {
      return null;
    }
    const metadata = patch.metadata || JSON.parse(round.metadata_json || "{}");
    const record = {
      id: roundId,
      payout: patch.payout,
      state: patch.state,
      result: patch.result,
      server_seed: patch.server_seed || round.server_seed,
      metadata_json: JSON.stringify(metadata),
      settled_at: patch.settled_at || nowIso(),
    };
    this.updateRoundSettlementStmt.run(record);
    this.appendAudit("round.settled", record);
    return this.getRound(roundId);
  }

  updateRoundState(roundId, patch) {
    const round = this.getRound(roundId);
    if (!round) {
      return null;
    }
    const metadata = patch.metadata || JSON.parse(round.metadata_json || "{}");
    const record = {
      id: roundId,
      state: patch.state,
      metadata_json: JSON.stringify(metadata),
      settled_at: patch.settled_at || null,
    };
    this.updateRoundStateStmt.run(record);
    this.appendAudit("round.updated", record);
    return this.getRound(roundId);
  }

  getRound(roundId) {
    return this.getRoundStmt.get(roundId) || null;
  }

  createMoneyOp(op) {
    const record = {
      round_id: op.round_id || null,
      external_tx_id: op.external_tx_id || null,
      reconciliation_status: op.reconciliation_status || "pending",
      last_error: op.last_error || null,
      attempts: op.attempts || 0,
      response_json: op.response_json ? JSON.stringify(op.response_json) : null,
      response_status: op.response_status || null,
      retry_at: op.retry_at || null,
      created_at: op.created_at || nowIso(),
      updated_at: op.updated_at || nowIso(),
      request_json: JSON.stringify(op.request_json || {}),
      ...op,
    };
    this.insertMoneyOpStmt.run(record);
    this.appendAudit("money_op.created", { ...record, request_json: op.request_json || {} });
    return this.getMoneyOp(record.idempotency_key);
  }

  updateMoneyOp(idempotencyKey, patch) {
    const existing = this.getMoneyOp(idempotencyKey);
    if (!existing) {
      return null;
    }
    const record = {
      idempotency_key: idempotencyKey,
      external_tx_id: patch.external_tx_id ?? existing.external_tx_id,
      status: patch.status ?? existing.status,
      reconciliation_status: patch.reconciliation_status ?? existing.reconciliation_status,
      last_error: patch.last_error ?? existing.last_error,
      attempts: patch.attempts ?? existing.attempts,
      response_json: patch.response_json ? JSON.stringify(patch.response_json) : existing.response_json,
      response_status: patch.response_status ?? existing.response_status,
      retry_at: patch.retry_at ?? existing.retry_at,
      updated_at: patch.updated_at || nowIso(),
    };
    this.updateMoneyOpStmt.run(record);
    this.appendAudit("money_op.updated", {
      ...record,
      response_json: patch.response_json || (existing.response_json ? JSON.parse(existing.response_json) : null),
    });
    return this.getMoneyOp(idempotencyKey);
  }

  getMoneyOp(idempotencyKey) {
    return this.getMoneyOpStmt.get(idempotencyKey) || null;
  }

  getPendingMoneyOps(limit = 25) {
    return this.getPendingMoneyOpsStmt.all({ now: nowIso(), limit });
  }

  listMoneyOpsForUser(externalId, limit = 100) {
    return this.listMoneyOpsForUserStmt.all(externalId, limit);
  }

  getUnreconciledOps(limit = 25) {
    return this.getUnreconciledOpsStmt.all(limit);
  }

  recordWebhookEvent(event) {
    const record = {
      processed_at: null,
      last_error: null,
      received_at: nowIso(),
      payload_json: JSON.stringify(event.payload || {}),
      ...event,
    };
    this.insertWebhookEventStmt.run(record);
    this.appendAudit("webhook.received", { ...record, payload: event.payload || {} });
    return this.getWebhookEvent(record.event_id);
  }

  getWebhookEvent(eventId) {
    return this.getWebhookEventStmt.get(eventId) || null;
  }

  markWebhookEvent(eventId, status, lastError = null) {
    const record = {
      event_id: eventId,
      processed_at: nowIso(),
      status,
      last_error: lastError,
    };
    this.updateWebhookEventStmt.run(record);
    this.appendAudit("webhook.updated", record);
    return this.getWebhookEvent(eventId);
  }

  getOrCreateLimits(userId, defaults) {
    const existing = this.getLimitsStmt.get(userId);
    if (existing) {
      return existing;
    }
    const ts = nowIso();
    const created = {
      user_id: userId,
      daily_wager_cap: defaults.daily_wager_cap,
      daily_loss_cap: defaults.daily_loss_cap,
      cooldown_until: null,
      max_bet: defaults.max_bet || null,
      created_at: ts,
      updated_at: ts,
    };
    this.upsertLimitsStmt.run(created);
    return this.getLimitsStmt.get(userId);
  }

  updateLimits(userId, patch, defaults) {
    const existing = this.getOrCreateLimits(userId, defaults);
    const updated = {
      ...existing,
      ...patch,
      updated_at: nowIso(),
    };
    this.upsertLimitsStmt.run(updated);
    this.appendAudit("limits.updated", updated);
    return this.getLimitsStmt.get(userId);
  }

  recordRiskEvent(userId, type, score, metadata) {
    const record = {
      user_id: userId,
      type,
      score,
      metadata_json: JSON.stringify(metadata || {}),
      created_at: nowIso(),
    };
    this.insertRiskEventStmt.run(record);
    this.appendAudit("risk_event.created", { ...record, metadata: metadata || {} });
  }

  getDailyTotals(externalId, startOfDayIso) {
    return this.dailyTotalsStmt.get({ external_id: externalId, start_of_day: startOfDayIso });
  }

  getSystemState(key, fallbackValue = null) {
    const row = this.getSystemStateStmt.get(key);
    if (!row) {
      return fallbackValue;
    }
    return JSON.parse(row.value_json);
  }

  setSystemState(key, value) {
    this.setSystemStateStmt.run({ key, value_json: JSON.stringify(value), updated_at: nowIso() });
    this.appendAudit("system_state.updated", { key, value });
  }
}

module.exports = {
  AuditStore,
  nowIso,
};