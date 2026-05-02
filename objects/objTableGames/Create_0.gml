backgroundTop = make_color_rgb(5, 6, 10);
backgroundBottom = make_color_rgb(34, 15, 38);
panelColor = make_color_rgb(16, 15, 25);
railColor = make_color_rgb(93, 228, 207);
buttonColor = make_color_rgb(30, 24, 43);
buttonHoverColor = make_color_rgb(42, 64, 72);
accentColor = make_color_rgb(213, 43, 102);
accentHoverColor = make_color_rgb(246, 94, 137);
textColor = c_white;
mutedTextColor = make_color_rgb(204, 195, 214);
blackFeltColor = make_color_rgb(7, 8, 14);

GAME_SLOTS = 0;
GAME_PACHINKO = 1;
GAME_BLACKJACK = 2;
GAME_HOLDEM = 3;
GAME_HORSE = 4;

gameNames = ["Slots", "Pachinko", "Blackjack", "Hold'em", "Horse Race"];
selectedGame = GAME_SLOTS;
tableRoomLocked = false;
tableBackRoom = RoomTableLobby;
tableLobbyOpen = false;
tableGameKey = "";

if (room == RoomSlots) {
	selectedGame = GAME_SLOTS;
	tableGameKey = "slots";
	tableRoomLocked = true;
	tableLobbyOpen = true;
}

if (room == RoomPachinko) {
	selectedGame = GAME_PACHINKO;
	tableGameKey = "pachinko";
	tableRoomLocked = true;
	tableLobbyOpen = true;
}

if (room == RoomBlackjack) {
	selectedGame = GAME_BLACKJACK;
	tableGameKey = "blackjack";
	tableRoomLocked = true;
	tableLobbyOpen = true;
}

if (room == RoomHoldem) {
	selectedGame = GAME_HOLDEM;
	tableGameKey = "holdem";
	tableRoomLocked = true;
	tableLobbyOpen = true;
}

if (room == RoomHorseRace) {
	selectedGame = GAME_HORSE;
	tableGameKey = "horse";
	tableRoomLocked = true;
	tableLobbyOpen = true;
}
balance = 500;
betOptions = [1, 5, 10, 25];
selectedBetIndex = 1;
statusText = "Pick a table, set a bet, and play.";
hoveredControl = "";
tableMultiplayerEnabled = (tableGameKey != "");
tableBrokerHost = "ws://127.0.0.1";
tableBrokerPort = 8080;
tableBrokerSocket = -1;
tableBrokerConnected = false;
tableBrokerStatus = "Connecting to broker...";
tablePlayerId = "";
tablePlayerName = "Player " + string(irandom_range(1000, 9999));
tableCurrentLobbyId = "";
tableCurrentLobbyName = "No lobby";
tableLobbyList = [];
tableSelectedLobbyId = "";
tableLobbyBrowserOpen = tableMultiplayerEnabled;
tableLastEvent = "Join or create a lobby.";
tableParticipants = [];
tableDealerHand = [];
tableCommunity = [];
tablePhase = "waiting";
tableTurnPlayerId = "";
tableYouAreTurn = false;
tablePot = 0;
tableMaxPlayers = 3;
tableHostPlayerId = "";
tableIsHost = false;
tableHorseState = "betting";
tableHorsePositions = [0, 0, 0, 0];
tableHorseWinner = -1;
tableHorseUnderdog = -1;
tableHorseWins = [0, 0, 0, 0];

function resetTableLobbyState(_message) {
	tableCurrentLobbyId = "";
	tableCurrentLobbyName = "No lobby";
	tableLobbyOpen = true;
	tableLobbyBrowserOpen = true;
	tableLastEvent = _message;
	statusText = _message;
	if (tableGameKey == "slots") {
		slotSeats = [createEmptySlotSeat(), createEmptySlotSeat(), createEmptySlotSeat()];
	}
	if (tableGameKey == "pachinko") {
		pachinkoSeats = [createEmptyPachinkoSeat(), createEmptyPachinkoSeat(), createEmptyPachinkoSeat()];
	}
	tableParticipants = [];
	tableDealerHand = [];
	tableCommunity = [];
	tablePhase = "waiting";
	tableTurnPlayerId = "";
	tableYouAreTurn = false;
	tablePot = 0;
	tableHostPlayerId = "";
	tableIsHost = false;
	tableHorseState = "betting";
	tableHorsePositions = [0, 0, 0, 0];
	tableHorseWinner = -1;
	tableHorseUnderdog = -1;
	tableHorseWins = [0, 0, 0, 0];
}

