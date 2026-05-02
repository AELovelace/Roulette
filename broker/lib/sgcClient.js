const crypto = require("crypto");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class ApiError extends Error {
  constructor(message, options = {}) {
    super(message);
    this.name = "ApiError";
    this.status = options.status || 0;
    this.code = options.code || "unknown_error";
    this.retryable = Boolean(options.retryable);
    this.body = options.body || null;
    this.headers = options.headers || {};
  }
}

class TokenBucket {
  constructor(capacity, refillPerMinute) {
    this.capacity = Math.max(1, capacity || 60);
    this.tokens = this.capacity;
    this.refillPerMs = this.capacity / Math.max(60000, refillPerMinute ? (60000 * this.capacity) / refillPerMinute : 60000);
    this.lastRefillAt = Date.now();
    this.queue = [];
  }

  refill() {
    const now = Date.now();
    const elapsed = now - this.lastRefillAt;
    if (elapsed <= 0) {
      return;
    }
    this.tokens = Math.min(this.capacity, this.tokens + (elapsed * this.refillPerMs));
    this.lastRefillAt = now;
  }

  pump() {
    this.refill();
    this.queue.sort((left, right) => left.priority - right.priority || left.createdAt - right.createdAt);
    while (this.queue.length > 0 && this.tokens >= 1) {
      this.tokens -= 1;
      const next = this.queue.shift();
      next.resolve();
    }
  }

  async take(priority = 5) {
    this.pump();
    if (this.tokens >= 1) {
      this.tokens -= 1;
      return;
    }
    await new Promise((resolve) => {
      this.queue.push({ priority, resolve, createdAt: Date.now() });
      const timer = setInterval(() => {
        this.pump();
        if (!this.queue.some((entry) => entry.resolve === resolve)) {
          clearInterval(timer);
        }
      }, 100);
    });
  }
}

class SadgirlcoinClient {
  constructor(config = {}) {
    this.baseUrl = String(config.baseUrl || "").replace(/\/$/, "");
    this.apiKey = config.apiKey || "";
    this.webhookSecret = config.webhookSecret || "";
    this.timeoutMs = Number(config.timeoutMs || 5000);
    this.maxRetries = Number(config.maxRetries || 3);
    this.circuitBreakerThreshold = Number(config.circuitBreakerThreshold || 5);
    this.circuitBreakerCooldownMs = Number(config.circuitBreakerCooldownMs || 30000);
    this.log = config.log || console;
    this.limiter = new TokenBucket(Number(config.rateLimitPerMin || 60), Number(config.rateLimitPerMin || 60));
    this.softFailures = 0;
    this.circuitOpenUntil = 0;
    this.identity = null;
  }

  ensureConfigured() {
    if (!this.baseUrl) {
      throw new Error("SGC_BASE_URL is required");
    }
    if (!this.apiKey) {
      throw new Error("SGC_API_KEY is required");
    }
  }

  verifyCircuit() {
    if (Date.now() < this.circuitOpenUntil) {
      throw new ApiError("Circuit breaker open", {
        code: "circuit_open",
        retryable: true,
      });
    }
  }

  noteSoftFailure() {
    this.softFailures += 1;
    if (this.softFailures >= this.circuitBreakerThreshold) {
      this.circuitOpenUntil = Date.now() + this.circuitBreakerCooldownMs;
      this.log.warn("Sadgirlcoin client circuit breaker opened");
    }
  }

  noteSuccess() {
    this.softFailures = 0;
    this.circuitOpenUntil = 0;
  }

  priorityNumber(priority) {
    if (priority === "bet") return 1;
    if (priority === "settle") return 2;
    if (priority === "reconcile") return 3;
    if (priority === "balance") return 4;
    return 5;
  }

  async bootstrap(requiredScopes = []) {
    const payload = await this.requestJson({
      method: "GET",
      path: "/me",
      priority: "balance",
      validate: (body) => {
        if (!body || typeof body !== "object" || !body.app || !Array.isArray(body.app.scopes)) {
          throw new ApiError("Invalid /me response schema", { code: "invalid_schema" });
        }
      },
    });
    const scopes = payload.body.app.scopes;
    for (const required of requiredScopes) {
      if (!scopes.includes(required)) {
        throw new Error(`Sadgirlcoin app missing required scope: ${required}`);
      }
    }
    this.identity = payload.body.app;
    return this.identity;
  }

