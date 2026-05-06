const WebSocket = require("ws");
const http = require("http");
const crypto = require("crypto");
const path = require("path");

const { IdentityStore } = require("./lib/identityStore");

const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;
const HOST = process.env.HOST || "0.0.0.0";
const SGC_WEBHOOK_SECRET = process.env.SGC_WEBHOOK_SECRET || "";
const SGC_BASE_URL = (process.env.SGC_BASE_URL || "").replace(/\/$/, "");
const SGC_API_KEY = process.env.SGC_API_KEY || "";
const SGC_OAUTH_CLIENT_ID = process.env.SGC_OAUTH_CLIENT_ID || "";
const SGC_OAUTH_CLIENT_SECRET = process.env.SGC_OAUTH_CLIENT_SECRET || "";
const SGC_OAUTH_REDIRECT_URI = process.env.SGC_OAUTH_REDIRECT_URI || "";
const SGC_OAUTH_SCOPE = process.env.SGC_OAUTH_SCOPE || "identity:read balance:read coins:debit coins:credit";
const SGC_PUBLIC_ORIGIN = (process.env.SGC_PUBLIC_ORIGIN || "").replace(/\/$/, "");
const DEFAULT_BANKROLL = 1000;
const SGC_DEBUG_SIGNIN = process.env.SGC_DEBUG_SIGNIN === "1";
const wheelOrder = [
  0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23,
  10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26,
];
const redNumbers = new Set([1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]);

const state = {
  players: new Map(),
  lobbies: new Map(),
  tableLobbies: new Map(),
  nextPlayerId: 1,
  nextLobbyId: 1,
  nextTableLobbyId: 1,
  nextSpinId: 1,
};

const oauthPendingByState = new Map();
const oauthCompletedBySessionId = new Map();
const oauthFailedBySessionId = new Map();
const oauthPendingTtlMs = 10 * 60 * 1000;
const identityStore = new IdentityStore({
  filePath: path.join(process.cwd(), "data", "identity-store.json"),
});