function leaveTableLobbyIfNeeded(_message) {
	if (tableMultiplayerEnabled && tableBrokerConnected && tableBrokerSocket >= 0 && tableCurrentLobbyId != "") {
		rouletteSendJson(tableBrokerSocket, { type: "table_leave_lobby", game: tableGameKey });
	}
	resetTableLobbyState(_message);
}

function closeTableBrokerSocket() {
	if (tableBrokerSocket >= 0) {
		if (tableBrokerConnected && tableCurrentLobbyId != "") {
			rouletteSendJson(tableBrokerSocket, { type: "table_leave_lobby", game: tableGameKey });
		}
		network_destroy(tableBrokerSocket);
		tableBrokerSocket = -1;
		tableBrokerConnected = false;
	}
}

slotNames = ["Cherry", "Bell", "Gem", "Seven", "Crown", "Moon"];
slotColors = [make_color_rgb(224, 57, 69), make_color_rgb(237, 195, 74), make_color_rgb(67, 185, 202), make_color_rgb(229, 78, 104), make_color_rgb(191, 137, 45), make_color_rgb(161, 114, 211)];
slotPoints = [1, 2, 3, 5, 7, 10];
slotGrid = array_create(9, 0);
slotFinalGrid = array_create(9, 0);
slotSpinTimer = 0;
slotSpinDuration = 44;
slotMessage = "Five lines score: three rows plus two diagonals. Bell is wild.";
slotSeats = [];

pachinkoWidth = 10;
pachinkoRows = 9;
pachinkoGuess = 5;
pachinkoPath = [];
pachinkoVisibleRows = 0;
pachinkoTimer = 0;
pachinkoRunning = false;
pachinkoLandedPeg = 0;
pachinkoMessage = "Choose a peg from 1 to 10, then drop the ball.";
pachinkoSeats = [];

cardSuits = ["S", "H", "D", "C"];
cardRanks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
bjDeck = [];
bjPlayerHand = [];
bjDealerHand = [];
bjPhase = "idle";
bjMessage = "Dealer stands on 17. Blackjack pays 2.5x return.";

holdemDeck = [];
holdemPlayer = [];
holdemCpu = [];
holdemCommunity = [];
holdemPhase = "idle";
holdemPot = 0;
holdemRaised = false;
holdemMessage = "One-player Hold'em against a CPU caller.";
holdemRevealCpu = false;

horseNames = ["A", "B", "C", "D"];
horseColors = [make_color_rgb(224, 74, 74), make_color_rgb(74, 149, 224), make_color_rgb(231, 188, 64), make_color_rgb(92, 191, 112)];
horseWins = [0, 0, 0, 0];
horseChoice = 0;
horsePositions = [0, 0, 0, 0];
horseState = "betting";
horseWinner = -1;
horseFinish = 100;
horseMessage = "Pick a horse. Underdogs pay double.";

function currentBet() {
	return betOptions[selectedBetIndex];
}

function tablePointInButton(_button, _mx, _my) {
	return point_in_rectangle(_mx, _my, _button.x, _button.y, _button.x + _button.w, _button.y + _button.h);
}

function setTableStatus(_text) {
	statusText = _text;
}

function randomSlotSymbol() {
	var weights = [24, 20, 18, 13, 9, 5];
	var total = 0;
	for (var i = 0; i < array_length(weights); i += 1) {
		total += weights[i];
	}
	var roll = irandom(total - 1);
	for (var s = 0; s < array_length(weights); s += 1) {
		roll -= weights[s];
		if (roll < 0) {
			return s;
		}
	}
	return 0;
}

function randomizeSlotGrid(_target) {
	for (var i = 0; i < 9; i += 1) {
		_target[i] = randomSlotSymbol();
	}
}

function makeSlotGrid() {
	var grid = array_create(9, 0);
	randomizeSlotGrid(grid);
	return grid;
}

function createSlotSeat(_name, _isHuman) {
	return {
		name: _name,
		isHuman: _isHuman,
		active: _name != "",
		balance: _isHuman ? balance : 0,
		bet: currentBet(),
		grid: makeSlotGrid(),
		finalGrid: makeSlotGrid(),
		spinTimer: 0,
		status: "Ready",
		playerId: ""
	};
}

function createEmptySlotSeat() {
	return createSlotSeat("", false);
}

function tableGridFromJson(_value) {
	var grid = array_create(9, 0);
	if (is_array(_value)) {
		for (var gridIndex = 0; gridIndex < min(9, array_length(_value)); gridIndex += 1) {
			grid[gridIndex] = real(_value[gridIndex]);
		}
	}
	return grid;
}

