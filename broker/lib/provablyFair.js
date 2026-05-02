const crypto = require("crypto");

function hashSeed(seed) {
  return crypto.createHash("sha256").update(seed, "utf8").digest("hex");
}

function randomSeed() {
  return crypto.randomBytes(32).toString("hex");
}

function createRandomCursor(serverSeed, clientSeed, nonce) {
  let cursor = 0;
  let cached = [];

  function refill() {
    const digest = crypto
      .createHmac("sha256", serverSeed)
      .update(`${clientSeed}:${nonce}:${cursor}`, "utf8")
      .digest();
    cursor += 1;
    cached = [];
    for (let i = 0; i < digest.length; i += 4) {
      const value = digest.readUInt32BE(i % (digest.length - 3));
      cached.push(value / 0xffffffff);
    }
  }

  function nextFloat() {
    if (!cached.length) {
      refill();
    }
    return cached.shift();
  }

  function nextInt(maxExclusive) {
    if (!Number.isInteger(maxExclusive) || maxExclusive <= 0) {
      throw new Error("maxExclusive must be a positive integer");
    }
    return Math.floor(nextFloat() * maxExclusive);
  }

  return {
    nextFloat,
    nextInt,
    describe() {
      return {
        server_seed_hash: hashSeed(serverSeed),
        client_seed: clientSeed,
        nonce,
        cursor,
      };
    },
  };
}

function shuffleWithCursor(items, cursor) {
  const nextItems = [...items];
  for (let i = nextItems.length - 1; i > 0; i -= 1) {
    const j = cursor.nextInt(i + 1);
    [nextItems[i], nextItems[j]] = [nextItems[j], nextItems[i]];
  }
  return nextItems;
}

function createRoundSeedBundle(previousHash, clientSeed, nonce = 0) {
  const serverSeed = randomSeed();
  const serverSeedHash = hashSeed(serverSeed);
  return {
    serverSeed,
    serverSeedHash,
    clientSeed: clientSeed || randomSeed().slice(0, 16),
    nonce,
    previousHash: previousHash || null,
  };
}

module.exports = {
  createRandomCursor,
  createRoundSeedBundle,
  hashSeed,
  randomSeed,
  shuffleWithCursor,
};