function base64Url(bufferValue) {
  return bufferValue.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function buildPkcePair() {
  const verifier = base64Url(crypto.randomBytes(32));
  const challenge = base64Url(crypto.createHash("sha256").update(verifier, "utf8").digest());
  return { verifier, challenge };
}

function cleanupOauthPending() {
  const now = Date.now();
  for (const [stateKey, pending] of oauthPendingByState.entries()) {
    if ((now - pending.createdAt) > oauthPendingTtlMs) {
      oauthPendingByState.delete(stateKey);
    }
  }

  for (const [sessionId, completed] of oauthCompletedBySessionId.entries()) {
    if ((now - completed.linkedAt) > oauthPendingTtlMs) {
      oauthCompletedBySessionId.delete(sessionId);
    }
  }

  for (const [sessionId, failed] of oauthFailedBySessionId.entries()) {
    if ((now - failed.failedAt) > oauthPendingTtlMs) {
      oauthFailedBySessionId.delete(sessionId);
    }
  }
}

function isBrokerManagedExternalId(externalId) {
  return /^sgcusr_[0-9a-f-]{36}$/i.test(String(externalId || "").trim());
}

function createImmutableExternalId() {
  return identityStore.createImmutableAppId();
}

function htmlEscape(value) {
  return String(value || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function writeHtml(res, statusCode, title, bodyHtml, extraHtml = "") {
  const page = `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${htmlEscape(title)}</title>
  <style>
    body { margin: 0; font-family: Segoe UI, Tahoma, sans-serif; background: #090b11; color: #f2eef6; }
    .wrap { max-width: 680px; margin: 0 auto; padding: 48px 24px; }
    .card { background: #151626; border: 1px solid #2f3450; border-radius: 14px; padding: 24px; }
    h1 { margin: 0 0 10px 0; font-size: 24px; }
    p { line-height: 1.5; color: #d2d6e8; }
    code { background: #232744; padding: 3px 6px; border-radius: 6px; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>${htmlEscape(title)}</h1>
      ${bodyHtml}
    </div>
  </div>
  ${extraHtml}
</body>
</html>`;
  res.writeHead(statusCode, { "Content-Type": "text/html; charset=utf-8" });
  res.end(page);
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
    "Access-Control-Max-Age": "600",
  };
}

function oauthReturnScript() {
  return `<script>
(() => {
  const bounceBackToGame = () => {
    try {
      if (window.opener && !window.opener.closed) {
        try {
          window.opener.postMessage({ type: "sgc_oauth_complete" }, "*");
        } catch (error) {}
        try {
          window.opener.focus();
        } catch (error) {}
        setTimeout(() => {
          try {
            window.close();
          } catch (error) {}
        }, 150);
      }
    } catch (error) {}
  };

  window.addEventListener("load", () => {
    setTimeout(bounceBackToGame, 400);
  });
})();
</script>`;
}

function sanitizeReturnUrl(rawUrl) {
  const value = String(rawUrl || "").trim();
  if (!value) return "";
  try {
    const parsed = new URL(value);
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
      return "";
    }
    return parsed.toString();
  } catch (error) {
    return "";
  }
}

function buildOauthReturnScript(returnUrl) {
  const safeReturnUrl = sanitizeReturnUrl(returnUrl);
  const returnUrlLiteral = JSON.stringify(safeReturnUrl);
  return `<script>
(() => {
  const returnUrl = ${returnUrlLiteral};

  const sendBackToGame = () => {
    try {
      if (window.opener && !window.opener.closed) {
        try {
          window.opener.postMessage({ type: "sgc_oauth_complete" }, "*");
        } catch (error) {}
        try {
          window.opener.focus();
        } catch (error) {}
        setTimeout(() => {
          try {
            window.close();
          } catch (error) {}
        }, 150);
      }
    } catch (error) {}
  };

  window.addEventListener("load", () => {
    setTimeout(sendBackToGame, 300);
  });
})();
</script>`;
}

function hasOauthConfig() {
  return !!(SGC_BASE_URL && SGC_API_KEY && SGC_OAUTH_CLIENT_ID && SGC_OAUTH_CLIENT_SECRET && SGC_OAUTH_REDIRECT_URI);
}

function normalizePublicOrigin(rawOrigin) {
  try {
    const parsed = new URL(rawOrigin);
    const proto = parsed.protocol === "http:" ? "http:" : "https:";
    const host = parsed.hostname;
    if (!host) {
      return "";
    }
    // Public redirects should not leak internal high ports.
    return `${proto}//${host}`;
  } catch (error) {
    return "";
  }
}

function oauthRedirectOrigin() {
  try {
    const parsed = new URL(SGC_OAUTH_REDIRECT_URI);
    return `${parsed.protocol}//${parsed.hostname}`;
  } catch (error) {
    return "";
  }
}

function requestPublicOrigin(req, requestUrl) {
  if (SGC_PUBLIC_ORIGIN) {
    const configured = normalizePublicOrigin(SGC_PUBLIC_ORIGIN);
    if (configured) {
      return configured;
    }
  }

  const forwardedProtoRaw = String(req.headers["x-forwarded-proto"] || "");
  const forwardedHostRaw = String(req.headers["x-forwarded-host"] || "");
  const forwardedProto = forwardedProtoRaw.split(",")[0].trim();
  const forwardedHost = forwardedHostRaw.split(",")[0].trim().split(":")[0];
  const proto = forwardedProto || requestUrl.protocol.replace(":", "") || "https";
  const hostHeader = String(req.headers.host || "").split(",")[0].trim();
  const host = forwardedHost || hostHeader.split(":")[0];
  if (!host) {
    return oauthRedirectOrigin();
  }
  const inferred = `${proto}://${host}`;
  return normalizePublicOrigin(inferred) || oauthRedirectOrigin();
}

function isPrivateOrLoopbackHost(hostname) {
  const host = String(hostname || "").toLowerCase();
  if (!host) return false;
  if (host === "localhost" || host === "127.0.0.1" || host === "::1") return true;
  if (host.startsWith("10.")) return true;
  if (host.startsWith("192.168.")) return true;
  if (/^172\.(1[6-9]|2[0-9]|3[0-1])\./.test(host)) return true;
  return false;
}

function rewriteAuthorizeUrlForPublicOrigin(authorizeUrl, publicOrigin) {
  try {
    const original = new URL(authorizeUrl);
    const needsRewrite = isPrivateOrLoopbackHost(original.hostname)
      || (original.protocol === "https:" && original.port && original.port !== "443")
      || (original.protocol === "http:" && original.port && original.port !== "80");
    if (!needsRewrite) {
      return authorizeUrl;
    }
    if (!publicOrigin) {
      return authorizeUrl;
    }
    const publicBase = new URL(publicOrigin);
    original.protocol = publicBase.protocol;
    original.host = publicBase.host;

    // Final guard: if a non-standard port somehow remains, strip it.
    if ((original.protocol === "https:" && original.port && original.port !== "443")
      || (original.protocol === "http:" && original.port && original.port !== "80")) {
      original.hostname = publicBase.hostname;
      original.port = "";
    }
    return original.toString();
  } catch (error) {
    return authorizeUrl;
  }
}

function oauthErrorDetail(error) {
  const top = error?.message ? String(error.message) : "unknown error";
  const causeCode = error?.cause?.code ? String(error.cause.code) : "";
  const causeMsg = error?.cause?.message ? String(error.cause.message) : "";
  if (causeCode && causeMsg) return `${top} (${causeCode}: ${causeMsg})`;
  if (causeCode) return `${top} (${causeCode})`;
  if (causeMsg) return `${top} (${causeMsg})`;
  return top;
}

async function revokeSgcLinkByExternalId(externalId) {
  const externalKey = String(externalId || "").trim();
  if (!externalKey) {
    throw new Error("external_id is required for revoke");
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const response = await fetch(`${SGC_BASE_URL}/v1/links/${encodeURIComponent(externalKey)}`, {
      method: "DELETE",
      headers: {
        Authorization: `Bearer ${SGC_API_KEY}`,
        Accept: "application/json",
      },
      signal: controller.signal,
    });

    const bodyText = await response.text();
    let parsed = null;
    if (bodyText) {
      try {
        parsed = JSON.parse(bodyText);
      } catch (error) {
        parsed = null;
      }
    }

    if (response.status === 404) {
      return { revoked: false, notFound: true, body: parsed };
    }

    if (!response.ok) {
      const message = parsed?.error?.message || `Link revoke failed (${response.status}).`;
      const error = new Error(message);
      error.status = response.status;
      error.body = parsed;
      throw error;
    }

    return {
      revoked: parsed?.revoked === true,
      notFound: false,
      body: parsed,
    };
  } finally {
    clearTimeout(timeout);
  }
}

function logSignedInPayload(player, signedIn, externalId, displayName, source) {
  console.log(
    `[sgc][to-gm][${source}] player=${player.id} signedIn=${signedIn} externalId=${externalId || "-"} displayName=${displayName || "-"}`
  );
}

function clearSignedInDelivery(player) {
  if (!player) return;
  if (player.signedInRetryTimer) {
    clearInterval(player.signedInRetryTimer);
    player.signedInRetryTimer = null;
  }
  player.pendingSignedInPayload = null;
  player.pendingSignedInSource = "";
  player.signedInAcked = false;
}

function queueSignedInDelivery(player, signedIn, externalId, displayName, source) {
  if (!player) return;

  if (player.signedInRetryTimer) {
    clearInterval(player.signedInRetryTimer);
    player.signedInRetryTimer = null;
  }

  player.pendingSignedInPayload = {
    type: "signed_in",
    playerId: player.id,
    signedIn: !!signedIn,
    externalId: externalId || "",
    displayName: displayName || "",
  };
  player.pendingSignedInSource = source || "push";
  player.signedInAcked = false;

  const sendAttempt = () => {
    if (!player.socket || player.socket.readyState !== WebSocket.OPEN) {
      return;
    }
    if (player.signedInAcked || !player.pendingSignedInPayload) {
      if (player.signedInRetryTimer) {
        clearInterval(player.signedInRetryTimer);
        player.signedInRetryTimer = null;
      }
      return;
    }

    logSignedInPayload(
      player,
      player.pendingSignedInPayload.signedIn,
      player.pendingSignedInPayload.externalId,
      player.pendingSignedInPayload.displayName,
      player.pendingSignedInSource
    );
    sendJson(player.socket, player.pendingSignedInPayload);
  };

  sendAttempt();
  player.signedInRetryTimer = setInterval(sendAttempt, 1000);
}

function acknowledgeSignedInDelivery(player, source = "client") {
  if (!player) return;
  player.signedInAcked = true;
  if (player.signedInRetryTimer) {
    clearInterval(player.signedInRetryTimer);
    player.signedInRetryTimer = null;
  }
  console.log(`[sgc][ack][${source}] player=${player.id} externalId=${player.sgcExternalId || "-"}`);
}

function hasSgcApiConfig() {
  return !!(SGC_BASE_URL && SGC_API_KEY);
}

async function refreshPlayerBankrollFromSgc(player, reason = "sync") {
  if (!player || !player.sgcSignedIn || !player.sgcExternalId || !hasSgcApiConfig()) {
    return false;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const response = await fetch(`${SGC_BASE_URL}/v1/users/${encodeURIComponent(player.sgcExternalId)}/balance`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${SGC_API_KEY}`,
        Accept: "application/json",
      },
      signal: controller.signal,
    });
    const text = await response.text();
    let parsed = null;
    if (text) {
      try {
        parsed = JSON.parse(text);
      } catch (error) {
        parsed = null;
      }
    }
    if (!response.ok) {
      console.warn(`[sgc] balance sync failed for ${player.id} (${reason}): status=${response.status}`);
      return false;
    }
    const balance = Number(parsed?.balance);
    if (!Number.isInteger(balance)) {
      console.warn(`[sgc] balance sync invalid schema for ${player.id} (${reason})`);
      return false;
    }
    player.bankroll = balance;
    return true;
  } catch (error) {
    const detail = oauthErrorDetail(error);
    console.warn(`[sgc] balance sync error for ${player.id} (${reason}): ${detail}`);
    return false;
  } finally {
    clearTimeout(timeout);
  }
}

async function sgcChargePlayer(player, amount, note, idempotencyKey) {
  const wager = Math.max(0, Number(amount) || 0);
  if (wager <= 0) {
    return { ok: true, balance: player.bankroll, fee: 0, source: "noop" };
  }

  if (player.sgcSignedIn && player.sgcExternalId && hasSgcApiConfig()) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 7000);
    try {
      const response = await fetch(`${SGC_BASE_URL}/v1/charge`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${SGC_API_KEY}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          "Idempotency-Key": idempotencyKey,
        },
        body: JSON.stringify({
          external_id: player.sgcExternalId,
          amount: wager,
          note,
          idempotency_key: idempotencyKey,
        }),
        signal: controller.signal,
      });
      const text = await response.text();
      let parsed = null;
      if (text) {
        try {
          parsed = JSON.parse(text);
        } catch (error) {
          parsed = null;
        }
      }

      if (!response.ok) {
        return {
          ok: false,
          status: response.status,
          code: parsed?.error?.code || "charge_failed",
          message: parsed?.error?.message || `Charge failed (${response.status}).`,
        };
      }

      const nextBalance = Number(parsed?.balance);
      if (Number.isInteger(nextBalance)) player.bankroll = nextBalance;
      return {
        ok: true,
        balance: player.bankroll,
        fee: Number(parsed?.fee) || 0,
        source: "sgc",
      };
    } catch (error) {
      return {
        ok: false,
        code: "charge_network_error",
        message: oauthErrorDetail(error),
      };
    } finally {
      clearTimeout(timeout);
    }
  }

  if (player.bankroll < wager) {
    return { ok: false, code: "insufficient_balance", message: "Insufficient SGC balance." };
  }
  player.bankroll -= wager;
  return { ok: true, balance: player.bankroll, fee: 0, source: "local" };
}

async function sgcCreditPlayer(player, amount, note, idempotencyKey) {
  const payout = Math.max(0, Number(amount) || 0);
  if (payout <= 0) {
    return { ok: true, balance: player.bankroll, source: "noop" };
  }

  if (player.sgcSignedIn && player.sgcExternalId && hasSgcApiConfig()) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 7000);
    try {
      const response = await fetch(`${SGC_BASE_URL}/v1/credit`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${SGC_API_KEY}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          "Idempotency-Key": idempotencyKey,
        },
        body: JSON.stringify({
          external_id: player.sgcExternalId,
          amount: payout,
          note,
          idempotency_key: idempotencyKey,
        }),
        signal: controller.signal,
      });
      const text = await response.text();
      let parsed = null;
      if (text) {
        try {
          parsed = JSON.parse(text);
        } catch (error) {
          parsed = null;
        }
      }

      if (!response.ok) {
        return {
          ok: false,
          status: response.status,
          code: parsed?.error?.code || "credit_failed",
          message: parsed?.error?.message || `Credit failed (${response.status}).`,
        };
      }

      const nextBalance = Number(parsed?.balance);
      if (Number.isInteger(nextBalance)) player.bankroll = nextBalance;
      return {
        ok: true,
        balance: player.bankroll,
        source: "sgc",
      };
    } catch (error) {
      return {
        ok: false,
        code: "credit_network_error",
        message: oauthErrorDetail(error),
      };
    } finally {
      clearTimeout(timeout);
    }
  }

  player.bankroll += payout;
  return { ok: true, balance: player.bankroll, source: "local" };
}

function getCompletedOauthSession(sessionId) {
  const key = String(sessionId || "").trim();
  if (!key) return false;
  const record = oauthCompletedBySessionId.get(key);
  if (!record) return null;
  if ((Date.now() - record.linkedAt) > oauthPendingTtlMs) {
    oauthCompletedBySessionId.delete(key);
    return null;
  }
  return record;
}

function resolveDisplayNameFromOauthPayload(payload, fallbackName) {
  const fallback = String(fallbackName || "").trim();
  const safeFallback = (/^Player\s+\d+$/i.test(fallback) || /^player$/i.test(fallback) || fallback === "") ? "" : fallback;
  const candidates = [
    // New Discord username fields (identity:read enabled)
    payload?.user?.discord_username,
    payload?.discord_username,
    payload?.user?.discord_name,
    payload?.discord_name,
    // Legacy/alternative locations
    payload?.user?.display_name,
    payload?.user?.global_name,
    payload?.user?.username,
    payload?.discord_user?.display_name,
    payload?.discord_user?.global_name,
    payload?.discord_user?.username,
    payload?.account?.display_name,
    payload?.account?.username,
    payload?.profile?.display_name,
    payload?.profile?.username,
    payload?.display_name,
    payload?.username,
    payload?.link?.discord_name,
    payload?.discord?.display_name,
    payload?.discord?.username,
    payload?.external_name,
    safeFallback,
  ];

  for (const candidate of candidates) {
    if (typeof candidate === "string") {
      const trimmed = candidate.trim();
      if (trimmed) {
        return trimmed.slice(0, 24);
      }
    }
  }

  return "";
}

function markOauthLinked(sessionId, externalId, displayName) {
  const statusKey = String(sessionId || "").trim();
  const externalKey = String(externalId || "").trim();
  if (!statusKey || !externalKey) return;
  oauthCompletedBySessionId.set(statusKey, {
    linkedAt: Date.now(),
    externalId: externalKey,
    displayName: String(displayName || ""),
  });

  for (const player of state.players.values()) {
    if (player.sgcExternalId === externalKey) {
      player.sgcSignedIn = true;
      if (displayName) {
        player.name = String(displayName).slice(0, 24);
      }

      refreshPlayerBankrollFromSgc(player, "oauth_linked")
        .finally(() => {
          queueSignedInDelivery(player, true, player.sgcExternalId, displayName || player.name, "oauth_linked");
          broadcastState();
          for (const game of tableGames) broadcastTableGame(game);
        });
    }
  }
}

const tableGames = new Set(["slots", "pachinko", "blackjack", "holdem", "horse", "breakout", "snake"]);
const slotSymbolCount = 6;
const slotPoints = [1, 2, 3, 5, 7, 10];
const pachinkoWidth = 10;
const pachinkoRows = 9;
const cardSuits = ["S", "H", "D", "C"];
const cardRanks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];

function angleNorm(value) {
  return ((value % 360) + 360) % 360;
}

function rouletteIsRed(number) {
  return redNumbers.has(number);
}

function buildColumn(modValue) {
  const values = [];
  for (let n = modValue; n <= 36; n += 3) {
    values.push(n);
  }
  return values;
}

function buildRange(startValue, endValue) {
  const values = [];
  for (let n = startValue; n <= endValue; n += 1) {
    values.push(n);
  }
  return values;
}

function buildEvenMoney(kind) {
  const values = [];
  for (let n = 1; n <= 36; n += 1) {
    let include = false;
    if (kind === "low") include = n <= 18;
    if (kind === "high") include = n >= 19;
    if (kind === "even") include = n % 2 === 0;
    if (kind === "odd") include = n % 2 === 1;
    if (kind === "red") include = rouletteIsRed(n);
    if (kind === "black") include = !rouletteIsRed(n);
    if (include) values.push(n);
  }
  return values;
}

const betDefinitions = new Map();
betDefinitions.set("n_0", { payout: 35, covered: [0] });
for (let n = 1; n <= 36; n += 1) {
  betDefinitions.set(`n_${n}`, { payout: 35, covered: [n] });
}
betDefinitions.set("col_1", { payout: 2, covered: buildColumn(1) });
betDefinitions.set("col_2", { payout: 2, covered: buildColumn(2) });
betDefinitions.set("col_3", { payout: 2, covered: buildColumn(3) });
betDefinitions.set("dozen_1", { payout: 2, covered: buildRange(1, 12) });
betDefinitions.set("dozen_2", { payout: 2, covered: buildRange(13, 24) });
betDefinitions.set("dozen_3", { payout: 2, covered: buildRange(25, 36) });
betDefinitions.set("low", { payout: 1, covered: buildEvenMoney("low") });
betDefinitions.set("high", { payout: 1, covered: buildEvenMoney("high") });
betDefinitions.set("even", { payout: 1, covered: buildEvenMoney("even") });
betDefinitions.set("odd", { payout: 1, covered: buildEvenMoney("odd") });
betDefinitions.set("red", { payout: 1, covered: buildEvenMoney("red") });
betDefinitions.set("black", { payout: 1, covered: buildEvenMoney("black") });

function getWinningNumber(rotation, ballAngle, zeroOffset, segmentAngle) {
  const local = angleNorm(rotation - ballAngle + zeroOffset);
  const idx = Math.floor((local + segmentAngle * 0.5) / segmentAngle) % wheelOrder.length;
  return wheelOrder[idx];
}

function playerBetTotal(player) {
  let total = 0;
  for (const amount of Object.values(player.bets)) {
    total += amount;
  }
  return total;
}

function createLobby(name) {
  const lobby = {
    id: `L${state.nextLobbyId++}`,
    name,
    playerIds: new Set(),
    phase: "betting",
    rotation: 0,
    ballAngle: 0,
    winningNumber: -1,
    lastSpinSummary: "Place bets, then click SPIN.",
    currentSpinPlan: null,
  };

  state.lobbies.set(lobby.id, lobby);
  return lobby;
}

function getLobbyForPlayer(player) {
  if (!player.lobbyId) {
    return null;
  }

  return state.lobbies.get(player.lobbyId) || null;
}

function aggregateTableTotals(lobby) {
  const totals = {};
  if (!lobby) {
    return totals;
  }

  for (const playerId of lobby.playerIds.values()) {
    const player = state.players.get(playerId);
    if (!player) {
      continue;
    }
    for (const [key, amount] of Object.entries(player.bets)) {
      totals[key] = (totals[key] || 0) + amount;
    }
  }
  return totals;
}

function buildLobbyList() {
  const lobbies = [];

  for (const lobby of state.lobbies.values()) {
    lobbies.push({
      id: lobby.id,
      name: lobby.name,
      playerCount: lobby.playerIds.size,
      phase: lobby.phase,
    });
  }

  lobbies.sort((left, right) => left.name.localeCompare(right.name));
  return lobbies;
}

function refundPlayerBets(player) {
  const refund = playerBetTotal(player);
  if (refund > 0) {
    player.bankroll += refund;
  }
  player.bets = {};
  player.lastWager = 0;
  player.lastPayout = 0;
}

function removePlayerFromLobby(player) {
  const lobby = getLobbyForPlayer(player);
  if (!lobby) {
    player.lobbyId = "";
    return;
  }

  if (lobby.phase == "betting") {
    refundPlayerBets(player);
  }

  lobby.playerIds.delete(player.id);
  player.lobbyId = "";

  if (lobby.playerIds.size === 0) {
    state.lobbies.delete(lobby.id);
  }
}

function createEmptyTableSeat(player) {
  return {
    playerId: player.id,
    name: player.name,
    balance: player.bankroll,
    bet: 5,
    status: "Ready",
    running: false,
    grid: randomSlotGrid(),
    finalGrid: randomSlotGrid(),
    guess: 5,
    path: [],
    visibleRows: 0,
    landedPeg: 0,
    hand: [],
    folded: false,
    stayed: false,
    acted: false,
    horseChoice: 0,
    raceBet: 0,
    role: "player",
    breakout: {
      score: 0,
      level: 1,
      lives: 3,
      distance: 0,
      batNorm: 0.5,
      ballXNorm: 0.5,
      ballYNorm: 0.85,
      brickCount: 0,
      brickMask: "",
      brickColorMask: "",
      finished: false,
      acceptedRematch: null,
    },
    snake: {
      score: 0,
      length: 3,
      distance: 0,
      headXNorm: 0.5,
      headYNorm: 0.5,
      segmentPoints: [],
      alive: true,
      finished: false,
      acceptedRematch: null,
    },
    timer: null,
  };
}

function createTableLobby(game, name) {
  const lobby = {
    id: `T${state.nextTableLobbyId++}`,
    game,
    name,
    playerIds: [],
    seats: new Map(),
    lastEvent: "Waiting for players.",
    deck: [],
    dealerHand: [],
    community: [],
    phase: "waiting",
    turnIndex: 0,
    pot: 0,
    currentBet: 0,
    hostPlayerId: "",
    horseState: "betting",
    horsePositions: [0, 0, 0, 0],
    horseWinner: -1,
    horseUnderdog: -1,
    horseWins: [0, 0, 0, 0],
    horseTimer: null,
    breakout: {
      state: "waiting",
      player1Id: "",
      player2Id: "",
      raceSeed: 0,
      winnerId: "",
      loserId: "",
      challengerPromptOpen: false,
      allowBets: true,
      scoreboard: {},
      bets: {},
      rematchVotes: {},
      showdownSummary: "Waiting for two racers.",
    },
    snake: {
      state: "waiting",
      player1Id: "",
      player2Id: "",
      raceSeed: 0,
      winnerId: "",
      loserId: "",
      challengerPromptOpen: false,
      allowBets: true,
      scoreboard: {},
      bets: {},
      rematchVotes: {},
      showdownSummary: "Waiting for two racers.",
    },
  };

  if (game !== "breakout") {
    delete lobby.breakout;
  }
  if (game !== "snake") {
    delete lobby.snake;
  }
  state.tableLobbies.set(lobby.id, lobby);
  return lobby;
}

function tableMaxPlayers(game) {
  if (game === "slots" || game === "pachinko") return 3;
  if (game === "blackjack") return 6;
  if (game === "horse") return 20;
  if (game === "breakout") return 7;
  if (game === "snake") return 7;
  return 8;
}

function breakoutScoreDistance(level, score) {
  const safeLevel = Math.max(1, Number(level) || 1);
  const safeScore = Math.max(0, Number(score) || 0);
  return (safeLevel - 1) * 100 + safeScore;
}

function breakoutRoleCounts(lobby) {
  const counts = { racer: 0, spectator: 0 };
  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    if (seat.role === "racer") counts.racer += 1;
    else counts.spectator += 1;
  }
  return counts;
}

function breakoutEnsureRoles(lobby) {
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  if (!breakout) return;

  if (breakout.player1Id && !lobby.seats.has(breakout.player1Id)) breakout.player1Id = "";
  if (breakout.player2Id && !lobby.seats.has(breakout.player2Id)) breakout.player2Id = "";

  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    if (id === breakout.player1Id || id === breakout.player2Id) {
      seat.role = "racer";
    } else {
      seat.role = "spectator";
    }
  }

  if (!breakout.player1Id) {
    const firstRacer = lobby.playerIds.find((id) => lobby.seats.get(id)?.role === "racer") || lobby.playerIds[0] || "";
    breakout.player1Id = firstRacer;
  }

  if (!breakout.player2Id) {
    const candidate = lobby.playerIds.find((id) => id !== breakout.player1Id && lobby.seats.has(id)) || "";
    breakout.player2Id = candidate;
  }

  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    if (id === breakout.player1Id || id === breakout.player2Id) seat.role = "racer";
    else seat.role = "spectator";
  }
}

function breakoutRacerIds(lobby) {
  if (!lobby || lobby.game !== "breakout") return [];
  const ids = [];
  if (lobby.breakout.player1Id && lobby.seats.has(lobby.breakout.player1Id)) ids.push(lobby.breakout.player1Id);
  if (lobby.breakout.player2Id && lobby.seats.has(lobby.breakout.player2Id)) ids.push(lobby.breakout.player2Id);
  return ids;
}

function breakoutResetRaceSeat(seat) {
  seat.breakout.score = 0;
  seat.breakout.level = 1;
  seat.breakout.lives = 3;
  seat.breakout.distance = 0;
  seat.breakout.batNorm = 0.5;
  seat.breakout.ballXNorm = 0.5;
  seat.breakout.ballYNorm = 0.85;
  seat.breakout.brickCount = 0;
  seat.breakout.brickMask = "";
  seat.breakout.brickColorMask = "";
  seat.breakout.finished = false;
  seat.breakout.acceptedRematch = null;
  seat.status = "Ready";
}

function breakoutMoveWinnerToP1(lobby, winnerId) {
  if (!lobby || lobby.game !== "breakout") return;
  if (!winnerId) return;
  if (!lobby.seats.has(winnerId)) return;
  const breakout = lobby.breakout;
  const previousP1 = breakout.player1Id;
  breakout.player1Id = winnerId;
  if (previousP1 && previousP1 !== winnerId && previousP1 !== breakout.player2Id && lobby.seats.has(previousP1)) {
    lobby.seats.get(previousP1).role = "spectator";
  }
  if (breakout.player2Id === winnerId) {
    breakout.player2Id = previousP1 && previousP1 !== winnerId ? previousP1 : "";
  }
  breakoutEnsureRoles(lobby);
}

function breakoutOpenChallengerPrompt(lobby, reasonText) {
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  const loserId = breakout.loserId;
  if (loserId && lobby.seats.has(loserId)) {
    const loserSeat = lobby.seats.get(loserId);
    loserSeat.role = "spectator";
    loserSeat.status = "Spectating";
  }
  breakout.player2Id = "";
  breakout.challengerPromptOpen = true;
  breakout.state = "waiting";
  breakout.allowBets = true;
  breakout.showdownSummary = reasonText || "Select next challenger.";
  breakout.rematchVotes = {};
  breakoutEnsureRoles(lobby);
}

function breakoutSnapshot(lobby) {
  if (!lobby || lobby.game !== "breakout") return undefined;
  const breakout = lobby.breakout;
  const betLedger = [];
  for (const [bettorId, bet] of Object.entries(breakout.bets || {})) {
    const bettorName = state.players.get(bettorId)?.name || "Spectator";
    const targets = bet && typeof bet.targets === "object"
      ? bet.targets
      : (bet && bet.targetId ? { [String(bet.targetId)]: Math.max(0, Number(bet.amount) || 0) } : {});
    for (const [targetId, amountRaw] of Object.entries(targets)) {
      const amount = Math.max(0, Number(amountRaw) || 0);
      if (!targetId || amount <= 0) continue;
      betLedger.push({
        bettorId,
        bettorName,
        targetId,
        amount,
      });
    }
  }
  return {
    state: breakout.state,
    player1Id: breakout.player1Id,
    player2Id: breakout.player2Id,
    raceSeed: breakout.raceSeed,
    winnerId: breakout.winnerId,
    loserId: breakout.loserId,
    challengerPromptOpen: breakout.challengerPromptOpen,
    allowBets: breakout.allowBets,
    showdownSummary: breakout.showdownSummary,
    rematchVotes: breakout.rematchVotes,
    scoreboard: breakout.scoreboard,
    bets: betLedger,
  };
}

function getTableLobbyForPlayer(player) {
  if (!player.tableLobbyId) return null;
  return state.tableLobbies.get(player.tableLobbyId) || null;
}

function clearTableSeatTimer(seat) {
  if (seat?.timer) {
    clearInterval(seat.timer);
    seat.timer = null;
  }
}

function removePlayerFromTableLobby(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby) {
    player.tableLobbyId = "";
    return;
  }

  const seat = lobby.seats.get(player.id);
  clearTableSeatTimer(seat);

  if (lobby.game === "breakout") {
    const breakout = lobby.breakout;
    if (breakout.player1Id === player.id) breakout.player1Id = "";
    if (breakout.player2Id === player.id) breakout.player2Id = "";
    delete breakout.rematchVotes[player.id];
    delete breakout.scoreboard[player.id];
    delete breakout.bets[player.id];
  }
  if (lobby.game === "snake") {
    const snake = lobby.snake;
    if (snake.player1Id === player.id) snake.player1Id = "";
    if (snake.player2Id === player.id) snake.player2Id = "";
    delete snake.rematchVotes[player.id];
    delete snake.scoreboard[player.id];
    delete snake.bets[player.id];
  }

  lobby.seats.delete(player.id);
  lobby.playerIds = lobby.playerIds.filter((id) => id !== player.id);
  player.tableLobbyId = "";
  lobby.lastEvent = `${player.name} left ${lobby.name}.`;

  if (lobby.hostPlayerId === player.id) {
    lobby.hostPlayerId = lobby.playerIds.length > 0 ? lobby.playerIds[0] : "";
    if (lobby.hostPlayerId) {
      const host = state.players.get(lobby.hostPlayerId);
      if (host) lobby.lastEvent = `${host.name} is now host of ${lobby.name}.`;
    }
  }

  if ((lobby.game === "blackjack" || lobby.game === "holdem") && lobby.phase !== "waiting") {
    advanceTableTurn(lobby);
  }

  if (lobby.playerIds.length === 0) {
    if (lobby.horseTimer) {
      clearInterval(lobby.horseTimer);
      lobby.horseTimer = null;
    }
    state.tableLobbies.delete(lobby.id);
  } else if (lobby.game === "breakout") {
    breakoutEnsureRoles(lobby);
  } else if (lobby.game === "snake") {
    snakeEnsureRoles(lobby);
  }
}

function assignPlayerToTableLobby(player, lobby) {
  if (lobby.playerIds.includes(player.id)) return true;
  if (lobby.playerIds.length >= tableMaxPlayers(lobby.game)) return false;

  removePlayerFromTableLobby(player);
  player.tableLobbyId = lobby.id;
  lobby.playerIds.push(player.id);
  lobby.seats.set(player.id, createEmptyTableSeat(player));

  if (lobby.game === "breakout") {
    const breakout = lobby.breakout;
    const seat = lobby.seats.get(player.id);
    if (!breakout.player1Id) {
      breakout.player1Id = player.id;
      seat.role = "racer";
      seat.status = "Player 1";
    } else if (!breakout.player2Id) {
      breakout.player2Id = player.id;
      seat.role = "racer";
      seat.status = "Player 2";
    } else {
      seat.role = "spectator";
      seat.status = "Spectating";
    }
    breakoutEnsureRoles(lobby);
  }
  if (lobby.game === "snake") {
    const snake = lobby.snake;
    const seat = lobby.seats.get(player.id);
    if (!snake.player1Id) {
      snake.player1Id = player.id;
      seat.role = "racer";
      seat.status = "Player 1";
    } else if (!snake.player2Id) {
      snake.player2Id = player.id;
      seat.role = "racer";
      seat.status = "Player 2";
    } else {
      seat.role = "spectator";
      seat.status = "Spectating";
    }
    snakeEnsureRoles(lobby);
  }

  if (!lobby.hostPlayerId) lobby.hostPlayerId = player.id;
  lobby.lastEvent = `${player.name} joined ${lobby.name}.`;
  return true;
}

function horseUnderdogIndex(horseWins) {
  let best = 0;
  for (let i = 1; i < horseWins.length; i += 1) {
    if (horseWins[i] < horseWins[best]) best = i;
  }
  let tied = true;
  for (let i = 1; i < horseWins.length; i += 1) {
    if (horseWins[i] !== horseWins[0]) tied = false;
  }
  return tied ? -1 : best;
}

function freshDeck() {
  const deck = [];
  for (const suit of cardSuits) {
    for (const rank of cardRanks) {
      deck.push({ rank, suit });
    }
  }
  for (let i = deck.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
}

function drawCard(deck) {
  return deck.pop();
}

function blackjackCardValue(card) {
  if (!card) return 0;
  if (card.rank === "A") return 11;
  if (["J", "Q", "K"].includes(card.rank)) return 10;
  return Number(card.rank);
}

function blackjackValue(hand) {
  let total = 0;
  let aces = 0;
  for (const card of hand) {
    total += blackjackCardValue(card);
    if (card.rank === "A") aces += 1;
  }
  while (total > 21 && aces > 0) {
    total -= 10;
    aces -= 1;
  }
  return total;
}

function blackjackNatural(hand) {
  return hand.length === 2 && blackjackValue(hand) === 21;
}

function rankPokerValue(card) {
  if (card.rank === "A") return 14;
  if (card.rank === "K") return 13;
  if (card.rank === "Q") return 12;
  if (card.rank === "J") return 11;
  return Number(card.rank);
}

function pokerScore(cards) {
  const counts = Array(15).fill(0);
  const suits = new Map();
  for (const card of cards) {
    const value = rankPokerValue(card);
    counts[value] += 1;
    suits.set(card.suit, (suits.get(card.suit) || 0) + 1);
  }
  counts[1] = counts[14];
  const flush = [...suits.values()].some((count) => count >= 5);
  let straightHigh = 0;
  let run = 0;
  for (let value = 1; value <= 14; value += 1) {
    if (counts[value] > 0) {
      run += 1;
      if (run >= 5) straightHigh = value;
    } else {
      run = 0;
    }
  }
  let fours = 0;
  let threes = 0;
  let pairs = 0;
  let high = 0;
  for (let value = 14; value >= 2; value -= 1) {
    if (counts[value] > 0 && high === 0) high = value;
    if (counts[value] === 4 && fours === 0) fours = value;
    if (counts[value] === 3 && threes === 0) threes = value;
    if (counts[value] === 2) pairs += 1;
  }
  if (flush && straightHigh > 0) return 800000 + straightHigh;
  if (fours > 0) return 700000 + fours;
  if (threes > 0 && pairs > 0) return 600000 + threes;
  if (flush) return 500000 + high;
  if (straightHigh > 0) return 400000 + straightHigh;
  if (threes > 0) return 300000 + threes;
  if (pairs >= 2) return 200000 + high;
  if (pairs === 1) return 100000 + high;
  return high;
}

function pokerLabel(score) {
  if (score >= 800000) return "straight flush";
  if (score >= 700000) return "four of a kind";
  if (score >= 600000) return "full house";
  if (score >= 500000) return "flush";
  if (score >= 400000) return "straight";
  if (score >= 300000) return "three of a kind";
  if (score >= 200000) return "two pair";
  if (score >= 100000) return "one pair";
  return "high card";
}

function activeSeatIds(lobby) {
  return lobby.playerIds.filter((id) => {
    const seat = lobby.seats.get(id);
    return seat && !seat.folded && !seat.stayed && playerCanAct(lobby, seat);
  });
}

function playerCanAct(lobby, seat) {
  if (!seat) return false;
  if (lobby.game === "blackjack") return seat.hand.length > 0 && !seat.stayed && blackjackValue(seat.hand) < 21;
  if (lobby.game === "holdem") return seat.hand.length > 0 && !seat.folded && !seat.acted;
  return false;
}

function currentTurnPlayerId(lobby) {
  if (lobby.phase === "waiting" || lobby.phase === "done" || lobby.phase === "showdown") return "";
  for (let offset = 0; offset < lobby.playerIds.length; offset += 1) {
    const index = (lobby.turnIndex + offset) % lobby.playerIds.length;
    const id = lobby.playerIds[index];
    const seat = lobby.seats.get(id);
    if (playerCanAct(lobby, seat)) {
      lobby.turnIndex = index;
      return id;
    }
  }
  return "";
}

function advanceTableTurn(lobby) {
  if (!lobby.playerIds.length) return;
  lobby.turnIndex = (lobby.turnIndex + 1) % lobby.playerIds.length;
  if (lobby.game === "blackjack" && !currentTurnPlayerId(lobby)) resolveTableBlackjack(lobby);
  if (lobby.game === "holdem" && !currentTurnPlayerId(lobby)) advanceHoldemStreet(lobby);
}

function randomSlotSymbol() {
  const weights = [24, 20, 18, 13, 9, 5];
  const total = weights.reduce((sum, weight) => sum + weight, 0);
  let roll = Math.floor(Math.random() * total);
  for (let i = 0; i < weights.length; i += 1) {
    roll -= weights[i];
    if (roll < 0) return i;
  }
  return 0;
}

function randomSlotGrid() {
  return Array.from({ length: 9 }, () => randomSlotSymbol());
}

function slotLinePoints(a, b, c) {
  const wild = 1;
  if (a === b && b === c) return slotPoints[a];
  if (a === wild && b === c) return Math.max(1, Math.floor(slotPoints[b] / 2));
  if (b === wild && a === c) return Math.max(1, Math.floor(slotPoints[a] / 2));
  if (c === wild && a === b) return Math.max(1, Math.floor(slotPoints[a] / 2));
  return 0;
}

function evaluateSlotGrid(grid) {
  return slotLinePoints(grid[0], grid[1], grid[2])
    + slotLinePoints(grid[3], grid[4], grid[5])
    + slotLinePoints(grid[6], grid[7], grid[8])
    + slotLinePoints(grid[0], grid[4], grid[8])
    + slotLinePoints(grid[2], grid[4], grid[6]);
}

function simulatePachinkoPath() {
  const path = [];
  let pos = 3 + Math.floor(Math.random() * 4);
  for (let row = 0; row < pachinkoRows; row += 1) {
    path.push(pos);
    pos = Math.max(0, Math.min(pachinkoWidth - 1, pos + (Math.random() < 0.5 ? -1 : 1)));
  }
  return path;
}

function buildTableLobbyList(game) {
  return [...state.tableLobbies.values()]
    .filter((lobby) => lobby.game === game)
    .map((lobby) => ({
      id: lobby.id,
      name: lobby.name,
      game: lobby.game,
      playerCount: lobby.playerIds.length,
      maxPlayers: tableMaxPlayers(game),
      phase: lobby.phase !== "waiting" ? lobby.phase : (lobby.playerIds.some((id) => lobby.seats.get(id)?.running) ? "playing" : "ready"),
    }))
    .sort((left, right) => left.name.localeCompare(right.name));
}

function buildTableSeats(lobby) {
  if (!lobby) return [null, null, null];
  const seats = lobby.playerIds.map((id) => {
    const seat = lobby.seats.get(id);
    const player = state.players.get(id);
    if (!seat || !player) return null;
    return {
      playerId: id,
      name: player.name,
      balance: player.bankroll,
      bet: seat.bet,
      status: seat.status,
      running: seat.running,
      grid: seat.grid,
      guess: seat.guess,
      path: seat.path,
      visibleRows: seat.visibleRows,
      landedPeg: seat.landedPeg,
      hand: seat.hand,
      folded: seat.folded,
      stayed: seat.stayed,
      acted: seat.acted,
      horseChoice: seat.horseChoice,
      raceBet: seat.raceBet,
      role: seat.role,
      breakout: seat.breakout,
      snake: seat.snake,
    };
  });
  while (seats.length < tableMaxPlayers(lobby.game)) seats.push(null);
  return seats.slice(0, tableMaxPlayers(lobby.game));
}

function sanitizeCard(card) {
  return card ? { rank: card.rank, suit: card.suit } : null;
}

function buildTableParticipants(lobby, forPlayer) {
  if (!lobby) return [];
  return lobby.playerIds.map((id) => {
    const seat = lobby.seats.get(id);
    const player = state.players.get(id);
    if (!seat || !player) return null;
    const showHand = lobby.game === "blackjack" || id === forPlayer.id || lobby.phase === "showdown" || lobby.phase === "done" || seat.folded;
    return {
      playerId: id,
      name: player.name,
      balance: player.bankroll,
      bet: seat.bet,
      status: seat.status,
      folded: seat.folded,
      stayed: seat.stayed,
      acted: seat.acted,
      isTurn: currentTurnPlayerId(lobby) === id,
      hand: showHand ? seat.hand.map(sanitizeCard) : seat.hand.map(() => null),
      total: lobby.game === "blackjack" && showHand ? blackjackValue(seat.hand) : 0,
      isHost: lobby.hostPlayerId === id,
      horseChoice: seat.horseChoice,
      role: seat.role,
      breakout: seat.breakout,
      snake: seat.snake,
    };
  }).filter(Boolean);
}

function buildTableSnapshot(forPlayer, game) {
  const lobby = getTableLobbyForPlayer(forPlayer);
  const inRequestedGame = lobby && lobby.game === game;
  const turnPlayerId = inRequestedGame ? currentTurnPlayerId(lobby) : "";
  return {
    type: "table_state",
    game,
    playerId: forPlayer.id,
    bankroll: forPlayer.bankroll,
    currentLobbyId: inRequestedGame ? lobby.id : "",
    currentLobbyName: inRequestedGame ? lobby.name : "No lobby",
    playerCount: inRequestedGame ? lobby.playerIds.length : 0,
    maxPlayers: tableMaxPlayers(game),
    lastEvent: inRequestedGame ? lobby.lastEvent : "Join or create a lobby.",
    lobbies: buildTableLobbyList(game),
    seats: inRequestedGame ? buildTableSeats(lobby) : [null, null, null],
    participants: inRequestedGame ? buildTableParticipants(lobby, forPlayer) : [],
    phase: inRequestedGame ? lobby.phase : "waiting",
    turnPlayerId,
    youAreTurn: turnPlayerId === forPlayer.id,
    dealerHand: inRequestedGame ? lobby.dealerHand.map((card, index) => (lobby.phase === "blackjack_turns" && index === 1 ? null : sanitizeCard(card))) : [],
    community: inRequestedGame ? lobby.community.map(sanitizeCard) : [],
    pot: inRequestedGame ? lobby.pot : 0,
    hostPlayerId: inRequestedGame ? lobby.hostPlayerId : "",
    horseState: inRequestedGame && lobby.game === "horse" ? lobby.horseState : "betting",
    horsePositions: inRequestedGame && lobby.game === "horse" ? lobby.horsePositions : [0, 0, 0, 0],
    horseWinner: inRequestedGame && lobby.game === "horse" ? lobby.horseWinner : -1,
    horseUnderdog: inRequestedGame && lobby.game === "horse" ? lobby.horseUnderdog : -1,
    horseWins: inRequestedGame && lobby.game === "horse" ? lobby.horseWins : [0, 0, 0, 0],
    breakout: inRequestedGame && lobby.game === "breakout" ? breakoutSnapshot(lobby) : undefined,
    snake: inRequestedGame && lobby.game === "snake" ? snakeSnapshot(lobby) : undefined,
  };
}

function sendTableSnapshot(player, game) {
  sendJson(player.socket, buildTableSnapshot(player, game));
}

function broadcastTableGame(game) {
  for (const player of state.players.values()) {
    sendTableSnapshot(player, game);
  }
}

function startTableSlotSpin(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "slots") return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.running) return;
  const bet = Math.max(1, Number(seat.bet) || 1);
  if (player.bankroll < bet) {
    seat.status = "Insufficient SGC";
    broadcastTableGame("slots");
    return;
  }

  player.bankroll -= bet;
  seat.running = true;
  seat.finalGrid = randomSlotGrid();
  seat.status = `Spinning for ${bet} SGC`;
  let frame = 0;
  clearTableSeatTimer(seat);
  seat.timer = setInterval(() => {
    frame += 1;
    if (frame < 18) {
      seat.grid = randomSlotGrid();
    } else {
      clearTableSeatTimer(seat);
      seat.grid = [...seat.finalGrid];
      const points = evaluateSlotGrid(seat.grid);
      const payout = points * bet;
      player.bankroll += payout;
      seat.running = false;
      seat.status = payout > 0 ? `Won ${payout} SGC` : "No line hit";
      lobby.lastEvent = `${player.name}: ${seat.status}.`;
    }
    broadcastTableGame("slots");
  }, 90);
  lobby.lastEvent = `${player.name} pulled the lever.`;
  broadcastTableGame("slots");
}

function startTablePachinkoDrop(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "pachinko") return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.running) return;
  const bet = Math.max(1, Number(seat.bet) || 1);
  if (player.bankroll < bet) {
    seat.status = "Insufficient SGC";
    broadcastTableGame("pachinko");
    return;
  }

  player.bankroll -= bet;
  seat.path = simulatePachinkoPath();
  seat.visibleRows = 1;
  seat.landedPeg = 0;
  seat.running = true;
  seat.status = `Dropping toward peg ${seat.guess}`;
  clearTableSeatTimer(seat);
  seat.timer = setInterval(() => {
    seat.visibleRows += 1;
    if (seat.visibleRows >= seat.path.length) {
      seat.visibleRows = seat.path.length;
      clearTableSeatTimer(seat);
      seat.landedPeg = seat.path[seat.path.length - 1] + 1;
      const distance = Math.abs(seat.guess - seat.landedPeg);
      let payout = 0;
      if (distance === 0) payout = bet * 2;
      else if (distance === 1) payout = Math.floor(bet * 1.5);
      else if (distance === 2) payout = bet;
      player.bankroll += payout;
      seat.running = false;
      seat.status = payout > 0 ? `Peg ${seat.landedPeg}: paid ${payout} SGC` : `Peg ${seat.landedPeg}: no payout`;
      lobby.lastEvent = `${player.name}: ${seat.status}.`;
    }
    broadcastTableGame("pachinko");
  }, 180);
  lobby.lastEvent = `${player.name} dropped a pachinko ball.`;
  broadcastTableGame("pachinko");
}

function resetCardSeats(lobby) {
  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    seat.hand = [];
    seat.folded = false;
    seat.stayed = false;
    seat.acted = false;
    seat.status = "Ready";
  }
}

function startTableBlackjack(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "blackjack" || lobby.phase === "blackjack_turns") return;
  const bet = Math.max(1, Number(lobby.seats.get(player.id)?.bet) || 1);
  const participants = lobby.playerIds
    .map((id) => state.players.get(id))
    .filter((participant) => participant && participant.bankroll >= bet);
  if (!participants.length) return;

  resetCardSeats(lobby);
  lobby.deck = freshDeck();
  lobby.dealerHand = [drawCard(lobby.deck), drawCard(lobby.deck)];
  lobby.community = [];
  lobby.phase = "blackjack_turns";
  lobby.turnIndex = 0;
  lobby.pot = 0;
  for (const participant of participants) {
    const seat = lobby.seats.get(participant.id);
    participant.bankroll -= bet;
    seat.bet = bet;
    seat.hand = [drawCard(lobby.deck), drawCard(lobby.deck)];
    seat.status = blackjackNatural(seat.hand) ? "Blackjack" : "Hit or stay";
    if (blackjackNatural(seat.hand)) seat.stayed = true;
    lobby.pot += bet;
  }
  lobby.lastEvent = `${player.name} dealt blackjack for ${participants.length} player(s).`;
  if (!currentTurnPlayerId(lobby)) resolveTableBlackjack(lobby);
  broadcastTableGame("blackjack");
}

function resolveTableBlackjack(lobby) {
  if (!lobby || lobby.game !== "blackjack") return;
  while (blackjackValue(lobby.dealerHand) < 17) {
    lobby.dealerHand.push(drawCard(lobby.deck));
  }
  const dealerTotal = blackjackValue(lobby.dealerHand);
  for (const id of lobby.playerIds) {
    const player = state.players.get(id);
    const seat = lobby.seats.get(id);
    if (!player || !seat || !seat.hand.length) continue;
    const total = blackjackValue(seat.hand);
    let payout = 0;
    if (total > 21) seat.status = "Bust";
    else if (blackjackNatural(seat.hand) && !blackjackNatural(lobby.dealerHand)) {
      payout = Math.floor(seat.bet * 2.5);
      seat.status = `Blackjack paid ${payout}`;
    } else if (dealerTotal > 21 || total > dealerTotal) {
      payout = seat.bet * 2;
      seat.status = `Won ${payout}`;
    } else if (total === dealerTotal) {
      payout = seat.bet;
      seat.status = "Push";
    } else {
      seat.status = "Dealer wins";
    }
    player.bankroll += payout;
    seat.stayed = true;
  }
  lobby.phase = "done";
  lobby.lastEvent = `Dealer stands on ${dealerTotal}.`;
  broadcastTableGame("blackjack");
}

function tableBlackjackHit(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "blackjack" || lobby.phase !== "blackjack_turns") return;
  if (currentTurnPlayerId(lobby) !== player.id) return;
  const seat = lobby.seats.get(player.id);
  seat.hand.push(drawCard(lobby.deck));
  const total = blackjackValue(seat.hand);
  if (total >= 21) {
    seat.stayed = true;
    seat.status = total > 21 ? "Bust" : "Standing on 21";
    advanceTableTurn(lobby);
  } else {
    seat.status = `Hit to ${total}`;
  }
  lobby.lastEvent = `${player.name}: ${seat.status}.`;
  broadcastTableGame("blackjack");
}

function tableBlackjackStay(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "blackjack" || lobby.phase !== "blackjack_turns") return;
  if (currentTurnPlayerId(lobby) !== player.id) return;
  const seat = lobby.seats.get(player.id);
  seat.stayed = true;
  seat.status = `Stayed on ${blackjackValue(seat.hand)}`;
  lobby.lastEvent = `${player.name} stayed.`;
  advanceTableTurn(lobby);
  broadcastTableGame("blackjack");
}

function startTableHoldem(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "holdem" || !["waiting", "done", "showdown"].includes(lobby.phase)) return;
  const bet = Math.max(1, Number(lobby.seats.get(player.id)?.bet) || 1);
  const participants = lobby.playerIds
    .map((id) => state.players.get(id))
    .filter((participant) => participant && participant.bankroll >= bet);
  if (participants.length < 2) {
    lobby.lastEvent = "Hold'em needs at least two funded players.";
    broadcastTableGame("holdem");
    return;
  }

  resetCardSeats(lobby);
  lobby.deck = freshDeck();
  lobby.dealerHand = [];
  lobby.community = [];
  lobby.phase = "preflop";
  lobby.turnIndex = 0;
  lobby.pot = 0;
  lobby.currentBet = bet;
  for (const participant of participants) {
    const seat = lobby.seats.get(participant.id);
    participant.bankroll -= bet;
    seat.bet = bet;
    seat.hand = [drawCard(lobby.deck), drawCard(lobby.deck)];
    seat.status = "In hand";
    lobby.pot += bet;
  }
  lobby.lastEvent = `${player.name} dealt Hold'em for ${participants.length} players.`;
  broadcastTableGame("holdem");
}

function resetHoldemActions(lobby) {
  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    if (seat && seat.hand.length && !seat.folded) seat.acted = false;
  }
}

function holdemLiveSeats(lobby) {
  return lobby.playerIds.map((id) => lobby.seats.get(id)).filter((seat) => seat && seat.hand.length && !seat.folded);
}

function advanceHoldemStreet(lobby) {
  const liveSeats = holdemLiveSeats(lobby);
  if (liveSeats.length <= 1) {
    resolveTableHoldem(lobby);
    return;
  }
  if (lobby.phase === "preflop") {
    lobby.community.push(drawCard(lobby.deck), drawCard(lobby.deck), drawCard(lobby.deck));
    lobby.phase = "flop";
  } else if (lobby.phase === "flop") {
    lobby.community.push(drawCard(lobby.deck));
    lobby.phase = "turn";
  } else if (lobby.phase === "turn") {
    lobby.community.push(drawCard(lobby.deck));
    lobby.phase = "river";
  } else if (lobby.phase === "river") {
    resolveTableHoldem(lobby);
    return;
  }
  resetHoldemActions(lobby);
  lobby.turnIndex = 0;
  lobby.lastEvent = `Hold'em phase: ${lobby.phase}.`;
}

function tableHoldemAction(player, action) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "holdem" || !["preflop", "flop", "turn", "river"].includes(lobby.phase)) return;
  if (currentTurnPlayerId(lobby) !== player.id) return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.folded) return;
  if (action === "fold") {
    seat.folded = true;
    seat.acted = true;
    seat.status = "Folded";
  } else if (action === "raise") {
    const raiseAmount = Math.min(5, player.bankroll);
    if (raiseAmount > 0) {
      player.bankroll -= raiseAmount;
      lobby.pot += raiseAmount;
      seat.bet += raiseAmount;
      seat.status = `Raised ${raiseAmount}`;
    } else {
      seat.status = "Checked";
    }
    seat.acted = true;
  } else {
    seat.status = "Checked";
    seat.acted = true;
  }
  lobby.lastEvent = `${player.name}: ${seat.status}.`;
  advanceTableTurn(lobby);
  broadcastTableGame("holdem");
}