function tablePathFromJson(_value) {
	var path = [];
	if (is_array(_value)) {
		for (var pathIndex = 0; pathIndex < array_length(_value); pathIndex += 1) {
			array_push(path, real(_value[pathIndex]));
		}
	}
	return path;
}

function tableCardsFromJson(_value) {
	var cards = [];
	if (is_array(_value)) {
		for (var cardIndex = 0; cardIndex < array_length(_value); cardIndex += 1) {
			var cardData = _value[cardIndex];
			if (is_struct(cardData)) {
				array_push(cards, { rank: rouletteStructGet(cardData, "rank", "?"), suit: rouletteStructGet(cardData, "suit", "?") });
			} else {
				array_push(cards, undefined);
			}
		}
	}
	return cards;
}

function tableParticipantsFromJson(_value) {
	var participants = [];
	if (is_array(_value)) {
		for (var participantIndex = 0; participantIndex < array_length(_value); participantIndex += 1) {
			var participantData = _value[participantIndex];
			if (is_struct(participantData)) {
				array_push(participants, {
					playerId: rouletteStructGet(participantData, "playerId", ""),
					name: rouletteStructGet(participantData, "name", "Player"),
					balance: rouletteStructGet(participantData, "balance", 0),
					bet: rouletteStructGet(participantData, "bet", currentBet()),
					status: rouletteStructGet(participantData, "status", "Ready"),
					folded: rouletteStructGet(participantData, "folded", false),
					stayed: rouletteStructGet(participantData, "stayed", false),
					acted: rouletteStructGet(participantData, "acted", false),
					isTurn: rouletteStructGet(participantData, "isTurn", false),
					isHost: rouletteStructGet(participantData, "isHost", false),
					horseChoice: rouletteStructGet(participantData, "horseChoice", 0),
					total: rouletteStructGet(participantData, "total", 0),
					hand: tableCardsFromJson(rouletteStructGet(participantData, "hand", []))
				});
			}
		}
	}
	return participants;
}

