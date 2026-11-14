FUNCTION_BLOCK V2_SB1_PROBE_REQUESTER
VAR_INPUT
    xDiagEnable : BOOL;
    xDeviceCommOk : BOOL;
    xStartProbePulse : BOOL;
    xAbortPulse : BOOL;
    xTimeoutPulse : BOOL;
    udiProbeResponseRx : UDINT;
END_VAR
VAR_OUTPUT
    udiProbeRequestTx : UDINT;
    xRequestWritePulse : BOOL;
    xDiagEchoSeenPulse : BOOL;
    udiDiagSb1State : UDINT;
    udiDiagPhase : UDINT;
    udiDiagResult : UDINT;
    udiCurrentSeq : UDINT;
    xProtectionFreshConfirmed : BOOL;
END_VAR
VAR
    udiLastIssuedSeq : UDINT := 0;
    udiPendingSeq : UDINT := 0;
    udiExpectedRelease : UDINT := 0;
    xStartWasHigh : BOOL := FALSE;
    xStartEdge : BOOL := FALSE;
END_VAR
// RemoteShutdownOfOwen V2-A / SIM_ONLY / 14.11.2026
// Proposed PR103 diagnostic request sequencer. NOT verified freshness.
// Candidate FC06 DEC 16417 -> PR205, FC03 DEC 16418 <- PR205.
// xRequestWritePulse is a single-scan COMMAND to the Owen Master write
// trigger, NOT an acknowledgement that FC06 actually reached PR205.
// udiProbeResponseRx can be cached: even a numerically matching reply
// does NOT establish that a new FC03 completed (device-level status only).
// This FB deliberately has NO usable safety-freshness output.
// Sequence 1..29999; no in-session wrap; reboot CAN replay an old number.
// xTimeoutPulse is supplied externally: D-13/D-14 timing remains OPEN.
// States: 0=IDLE, 1=WAIT_CLEAR, 2=ISSUE_PROBE,
//         3=WAIT_ECHO, 4=DIAG_RESULT, 5=EXHAUSTED.
// Results: 0=IDLE, 1=CLEAR_SENT, 2=PROBE_SENT, 3=DIAG_RELEASE,
//          4=DIAG_STOP, 5=ECHO_MISMATCH, 6=LINK/ABORT,
//          7=TIMEOUT, 8=SEQ_EXHAUSTED.
// NEVER connect xDiagEchoSeenPulse to MODE_CORE.xFreshEdge.
// NEVER connect the diagnostic SB1 state to MODE_CORE.xSb1Valid.

xStartEdge := xStartProbePulse AND (NOT xStartWasHigh);
xStartWasHigh := xStartProbePulse;
xRequestWritePulse := FALSE;
xDiagEchoSeenPulse := FALSE;
xProtectionFreshConfirmed := FALSE;

IF (NOT xDiagEnable) OR (NOT xDeviceCommOk) OR xAbortPulse THEN
    udiProbeRequestTx := 0;
    udiPendingSeq := 0;
    udiCurrentSeq := 0;
    udiDiagSb1State := 0;
    udiDiagPhase := 0;
    IF NOT xDiagEnable THEN
        udiDiagResult := 0;
    ELSE
        udiDiagResult := 6;
    END_IF;
ELSIF xTimeoutPulse THEN
    udiProbeRequestTx := 0;
    udiPendingSeq := 0;
    udiCurrentSeq := 0;
    udiDiagSb1State := 0;
    udiDiagPhase := 0;
    udiDiagResult := 7;
ELSE
    CASE udiDiagPhase OF
        0, 4:
            IF xStartEdge THEN
                udiDiagSb1State := 0;
                IF udiLastIssuedSeq >= 29999 THEN
                    udiProbeRequestTx := 0;
                    udiDiagPhase := 5;
                    udiDiagResult := 8;
                ELSE
                    udiLastIssuedSeq := udiLastIssuedSeq + 1;
                    udiPendingSeq := udiLastIssuedSeq;
                    udiCurrentSeq := udiPendingSeq;
                    udiProbeRequestTx := 0;
                    xRequestWritePulse := TRUE;
                    udiDiagPhase := 1;
                    udiDiagResult := 1;
                END_IF;
            END_IF;
        1:
            // Clear response may be old/cached. Diagnostic sequencing ONLY.
            // A separate scan ensures the next write trigger has a low gap.
            IF udiProbeResponseRx = 0 THEN
                udiDiagPhase := 2;
            END_IF;
        2:
            udiProbeRequestTx := udiPendingSeq;
            xRequestWritePulse := TRUE;
            udiDiagPhase := 3;
            udiDiagResult := 2;
        3:
            udiExpectedRelease := 2 * udiPendingSeq;
            IF udiProbeResponseRx = udiExpectedRelease THEN
                udiDiagSb1State := 1;
                xDiagEchoSeenPulse := TRUE;
                udiDiagPhase := 4;
                udiDiagResult := 3;
            ELSIF udiProbeResponseRx = (udiExpectedRelease + 1) THEN
                udiDiagSb1State := 2;
                xDiagEchoSeenPulse := TRUE;
                udiDiagPhase := 4;
                udiDiagResult := 4;
            ELSIF udiProbeResponseRx <> 0 THEN
                // Not accepted: continue waiting for a newer diagnostic echo.
                udiDiagResult := 5;
            END_IF;
        5:
            udiProbeRequestTx := 0;
            udiDiagResult := 8;
    ELSE
        udiProbeRequestTx := 0;
        udiDiagPhase := 0;
        udiDiagResult := 6;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