function resolveTableHoldem(lobby) {
  if (!lobby || lobby.game !== "holdem") return;
  const liveIds = lobby.playerIds.filter((id) => {
    const seat = lobby.seats.get(id);
    return seat && seat.hand.length && !seat.folded;
  });
  let winners = liveIds;
  let label = "uncontested";
  if (liveIds.length > 1) {
    let best = -1;
    winners = [];
    for (const id of liveIds) {
      const seat = lobby.seats.get(id);
      const score = pokerScore([...seat.hand, ...lobby.community]);
      seat.status = pokerLabel(score);
      if (score > best) {
        best = score;
        winners = [id];
        label = seat.status;
      } else if (score === best) {
        winners.push(id);
      }
    }
  }
  const share = winners.length ? Math.floor(lobby.pot / winners.length) : 0;
  for (const id of winners) {
    const player = state.players.get(id);
    const seat = lobby.seats.get(id);
    if (!player || !seat) continue;
    player.bankroll += share;
    seat.status = `Won ${share} with ${label}`;
  }
  lobby.phase = "showdown";
  lobby.lastEvent = `Showdown: ${winners.length} winner(s), pot ${lobby.pot}.`;
  broadcastTableGame("holdem");
}

function tableSetHorseChoice(player, choice) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "horse" || lobby.horseState === "racing") return;
  const seat = lobby.seats.get(player.id);
  if (!seat) return;
  seat.horseChoice = Math.max(0, Math.min(3, Number(choice) || 0));
  seat.status = `Picked horse ${seat.horseChoice + 1}`;
  lobby.lastEvent = `${player.name} picked horse ${seat.horseChoice + 1}.`;
  broadcastTableGame("horse");
}