function applyTableSnapshot(_message) {
	tableCurrentLobbyId = rouletteStructGet(_message, "currentLobbyId", tableCurrentLobbyId);
	tableCurrentLobbyName = rouletteStructGet(_message, "currentLobbyName", tableCurrentLobbyName);
	tableLobbyList = rouletteStructGet(_message, "lobbies", []);
	tableLastEvent = rouletteStructGet(_message, "lastEvent", tableLastEvent);
	balance = rouletteStructGet(_message, "bankroll", balance);
	tableParticipants = tableParticipantsFromJson(rouletteStructGet(_message, "participants", []));
	tableDealerHand = tableCardsFromJson(rouletteStructGet(_message, "dealerHand", []));
	tableCommunity = tableCardsFromJson(rouletteStructGet(_message, "community", []));
	tablePhase = rouletteStructGet(_message, "phase", tablePhase);
	tableTurnPlayerId = rouletteStructGet(_message, "turnPlayerId", "");
	tableYouAreTurn = rouletteStructGet(_message, "youAreTurn", false);
	tablePot = rouletteStructGet(_message, "pot", tablePot);
	tableMaxPlayers = rouletteStructGet(_message, "maxPlayers", tableMaxPlayers);
	tableHostPlayerId = rouletteStructGet(_message, "hostPlayerId", tableHostPlayerId);
	tableIsHost = (tableHostPlayerId != "" && tableHostPlayerId == tablePlayerId);
	tableHorseState = rouletteStructGet(_message, "horseState", tableHorseState);
	tableHorsePositions = rouletteStructGet(_message, "horsePositions", tableHorsePositions);
	tableHorseWinner = rouletteStructGet(_message, "horseWinner", tableHorseWinner);
	tableHorseUnderdog = rouletteStructGet(_message, "horseUnderdog", tableHorseUnderdog);
	tableHorseWins = rouletteStructGet(_message, "horseWins", tableHorseWins);
	if (tableGameKey == "horse") {
		for (var participantIndex = 0; participantIndex < array_length(tableParticipants); participantIndex += 1) {
			var participant = tableParticipants[participantIndex];
			if (rouletteStructGet(participant, "playerId", "") == tablePlayerId) {
				horseChoice = rouletteStructGet(participant, "horseChoice", horseChoice);
			}
		}
	}
	var incomingSeats = rouletteStructGet(_message, "seats", []);
	if (tableGameKey == "slots") {
		slotSeats = [];
		for (var slotSeatIndex = 0; slotSeatIndex < 3; slotSeatIndex += 1) {
			var slotSeatData = (is_array(incomingSeats) && slotSeatIndex < array_length(incomingSeats)) ? incomingSeats[slotSeatIndex] : undefined;
			if (is_struct(slotSeatData)) {
				var slotSeat = createSlotSeat(rouletteStructGet(slotSeatData, "name", "Player"), rouletteStructGet(slotSeatData, "playerId", "") == tablePlayerId);
				slotSeat.active = true;
				slotSeat.playerId = rouletteStructGet(slotSeatData, "playerId", "");
				slotSeat.balance = rouletteStructGet(slotSeatData, "balance", 0);
				slotSeat.bet = rouletteStructGet(slotSeatData, "bet", currentBet());
				slotSeat.status = rouletteStructGet(slotSeatData, "status", "Ready");
				slotSeat.spinTimer = rouletteStructGet(slotSeatData, "running", false) ? 1 : 0;
				slotSeat.grid = tableGridFromJson(rouletteStructGet(slotSeatData, "grid", []));
				array_push(slotSeats, slotSeat);
			} else {
				array_push(slotSeats, createEmptySlotSeat());
			}
		}
	}
	if (tableGameKey == "pachinko") {
		pachinkoSeats = [];
		for (var pachinkoSeatIndex = 0; pachinkoSeatIndex < 3; pachinkoSeatIndex += 1) {
			var pachinkoSeatData = (is_array(incomingSeats) && pachinkoSeatIndex < array_length(incomingSeats)) ? incomingSeats[pachinkoSeatIndex] : undefined;
			if (is_struct(pachinkoSeatData)) {
				var pachinkoSeat = createPachinkoSeat(rouletteStructGet(pachinkoSeatData, "name", "Player"), rouletteStructGet(pachinkoSeatData, "playerId", "") == tablePlayerId);
				pachinkoSeat.active = true;
				pachinkoSeat.playerId = rouletteStructGet(pachinkoSeatData, "playerId", "");
				pachinkoSeat.balance = rouletteStructGet(pachinkoSeatData, "balance", 0);
				pachinkoSeat.bet = rouletteStructGet(pachinkoSeatData, "bet", currentBet());
				pachinkoSeat.guess = rouletteStructGet(pachinkoSeatData, "guess", 5);
				pachinkoSeat.status = rouletteStructGet(pachinkoSeatData, "status", "Ready");
				pachinkoSeat.running = rouletteStructGet(pachinkoSeatData, "running", false);
				pachinkoSeat.path = tablePathFromJson(rouletteStructGet(pachinkoSeatData, "path", []));
				pachinkoSeat.visibleRows = rouletteStructGet(pachinkoSeatData, "visibleRows", 0);
				pachinkoSeat.landedPeg = rouletteStructGet(pachinkoSeatData, "landedPeg", 0);
				array_push(pachinkoSeats, pachinkoSeat);
			} else {
				array_push(pachinkoSeats, createEmptyPachinkoSeat());
			}
		}
	}
	if (array_length(tableLobbyList) > 0) {
		var foundSelectedLobby = false;
		for (var lobbyIndex = 0; lobbyIndex < array_length(tableLobbyList); lobbyIndex += 1) {
			if (rouletteStructGet(tableLobbyList[lobbyIndex], "id", "") == tableSelectedLobbyId) {
				foundSelectedLobby = true;
			}
		}
		if (!foundSelectedLobby) tableSelectedLobbyId = rouletteStructGet(tableLobbyList[0], "id", "");
	} else {
		tableSelectedLobbyId = "";
	}
	tableLobbyBrowserOpen = tableBrokerConnected && (tableCurrentLobbyId == "" || tableLobbyBrowserOpen);
	if (tableCurrentLobbyId != "") tableLobbyBrowserOpen = false;
}

function slotLinePoints(_a, _b, _c) {
	var wild = 1;
	if (_a == _b && _b == _c) {
		return slotPoints[_a];
	}
	if (_a == wild && _b == _c) {
		return max(1, slotPoints[_b] div 2);
	}
	if (_b == wild && _a == _c) {
		return max(1, slotPoints[_a] div 2);
	}
	if (_c == wild && _a == _b) {
		return max(1, slotPoints[_a] div 2);
	}
	return 0;
}

function evaluateSlots() {
	return evaluateSlotGrid(slotGrid);
}

