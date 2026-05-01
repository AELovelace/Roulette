var startRequested = keyboard_check_pressed(vk_space);
var mouseLeftPressed = mouse_check_button_pressed(mb_left);
var mouseRightPressed = mouse_check_button_pressed(mb_right);
var mouseInsideTable = false;
var mouseXPos = mouse_x;
var mouseYPos = mouse_y;
var brokerMode = multiplayerEnabled && brokerConnected;
var canEditTable = !spinActive && ballState != 1 && (!brokerMode || (brokerPhase == "betting" && !lobbyBrowserOpen && currentLobbyId != ""));

function returnToMenuRoom() {
    if (brokerSocket >= 0) {
        network_destroy(brokerSocket);
        brokerSocket = -1;
        brokerConnected = false;
    }
    room_goto(RoomMenu);
}

function pointInButton(_button, _mx, _my) {
    return point_in_rectangle(_mx, _my, _button.x, _button.y, _button.x + _button.w, _button.y + _button.h);
}

hoverBetIndex = -1;

for (var i = 0; i < array_length(betAreas); i++) {
    var area = betAreas[i];
    if (point_in_rectangle(mouseXPos, mouseYPos, area.x, area.y, area.x + area.w, area.y + area.h)) {
        hoverBetIndex = i;
        mouseInsideTable = true;
        break;
    }
}

if (is_struct(pendingSpinPlan) && activeSpinId != rouletteStructGet(pendingSpinPlan, "spinId", -1)) {
    activeSpinId = rouletteStructGet(pendingSpinPlan, "spinId", -1);
    rotation = rouletteStructGet(pendingSpinPlan, "startRotation", rotation);
    ballAngle = rouletteStructGet(pendingSpinPlan, "startBallAngle", ballAngle);
    spinSpeed = rouletteStructGet(pendingSpinPlan, "spinSpeed", spinSpeed);
    ballSpeed = rouletteStructGet(pendingSpinPlan, "ballSpeed", ballSpeed);
    fullSpeedTimer = rouletteStructGet(pendingSpinPlan, "fullSpeedFrames", 180);
    winningNumber = -1;
    lastPayout = 0;
    betsResolved = false;
    spinActive = true;
    ballState = 1;
    resultLocked = false;
    lastSpinSummary = "Spinning...";
    pendingSpinPlan = undefined;
}

if (brokerMode && lobbyBrowserOpen) {
    if (keyboard_check_pressed(vk_escape) && currentLobbyId != "") {
        lobbyBrowserOpen = false;
    }

    if (keyboard_check_pressed(vk_enter) && selectedLobbyId != "") {
        rouletteSendJson(brokerSocket, { type: "join_lobby", lobbyId: selectedLobbyId });
    }

    if (mouseLeftPressed) {
        var entryY = lobbyPanel.y1 + 94;
        var entryH = 34;

        for (var lobbyIndex = 0; lobbyIndex < array_length(lobbyList); lobbyIndex++) {
            var lobbyEntry = lobbyList[lobbyIndex];
            var rowTop = entryY + (lobbyIndex * (entryH + 8));
            if (point_in_rectangle(mouseXPos, mouseYPos, lobbyPanel.x1 + 26, rowTop, lobbyPanel.x2 - 26, rowTop + entryH)) {
                selectedLobbyId = rouletteStructGet(lobbyEntry, "id", "");
                break;
            }
        }

        if (pointInButton(createLobbyButton, mouseXPos, mouseYPos)) {
            rouletteSendJson(brokerSocket, { type: "create_lobby" });
        }

        if (pointInButton(joinLobbyButton, mouseXPos, mouseYPos) && selectedLobbyId != "") {
            rouletteSendJson(brokerSocket, { type: "join_lobby", lobbyId: selectedLobbyId });
        }

        if (pointInButton(leaveLobbyButton, mouseXPos, mouseYPos) && currentLobbyId != "") {
            rouletteSendJson(brokerSocket, { type: "leave_lobby" });
        }
    }
}

if (brokerMode && mouseLeftPressed && pointInButton(lobbyButton, mouseXPos, mouseYPos)) {
    lobbyBrowserOpen = !lobbyBrowserOpen;
}