function startTableHorseRace(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "horse") return;
  if (lobby.hostPlayerId !== player.id) {
    lobby.lastEvent = `Only host ${state.players.get(lobby.hostPlayerId)?.name || ""} can start races.`;
    sendTableSnapshot(player, "horse");
    return;
  }
  if (lobby.horseState === "racing") return;

  lobby.horsePositions = [0, 0, 0, 0];
  lobby.horseWinner = -1;
  lobby.horseUnderdog = horseUnderdogIndex(lobby.horseWins);
  lobby.horseState = "racing";
  lobby.phase = "racing";

  let entrants = 0;
  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    const participant = state.players.get(id);
    if (!seat || !participant) continue;
    const bet = Math.max(1, Number(seat.bet) || 1);
    seat.raceBet = 0;
    if (participant.bankroll >= bet) {
      participant.bankroll -= bet;
      seat.raceBet = bet;
      entrants += 1;
      seat.running = true;
      seat.status = `Racing horse ${seat.horseChoice + 1} for ${bet}`;
    } else {
      seat.running = false;
      seat.status = "Insufficient SGC";
    }
  }

  if (entrants === 0) {
    lobby.horseState = "betting";
    lobby.phase = "ready";
    lobby.lastEvent = "No entrants had enough chips for this race.";
    broadcastTableGame("horse");
    return;
  }

  lobby.lastEvent = `${player.name} started the race with ${entrants} entrant(s).`;
  if (lobby.horseTimer) clearInterval(lobby.horseTimer);
  lobby.horseTimer = setInterval(() => {
    for (let horse = 0; horse < 4; horse += 1) {
      const boost = (horse === lobby.horseUnderdog) ? 1 : 0;
      lobby.horsePositions[horse] += (0.8 + Math.random() * 3.0) + boost;
      if (lobby.horsePositions[horse] >= 100 && lobby.horseWinner < 0) {
        lobby.horseWinner = horse;
      }
    }
    if (lobby.horseWinner >= 0) {
      clearInterval(lobby.horseTimer);
      lobby.horseTimer = null;
      lobby.horseWins[lobby.horseWinner] += 1;
      lobby.horseState = "done";
      lobby.phase = "done";
      for (const id of lobby.playerIds) {
        const seat = lobby.seats.get(id);
        const participant = state.players.get(id);
        if (!seat || !participant) continue;
        let payout = 0;
        if (seat.raceBet > 0 && seat.horseChoice === lobby.horseWinner) {
          payout = seat.raceBet * ((lobby.horseWinner === lobby.horseUnderdog) ? 8 : 4);
          participant.bankroll += payout;
        }
        seat.running = false;
        seat.status = payout > 0 ? `Won ${payout} on horse ${lobby.horseWinner + 1}` : `Horse ${lobby.horseWinner + 1} won`;
        seat.raceBet = 0;
      }
      lobby.lastEvent = `Horse ${lobby.horseWinner + 1} wins.`;
    }
    broadcastTableGame("horse");
  }, 120);
  broadcastTableGame("horse");
}