function evaluateSlotGrid(_grid) {
	var points = 0;
	points += slotLinePoints(_grid[0], _grid[1], _grid[2]);
	points += slotLinePoints(_grid[3], _grid[4], _grid[5]);
	points += slotLinePoints(_grid[6], _grid[7], _grid[8]);
	points += slotLinePoints(_grid[0], _grid[4], _grid[8]);
	points += slotLinePoints(_grid[2], _grid[4], _grid[6]);
	return points;
}

function startSlotSeat(_seatIndex) {
	var seat = slotSeats[_seatIndex];
	if (seat.spinTimer > 0) {
		return;
	}
	var bet = seat.isHuman ? currentBet() : seat.bet;
	seat.bet = bet;
	if (seat.balance < bet) {
		seat.status = "Insufficient SGC";
		if (seat.isHuman) setTableStatus("Not enough chips for that spin.");
		slotSeats[_seatIndex] = seat;
		return;
	}
	seat.balance -= bet;
	seat.finalGrid = makeSlotGrid();
	seat.spinTimer = slotSpinDuration + (_seatIndex * 8);
	seat.status = "Spinning for " + string(bet) + " SGC";
	if (seat.isHuman) {
		balance = seat.balance;
		slotMessage = "Your reels are spinning. Other seats stay visible.";
		setTableStatus(slotMessage);
	}
	slotSeats[_seatIndex] = seat;
}

function startSlots() {
	startSlotSeat(0);
}

function updateSlotSeats() {
	for (var seatIndex = 0; seatIndex < array_length(slotSeats); seatIndex += 1) {
		var seat = slotSeats[seatIndex];
		if (!seat.active) continue;
		if (seat.spinTimer > 0) {
			seat.spinTimer -= 1;
			if (seat.spinTimer > 1) {
				randomizeSlotGrid(seat.grid);
			} else {
				for (var si = 0; si < 9; si += 1) {
					seat.grid[si] = seat.finalGrid[si];
				}
				var points = evaluateSlotGrid(seat.grid);
				var payout = points * seat.bet;
				seat.balance += payout;
				seat.status = (payout > 0) ? ("Won " + string(payout) + " SGC") : "No line hit";
				if (seat.isHuman) {
					balance = seat.balance;
					slotMessage = seat.status + ". Everyone's boards remain live.";
					setTableStatus(slotMessage);
				}
			}
		}
		slotSeats[seatIndex] = seat;
	}
}

function makeDeck() {
	var deck = [];
	for (var suit = 0; suit < array_length(cardSuits); suit += 1) {
		for (var rank = 0; rank < array_length(cardRanks); rank += 1) {
			array_push(deck, { rank: cardRanks[rank], suit: cardSuits[suit], value: rank + 1 });
		}
	}
	for (var i = array_length(deck) - 1; i > 0; i -= 1) {
		var j = irandom(i);
		var temp = deck[i];
		deck[i] = deck[j];
		deck[j] = temp;
	}
	return deck;
}

function drawFromDeck(_deck) {
	var card = _deck[array_length(_deck) - 1];
	array_delete(_deck, array_length(_deck) - 1, 1);
	return card;
}

function cardBlackjackValue(_card) {
	if (_card.rank == "A") {
		return 11;
	}
	if (_card.rank == "J" || _card.rank == "Q" || _card.rank == "K") {
		return 10;
	}
	return real(_card.rank);
}

function blackjackHandValue(_hand) {
	var total = 0;
	var aces = 0;
	for (var i = 0; i < array_length(_hand); i += 1) {
		total += cardBlackjackValue(_hand[i]);
		if (_hand[i].rank == "A") {
			aces += 1;
		}
	}
	while (total > 21 && aces > 0) {
		total -= 10;
		aces -= 1;
	}
	return total;
}

function blackjackNatural(_hand) {
	return array_length(_hand) == 2 && blackjackHandValue(_hand) == 21;
}

function startBlackjack() {
	var bet = currentBet();
	if (balance < bet) {
		setTableStatus("Not enough chips to deal blackjack.");
		return;
	}
	balance -= bet;
	bjDeck = makeDeck();
	bjPlayerHand = [drawFromDeck(bjDeck), drawFromDeck(bjDeck)];
	bjDealerHand = [drawFromDeck(bjDeck), drawFromDeck(bjDeck)];
	bjPhase = "playing";
	bjMessage = "Hit or stay.";
	if (blackjackNatural(bjPlayerHand)) {
		resolveBlackjack();
	}
	setTableStatus(bjMessage);
}