  async requestJson(options) {
    this.ensureConfigured();
    const method = options.method || "GET";
    const path = options.path || "/";
    const body = options.body;
    const idempotencyKey = options.idempotencyKey;
    const priority = this.priorityNumber(options.priority);
    const validate = options.validate;

    let attempt = 0;
    let delayMs = 500;

    while (true) {
      attempt += 1;
      this.verifyCircuit();
      await this.limiter.take(priority);

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
      const headers = {
        Authorization: `Bearer ${this.apiKey}`,
        Accept: "application/json",
      };
      if (body !== undefined) {
        headers["Content-Type"] = "application/json";
      }
      if (idempotencyKey) {
        headers["Idempotency-Key"] = idempotencyKey;
      }

      try {
        const response = await fetch(`${this.baseUrl}${path}`, {
          method,
          headers,
          body: body !== undefined ? JSON.stringify(body) : undefined,
          signal: controller.signal,
        });
        clearTimeout(timeout);
        const text = await response.text();
        let parsed = null;
        if (text) {
          try {
            parsed = JSON.parse(text);
          } catch (error) {
            throw new ApiError("Non-JSON response from Sadgirlcoin API", {
              status: response.status,
              code: "invalid_json",
              retryable: response.status >= 500,
              body: text,
            });
          }
        }
        const headersObject = Object.fromEntries(response.headers.entries());

        if (response.status === 429) {
          const retryAfterSeconds = Number(parsed?.error?.retry_after_s || response.headers.get("retry-after") || 1);
          if (attempt < this.maxRetries) {
            this.noteSoftFailure();
            await sleep(Math.max(250, retryAfterSeconds * 1000));
            continue;
          }
          throw new ApiError(parsed?.error?.message || "Rate limited", {
            status: response.status,
            code: parsed?.error?.code || "rate_limited",
            retryable: true,
            body: parsed,
            headers: headersObject,
          });
        }

        if (response.status >= 500) {
          if (attempt < this.maxRetries) {
            this.noteSoftFailure();
            await sleep(delayMs);
            delayMs *= 2;
            continue;
          }
          throw new ApiError(parsed?.error?.message || "Sadgirlcoin server error", {
            status: response.status,
            code: parsed?.error?.code || "server_error",
            retryable: true,
            body: parsed,
            headers: headersObject,
          });
        }

        if (response.status < 200 || response.status >= 300) {
          throw new ApiError(parsed?.error?.message || `Sadgirlcoin API rejected ${method} ${path}`, {
            status: response.status,
            code: parsed?.error?.code || "request_failed",
            retryable: false,
            body: parsed,
            headers: headersObject,
          });
        }

        if (validate) {
          validate(parsed);
        }
        this.noteSuccess();
        return { body: parsed, status: response.status, headers: headersObject };
      } catch (error) {
        clearTimeout(timeout);
        if (error instanceof ApiError) {
          throw error;
        }
        if (attempt < this.maxRetries) {
          this.noteSoftFailure();
          await sleep(delayMs);
          delayMs *= 2;
          continue;
        }
        throw new ApiError(error.name === "AbortError" ? "Sadgirlcoin API timeout" : error.message, {
          code: error.name === "AbortError" ? "timeout" : "network_error",
          retryable: true,
        });
      }
    }
  }

  async fetchBalance(externalId, priority = "balance") {
    return this.requestJson({
      method: "GET",
      path: `/users/${encodeURIComponent(externalId)}/balance`,
      priority,
      validate: (body) => {
        if (!body || !Number.isInteger(body.balance)) {
          throw new ApiError("Invalid balance response schema", { code: "invalid_schema" });
        }
      },
    });
  }

  async fetchTransactions(externalId, limit = 50) {
    return this.requestJson({
      method: "GET",
      path: `/users/${encodeURIComponent(externalId)}/transactions?limit=${Math.max(1, Math.min(100, limit))}`,
      priority: "reconcile",
      validate: (body) => {
        if (!body || !Array.isArray(body.transactions)) {
          throw new ApiError("Invalid transactions response schema", { code: "invalid_schema" });
        }
      },
    });
  }

  async redeemLinkCode(code, externalId, externalName) {
    return this.requestJson({
      method: "POST",
      path: "/links/codes/redeem",
      priority: "balance",
      body: {
        code,
        external_id: externalId,
        external_name: externalName,
      },
      validate: (body) => {
        if (!body || !body.link || typeof body.link.external_id !== "string") {
          throw new ApiError("Invalid redeem response schema", { code: "invalid_schema" });
        }
      },
    });
  }

  async charge(externalId, amount, note, idempotencyKey) {
    return this.requestJson({
      method: "POST",
      path: "/charge",
      priority: "bet",
      idempotencyKey,
      body: {
        external_id: externalId,
        amount,
        note,
        idempotency_key: idempotencyKey,
      },
      validate: (body) => {
        if (!body || body.ok !== true || !Number.isInteger(body.amount) || !Number.isInteger(body.balance)) {
          throw new ApiError("Invalid charge response schema", { code: "invalid_schema" });
        }
      },
    });
  }

  async credit(externalId, amount, note, idempotencyKey) {
    return this.requestJson({
      method: "POST",
      path: "/credit",
      priority: "settle",
      idempotencyKey,
      body: {
        external_id: externalId,
        amount,
        note,
        idempotency_key: idempotencyKey,
      },
      validate: (body) => {
        if (!body || body.ok !== true || !Number.isInteger(body.amount) || !Number.isInteger(body.balance)) {
          throw new ApiError("Invalid credit response schema", { code: "invalid_schema" });
        }
      },
    });
  }

  async mint(externalId, amount, note, idempotencyKey) {
    return this.requestJson({
      method: "POST",
      path: "/mint",
      priority: "settle",
      idempotencyKey,
      body: {
        external_id: externalId,
        amount,
        note,
        idempotency_key: idempotencyKey,
      },
      validate: (body) => {
        if (!body || body.ok !== true || body.minted !== true) {
          throw new ApiError("Invalid mint response schema", { code: "invalid_schema" });
        }
      },
    });
  }

  verifyWebhookSignature(rawBody, signatureHeader) {
    if (!this.webhookSecret) {
      return false;
    }
    if (!signatureHeader || !signatureHeader.startsWith("sha256=")) {
      return false;
    }
    const expected = `sha256=${crypto.createHmac("sha256", this.webhookSecret).update(rawBody, "utf8").digest("hex")}`;
    const actualBuffer = Buffer.from(signatureHeader, "utf8");
    const expectedBuffer = Buffer.from(expected, "utf8");
    if (actualBuffer.length !== expectedBuffer.length) {
      return false;
    }
    return crypto.timingSafeEqual(actualBuffer, expectedBuffer);
  }
}

module.exports = {
  ApiError,
  SadgirlcoinClient,
};