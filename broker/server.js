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

const tableGames = new Set(["slots", "pachinko", "blackjack", "holdem", "horse"]);
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
  };
  state.tableLobbies.set(lobby.id, lobby);
  return lobby;
}

function tableMaxPlayers(game) {
  if (game === "slots" || game === "pachinko") return 3;
  if (game === "blackjack") return 6;
  if (game === "horse") return 20;
  return 8;
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
  }
}

function assignPlayerToTableLobby(player, lobby) {
  if (lobby.playerIds.includes(player.id)) return true;
  if (lobby.playerIds.length >= tableMaxPlayers(lobby.game)) return false;

  removePlayerFromTableLobby(player);
  player.tableLobbyId = lobby.id;
  lobby.playerIds.push(player.id);
  lobby.seats.set(player.id, createEmptyTableSeat(player));
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
    tableLobbyId: "",
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
      for (const game of tableGames) broadcastTableGame(game);
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
      const gameLabels = { slots: "Slots", pachinko: "Pachinko", blackjack: "Blackjack", holdem: "Hold'em", horse: "Horse Race" };
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