function resolveBlackjack() {
	bjPhase = "dealer";
	while (blackjackHandValue(bjDealerHand) < 17) {
		array_push(bjDealerHand, drawFromDeck(bjDeck));
	}
	var bet = currentBet();
	var playerTotal = blackjackHandValue(bjPlayerHand);
	var dealerTotal = blackjackHandValue(bjDealerHand);
	var payout = 0;
	if (playerTotal > 21) {
		bjMessage = "Player busts. House keeps the bet.";
	} else if (blackjackNatural(bjPlayerHand) && !blackjackNatural(bjDealerHand)) {
		payout = floor(bet * 2.5);
		bjMessage = "Blackjack. Paid " + string(payout) + " chips.";
	} else if (dealerTotal > 21 || playerTotal > dealerTotal) {
		payout = bet * 2;
		bjMessage = "Player wins. Paid " + string(payout) + " chips.";
	} else if (playerTotal == dealerTotal) {
		payout = bet;
		bjMessage = "Push. Bet returned.";
	} else {
		bjMessage = "Dealer wins.";
	}
	balance += payout;
	bjPhase = "done";
	setTableStatus(bjMessage);
}

function blackjackHit() {
	if (bjPhase != "playing") {
		return;
	}
	array_push(bjPlayerHand, drawFromDeck(bjDeck));
	if (blackjackHandValue(bjPlayerHand) >= 21) {
		resolveBlackjack();
	} else {
		bjMessage = "Hit or stay.";
		setTableStatus(bjMessage);
	}
}

function rankPokerValue(_card) {
	if (_card.rank == "A") return 14;
	if (_card.rank == "K") return 13;
	if (_card.rank == "Q") return 12;
	if (_card.rank == "J") return 11;
	return real(_card.rank);
}

function pokerScore(_cards) {
	var counts = array_create(15, 0);
	var suits = [0, 0, 0, 0];
	for (var i = 0; i < array_length(_cards); i += 1) {
		var value = rankPokerValue(_cards[i]);
		counts[value] += 1;
		for (var suit = 0; suit < 4; suit += 1) {
			if (_cards[i].suit == cardSuits[suit]) suits[suit] += 1;
		}
	}
	counts[1] = counts[14];
	var flush = false;
	for (var fs = 0; fs < 4; fs += 1) {
		if (suits[fs] >= 5) flush = true;
	}
	var straightHigh = 0;
	var run = 0;
	for (var v = 1; v <= 14; v += 1) {
		if (counts[v] > 0) {
			run += 1;
			if (run >= 5) straightHigh = v;
		} else {
			run = 0;
		}
	}
	var fours = 0;
	var threes = 0;
	var pairs = 0;
	var high = 0;
	for (var r = 14; r >= 2; r -= 1) {
		if (counts[r] > 0 && high == 0) high = r;
		if (counts[r] == 4 && fours == 0) fours = r;
		if (counts[r] == 3 && threes == 0) threes = r;
		if (counts[r] == 2) pairs += 1;
	}
	if (flush && straightHigh > 0) return 800000 + straightHigh;
	if (fours > 0) return 700000 + fours;
	if (threes > 0 && pairs > 0) return 600000 + threes;
	if (flush) return 500000 + high;
	if (straightHigh > 0) return 400000 + straightHigh;
	if (threes > 0) return 300000 + threes;
	if (pairs >= 2) return 200000 + high;
	if (pairs == 1) return 100000 + high;
	return high;
}

function pokerLabel(_score) {
	if (_score >= 800000) return "straight flush";
	if (_score >= 700000) return "four of a kind";
	if (_score >= 600000) return "full house";
	if (_score >= 500000) return "flush";
	if (_score >= 400000) return "straight";
	if (_score >= 300000) return "three of a kind";
	if (_score >= 200000) return "two pair";
	if (_score >= 100000) return "one pair";
	return "high card";
}

function startHoldem() {
	var bet = currentBet();
	if (balance < bet) {
		setTableStatus("Not enough chips for the ante.");
		return;
	}
	balance -= bet;
	holdemDeck = makeDeck();
	holdemPlayer = [drawFromDeck(holdemDeck), drawFromDeck(holdemDeck)];
	holdemCpu = [drawFromDeck(holdemDeck), drawFromDeck(holdemDeck)];
	holdemCommunity = [];
	holdemPot = bet * 2;
	holdemRaised = false;
	holdemRevealCpu = false;
	holdemPhase = "preflop";
	holdemMessage = "Pre-flop. Check, raise, or fold.";
	setTableStatus(holdemMessage);
}

