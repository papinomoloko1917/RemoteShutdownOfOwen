FUNCTION_BLOCK V2_MODE_CORE
VAR_INPUT
    xCommOk : BOOL;
    xSb1Valid : BOOL;
    xSb1Stop : BOOL;
    xSb3PressEdge : BOOL;
    xBootAuthEdge : BOOL;
    xFreshEdge : BOOL;
    xRecoveryCheckFail : BOOL;
END_VAR
VAR_OUTPUT
    udiMode : UDINT;
    xStopRequest : BOOL;
    xReleasePermission : BOOL;
    xLockedByCommLoss : BOOL;
END_VAR
VAR
    udiState : UDINT := 0;
    xInitArmed : BOOL := FALSE;
    xLocalStopHold : BOOL := FALSE;
    xTrustedForRelease : BOOL := FALSE;
END_VAR

// SIM_ONLY: inputs xSb1Valid/xFreshEdge are artificial assertions.
// No real Modbus freshness is established by this functional block.
IF (NOT xCommOk) OR (NOT xSb1Valid) THEN
    xTrustedForRelease := FALSE;
END_IF;

CASE udiState OF
    0: // INIT_UNTRUSTED
        xTrustedForRelease := FALSE;
        IF (NOT xCommOk) OR (NOT xSb1Valid) THEN
            xInitArmed := FALSE;
        ELSE
            IF xBootAuthEdge THEN
                xInitArmed := TRUE;
            END_IF;
            IF xInitArmed AND xFreshEdge THEN
                udiState := 1;
                xTrustedForRelease := TRUE;
                xInitArmed := FALSE;
            END_IF;
        END_IF;
    1: // REMOTE
        IF (NOT xCommOk) OR (NOT xSb1Valid) THEN
            udiState := 2;
            xTrustedForRelease := FALSE;
        END_IF;
    2: // LOSS_LOCK
        IF xSb3PressEdge THEN
            udiState := 3;
        END_IF;
    3: // LOCAL
        IF xCommOk AND xSb1Valid AND xSb1Stop THEN
            xLocalStopHold := TRUE;
        END_IF;
        IF xSb3PressEdge AND xCommOk AND xSb1Valid THEN
            udiState := 4;
        END_IF;
    4: // RECOVERY_WAIT
        IF (NOT xCommOk) OR (NOT xSb1Valid) OR xSb1Stop OR xRecoveryCheckFail THEN
            udiState := 2;
            xTrustedForRelease := FALSE;
        ELSIF xFreshEdge THEN
            udiState := 1;
            xTrustedForRelease := TRUE;
            xLocalStopHold := FALSE;
        END_IF;
ELSE
    // An invalid state must not produce automatic release.
    udiState := 0;
    xInitArmed := FALSE;
    xTrustedForRelease := FALSE;
    xLocalStopHold := TRUE;
END_CASE;

udiMode := udiState;
xLockedByCommLoss := (udiState = 2) OR (udiState = 3) OR (udiState = 4);

CASE udiState OF
    0, 2, 4:
        xStopRequest := TRUE;
    1:
        xStopRequest := (NOT xTrustedForRelease) OR (NOT xCommOk) OR (NOT xSb1Valid) OR xSb1Stop;
    3:
        xStopRequest := xLocalStopHold OR (xCommOk AND xSb1Valid AND xSb1Stop);
ELSE
    xStopRequest := TRUE;
END_CASE;

// Permission is a logical SIM result, never a physical start command.
xReleasePermission := (udiState = 1) AND xTrustedForRelease AND (NOT xStopRequest);
END_FUNCTION_BLOCK