if (canEditTable) {
    if (keyboard_check_pressed(vk_escape)) {
        returnToMenuRoom();
    }

    if (mouseLeftPressed) {
        var handledLeftClick = false;

        for (var chipIndex = 0; chipIndex < array_length(chipButtons); chipIndex++) {
            var chipButton = chipButtons[chipIndex];
            if (point_in_rectangle(mouseXPos, mouseYPos, chipButton.x, chipButton.y, chipButton.x + chipButton.w, chipButton.y + chipButton.h)) {
                currentChip = chipButton.value;
                handledLeftClick = true;
                break;
            }
        }

        if (!handledLeftClick && point_in_rectangle(mouseXPos, mouseYPos, spinButton.x, spinButton.y, spinButton.x + spinButton.w, spinButton.y + spinButton.h)) {
            if (brokerMode) {
                rouletteSendJson(brokerSocket, { type: "request_spin" });
            } else {
                startRequested = rouletteGetTotalBet(betAreas) > 0;
            }
            handledLeftClick = true;
        }

        if (!handledLeftClick && point_in_rectangle(mouseXPos, mouseYPos, clearButton.x, clearButton.y, clearButton.x + clearButton.w, clearButton.y + clearButton.h)) {
            if (brokerMode) {
                rouletteSendJson(brokerSocket, { type: "clear_bets" });
                lastSpinSummary = "Requested table clear.";
            } else {
                for (var clearIndex = 0; clearIndex < array_length(betAreas); clearIndex++) {
                    bankroll += betAreas[clearIndex].amount;
                    betAreas[clearIndex].amount = 0;
                }
                lastSpinSummary = "Bets cleared.";
            }
            handledLeftClick = true;
        }

        if (!handledLeftClick && pointInButton(menuButton, mouseXPos, mouseYPos)) {
			returnToMenuRoom();
			handledLeftClick = true;
		}

        if (!handledLeftClick && hoverBetIndex != -1) {
            if (brokerMode) {
                rouletteSendJson(brokerSocket, {
                    type: "place_bet",
                    key: betAreas[hoverBetIndex].key,
                    amount: currentChip
                });
                lastSpinSummary = "Placed $" + string(currentChip) + " on " + betAreas[hoverBetIndex].label + ".";
            } else if (bankroll >= currentChip) {
                betAreas[hoverBetIndex].amount += currentChip;
                bankroll -= currentChip;
                lastSpinSummary = "Added $" + string(currentChip) + " to " + betAreas[hoverBetIndex].label + ".";
            }
        }
    }

    if (mouseRightPressed && hoverBetIndex != -1 && betAreas[hoverBetIndex].amount > 0) {
        if (brokerMode) {
            rouletteSendJson(brokerSocket, {
                type: "remove_bet",
                key: betAreas[hoverBetIndex].key,
                amount: currentChip
            });
            lastSpinSummary = "Requested removal from " + betAreas[hoverBetIndex].label + ".";
        } else {
            var refund = min(currentChip, betAreas[hoverBetIndex].amount);
            betAreas[hoverBetIndex].amount -= refund;
            bankroll += refund;
            lastSpinSummary = "Removed $" + string(refund) + " from " + betAreas[hoverBetIndex].label + ".";
        }
    }
}

if (!brokerMode && startRequested && !spinActive && rouletteGetTotalBet(betAreas) > 0) {
    spinActive = true;
    spinSpeed = random_range(10, 15);
    ballState = 1;
    ballSpeed = random_range(12, 18);
    fullSpeedTimer = 180; // 3 seconds at 60fps — no decel until this hits 0
    resultLocked = false;
    betsResolved = false;
    winningNumber = -1;
    lastWager = rouletteGetTotalBet(betAreas);
    lastPayout = 0;
    lastSpinSummary = "Spinning...";
}

if (spinActive) {
    rotation += spinSpeed;
    if (fullSpeedTimer > 0) {
        fullSpeedTimer--; // hold full speed
    } else {
        spinSpeed *= decel; // only decel after timer expires
    }
    if (spinSpeed < minSpeed) {
        spinSpeed   = 0;
        spinActive  = false;
    }
}

if (ballState == 1) {
    ballAngle -= ballSpeed; // opposite direction to wheel
    if (fullSpeedTimer <= 0) {
        ballSpeed *= ballDecel; // decel in sync with wheel
    }

    if (ballSpeed < ballMinSpeed) {
        ballSpeed = 0;

        // Snap to nearest pocket in wheel-local space, then convert back to world
        var _seg       = 360 / array_length(wheelOrder);
        var _normBall  = ((ballAngle mod 360) + 360) mod 360;
        var _local     = ((rotation - _normBall + zeroOffset) mod 360 + 360) mod 360;
        var _snapped   = round(_local / _seg) * _seg;
        // Convert snapped local angle back to world angle
        finalBallAngle = ((rotation + zeroOffset - _snapped) mod 360 + 360) mod 360;
        ballAngle      = finalBallAngle;
        ballState      = 3;
    }
}

// Optional: lock result only when both wheel and ball have finished
if (!resultLocked && ballState == 3 && !spinActive) {
    segmentAngle = 360 / array_length(wheelOrder);
    var _local = ((rotation - finalBallAngle + zeroOffset) mod 360 + 360) mod 360;
    var _idx   = floor((_local + segmentAngle * 0.5) / segmentAngle) mod array_length(wheelOrder);
    winningNumber = getWinningNumber(rotation, finalBallAngle, zeroOffset, wheelOrder, segmentAngle);
    
    // Angle of the winning pocket center in world space (for comparison with ball)
    var _winnerIdx       = _idx;
    var _pocketLocalAngle = _winnerIdx * segmentAngle;
    var _pocketWorldAngle = ((rotation + zeroOffset - _pocketLocalAngle) mod 360 + 360) mod 360;
    
    resultLocked = true;
    show_debug_message(
        "=== LOCK ===" +
        " | ballStoppedAt="   + string(finalBallAngle) +
        " | pocketWorldAngle="+ string(_pocketWorldAngle) +
        " | angleDiff="       + string(angle_difference(_pocketWorldAngle, finalBallAngle)) +
        " | rotation="        + string(rotation) +
        " | local="           + string(_local) +
        " | idx="             + string(_idx) +
        " | Winner="          + string(winningNumber)
    );
}

if (resultLocked && !betsResolved) {
    if (brokerMode) {
        betsResolved = true;
    } else {
        var payoutTotal = 0;

        for (var betIndex = 0; betIndex < array_length(betAreas); betIndex++) {
            var betArea = betAreas[betIndex];
            if (betArea.amount > 0 && rouletteArrayContains(betArea.covered, winningNumber)) {
                payoutTotal += betArea.amount * (betArea.payout + 1);
            }
            betAreas[betIndex].amount = 0;
            betAreas[betIndex].totalAmount = 0;
        }

        bankroll += payoutTotal;
        lastPayout = payoutTotal;
        lastSpinSummary = "Winner " + string(winningNumber) + " | Bet $" + string(lastWager) + " | Payout $" + string(payoutTotal);
        betsResolved = true;
    }
}