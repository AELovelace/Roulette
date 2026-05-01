const WebSocket = require("ws");

const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;
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

const tableGames = new Set(["slots", "pachinko"]);
const slotSymbolCount = 6;
const slotPoints = [1, 2, 3, 5, 7, 10];
const pachinkoWidth = 10;
const pachinkoRows = 9;

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
  };
  state.tableLobbies.set(lobby.id, lobby);
  return lobby;
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
  lobby.seats.delete(player.id);
  lobby.playerIds = lobby.playerIds.filter((id) => id !== player.id);
  player.tableLobbyId = "";
  lobby.lastEvent = `${player.name} left ${lobby.name}.`;

  if (lobby.playerIds.length === 0) {
    state.tableLobbies.delete(lobby.id);
  }
}

function assignPlayerToTableLobby(player, lobby) {
  if (lobby.playerIds.includes(player.id)) return true;
  if (lobby.playerIds.length >= 3) return false;

  removePlayerFromTableLobby(player);
  player.tableLobbyId = lobby.id;
  lobby.playerIds.push(player.id);
  lobby.seats.set(player.id, createEmptyTableSeat(player));
  lobby.lastEvent = `${player.name} joined ${lobby.name}.`;
  return true;
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
      maxPlayers: 3,
      phase: lobby.playerIds.some((id) => lobby.seats.get(id)?.running) ? "playing" : "ready",
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
    };
  });
  while (seats.length < 3) seats.push(null);
  return seats.slice(0, 3);
}

function buildTableSnapshot(forPlayer, game) {
  const lobby = getTableLobbyForPlayer(forPlayer);
  const inRequestedGame = lobby && lobby.game === game;
  return {
    type: "table_state",
    game,
    playerId: forPlayer.id,
    bankroll: forPlayer.bankroll,
    currentLobbyId: inRequestedGame ? lobby.id : "",
    currentLobbyName: inRequestedGame ? lobby.name : "No lobby",
    playerCount: inRequestedGame ? lobby.playerIds.length : 0,
    maxPlayers: 3,
    lastEvent: inRequestedGame ? lobby.lastEvent : "Join or create a lobby.",
    lobbies: buildTableLobbyList(game),
    seats: inRequestedGame ? buildTableSeats(lobby) : [null, null, null],
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

function assignPlayerToLobby(player, lobby) {
  removePlayerFromLobby(player);
  player.lobbyId = lobby.id;
  lobby.playerIds.add(player.id);
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

const wss = new WebSocket.Server({ port: PORT });

wss.on("connection", (socket) => {
  const player = {
    id: `P${state.nextPlayerId++}`,
    name: "Player",
    bankroll: 1000,
    bets: {},
    lastWager: 0,
    lastPayout: 0,
    lobbyId: "",
    socket,
  };
  state.players.set(player.id, player);

  sendJson(socket, { type: "welcome", playerId: player.id });
  broadcastState();

  socket.on("message", (raw) => {
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

    if (message.type === "join" && typeof message.name === "string" && message.name.trim()) {
      player.name = message.name.trim().slice(0, 24);
      broadcastState();
      broadcastTableGame("slots");
      broadcastTableGame("pachinko");
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
      const gameLabel = message.game === "slots" ? "Slots" : "Pachinko";
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
    removePlayerFromLobby(player);
    const tableLobby = getTableLobbyForPlayer(player);
    const tableGame = tableLobby?.game;
    removePlayerFromTableLobby(player);
    state.players.delete(player.id);
    broadcastState();
    if (tableGame) broadcastTableGame(tableGame);
  });
});

console.log(`Roulette broker listening on ws://127.0.0.1:${PORT}`);