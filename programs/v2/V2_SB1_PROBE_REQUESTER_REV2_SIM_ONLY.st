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
    udiWaitScans : UDINT := 0;
    xStartWasHigh : BOOL := FALSE;
    xStartEdge : BOOL := FALSE;
END_VAR
// RemoteShutdownOfOwen V2-A / SIM_ONLY / 14.11.2026 / Requester REV2.
// FC06: PR205 DEC 16417 (write 0, then write N).
// FC03: PR205 DEC 16418 (read diagnostic answer = 2*N + stop_bit).
// xRequestWritePulse: 0->1 for ONE PLC scan, once per FC06.
// Owen Logic Master "Start writing": set to a BOOL, 0->1 fires write.
// IMPORTANT: disable "Write on change" for V2_PROBE_REQUEST_TX.
// Prepared data is stable one scan BEFORE the write command.
// Neither this pulse nor device-level COMM_OK acknowledges an FC06.
// Cached FC03 values may mimic ACK=0 or an old matching answer.
// Scan watchdog 50 scans is SIM diagnostics, NOT verified real time.
// Neither reboot/replay nor wrap protection is established (D-01/D-04).
// NEVER connect diagnostic outputs to V2_MODE_CORE or physical Q.
// xProtectionFreshConfirmed ALWAYS FALSE.
//
// Phases: 0 IDLE; 1 PREP_CLEAR; 2 WRITE_CLEAR; 3 WAIT_ZERO;
//         4 PREP_SEQ; 5 WRITE_SEQ; 6 WAIT_ECHO; 7 DONE;
//         8 FAILED; 9 EXHAUSTED.
// Results: 0 IDLE; 1 PREP_CLEAR; 2 CLEAR_COMMANDED;
//          3 ZERO_SEEN_UNVERIFIED; 4 SEQ_PREPARED;
//          5 SEQ_COMMANDED; 6 DIAG_RELEASE; 7 DIAG_STOP;
//          8 ECHO_MISMATCH; 9 SCAN_OR_EXTERNAL_TIMEOUT;
//          10 LINK_OR_ABORT; 11 SEQ_EXHAUSTED; 12 BAD_PHASE.

xStartEdge := xStartProbePulse AND (NOT xStartWasHigh);
xStartWasHigh := xStartProbePulse;
xRequestWritePulse := FALSE;
xDiagEchoSeenPulse := FALSE;
xProtectionFreshConfirmed := FALSE;

IF NOT xDiagEnable THEN
    udiProbeRequestTx := 0;
    udiPendingSeq := 0;
    udiCurrentSeq := 0;
    udiExpectedRelease := 0;
    udiWaitScans := 0;
    udiDiagSb1State := 0;
    udiDiagResult := 0;
    udiDiagPhase := 0;
ELSIF (NOT xDeviceCommOk) OR xAbortPulse THEN
    // Fail closed. No remote write-to-zero is guaranteed here.
    udiProbeRequestTx := 0;
    udiDiagSb1State := 0;
    udiDiagResult := 10;
    udiDiagPhase := 8;
ELSIF xTimeoutPulse AND (udiDiagPhase > 0) AND (udiDiagPhase < 7) THEN
    udiProbeRequestTx := 0;
    udiDiagSb1State := 0;
    udiDiagResult := 9;
    udiDiagPhase := 8;
ELSE
    CASE udiDiagPhase OF
        0, 7:
            IF xStartEdge THEN
                udiDiagSb1State := 0;
                udiWaitScans := 0;
                IF udiLastIssuedSeq >= 29999 THEN
                    udiProbeRequestTx := 0;
                    udiDiagResult := 11;
                    udiDiagPhase := 9;
                ELSE
                    udiLastIssuedSeq := udiLastIssuedSeq + 1;
                    udiPendingSeq := udiLastIssuedSeq;
                    udiCurrentSeq := udiPendingSeq;
                    udiProbeRequestTx := 0;
                    udiDiagResult := 1;
                    udiDiagPhase := 1;
                END_IF;
            END_IF;

        1: // PREP_CLEAR: data 0 is stable for this complete scan.
            udiProbeRequestTx := 0;
            udiDiagPhase := 2;

        2: // WRITE_CLEAR: one rising write command, 0 is already stable.
            udiProbeRequestTx := 0;
            xRequestWritePulse := TRUE;
            udiWaitScans := 0;
            udiDiagResult := 2;
            udiDiagPhase := 3;

        3: // WAIT_ZERO: cached zero is NOT a verified FC06 completion.
            udiWaitScans := udiWaitScans + 1;
            IF udiWaitScans >= 50 THEN
                udiDiagResult := 9;
                udiDiagPhase := 8;
            ELSIF (udiWaitScans >= 3) AND (udiProbeResponseRx = 0) THEN
                udiDiagResult := 3;
                udiDiagPhase := 4;
            END_IF;

        4: // PREP_SEQ: prepare N a full scan BEFORE the second FC06.
            udiProbeRequestTx := udiPendingSeq;
            udiDiagResult := 4;
            udiDiagPhase := 5;

        5: // WRITE_SEQ: second, separate rising command.
            udiProbeRequestTx := udiPendingSeq;
            xRequestWritePulse := TRUE;
            udiExpectedRelease := 2 * udiPendingSeq;
            udiWaitScans := 0;
            udiDiagResult := 5;
            udiDiagPhase := 6;

        6: // WAIT_ECHO: numeric match is diagnostics only.
            udiWaitScans := udiWaitScans + 1;
            IF udiWaitScans >= 50 THEN
                udiDiagSb1State := 0;
                udiDiagResult := 9;
                udiDiagPhase := 8;
            ELSIF (udiWaitScans >= 1) AND (udiProbeResponseRx = udiExpectedRelease) THEN
                udiDiagSb1State := 1;
                udiDiagResult := 6;
                xDiagEchoSeenPulse := TRUE;
                udiDiagPhase := 7;
            ELSIF (udiWaitScans >= 1) AND (udiProbeResponseRx = (udiExpectedRelease + 1)) THEN
                udiDiagSb1State := 2;
                udiDiagResult := 7;
                xDiagEchoSeenPulse := TRUE;
                udiDiagPhase := 7;
            ELSIF udiProbeResponseRx <> 0 THEN
                // Mismatch is recorded but may be a cached old reply.
                udiDiagResult := 8;
            END_IF;

        8: // FAILED: latched until xDiagEnable becomes FALSE.
            udiProbeRequestTx := 0;

        9: // EXHAUSTED: no automatic reuse or sequence wrap.
            udiProbeRequestTx := 0;
            udiDiagResult := 11;

    ELSE
        udiProbeRequestTx := 0;
        udiDiagSb1State := 0;
        udiDiagResult := 12;
        udiDiagPhase := 8;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