function holdemAdvance() {
	if (holdemPhase == "preflop") {
		array_push(holdemCommunity, drawFromDeck(holdemDeck));
		array_push(holdemCommunity, drawFromDeck(holdemDeck));
		array_push(holdemCommunity, drawFromDeck(holdemDeck));
		holdemPhase = "flop";
		holdemMessage = "Flop revealed.";
	} else if (holdemPhase == "flop") {
		array_push(holdemCommunity, drawFromDeck(holdemDeck));
		holdemPhase = "turn";
		holdemMessage = "Turn revealed.";
	} else if (holdemPhase == "turn") {
		array_push(holdemCommunity, drawFromDeck(holdemDeck));
		holdemPhase = "river";
		holdemMessage = "River revealed.";
	} else if (holdemPhase == "river") {
		resolveHoldem();
		return;
	}
	setTableStatus(holdemMessage);
}

function holdemRaise() {
	if (holdemPhase == "idle" || holdemPhase == "done" || holdemRaised) {
		return;
	}
	var raiseAmount = 5;
	if (balance < raiseAmount) {
		setTableStatus("Not enough chips to raise.");
		return;
	}
	balance -= raiseAmount;
	holdemPot += raiseAmount * 2;
	holdemRaised = true;
	if (irandom(99) < 18) {
		balance += holdemPot;
		holdemMessage = "CPU folds to the raise. You win " + string(holdemPot) + ".";
		holdemPhase = "done";
		holdemRevealCpu = true;
	} else {
		holdemMessage = "CPU calls the raise. Pot is " + string(holdemPot) + ".";
	}
	setTableStatus(holdemMessage);
}

function holdemFold() {
	if (holdemPhase == "idle" || holdemPhase == "done") {
		return;
	}
	holdemRevealCpu = true;
	holdemPhase = "done";
	holdemMessage = "You folded. CPU wins the pot.";
	setTableStatus(holdemMessage);
}

function resolveHoldem() {
	var playerCards = [];
	var cpuCards = [];
	for (var i = 0; i < array_length(holdemPlayer); i += 1) array_push(playerCards, holdemPlayer[i]);
	for (var c = 0; c < array_length(holdemCommunity); c += 1) array_push(playerCards, holdemCommunity[c]);
	for (var j = 0; j < array_length(holdemCpu); j += 1) array_push(cpuCards, holdemCpu[j]);
	for (var k = 0; k < array_length(holdemCommunity); k += 1) array_push(cpuCards, holdemCommunity[k]);
	var playerScore = pokerScore(playerCards);
	var cpuScore = pokerScore(cpuCards);
	holdemRevealCpu = true;
	if (playerScore > cpuScore) {
		balance += holdemPot;
		holdemMessage = "You win with " + pokerLabel(playerScore) + ". Paid " + string(holdemPot) + ".";
	} else if (playerScore == cpuScore) {
		var share = holdemPot div 2;
		balance += share;
		holdemMessage = "Split pot. Both show " + pokerLabel(playerScore) + ".";
	} else {
		holdemMessage = "CPU wins with " + pokerLabel(cpuScore) + ".";
	}
	holdemPhase = "done";
	setTableStatus(holdemMessage);
}

function simulatePachinkoPath() {
	pachinkoPath = simulatePachinkoPathArray();
}

function simulatePachinkoPathArray() {
	var path = [];
	var pos = 3 + irandom(3);
	for (var row = 0; row < pachinkoRows; row += 1) {
		array_push(path, pos);
		var drift = choose(-1, 1);
		pos = clamp(pos + drift, 0, pachinkoWidth - 1);
	}
	return path;
}

function createPachinkoSeat(_name, _isHuman) {
	return {
		name: _name,
		isHuman: _isHuman,
		active: _name != "",
		balance: _isHuman ? balance : 0,
		bet: currentBet(),
		guess: _isHuman ? pachinkoGuess : irandom_range(1, pachinkoWidth),
		path: [],
		visibleRows: 0,
		timer: 0,
		running: false,
		landedPeg: 0,
		status: "Ready",
		playerId: ""
	};
}

function createEmptyPachinkoSeat() {
	return createPachinkoSeat("", false);
}

function startPachinkoSeat(_seatIndex) {
	var seat = pachinkoSeats[_seatIndex];
	if (seat.running) {
		return;
	}
	var bet = seat.isHuman ? currentBet() : seat.bet;
	seat.bet = bet;
	if (seat.balance < bet) {
		seat.status = "Insufficient SGC";
		if (seat.isHuman) setTableStatus("Not enough chips for pachinko.");
		pachinkoSeats[_seatIndex] = seat;
		return;
	}
	seat.balance -= bet;
	seat.path = simulatePachinkoPathArray();
	seat.visibleRows = 1;
	seat.timer = 0;
	seat.running = true;
	seat.landedPeg = 0;
	seat.status = "Dropping toward peg " + string(seat.guess);
	if (seat.isHuman) {
		balance = seat.balance;
		pachinkoGuess = seat.guess;
		pachinkoMessage = seat.status + ". Other boards remain visible.";
		setTableStatus(pachinkoMessage);
	}
	pachinkoSeats[_seatIndex] = seat;
}