async function startBreakoutShowdown(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  breakoutEnsureRoles(lobby);
  const racers = breakoutRacerIds(lobby);
  if (racers.length < 2) {
    lobby.lastEvent = "Breakout showdown needs two racers.";
    breakout.showdownSummary = lobby.lastEvent;
    broadcastTableGame("breakout");
    return;
  }
  if (breakout.state === "racing") return;

  const entryCost = 25;
  for (const racerId of racers) {
    const racer = state.players.get(racerId);
    if (!racer) continue;
    const chargeId = `bo-showdown-entry-${lobby.id}-${racerId}-${Date.now()}`;
    const charge = await sgcChargePlayer(racer, entryCost, `Breakout showdown entry ${lobby.id}`, chargeId);
    if (!charge.ok) {
      lobby.lastEvent = `${racer.name} could not pay ${entryCost} SGC buy-in.`;
      breakout.showdownSummary = lobby.lastEvent;
      broadcastTableGame("breakout");
      return;
    }
  }

  breakout.state = "racing";
  breakout.allowBets = false;
  breakout.challengerPromptOpen = false;
  breakout.winnerId = "";
  breakout.loserId = "";
  breakout.raceSeed = Math.floor(Math.random() * 2147483000) + 1;
  breakout.rematchVotes = {};
  breakout.scoreboard = {};
  breakout.showdownSummary = "Race live. First to survive farther wins.";

  for (const id of racers) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    breakoutResetRaceSeat(seat);
    seat.status = id === breakout.player1Id ? "Racing as P1" : "Racing as P2";
  }

  lobby.phase = "racing";
  lobby.lastEvent = `${state.players.get(breakout.player1Id)?.name || "P1"} vs ${state.players.get(breakout.player2Id)?.name || "P2"} started.`;
  broadcastTableGame("breakout");
}

function breakoutDistanceFromSeat(seat) {
  if (!seat) return 0;
  return breakoutScoreDistance(seat.breakout.level, seat.breakout.score);
}

async function settleBreakoutBets(lobby) {
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  const winnerId = breakout.winnerId;
  if (!winnerId) return;

  const betEntries = Object.entries(breakout.bets || {});
  for (const [bettorId, bet] of betEntries) {
    const bettor = state.players.get(bettorId);
    if (!bettor) continue;
    const targets = bet && typeof bet.targets === "object"
      ? bet.targets
      : (bet && bet.targetId ? { [String(bet.targetId)]: Math.max(0, Number(bet.amount) || 0) } : {});
    const winningAmount = Math.max(0, Number(targets[winnerId]) || 0);
    if (winningAmount <= 0) continue;

    const payout = winningAmount * 2;
    const creditId = `bo-bet-win-${lobby.id}-${bettorId}-${winnerId}-${Date.now()}`;
    await sgcCreditPlayer(bettor, payout, `Breakout showdown bet win ${lobby.id}`, creditId);
  }
}

async function settleBreakoutRacerPayouts(lobby) {
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  for (const racerId of breakoutRacerIds(lobby)) {
    const racer = state.players.get(racerId);
    const seat = lobby.seats.get(racerId);
    if (!racer || !seat) continue;
    const scorePayout = Math.max(0, Number(seat.breakout.score) || 0);
    if (scorePayout <= 0) continue;
    const creditId = `bo-score-${lobby.id}-${racerId}-${Date.now()}`;
    await sgcCreditPlayer(racer, scorePayout, `Breakout showdown score payout ${lobby.id}`, creditId);
  }
}

async function finalizeBreakoutRaceIfReady(lobby) {
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  if (breakout.state !== "racing") return;
  const racers = breakoutRacerIds(lobby);
  if (racers.length < 2) return;

  const seatA = lobby.seats.get(racers[0]);
  const seatB = lobby.seats.get(racers[1]);
  if (!seatA || !seatB) return;
  if (!seatA.breakout.finished || !seatB.breakout.finished) return;

  const distA = breakoutDistanceFromSeat(seatA);
  const distB = breakoutDistanceFromSeat(seatB);
  let winnerId = racers[0];
  let loserId = racers[1];
  if (distB > distA) {
    winnerId = racers[1];
    loserId = racers[0];
  } else if (distA === distB) {
    const scoreA = Number(seatA.breakout.score) || 0;
    const scoreB = Number(seatB.breakout.score) || 0;
    if (scoreB > scoreA) {
      winnerId = racers[1];
      loserId = racers[0];
    }
  }

  breakout.winnerId = winnerId;
  breakout.loserId = loserId;
  breakout.state = "showdown";
  breakout.allowBets = false;
  breakout.challengerPromptOpen = false;
  breakoutMoveWinnerToP1(lobby, winnerId);

  const winner = state.players.get(winnerId);
  const loser = state.players.get(loserId);
  breakout.scoreboard[winnerId] = {
    score: lobby.seats.get(winnerId)?.breakout.score || 0,
    level: lobby.seats.get(winnerId)?.breakout.level || 1,
    distance: breakoutDistanceFromSeat(lobby.seats.get(winnerId)),
  };
  breakout.scoreboard[loserId] = {
    score: lobby.seats.get(loserId)?.breakout.score || 0,
    level: lobby.seats.get(loserId)?.breakout.level || 1,
    distance: breakoutDistanceFromSeat(lobby.seats.get(loserId)),
  };
  breakout.rematchVotes = {
    [winnerId]: null,
    [loserId]: null,
  };

  await settleBreakoutRacerPayouts(lobby);
  await settleBreakoutBets(lobby);

  breakout.bets = {};
  lobby.phase = "showdown";
  breakout.showdownSummary = `${winner?.name || "Player 1"} won the showdown. Rematch?`;
  lobby.lastEvent = `${winner?.name || "Player 1"} defeated ${loser?.name || "Player 2"}.`;

  for (const id of racers) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    seat.status = id === winnerId ? "Winner" : "Runner-up";
  }

  broadcastTableGame("breakout");
}

function breakoutProgressUpdate(player, payload) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  if (breakout.state !== "racing") return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.role !== "racer") return;

  seat.breakout.score = Math.max(0, Number(payload?.score) || seat.breakout.score);
  seat.breakout.level = Math.max(1, Number(payload?.level) || seat.breakout.level);
  seat.breakout.lives = Math.max(0, Number(payload?.lives) || seat.breakout.lives);
  seat.breakout.batNorm = Math.min(1, Math.max(0, Number(payload?.batNorm) || seat.breakout.batNorm));
  seat.breakout.ballXNorm = Math.min(1, Math.max(0, Number(payload?.ballXNorm) || seat.breakout.ballXNorm));
  seat.breakout.ballYNorm = Math.min(1, Math.max(0, Number(payload?.ballYNorm) || seat.breakout.ballYNorm));
  seat.breakout.brickCount = Math.max(0, Number(payload?.brickCount) || seat.breakout.brickCount);
  seat.breakout.brickMask = typeof payload?.brickMask === "string" ? payload.brickMask.slice(0, 108) : seat.breakout.brickMask;
  seat.breakout.brickColorMask = typeof payload?.brickColorMask === "string" ? payload.brickColorMask.slice(0, 108) : seat.breakout.brickColorMask;
  seat.breakout.distance = Math.max(seat.breakout.distance, breakoutScoreDistance(seat.breakout.level, seat.breakout.score));
  if (seat.breakout.lives <= 0) {
    seat.breakout.finished = true;
  }
}

async function breakoutFinish(player, payload) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  if (breakout.state !== "racing") return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.role !== "racer") return;

  seat.breakout.score = Math.max(0, Number(payload?.score) || seat.breakout.score);
  seat.breakout.level = Math.max(1, Number(payload?.level) || seat.breakout.level);
  seat.breakout.lives = Math.max(0, Number(payload?.lives) || 0);
  seat.breakout.batNorm = Math.min(1, Math.max(0, Number(payload?.batNorm) || seat.breakout.batNorm));
  seat.breakout.ballXNorm = Math.min(1, Math.max(0, Number(payload?.ballXNorm) || seat.breakout.ballXNorm));
  seat.breakout.ballYNorm = Math.min(1, Math.max(0, Number(payload?.ballYNorm) || seat.breakout.ballYNorm));
  seat.breakout.brickCount = Math.max(0, Number(payload?.brickCount) || seat.breakout.brickCount);
  seat.breakout.brickMask = typeof payload?.brickMask === "string" ? payload.brickMask.slice(0, 108) : seat.breakout.brickMask;
  seat.breakout.brickColorMask = typeof payload?.brickColorMask === "string" ? payload.brickColorMask.slice(0, 108) : seat.breakout.brickColorMask;
  seat.breakout.distance = Math.max(
    seat.breakout.distance,
    Math.max(0, Number(payload?.distance) || 0),
    breakoutScoreDistance(seat.breakout.level, seat.breakout.score)
  );
  seat.breakout.finished = true;
  seat.status = "Finished run";

  await finalizeBreakoutRaceIfReady(lobby);
}

function breakoutVoteRematch(player, accept) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  if (breakout.state !== "showdown") return;
  if (player.id !== breakout.winnerId && player.id !== breakout.loserId) return;

  breakout.rematchVotes[player.id] = !!accept;
  const winnerVote = breakout.rematchVotes[breakout.winnerId];
  const loserVote = breakout.rematchVotes[breakout.loserId];

  if (winnerVote === true && loserVote === true) {
    breakout.state = "waiting";
    breakout.challengerPromptOpen = false;
    breakout.allowBets = true;
    breakout.showdownSummary = "Rematch accepted. Host can start the next race.";
    breakout.rematchVotes = {};
    lobby.phase = "waiting";
    breakoutEnsureRoles(lobby);
  } else if (winnerVote === false || loserVote === false) {
    breakoutOpenChallengerPrompt(lobby, "Rematch declined. Select next challenger for Player 2.");
  }

  broadcastTableGame("breakout");
}

function breakoutForceNextChallenger(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  if (breakout.state !== "showdown") return;
  if (player.id !== breakout.winnerId && player.id !== breakout.loserId) return;
  breakoutOpenChallengerPrompt(lobby, `${player.name} requested the next challenger.`);
  broadcastTableGame("breakout");
}

function breakoutClaimPlayer2(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  const seat = lobby.seats.get(player.id);
  if (!seat) return;
  if (seat.role !== "spectator") return;
  if (!breakout.challengerPromptOpen && breakout.state !== "waiting") return;

  breakout.player2Id = player.id;
  seat.role = "racer";
  seat.status = "Player 2";
  breakout.challengerPromptOpen = false;
  breakout.showdownSummary = `${player.name} claimed Player 2 seat.`;
  breakoutEnsureRoles(lobby);
  broadcastTableGame("breakout");
}

async function breakoutPlaceBet(player, payload) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "breakout") return;
  const breakout = lobby.breakout;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.role !== "spectator") return;
  if (!breakout.allowBets || breakout.state === "racing") return;

  const targetId = String(payload?.targetPlayerId || "");
  const amount = Math.max(1, Number(payload?.amount) || 0);
  if (targetId !== breakout.player1Id && targetId !== breakout.player2Id) return;
  if (amount <= 0) return;

  const chargeId = `bo-bet-${lobby.id}-${player.id}-${targetId}-${Date.now()}`;
  const charge = await sgcChargePlayer(player, amount, `Breakout bet ${lobby.id}`, chargeId);
  if (!charge.ok) {
    seat.status = charge.message || "Bet failed";
    broadcastTableGame("breakout");
    return;
  }

  const playerBet = breakout.bets[player.id] || { targets: {} };
  if (!playerBet.targets || typeof playerBet.targets !== "object") {
    playerBet.targets = {};
  }
  playerBet.targets[targetId] = Math.max(0, Number(playerBet.targets[targetId]) || 0) + amount;
  breakout.bets[player.id] = playerBet;

  const targetTotal = Math.max(0, Number(playerBet.targets[targetId]) || 0);
  seat.status = `Bet +${amount} on ${(state.players.get(targetId)?.name || "racer")} (total ${targetTotal})`;
  broadcastTableGame("breakout");
}

async function breakoutSingleStart(player) {
  const entryCost = 25;
  const charge = await sgcChargePlayer(
    player,
    entryCost,
    "Breakout single-run entry",
    `bo-solo-entry-${player.id}-${Date.now()}`
  );

  sendJson(player.socket, {
    type: "breakout_single_start_result",
    ok: charge.ok,
    balance: player.bankroll,
    message: charge.ok ? "Entry paid." : (charge.message || "Unable to pay entry."),
  });

  if (charge.ok) {
    broadcastState();
  }
}

async function breakoutSingleSettle(player, payload) {
  const score = Math.max(0, Number(payload?.score) || 0);
  const payout = score;
  const credit = await sgcCreditPlayer(
    player,
    payout,
    "Breakout single-run score payout",
    `bo-solo-payout-${player.id}-${Date.now()}`
  );

  sendJson(player.socket, {
    type: "breakout_single_settle_result",
    ok: credit.ok,
    payout,
    balance: player.bankroll,
    message: credit.ok ? "Payout settled." : (credit.message || "Payout failed."),
  });

  if (credit.ok) {
    broadcastState();
  }
}

function snakeScoreDistance(length, score) {
  const safeLength = Math.max(3, Number(length) || 3);
  const safeScore = Math.max(0, Number(score) || 0);
  return safeScore + (safeLength - 3) * 5;
}

function snakeEnsureRoles(lobby) {
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  if (!snake) return;

  if (snake.player1Id && !lobby.seats.has(snake.player1Id)) snake.player1Id = "";
  if (snake.player2Id && !lobby.seats.has(snake.player2Id)) snake.player2Id = "";

  if (!snake.player1Id) {
    snake.player1Id = lobby.playerIds[0] || "";
  }
  if (!snake.player2Id) {
    snake.player2Id = lobby.playerIds.find((id) => id !== snake.player1Id && lobby.seats.has(id)) || "";
  }

  for (const id of lobby.playerIds) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    seat.role = (id === snake.player1Id || id === snake.player2Id) ? "racer" : "spectator";
  }
}

function snakeRacerIds(lobby) {
  if (!lobby || lobby.game !== "snake") return [];
  const ids = [];
  if (lobby.snake.player1Id && lobby.seats.has(lobby.snake.player1Id)) ids.push(lobby.snake.player1Id);
  if (lobby.snake.player2Id && lobby.seats.has(lobby.snake.player2Id)) ids.push(lobby.snake.player2Id);
  return ids;
}

function snakeResetRaceSeat(seat) {
  seat.snake.score = 0;
  seat.snake.length = 3;
  seat.snake.distance = 0;
  seat.snake.headXNorm = 0.5;
  seat.snake.headYNorm = 0.5;
  seat.snake.segmentPoints = [];
  seat.snake.alive = true;
  seat.snake.finished = false;
  seat.snake.acceptedRematch = null;
  seat.status = "Ready";
}

function snakeMoveWinnerToP1(lobby, winnerId) {
  if (!lobby || lobby.game !== "snake") return;
  if (!winnerId || !lobby.seats.has(winnerId)) return;
  const snake = lobby.snake;
  const previousP1 = snake.player1Id;
  snake.player1Id = winnerId;
  if (snake.player2Id === winnerId) {
    snake.player2Id = previousP1 && previousP1 !== winnerId ? previousP1 : "";
  }
  snakeEnsureRoles(lobby);
}

function snakeOpenChallengerPrompt(lobby, reasonText) {
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  const loserId = snake.loserId;
  if (loserId && lobby.seats.has(loserId)) {
    const loserSeat = lobby.seats.get(loserId);
    loserSeat.role = "spectator";
    loserSeat.status = "Spectating";
  }
  snake.player2Id = "";
  snake.challengerPromptOpen = true;
  snake.state = "waiting";
  snake.allowBets = true;
  snake.showdownSummary = reasonText || "Select next challenger.";
  snake.rematchVotes = {};
  snakeEnsureRoles(lobby);
}

