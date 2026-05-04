const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function ensureParentDir(filePath) {
  const dirPath = path.dirname(filePath);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function nowIso() {
  return new Date().toISOString();
}

class IdentityStore {
  constructor(options = {}) {
    this.filePath = options.filePath || path.join(process.cwd(), "data", "identity-store.json");
    ensureParentDir(this.filePath);
    this.state = this.load();
  }

  load() {
    if (!fs.existsSync(this.filePath)) {
      const emptyState = { usersByAppId: {}, appIdByDiscordId: {} };
      fs.writeFileSync(this.filePath, JSON.stringify(emptyState, null, 2));
      return emptyState;
    }

    try {
      const raw = fs.readFileSync(this.filePath, "utf8");
      const parsed = raw ? JSON.parse(raw) : {};
      return {
        usersByAppId: parsed && typeof parsed.usersByAppId === "object" ? parsed.usersByAppId : {},
        appIdByDiscordId: parsed && typeof parsed.appIdByDiscordId === "object" ? parsed.appIdByDiscordId : {},
      };
    } catch (error) {
      const backupPath = `${this.filePath}.corrupt-${Date.now()}`;
      fs.copyFileSync(this.filePath, backupPath);
      const emptyState = { usersByAppId: {}, appIdByDiscordId: {} };
      fs.writeFileSync(this.filePath, JSON.stringify(emptyState, null, 2));
      return emptyState;
    }
  }

  save() {
    fs.writeFileSync(this.filePath, JSON.stringify(this.state, null, 2));
  }

  createImmutableAppId() {
    return `sgcusr_${crypto.randomUUID()}`;
  }

  ensureAppId(appId, displayName = "") {
    const key = String(appId || "").trim();
    if (!key) {
      throw new Error("appId is required");
    }

    const existing = this.state.usersByAppId[key];
    if (existing) {
      const nextName = String(displayName || "").trim().slice(0, 24);
      if (nextName && existing.displayName !== nextName) {
        this.state.usersByAppId[key] = {
          ...existing,
          displayName: nextName,
          updatedAt: nowIso(),
        };
        this.save();
      }
      return { ...this.state.usersByAppId[key] };
    }

    const timestamp = nowIso();
    const record = {
      appId: key,
      discordId: "",
      displayName: String(displayName || "").trim().slice(0, 24),
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.state.usersByAppId[key] = record;
    this.save();
    return { ...record };
  }

  getByAppId(appId) {
    const key = String(appId || "").trim();
    if (!key) return null;
    const user = this.state.usersByAppId[key];
    return user ? { ...user } : null;
  }

  getByDiscordId(discordId) {
    const key = String(discordId || "").trim();
    if (!key) return null;
    const appId = this.state.appIdByDiscordId[key];
    if (!appId) return null;
    return this.getByAppId(appId);
  }

  getOrCreateByDiscordId(discordId, displayName = "") {
    const discordKey = String(discordId || "").trim();
    if (!discordKey) {
      throw new Error("discord_id is required");
    }

    const existing = this.getByDiscordId(discordKey);
    if (existing) {
      let updated = false;
      const nextName = String(displayName || "").trim().slice(0, 24);
      if (nextName && existing.displayName !== nextName) {
        existing.displayName = nextName;
        existing.updatedAt = nowIso();
        this.state.usersByAppId[existing.appId] = existing;
        updated = true;
      }
      if (updated) {
        this.save();
      }
      return { ...existing, created: false };
    }

    const timestamp = nowIso();
    const appId = this.createImmutableAppId();
    const record = {
      appId,
      discordId: discordKey,
      displayName: String(displayName || "").trim().slice(0, 24),
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.state.usersByAppId[appId] = record;
    this.state.appIdByDiscordId[discordKey] = appId;
    this.save();
    return { ...record, created: true };
  }

  bindDiscordId(discordId, appId, displayName = "", options = {}) {
    const discordKey = String(discordId || "").trim();
    const appKey = String(appId || "").trim();
    const forceRebind = !!options.forceRebind;
    if (!discordKey || !appKey) {
      throw new Error("discord_id and appId are required");
    }

    const existingForDiscord = this.state.appIdByDiscordId[discordKey];
    if (existingForDiscord && existingForDiscord !== appKey) {
      if (!forceRebind) {
        throw new Error(`discord_id already bound to ${existingForDiscord}`);
      }
      const previousRecord = this.state.usersByAppId[existingForDiscord];
      if (previousRecord) {
        this.state.usersByAppId[existingForDiscord] = {
          ...previousRecord,
          discordId: "",
          updatedAt: nowIso(),
        };
      }
    }

    const ensured = this.ensureAppId(appKey, displayName);
    const nextName = String(displayName || "").trim().slice(0, 24);
    if (ensured.discordId && ensured.discordId !== discordKey) {
      delete this.state.appIdByDiscordId[ensured.discordId];
    }
    const updated = {
      ...ensured,
      discordId: discordKey,
      displayName: nextName || ensured.displayName || "",
      updatedAt: nowIso(),
    };
    this.state.usersByAppId[appKey] = updated;
    this.state.appIdByDiscordId[discordKey] = appKey;
    this.save();
    return { ...updated };
  }

  updateDisplayName(appId, displayName) {
    const key = String(appId || "").trim();
    if (!key || !this.state.usersByAppId[key]) {
      return null;
    }

    const nextName = String(displayName || "").trim().slice(0, 24);
    this.state.usersByAppId[key] = {
      ...this.state.usersByAppId[key],
      displayName: nextName,
      updatedAt: nowIso(),
    };
    this.save();
    return { ...this.state.usersByAppId[key] };
  }
}

module.exports = { IdentityStore };