function startPachinko() {
	startPachinkoSeat(0);
}

function resolvePachinko() {
	resolvePachinkoSeat(0);
}

function resolvePachinkoSeat(_seatIndex) {
	var seat = pachinkoSeats[_seatIndex];
	seat.running = false;
	seat.landedPeg = seat.path[array_length(seat.path) - 1] + 1;
	var distance = abs(seat.guess - seat.landedPeg);
	var payout = 0;
	if (distance == 0) payout = seat.bet * 2;
	else if (distance == 1) payout = floor(seat.bet * 1.5);
	else if (distance == 2) payout = seat.bet;
	seat.balance += payout;
	if (payout > 0) {
		seat.status = "Peg " + string(seat.landedPeg) + ": paid " + string(payout) + " SGC";
	} else {
		seat.status = "Peg " + string(seat.landedPeg) + ": no payout";
	}
	if (seat.isHuman) {
		balance = seat.balance;
		pachinkoLandedPeg = seat.landedPeg;
		pachinkoMessage = seat.status + ". Everyone can watch every board.";
		setTableStatus(pachinkoMessage);
	}
	pachinkoSeats[_seatIndex] = seat;
}

function updatePachinkoSeats() {
	for (var seatIndex = 0; seatIndex < array_length(pachinkoSeats); seatIndex += 1) {
		var seat = pachinkoSeats[seatIndex];
		if (!seat.active) continue;
		if (seat.running) {
			seat.timer += 1;
			if (seat.timer >= 10) {
				seat.timer = 0;
				seat.visibleRows += 1;
				if (seat.visibleRows >= array_length(seat.path)) {
					seat.visibleRows = array_length(seat.path);
					pachinkoSeats[seatIndex] = seat;
					resolvePachinkoSeat(seatIndex);
					continue;
				}
			}
		}
		pachinkoSeats[seatIndex] = seat;
	}
}

function horseUnderdog() {
	var best = 0;
	for (var i = 1; i < 4; i += 1) {
		if (horseWins[i] < horseWins[best]) best = i;
	}
	var tied = true;
	for (var j = 1; j < 4; j += 1) {
		if (horseWins[j] != horseWins[0]) tied = false;
	}
	return tied ? -1 : best;
}

function startHorseRace() {
	var bet = currentBet();
	if (horseState == "racing") {
		return;
	}
	if (balance < bet) {
		setTableStatus("Not enough chips for the race ticket.");
		return;
	}
	balance -= bet;
	horsePositions = [0, 0, 0, 0];
	horseWinner = -1;
	horseState = "racing";
	horseMessage = "Horse " + horseNames[horseChoice] + " is your pick.";
	setTableStatus(horseMessage);
}

function resolveHorseRace(_winner) {
	horseWinner = _winner;
	horseWins[_winner] += 1;
	horseState = "done";
	var bet = currentBet();
	var underdog = horseUnderdog();
	var payout = 0;
	if (_winner == horseChoice) {
		payout = bet * ((_winner == underdog) ? 8 : 4);
		balance += payout;
		horseMessage = "Horse " + horseNames[_winner] + " wins. Paid " + string(payout) + " chips.";
	} else {
		horseMessage = "Horse " + horseNames[_winner] + " wins. Your ticket misses.";
	}
	setTableStatus(horseMessage);
}

randomizeSlotGrid(slotGrid);
slotSeats = [
	createEmptySlotSeat(),
	createEmptySlotSeat(),
	createEmptySlotSeat()
];
pachinkoSeats = [
	createEmptyPachinkoSeat(),
	createEmptyPachinkoSeat(),
	createEmptyPachinkoSeat()
];

if (tableMultiplayerEnabled) {
	tableBrokerSocket = network_create_socket(network_socket_ws);
	if (tableBrokerSocket >= 0) {
		var tableConnectState = network_connect_raw_async(tableBrokerSocket, tableBrokerHost, tableBrokerPort);
		if (tableConnectState < 0) {
			tableBrokerStatus = "Broker connect failed.";
		}
	} else {
		tableBrokerStatus = "Socket creation failed.";
	}
}