function snakeSnapshot(lobby) {
  if (!lobby || lobby.game !== "snake") return undefined;
  const snake = lobby.snake;
  const betLedger = [];
  for (const [bettorId, bet] of Object.entries(snake.bets || {})) {
    const bettorName = state.players.get(bettorId)?.name || "Spectator";
    const targets = bet && typeof bet.targets === "object"
      ? bet.targets
      : (bet && bet.targetId ? { [String(bet.targetId)]: Math.max(0, Number(bet.amount) || 0) } : {});
    for (const [targetId, amountRaw] of Object.entries(targets)) {
      const amount = Math.max(0, Number(amountRaw) || 0);
      if (!targetId || amount <= 0) continue;
      betLedger.push({ bettorId, bettorName, targetId, amount });
    }
  }
  return {
    state: snake.state,
    player1Id: snake.player1Id,
    player2Id: snake.player2Id,
    raceSeed: snake.raceSeed,
    winnerId: snake.winnerId,
    loserId: snake.loserId,
    challengerPromptOpen: snake.challengerPromptOpen,
    allowBets: snake.allowBets,
    showdownSummary: snake.showdownSummary,
    rematchVotes: snake.rematchVotes,
    scoreboard: snake.scoreboard,
    bets: betLedger,
  };
}

async function startSnakeShowdown(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  snakeEnsureRoles(lobby);
  const racers = snakeRacerIds(lobby);
  if (racers.length < 2) {
    lobby.lastEvent = "Snake showdown needs two racers.";
    snake.showdownSummary = lobby.lastEvent;
    broadcastTableGame("snake");
    return;
  }
  if (snake.state === "racing") return;

  const entryCost = 25;
  for (const racerId of racers) {
    const racer = state.players.get(racerId);
    if (!racer) continue;
    const chargeId = `snake-showdown-entry-${lobby.id}-${racerId}-${Date.now()}`;
    const charge = await sgcChargePlayer(racer, entryCost, `Snake showdown entry ${lobby.id}`, chargeId);
    if (!charge.ok) {
      lobby.lastEvent = `${racer.name} could not pay ${entryCost} SGC buy-in.`;
      snake.showdownSummary = lobby.lastEvent;
      broadcastTableGame("snake");
      return;
    }
  }

  snake.state = "racing";
  snake.allowBets = false;
  snake.challengerPromptOpen = false;
  snake.winnerId = "";
  snake.loserId = "";
  snake.raceSeed = Math.floor(Math.random() * 2147483000) + 1;
  snake.rematchVotes = {};
  snake.scoreboard = {};
  snake.showdownSummary = "Race live. Survive farther to win.";

  for (const id of racers) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    snakeResetRaceSeat(seat);
    seat.status = id === snake.player1Id ? "Racing as P1" : "Racing as P2";
  }

  lobby.phase = "racing";
  lobby.lastEvent = `${state.players.get(snake.player1Id)?.name || "P1"} vs ${state.players.get(snake.player2Id)?.name || "P2"} started.`;
  broadcastTableGame("snake");
}

async function settleSnakeBets(lobby) {
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  const winnerId = snake.winnerId;
  if (!winnerId) return;

  const betEntries = Object.entries(snake.bets || {});
  for (const [bettorId, bet] of betEntries) {
    const bettor = state.players.get(bettorId);
    if (!bettor) continue;
    const targets = bet && typeof bet.targets === "object"
      ? bet.targets
      : (bet && bet.targetId ? { [String(bet.targetId)]: Math.max(0, Number(bet.amount) || 0) } : {});
    const winningAmount = Math.max(0, Number(targets[winnerId]) || 0);
    if (winningAmount <= 0) continue;

    const payout = winningAmount * 2;
    const creditId = `snake-bet-win-${lobby.id}-${bettorId}-${winnerId}-${Date.now()}`;
    await sgcCreditPlayer(bettor, payout, `Snake showdown bet win ${lobby.id}`, creditId);
  }
}

async function settleSnakeRacerPayouts(lobby) {
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  for (const racerId of snakeRacerIds(lobby)) {
    const racer = state.players.get(racerId);
    const seat = lobby.seats.get(racerId);
    if (!racer || !seat) continue;
    const scorePayout = Math.max(0, Number(seat.snake.score) || 0);
    if (scorePayout <= 0) continue;
    const creditId = `snake-score-${lobby.id}-${racerId}-${Date.now()}`;
    await sgcCreditPlayer(racer, scorePayout, `Snake showdown score payout ${lobby.id}`, creditId);
  }
}

async function finalizeSnakeRaceIfReady(lobby) {
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  if (snake.state !== "racing") return;
  const racers = snakeRacerIds(lobby);
  if (racers.length < 2) return;

  const seatA = lobby.seats.get(racers[0]);
  const seatB = lobby.seats.get(racers[1]);
  if (!seatA || !seatB) return;
  if (!seatA.snake.finished || !seatB.snake.finished) return;

  const distA = Math.max(0, Number(seatA.snake.distance) || snakeScoreDistance(seatA.snake.length, seatA.snake.score));
  const distB = Math.max(0, Number(seatB.snake.distance) || snakeScoreDistance(seatB.snake.length, seatB.snake.score));
  let winnerId = racers[0];
  let loserId = racers[1];
  if (distB > distA) {
    winnerId = racers[1];
    loserId = racers[0];
  } else if (distA === distB) {
    const scoreA = Number(seatA.snake.score) || 0;
    const scoreB = Number(seatB.snake.score) || 0;
    if (scoreB > scoreA) {
      winnerId = racers[1];
      loserId = racers[0];
    }
  }

  snake.winnerId = winnerId;
  snake.loserId = loserId;
  snake.state = "showdown";
  snake.allowBets = false;
  snake.challengerPromptOpen = false;
  snakeMoveWinnerToP1(lobby, winnerId);

  const winner = state.players.get(winnerId);
  const loser = state.players.get(loserId);
  snake.scoreboard[winnerId] = {
    score: lobby.seats.get(winnerId)?.snake.score || 0,
    length: lobby.seats.get(winnerId)?.snake.length || 3,
    distance: lobby.seats.get(winnerId)?.snake.distance || 0,
  };
  snake.scoreboard[loserId] = {
    score: lobby.seats.get(loserId)?.snake.score || 0,
    length: lobby.seats.get(loserId)?.snake.length || 3,
    distance: lobby.seats.get(loserId)?.snake.distance || 0,
  };
  snake.rematchVotes = { [winnerId]: null, [loserId]: null };

  await settleSnakeRacerPayouts(lobby);
  await settleSnakeBets(lobby);

  snake.bets = {};
  lobby.phase = "showdown";
  snake.showdownSummary = `${winner?.name || "Player 1"} won the showdown. Rematch?`;
  lobby.lastEvent = `${winner?.name || "Player 1"} defeated ${loser?.name || "Player 2"}.`;

  for (const id of racers) {
    const seat = lobby.seats.get(id);
    if (!seat) continue;
    seat.status = id === winnerId ? "Winner" : "Runner-up";
  }

  broadcastTableGame("snake");
}

function snakeProgressUpdate(player, payload) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  if (snake.state !== "racing") return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.role !== "racer") return;

  seat.snake.score = Math.max(0, Number(payload?.score) || seat.snake.score);
  seat.snake.length = Math.max(3, Number(payload?.length) || seat.snake.length);
  seat.snake.distance = Math.max(0, Number(payload?.distance) || seat.snake.distance, snakeScoreDistance(seat.snake.length, seat.snake.score));
  seat.snake.headXNorm = Math.min(1, Math.max(0, Number(payload?.headXNorm) || seat.snake.headXNorm));
  seat.snake.headYNorm = Math.min(1, Math.max(0, Number(payload?.headYNorm) || seat.snake.headYNorm));
  seat.snake.segmentPoints = Array.isArray(payload?.segmentPoints)
    ? payload.segmentPoints.map((value) => Math.min(1, Math.max(0, Number(value) || 0))).slice(0, 600)
    : seat.snake.segmentPoints;
  seat.snake.alive = payload?.alive === false ? false : seat.snake.alive;
  if (seat.snake.alive === false) {
    seat.snake.finished = true;
  }
}

async function snakeFinish(player, payload) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  if (snake.state !== "racing") return;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.role !== "racer") return;

  seat.snake.score = Math.max(0, Number(payload?.score) || seat.snake.score);
  seat.snake.length = Math.max(3, Number(payload?.length) || seat.snake.length);
  seat.snake.distance = Math.max(0, Number(payload?.distance) || seat.snake.distance, snakeScoreDistance(seat.snake.length, seat.snake.score));
  seat.snake.headXNorm = Math.min(1, Math.max(0, Number(payload?.headXNorm) || seat.snake.headXNorm));
  seat.snake.headYNorm = Math.min(1, Math.max(0, Number(payload?.headYNorm) || seat.snake.headYNorm));
  seat.snake.segmentPoints = Array.isArray(payload?.segmentPoints)
    ? payload.segmentPoints.map((value) => Math.min(1, Math.max(0, Number(value) || 0))).slice(0, 600)
    : seat.snake.segmentPoints;
  seat.snake.alive = payload?.alive === false ? false : seat.snake.alive;
  seat.snake.finished = true;
  seat.status = "Finished run";

  await finalizeSnakeRaceIfReady(lobby);
}

function snakeVoteRematch(player, accept) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  if (snake.state !== "showdown") return;
  if (player.id !== snake.winnerId && player.id !== snake.loserId) return;

  snake.rematchVotes[player.id] = !!accept;
  const winnerVote = snake.rematchVotes[snake.winnerId];
  const loserVote = snake.rematchVotes[snake.loserId];

  if (winnerVote === true && loserVote === true) {
    snake.state = "waiting";
    snake.challengerPromptOpen = false;
    snake.allowBets = true;
    snake.showdownSummary = "Rematch accepted. Host can start the next race.";
    snake.rematchVotes = {};
    lobby.phase = "waiting";
    snakeEnsureRoles(lobby);
  } else if (winnerVote === false || loserVote === false) {
    snakeOpenChallengerPrompt(lobby, "Rematch declined. Select next challenger for Player 2.");
  }

  broadcastTableGame("snake");
}

function snakeForceNextChallenger(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  if (snake.state !== "showdown") return;
  if (player.id !== snake.winnerId && player.id !== snake.loserId) return;
  snakeOpenChallengerPrompt(lobby, `${player.name} requested the next challenger.`);
  broadcastTableGame("snake");
}

function snakeClaimPlayer2(player) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  const seat = lobby.seats.get(player.id);
  if (!seat) return;
  if (seat.role !== "spectator") return;
  if (!snake.challengerPromptOpen && snake.state !== "waiting") return;

  snake.player2Id = player.id;
  seat.role = "racer";
  seat.status = "Player 2";
  snake.challengerPromptOpen = false;
  snake.showdownSummary = `${player.name} claimed Player 2 seat.`;
  snakeEnsureRoles(lobby);
  broadcastTableGame("snake");
}

async function snakePlaceBet(player, payload) {
  const lobby = getTableLobbyForPlayer(player);
  if (!lobby || lobby.game !== "snake") return;
  const snake = lobby.snake;
  const seat = lobby.seats.get(player.id);
  if (!seat || seat.role !== "spectator") return;
  if (!snake.allowBets || snake.state === "racing") return;

  const targetId = String(payload?.targetPlayerId || "");
  const amount = Math.max(1, Number(payload?.amount) || 0);
  if (targetId !== snake.player1Id && targetId !== snake.player2Id) return;
  if (amount <= 0) return;

  const chargeId = `snake-bet-${lobby.id}-${player.id}-${targetId}-${Date.now()}`;
  const charge = await sgcChargePlayer(player, amount, `Snake bet ${lobby.id}`, chargeId);
  if (!charge.ok) {
    seat.status = charge.message || "Bet failed";
    broadcastTableGame("snake");
    return;
  }

  const playerBet = snake.bets[player.id] || { targets: {} };
  if (!playerBet.targets || typeof playerBet.targets !== "object") playerBet.targets = {};
  playerBet.targets[targetId] = Math.max(0, Number(playerBet.targets[targetId]) || 0) + amount;
  snake.bets[player.id] = playerBet;

  const targetTotal = Math.max(0, Number(playerBet.targets[targetId]) || 0);
  seat.status = `Bet +${amount} on ${(state.players.get(targetId)?.name || "racer")} (total ${targetTotal})`;
  broadcastTableGame("snake");
}

async function snakeSingleStart(player) {
  const entryCost = 25;
  const charge = await sgcChargePlayer(
    player,
    entryCost,
    "Snake single-run entry",
    `snake-solo-entry-${player.id}-${Date.now()}`
  );

  sendJson(player.socket, {
    type: "snake_single_start_result",
    ok: charge.ok,
    balance: player.bankroll,
    message: charge.ok ? "Entry paid." : (charge.message || "Unable to pay entry."),
  });

  if (charge.ok) {
    broadcastState();
  }
}

async function snakeSingleSettle(player, payload) {
  const score = Math.max(0, Number(payload?.score) || 0);
  const payout = score;
  const credit = await sgcCreditPlayer(
    player,
    payout,
    "Snake single-run score payout",
    `snake-solo-payout-${player.id}-${Date.now()}`
  );

  sendJson(player.socket, {
    type: "snake_single_settle_result",
    ok: credit.ok,
    payout,
    balance: player.bankroll,
    message: credit.ok ? "Payout settled." : (credit.message || "Payout failed."),
  });

  if (credit.ok) {
    broadcastState();
  }
}

function assignPlayerToLobby(player, lobby) {
  removePlayerFromLobby(player);
  player.lobbyId = lobby.id;
  lobby.playerIds.add(player.id);
}

function buildActivePlayers(lobby) {
  if (!lobby) {
    return [];
  }

  const active = [];
  for (const playerId of lobby.playerIds.values()) {
    const participant = state.players.get(playerId);
    if (!participant) {
      continue;
    }

    active.push({
      playerId: participant.id,
      name: participant.name,
      bankroll: participant.bankroll,
      wager: playerBetTotal(participant),
      signedIn: !!participant.sgcSignedIn,
    });
  }

  active.sort((left, right) => {
    if (right.wager !== left.wager) {
      return right.wager - left.wager;
    }
    return left.name.localeCompare(right.name);
  });

  return active;
}

function buildSnapshot(forPlayer) {
  const lobby = getLobbyForPlayer(forPlayer);
  const yourBets = { ...forPlayer.bets };
  return {
    type: "state",
    phase: lobby ? lobby.phase : "browser",
    playerCount: lobby ? lobby.playerIds.size : 0,
    yourBankroll: forPlayer.bankroll,
    yourBets,
    tableTotals: aggregateTableTotals(lobby),
    rotation: lobby ? lobby.rotation : 0,
    ballAngle: lobby ? lobby.ballAngle : 0,
    winningNumber: lobby ? lobby.winningNumber : -1,
    lastWager: forPlayer.lastWager,
    lastPayout: forPlayer.lastPayout,
    lastSpinSummary: lobby ? lobby.lastSpinSummary : "Join or create a lobby.",
    spinPlan: lobby ? lobby.currentSpinPlan : null,
    currentLobbyId: lobby ? lobby.id : "",
    currentLobbyName: lobby ? lobby.name : "No lobby",
    activePlayers: buildActivePlayers(lobby),
    lobbies: buildLobbyList(),
  };
}

function sendJson(socket, payload) {
  if (socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(payload));
  }
}

function parseClientMessage(raw) {
  const text = raw.toString("utf8").replace(/\0+$/, "").trim();
  if (!text) {
    return null;
  }

  return JSON.parse(text);
}

function broadcastState() {
  for (const player of state.players.values()) {
    sendJson(player.socket, buildSnapshot(player));
  }
}

