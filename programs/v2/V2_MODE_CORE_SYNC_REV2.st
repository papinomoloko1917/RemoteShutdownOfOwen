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

// V2-A SIM_ONLY. No real Modbus freshness or hardware safety is proven.
// Mode: 0=INIT, 1=REMOTE, 2=LOSS_LOCK, 3=LOCAL, 4=RECOVERY_WAIT.
// All *Edge inputs must be single-cycle events, qualified externally.

// Communication/validity loss immediately invalidates release trust.
IF (NOT xCommOk) OR (NOT xSb1Valid) THEN
    xTrustedForRelease := FALSE;
END_IF;

CASE udiState OF
    0: // INIT_UNTRUSTED: no release before two separate trusted events.
        xTrustedForRelease := FALSE;
        xLocalStopHold := FALSE;
        IF (NOT xCommOk) OR (NOT xSb1Valid) THEN
            xInitArmed := FALSE;
        ELSIF xInitArmed AND xFreshEdge THEN
            // xInitArmed was set in an earlier cycle.
            udiState := 1;
            xTrustedForRelease := TRUE;
            xInitArmed := FALSE;
        ELSIF xBootAuthEdge THEN
            xInitArmed := TRUE;
        END_IF;

    1: // REMOTE: any loss of communication/validity goes to LOSS_LOCK.
        xInitArmed := FALSE;
        IF (NOT xCommOk) OR (NOT xSb1Valid) THEN
            udiState := 2;
            xTrustedForRelease := FALSE;
        END_IF;

    2: // LOSS_LOCK: only a new SB3 authorization permits LOCAL.
        xInitArmed := FALSE;
        xTrustedForRelease := FALSE;
        IF xSb3PressEdge THEN
            // Forget a previous LOCAL latch, but latch CURRENT valid STOP.
            // This prevents a 1-cycle SB1=1 from being lost on entry.
            xLocalStopHold := xCommOk AND xSb1Valid AND xSb1Stop;
            udiState := 3;
        END_IF;

    3: // LOCAL: returning communication cannot leave LOCAL by itself.
        xInitArmed := FALSE;
        xTrustedForRelease := FALSE;
        IF xCommOk AND xSb1Valid AND xSb1Stop THEN
            xLocalStopHold := TRUE;
        END_IF;
        IF xSb3PressEdge AND xCommOk AND xSb1Valid THEN
            udiState := 4;
        END_IF;

    4: // RECOVERY_WAIT: failure has priority over a successful check.
        xInitArmed := FALSE;
        xTrustedForRelease := FALSE;
        IF (NOT xCommOk) OR (NOT xSb1Valid) OR xSb1Stop OR xRecoveryCheckFail THEN
            udiState := 2;
        ELSIF xFreshEdge THEN
            // Conditions above guarantee COMM=1, VALID=1, SB1_STOP=0.
            udiState := 1;
            xTrustedForRelease := TRUE;
            xLocalStopHold := FALSE;
        END_IF;

ELSE
    // An invalid mode never generates automatic RELEASE.
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
        xStopRequest := (NOT xTrustedForRelease) OR (NOT xCommOk)
                     OR (NOT xSb1Valid) OR xSb1Stop;
    3:
        xStopRequest := xLocalStopHold
                     OR (xCommOk AND xSb1Valid AND xSb1Stop);
ELSE
    xStopRequest := TRUE;
END_CASE;

// Logical remote release permission ONLY: never a physical start command.
xReleasePermission := (udiState = 1) AND xTrustedForRelease
                   AND (NOT xStopRequest);
END_FUNCTION_BLOCK