function simulateSpin(startRotation, startBallAngle) {
  const segmentAngle = 360 / wheelOrder.length;
  const zeroOffset = 90;
  const decel = 0.98;
  const minSpeed = 0.05;
  const ballDecel = 0.985;
  const ballMinSpeed = 0.1;
  let rotation = startRotation;
  let ballAngle = startBallAngle;
  const initialSpinSpeed = 10 + (Math.random() * 5);
  const initialBallSpeed = 12 + (Math.random() * 6);
  let spinSpeed = initialSpinSpeed;
  let ballSpeed = initialBallSpeed;
  let fullSpeedFrames = 180;
  let frameCount = 0;
  let spinActive = true;
  let ballState = 1;

  while (spinActive || ballState === 1) {
    if (spinActive) {
      rotation += spinSpeed;
      if (fullSpeedFrames > 0) {
        fullSpeedFrames -= 1;
      } else {
        spinSpeed *= decel;
      }
      if (spinSpeed < minSpeed) {
        spinSpeed = 0;
        spinActive = false;
      }
    }

    if (ballState === 1) {
      ballAngle -= ballSpeed;
      if (fullSpeedFrames <= 0) {
        ballSpeed *= ballDecel;
      }

      if (ballSpeed < ballMinSpeed) {
        ballSpeed = 0;
        const normBall = angleNorm(ballAngle);
        const local = angleNorm(rotation - normBall + zeroOffset);
        const snapped = Math.round(local / segmentAngle) * segmentAngle;
        ballAngle = angleNorm(rotation + zeroOffset - snapped);
        ballState = 3;
      }
    }

    frameCount += 1;
    if (frameCount > 10000) {
      throw new Error("Spin simulation exceeded sane bounds");
    }
  }

  return {
    spinId: state.nextSpinId++,
    startRotation,
    startBallAngle,
    spinSpeed: initialSpinSpeed,
    ballSpeed: initialBallSpeed,
    fullSpeedFrames: 180,
    finalRotation: rotation,
    finalBallAngle: ballAngle,
    winningNumber: getWinningNumber(rotation, ballAngle, zeroOffset, segmentAngle),
    durationFrames: frameCount,
  };
}

function resolvePayouts(lobby, winningNumber) {
  for (const playerId of lobby.playerIds.values()) {
    const player = state.players.get(playerId);
    if (!player) {
      continue;
    }
    const wager = playerBetTotal(player);
    let payout = 0;
    for (const [key, amount] of Object.entries(player.bets)) {
      const def = betDefinitions.get(key);
      if (def && def.covered.includes(winningNumber)) {
        payout += amount * (def.payout + 1);
      }
    }

    player.bankroll += payout;
    player.lastWager = wager;
    player.lastPayout = payout;
    player.bets = {};
  }
}

function startSpin(requestingPlayer) {
  const lobby = getLobbyForPlayer(requestingPlayer);
  if (!lobby || lobby.phase !== "betting") {
    return;
  }

  let hasAnyBet = false;
  for (const playerId of lobby.playerIds.values()) {
    const player = state.players.get(playerId);
    if (!player) {
      continue;
    }
    if (playerBetTotal(player) > 0) {
      hasAnyBet = true;
      break;
    }
  }
  if (!hasAnyBet) {
    return;
  }

  const spinPlan = simulateSpin(lobby.rotation, lobby.ballAngle);
  lobby.phase = "spinning";
  lobby.currentSpinPlan = spinPlan;
  lobby.winningNumber = -1;
  lobby.lastSpinSummary = `${requestingPlayer.name} started the spin.`;
  broadcastState();

  const durationMs = Math.ceil((spinPlan.durationFrames / 60) * 1000);
  setTimeout(() => {
    lobby.rotation = spinPlan.finalRotation;
    lobby.ballAngle = spinPlan.finalBallAngle;
    lobby.winningNumber = spinPlan.winningNumber;
    resolvePayouts(lobby, spinPlan.winningNumber);
    lobby.phase = "betting";
    lobby.currentSpinPlan = null;
    lobby.lastSpinSummary = `Winner ${spinPlan.winningNumber}. Bets are open.`;
    broadcastState();
  }, durationMs);
}

// HTTP server for webhooks + WebSocket upgrade
const httpServer = http.createServer((req, res) => {
  const requestUrl = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  const pathname = requestUrl.pathname;

  if (req.method === "OPTIONS" && pathname === "/sgc/oauth/status") {
    res.writeHead(204, corsHeaders());
    res.end();
    return;
  }

  if (req.method === "GET" && pathname === "/sgc/oauth/start") {
    cleanupOauthPending();
    const publicOrigin = requestPublicOrigin(req, requestUrl);
    if (!hasOauthConfig()) {
      writeHtml(
        res,
        503,
        "Discord OAuth unavailable",
        "<p>Broker OAuth is not configured. Set <code>SGC_BASE_URL</code>, <code>SGC_API_KEY</code>, <code>SGC_OAUTH_CLIENT_ID</code>, <code>SGC_OAUTH_CLIENT_SECRET</code>, and <code>SGC_OAUTH_REDIRECT_URI</code>.</p>"
      );
      return;
    }

    const providedExternalId = (requestUrl.searchParams.get("external_id") || "").trim().slice(0, 64);
    const externalName = (requestUrl.searchParams.get("external_name") || "Player").trim().slice(0, 24);
    const oauthSessionId = (requestUrl.searchParams.get("session_id") || "").trim().slice(0, 64);
    if (!oauthSessionId) {
      writeHtml(res, 400, "Missing identity", "<p>Missing required query parameter <code>session_id</code>.</p>");
      return;
    }

    const externalId = isBrokerManagedExternalId(providedExternalId) ? providedExternalId : createImmutableExternalId();
    identityStore.ensureAppId(externalId, externalName);

    const stateKey = base64Url(crypto.randomBytes(24));
    const pkce = buildPkcePair();
    const requestedReturnTo = requestUrl.searchParams.get("return_to") || req.headers.referer || "";
    oauthPendingByState.set(stateKey, {
      oauthSessionId,
      externalId,
      externalName,
      returnTo: sanitizeReturnUrl(requestedReturnTo),
      verifier: pkce.verifier,
      createdAt: Date.now(),
    });

    const payload = {
      client_id: SGC_OAUTH_CLIENT_ID,
      redirect_uri: SGC_OAUTH_REDIRECT_URI,
      scope: SGC_OAUTH_SCOPE,
      state: stateKey,
      code_challenge: pkce.challenge,
      code_challenge_method: "S256",
      external_id: externalId,
      external_name: externalName,
    };

    fetch(`${SGC_BASE_URL}/v1/links/oauth/start`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${SGC_API_KEY}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(payload),
    })
      .then(async (oauthRes) => {
        const bodyText = await oauthRes.text();
        let parsed = null;
        if (bodyText) {
          try {
            parsed = JSON.parse(bodyText);
          } catch (error) {
            parsed = null;
          }
        }

        if (!oauthRes.ok) {
          oauthPendingByState.delete(stateKey);
          const message = htmlEscape(parsed?.error?.message || `OAuth start failed (${oauthRes.status}).`);
          writeHtml(res, 502, "OAuth start failed", `<p>${message}</p>`);
          return;
        }

        const authorizeUrl = parsed?.oauth?.authorize_url;
        if (!authorizeUrl) {
          oauthPendingByState.delete(stateKey);
          writeHtml(res, 502, "OAuth start failed", "<p>Sadgirlcoin API did not return an authorize URL.</p>");
          return;
        }

        const finalAuthorizeUrl = rewriteAuthorizeUrlForPublicOrigin(authorizeUrl, publicOrigin);
        if (finalAuthorizeUrl !== authorizeUrl) {
          console.log(`[oauth] rewrote authorize url origin for proxy: ${authorizeUrl} -> ${finalAuthorizeUrl}`);
        }

        res.writeHead(302, { Location: finalAuthorizeUrl });
        res.end();
      })
      .catch((error) => {
        oauthPendingByState.delete(stateKey);
        const detail = oauthErrorDetail(error);
        console.error(`[oauth] start fetch error to ${SGC_BASE_URL}/v1/links/oauth/start: ${detail}`);
        writeHtml(
          res,
          502,
          "OAuth start failed",
          `<p>${htmlEscape(detail)}</p><p>Check broker egress/DNS/TLS to <code>${htmlEscape(SGC_BASE_URL)}</code>.</p>`
        );
      });
    return;
  }

  if (req.method === "GET" && pathname === "/sgc/oauth/callback") {
    cleanupOauthPending();
    if (!hasOauthConfig()) {
      writeHtml(res, 503, "Discord OAuth unavailable", "<p>Broker OAuth is not configured.</p>");
      return;
    }

    const code = (requestUrl.searchParams.get("code") || "").trim();
    const stateKey = (requestUrl.searchParams.get("state") || "").trim();
    const pending = oauthPendingByState.get(stateKey);

    if (!code || !pending) {
      writeHtml(res, 400, "Invalid OAuth callback", "<p>Missing or expired OAuth state. Start sign-in again from the game.</p>");
      return;
    }

    oauthPendingByState.delete(stateKey);

    const tokenPayload = {
      grant_type: "authorization_code",
      client_id: SGC_OAUTH_CLIENT_ID,
      client_secret: SGC_OAUTH_CLIENT_SECRET,
      redirect_uri: SGC_OAUTH_REDIRECT_URI,
      code,
      code_verifier: pending.verifier,
    };

    const exchangeOauthToken = async (allowAutoRelink) => {
      const tokenRes = await fetch(`${SGC_BASE_URL}/oauth/token`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${SGC_API_KEY}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(tokenPayload),
      });

      const bodyText = await tokenRes.text();
      let parsed = null;
      if (bodyText) {
        try {
          parsed = JSON.parse(bodyText);
        } catch (error) {
          parsed = null;
        }
      }

      if (!tokenRes.ok) {
        console.error(`[sgc][oauth] token exchange failed (${tokenRes.status}):`, JSON.stringify(parsed, null, 2));
        const errCode = parsed?.error?.code || parsed?.code || "";
        if (allowAutoRelink && errCode === "discord_already_linked_to_different_external_id") {
          const discordIdFromError =
            String(parsed?.discord_id || parsed?.user?.discord_id || parsed?.error?.discord_id || "").trim() || "";
          const localIdentity = discordIdFromError ? identityStore.getByDiscordId(discordIdFromError) : null;
          const conflictingExternalId = String(
            parsed?.existing_external_id ||
            parsed?.error?.existing_external_id ||
            parsed?.conflicting_external_id ||
            parsed?.error?.conflicting_external_id ||
            localIdentity?.appId ||
            ""
          ).trim().slice(0, 64);

          if (conflictingExternalId) {
            console.log(
              `[sgc][oauth] duplicate sign-in detected; revoking existing external_id ${conflictingExternalId} before retrying pending external_id ${pending.externalId}`
            );
            try {
              const revokeResult = await revokeSgcLinkByExternalId(conflictingExternalId);
              console.log(
                `[sgc][oauth] revoke result for ${conflictingExternalId}: revoked=${revokeResult.revoked ? "yes" : "no"} not_found=${revokeResult.notFound ? "yes" : "no"}`
              );
            } catch (error) {
              const detail = oauthErrorDetail(error);
              console.error(`[sgc][oauth] revoke failed for ${conflictingExternalId}: ${detail}`);
              oauthFailedBySessionId.set(pending.oauthSessionId, {
                failedAt: Date.now(),
                code: "discord_revoke_failed",
                message: `Automatic unlink failed for ${conflictingExternalId}: ${detail}`,
              });
              writeHtml(
                res,
                502,
                "Automatic unlink failed",
                `<p>We detected an existing Sadgirlcoin link for this Discord account, but the broker could not revoke it automatically.</p><p>${htmlEscape(detail)}</p>`
              );
              return;
            }

            await exchangeOauthToken(false);
            return;
          }

          oauthFailedBySessionId.set(pending.oauthSessionId, {
            failedAt: Date.now(),
            code: "discord_already_linked",
            message: "Discord already linked to a different identity, but the conflicting external_id was not returned by the API.",
          });
          writeHtml(
            res,
            409,
            "Discord account conflict",
            "<p>Your Discord account is already linked to a different game identity on Sadgirlcoin, and the conflicting link ID was not returned so the broker could not auto-repair it.</p>"
          );
          return;
        }

        const message = htmlEscape(parsed?.error?.message || `Token exchange failed (${tokenRes.status}).`);
        writeHtml(res, 502, "OAuth sign-in failed", `<p>${message}</p>`);
        return;
      }

      // Always log the full token response when OAuth completes
      console.log("[sgc][oauth] FULL TOKEN RESPONSE:", JSON.stringify(parsed, null, 2));
      console.log("[sgc][oauth] token payload keys:", Object.keys(parsed || {}));
      console.log("[sgc][oauth] token name candidates:", {
        discord_username: parsed?.discord_username,
        user_discord_username: parsed?.user?.discord_username,
        discord_name: parsed?.discord_name,
        user_discord_name: parsed?.user?.discord_name,
        user_discord_id: parsed?.user?.discord_id,
        user_discord_username: parsed?.user?.discord_username,
        user_display_name: parsed?.user?.display_name,
        user_global_name: parsed?.user?.global_name,
        user_username: parsed?.user?.username,
        discord_user_display_name: parsed?.discord_user?.display_name,
        discord_user_global_name: parsed?.discord_user?.global_name,
        discord_user_username: parsed?.discord_user?.username,
        account_display_name: parsed?.account?.display_name,
        account_username: parsed?.account?.username,
        profile_display_name: parsed?.profile?.display_name,
        profile_username: parsed?.profile?.username,
        display_name: parsed?.display_name,
        username: parsed?.username,
        external_name: parsed?.external_name,
        link_discord_name: parsed?.link?.discord_name,
      });

      const discordId = String(parsed?.discord_id || parsed?.user?.discord_id || "").trim();
      if (!discordId) {
        writeHtml(
          res,
          502,
          "OAuth sign-in failed",
          "<p>Sadgirlcoin OAuth did not return a Discord account identifier.</p>"
        );
        return;
      }

      var resolvedName = resolveDisplayNameFromOauthPayload(parsed, pending.externalName);
      if (!resolvedName) {
        console.warn(
          "[sgc][oauth] missing Discord username in token response; keeping existing in-game name. Check that the app record and grant both include identity:read."
        );
      }

      const linkedExternalId = pending.externalId;
      try {
        identityStore.bindDiscordId(discordId, linkedExternalId, resolvedName, { forceRebind: true });
      } catch (error) {
        console.error(`[sgc][oauth] identity bind failed: ${oauthErrorDetail(error)}`);
        writeHtml(
          res,
          409,
          "OAuth sign-in conflict",
          "<p>This Discord account could not be rebound to the new Roulette identity after OAuth completed.</p>"
        );
        return;
      }

      oauthFailedBySessionId.delete(pending.oauthSessionId);
      console.log(`[sgc][oauth] resolved display name: ${resolvedName || "(unchanged)"}`);
      markOauthLinked(pending.oauthSessionId, linkedExternalId, resolvedName);
      writeHtml(
        res,
        200,
        "Discord OAuth complete",
        `<p>Your Sadgirlcoin account is now linked${resolvedName ? ` for <code>${htmlEscape(resolvedName)}</code>` : ""}.</p><p>Your immutable Roulette ID is <code>${htmlEscape(linkedExternalId)}</code>.</p><p>This window can close now. The original game tab will pick up the auth state automatically.</p>${resolvedName ? "" : "<p><strong>Note:</strong> The OAuth grant did not return Discord identity fields. Enable <code>identity:read</code> on the app and re-authorize to use your Discord username in-game.</p>"}${pending.returnTo ? `<p>If this window does not close on its own, close it and return to your original game tab.</p>` : ""}`,
        buildOauthReturnScript(pending.returnTo)
      );
    };

    exchangeOauthToken(true)
      .catch((error) => {
        const detail = oauthErrorDetail(error);
        console.error(`[oauth] token fetch error to ${SGC_BASE_URL}/oauth/token: ${detail}`);
        writeHtml(
          res,
          502,
          "OAuth sign-in failed",
          `<p>${htmlEscape(detail)}</p><p>Check broker egress/DNS/TLS to <code>${htmlEscape(SGC_BASE_URL)}</code>.</p>`
        );
      });
    return;
  }

  if (req.method === "GET" && pathname === "/sgc/oauth/status") {
    cleanupOauthPending();
    const sessionId = (requestUrl.searchParams.get("session_id") || "").trim();
    const oauthRecord = getCompletedOauthSession(sessionId);
    const linked = !!oauthRecord;
    const failedRecord = !linked ? (oauthFailedBySessionId.get(String(sessionId || "").trim()) || null) : null;
    res.writeHead(200, { "Content-Type": "application/json", ...corsHeaders() });
    res.end(JSON.stringify({
      ok: true,
      linked,
      session_id: sessionId,
      external_id: oauthRecord?.externalId || "",
      display_name: oauthRecord?.displayName || "",
      linked_at: oauthRecord?.linkedAt || null,
      error: failedRecord ? { code: failedRecord.code, message: failedRecord.message } : null,
    }));
    return;
  }

  if (req.method === "POST" && pathname === "/sgc/webhook") {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk.toString("utf8");
    });
    req.on("end", () => {
      // Verify signature
      const signature = req.headers["x-sgc-signature"] || "";
      const expected = "sha256=" + crypto
        .createHmac("sha256", SGC_WEBHOOK_SECRET)
        .update(body, "utf8")
        .digest("hex");

      if (signature !== expected) {
        console.warn(`[webhook] signature mismatch: ${signature.slice(0, 16)}... vs ${expected.slice(0, 16)}...`);
        res.writeHead(401, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "unauthorized" }));
        return;
      }

      try {
        const event = JSON.parse(body);
        console.log(`[webhook] received ${event.event || "unknown"} from SGC`);
        
        // Parse event and update local state if needed
        // For now, just acknowledge; full reconciliation logic goes here
        
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true }));
      } catch (err) {
        console.error(`[webhook] parse error: ${err.message}`);
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "bad_json" }));
      }
    });
    return;
  }

  // Default 404
  res.writeHead(404);
  res.end("not found");
});

const wss = new WebSocket.Server({ server: httpServer });

wss.on("connection", (socket) => {
  const player = {
    id: `P${state.nextPlayerId++}`,
    name: "Player",
    bankroll: DEFAULT_BANKROLL,
    bets: {},
    lastWager: 0,
    lastPayout: 0,
    lobbyId: "",
    tableLobbyId: "",
    sgcExternalId: "",
    sgcLinkCode: "",
    sgcSignedIn: false,
    signedInAcked: false,
    signedInRetryTimer: null,
    pendingSignedInPayload: null,
    pendingSignedInSource: "",
    socket,
  };
  state.players.set(player.id, player);

  sendJson(socket, { type: "welcome", playerId: player.id });
  broadcastState();

  socket.on("message", async (raw) => {
    let message;
    try {
      message = parseClientMessage(raw);
    } catch (error) {
      console.warn("Ignoring malformed client message:", error.message);
      return;
    }

    if (!message) {
      return;
    }

    if (message.type === "signed_in_ack") {
      acknowledgeSignedInDelivery(player, "client");
      return;
    }

    if (message.type === "sign_out") {
      acknowledgeSignedInDelivery(player, "sign_out_reset");
      player.sgcSignedIn = false;
      player.sgcLinkCode = "";
      player.name = (typeof message.name === "string" && message.name.trim())
        ? message.name.trim().slice(0, 24)
        : "Player";
      player.bankroll = DEFAULT_BANKROLL;
      console.log(`[sgc] sign_out id=${player.id} name=${player.name}`);
      queueSignedInDelivery(player, false, player.sgcExternalId || "", "", "sign_out");
      broadcastState();
      for (const game of tableGames) broadcastTableGame(game);
      return;
    }

    if (message.type === "join") {
      acknowledgeSignedInDelivery(player, "join_reset");
      if (typeof message.name === "string" && message.name.trim()) {
        player.name = message.name.trim().slice(0, 24);
      }
      if (typeof message.external_id === "string") {
        player.sgcExternalId = message.external_id.trim().slice(0, 64);
      }
      if (typeof message.link_code === "string") {
        player.sgcLinkCode = message.link_code.trim().slice(0, 16);
      }
      const knownIdentity = isBrokerManagedExternalId(player.sgcExternalId)
        ? identityStore.getByAppId(player.sgcExternalId)
        : null;
      player.sgcSignedIn = !!message.signed_in && !!knownIdentity;
      if (knownIdentity?.displayName) {
        player.name = knownIdentity.displayName.slice(0, 24);
      }
      if (!player.sgcSignedIn) {
        player.bankroll = DEFAULT_BANKROLL;
      }
      if (player.sgcSignedIn) {
        await refreshPlayerBankrollFromSgc(player, "join");
      }
      console.log(
        `[sgc] join id=${player.id} name=${player.name} signed_in=${player.sgcSignedIn} external_id=${player.sgcExternalId || "-"} link_code=${player.sgcLinkCode ? "yes" : "no"} known_identity=${knownIdentity ? "yes" : "no"}`
      );
      queueSignedInDelivery(player, player.sgcSignedIn, player.sgcExternalId || "", player.name, "join");
      broadcastState();
      for (const game of tableGames) broadcastTableGame(game);
      return;
    }

    if (message.type === "breakout_single_start") {
      await breakoutSingleStart(player);
      return;
    }

    if (message.type === "breakout_single_settle") {
      await breakoutSingleSettle(player, message);
      return;
    }

    if (message.type === "snake_single_start") {
      await snakeSingleStart(player);
      return;
    }

    if (message.type === "snake_single_settle") {
      await snakeSingleSettle(player, message);
      return;
    }

    if (message.type === "table_watch" && tableGames.has(message.game)) {
      sendTableSnapshot(player, message.game);
      return;
    }

    if (message.type === "table_create_lobby" && tableGames.has(message.game)) {
      const currentTableLobby = getTableLobbyForPlayer(player);
      if (currentTableLobby) {
        const currentSeat = currentTableLobby.seats.get(player.id);
        if (currentSeat?.running) return;
      }

      const lobbyCount = buildTableLobbyList(message.game).length + 1;
      const gameLabels = { slots: "Slots", pachinko: "Pachinko", blackjack: "Blackjack", holdem: "Hold'em", horse: "Horse Race", breakout: "Breakout Showdown", snake: "Snake Showdown" };
      const gameLabel = gameLabels[message.game] || "Table";
      const lobbyName = (typeof message.name === "string" && message.name.trim())
        ? message.name.trim().slice(0, 24)
        : `${gameLabel} Lobby ${lobbyCount}`;
      const lobby = createTableLobby(message.game, lobbyName);
      assignPlayerToTableLobby(player, lobby);
      lobby.lastEvent = `${player.name} created ${lobby.name}.`;
      broadcastTableGame(message.game);
      return;
    }

    if (message.type === "table_join_lobby" && tableGames.has(message.game)) {
      const targetLobby = state.tableLobbies.get(message.lobbyId);
      if (!targetLobby || targetLobby.game !== message.game) return;
      const currentTableLobby = getTableLobbyForPlayer(player);
      if (currentTableLobby) {
        const currentSeat = currentTableLobby.seats.get(player.id);
        if (currentSeat?.running) return;
      }
      if (assignPlayerToTableLobby(player, targetLobby)) {
        targetLobby.lastEvent = `${player.name} joined ${targetLobby.name}.`;
        broadcastTableGame(message.game);
      }
      return;
    }

    if (message.type === "table_leave_lobby" && tableGames.has(message.game)) {
      const tableLobby = getTableLobbyForPlayer(player);
      const seat = tableLobby?.seats.get(player.id);
      if (tableLobby && tableLobby.game === message.game && !seat?.running) {
        removePlayerFromTableLobby(player);
        broadcastTableGame(message.game);
      } else {
        sendTableSnapshot(player, message.game);
      }
      return;
    }

    if (message.type === "table_set_bet") {
      const tableLobby = getTableLobbyForPlayer(player);
      const seat = tableLobby?.seats.get(player.id);
      const amount = Math.max(1, Math.min(100, Number(message.amount) || 1));
      if (tableLobby && seat && !seat.running) {
        seat.bet = amount;
        seat.status = `Bet set to ${amount} SGC`;
        broadcastTableGame(tableLobby.game);
      }
      return;
    }

    if (message.type === "table_set_peg") {
      const tableLobby = getTableLobbyForPlayer(player);
      const seat = tableLobby?.seats.get(player.id);
      const peg = Math.max(1, Math.min(pachinkoWidth, Number(message.peg) || 1));
      if (tableLobby?.game === "pachinko" && seat && !seat.running) {
        seat.guess = peg;
        seat.status = `Peg set to ${peg}`;
        broadcastTableGame("pachinko");
      }
      return;
    }

    if (message.type === "table_spin") {
      startTableSlotSpin(player);
      return;
    }

    if (message.type === "table_drop") {
      startTablePachinkoDrop(player);
      return;
    }

    if (message.type === "table_blackjack_deal") {
      startTableBlackjack(player);
      return;
    }

    if (message.type === "table_blackjack_hit") {
      tableBlackjackHit(player);
      return;
    }

    if (message.type === "table_blackjack_stay") {
      tableBlackjackStay(player);
      return;
    }

    if (message.type === "table_holdem_deal") {
      startTableHoldem(player);
      return;
    }

    if (message.type === "table_holdem_action") {
      tableHoldemAction(player, typeof message.action === "string" ? message.action : "check");
      return;
    }

    if (message.type === "table_set_horse") {
      tableSetHorseChoice(player, message.horse);
      return;
    }

    if (message.type === "table_horse_start") {
      startTableHorseRace(player);
      return;
    }

    if (message.type === "table_breakout_start") {
      await startBreakoutShowdown(player);
      return;
    }

    if (message.type === "table_breakout_progress") {
      breakoutProgressUpdate(player, message);
      broadcastTableGame("breakout");
      return;
    }

    if (message.type === "table_breakout_finish") {
      await breakoutFinish(player, message);
      return;
    }

    if (message.type === "table_breakout_vote_rematch") {
      breakoutVoteRematch(player, !!message.accept);
      return;
    }

    if (message.type === "table_breakout_next_challenger") {
      breakoutForceNextChallenger(player);
      return;
    }

    if (message.type === "table_breakout_claim_player2") {
      breakoutClaimPlayer2(player);
      return;
    }

    if (message.type === "table_breakout_place_bet") {
      await breakoutPlaceBet(player, message);
      return;
    }

    if (message.type === "table_snake_start") {
      await startSnakeShowdown(player);
      return;
    }

    if (message.type === "table_snake_progress") {
      snakeProgressUpdate(player, message);
      broadcastTableGame("snake");
      return;
    }

    if (message.type === "table_snake_finish") {
      await snakeFinish(player, message);
      return;
    }

    if (message.type === "table_snake_vote_rematch") {
      snakeVoteRematch(player, !!message.accept);
      return;
    }

    if (message.type === "table_snake_next_challenger") {
      snakeForceNextChallenger(player);
      return;
    }

    if (message.type === "table_snake_claim_player2") {
      snakeClaimPlayer2(player);
      return;
    }

    if (message.type === "table_snake_place_bet") {
      await snakePlaceBet(player, message);
      return;
    }

    if (message.type === "place_bet") {
      const lobby = getLobbyForPlayer(player);
      const amount = Number(message.amount) || 0;
      const def = betDefinitions.get(message.key);
      if (lobby && lobby.phase === "betting" && def && amount > 0 && player.bankroll >= amount) {
        player.bankroll -= amount;
        player.bets[message.key] = (player.bets[message.key] || 0) + amount;
        broadcastState();
      }
      return;
    }

    if (message.type === "remove_bet") {
      const lobby = getLobbyForPlayer(player);
      const amount = Number(message.amount) || 0;
      if (lobby && lobby.phase === "betting" && amount > 0 && player.bets[message.key]) {
        const refund = Math.min(amount, player.bets[message.key]);
        player.bets[message.key] -= refund;
        if (player.bets[message.key] <= 0) {
          delete player.bets[message.key];
        }
        player.bankroll += refund;
        broadcastState();
      }
      return;
    }

    if (message.type === "clear_bets") {
      const lobby = getLobbyForPlayer(player);
      if (lobby && lobby.phase === "betting") {
        refundPlayerBets(player);
        broadcastState();
      }
      return;
    }

    if (message.type === "create_lobby") {
      if (getLobbyForPlayer(player)?.phase === "spinning") {
        return;
      }

      const lobbyCount = state.lobbies.size + 1;
      const lobbyName = (typeof message.name === "string" && message.name.trim())
        ? message.name.trim().slice(0, 24)
        : `Lobby ${lobbyCount}`;
      const lobby = createLobby(lobbyName);
      assignPlayerToLobby(player, lobby);
      lobby.lastSpinSummary = `${player.name} created ${lobby.name}.`;
      broadcastState();
      return;
    }

    if (message.type === "join_lobby") {
      const targetLobby = state.lobbies.get(message.lobbyId);
      if (!targetLobby || targetLobby.phase !== "betting") {
        return;
      }

      const currentLobby = getLobbyForPlayer(player);
      if (currentLobby && currentLobby.phase === "spinning") {
        return;
      }

      assignPlayerToLobby(player, targetLobby);
      targetLobby.lastSpinSummary = `${player.name} joined ${targetLobby.name}.`;
      broadcastState();
      return;
    }

    if (message.type === "leave_lobby") {
      const lobby = getLobbyForPlayer(player);
      if (lobby && lobby.phase === "betting") {
        removePlayerFromLobby(player);
        broadcastState();
      }
      return;
    }

    if (message.type === "request_spin") {
      startSpin(player);
    }
  });

  socket.on("close", () => {
    const tableLobbyBeforeRemove = getTableLobbyForPlayer(player);
    const tableGame = tableLobbyBeforeRemove?.game;
    clearSignedInDelivery(player);
    removePlayerFromTableLobby(player);
    removePlayerFromLobby(player);
    state.players.delete(player.id);
    broadcastState();
    if (tableGame) broadcastTableGame(tableGame);
  });
});

httpServer.listen(PORT, HOST, () => {
  console.log(`[broker] listening on ws://${HOST}:${PORT}`);
  console.log(`[broker] webhook endpoint: http://${HOST}:${PORT}/sgc/webhook`);
  console.log(`[broker] oauth start endpoint: http://${HOST}:${PORT}/sgc/oauth/start?session_id=...&external_id=...&external_name=...`);
  if (hasOauthConfig()) {
    console.log(`[broker] oauth upstream: ${SGC_BASE_URL}`);
    console.log(`[broker] oauth redirect_uri: ${SGC_OAUTH_REDIRECT_URI}`);
    console.log(`[broker] oauth client_secret: configured`);
    if (SGC_PUBLIC_ORIGIN) {
      console.log(`[broker] oauth public_origin: ${normalizePublicOrigin(SGC_PUBLIC_ORIGIN) || SGC_PUBLIC_ORIGIN}`);
    } else {
      const fallbackOrigin = oauthRedirectOrigin();
      if (fallbackOrigin) {
        console.log(`[broker] oauth public_origin fallback from redirect_uri: ${fallbackOrigin}`);
      }
    }
  }
  if (!SGC_WEBHOOK_SECRET) {
    console.warn(`[broker] WARNING: SGC_WEBHOOK_SECRET not set; webhook signatures will not validate`);
  }
  if (!SGC_OAUTH_CLIENT_SECRET) {
    console.warn("[broker] WARNING: SGC_OAUTH_CLIENT_SECRET not set; OAuth token exchange will fail");
  }
  if (!hasOauthConfig()) {
    console.warn("[broker] WARNING: OAuth env vars missing; Discord OAuth route will be unavailable");
  }
});
