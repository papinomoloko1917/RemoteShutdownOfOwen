FUNCTION_BLOCK V2_SB1_PROBE_RESPONDER
VAR_INPUT
    udiProbeRequestRx : UDINT;
    udiSb1StateTx : UDINT;
    xDiagEnable : BOOL;
END_VAR
VAR_OUTPUT
    udiProbeResponseTx : UDINT;
    udiLastHandledSeq : UDINT;
    xDiagResponseUpdatedPulse : BOOL;
    udiDiagStatus : UDINT;
    xProtectionFreshConfirmed : BOOL;
END_VAR
VAR
    xClearObserved : BOOL := FALSE;
    udiLastSeq : UDINT := 0;
END_VAR
// RemoteShutdownOfOwen V2-A / SIM_ONLY / 14.11.2026
// Proposed PR205 diagnostic handshake; NOT a safety freshness protocol.
// Candidate PR205 Modbus Slave: request DEC 16417, response DEC 16418.
// Existing source SB1 word is DEC 16416: 0=unknown, 1=released, 2=STOP.
// Master writes a zero between requests. The clear is NOT proof of freshness.
// Response = 2 * request + stop_bit, for request in 1..29999.
// Request numbers do not wrap within a running FB instance.
// After reboot, numbers CAN repeat. P04-02 remains unresolved.
// NEVER connect xDiagResponseUpdatedPulse to MODE_CORE.xFreshEdge.
// NEVER connect this block to a physical Q/K1/SB2.

xDiagResponseUpdatedPulse := FALSE;
xProtectionFreshConfirmed := FALSE;
udiLastHandledSeq := udiLastSeq;

IF NOT xDiagEnable THEN
    udiProbeResponseTx := 0;
    udiLastSeq := 0;
    udiLastHandledSeq := 0;
    xClearObserved := FALSE;
    udiDiagStatus := 0;
ELSIF udiProbeRequestRx = 0 THEN
    udiProbeResponseTx := 0;
    xClearObserved := TRUE;
    udiDiagStatus := 1;
ELSIF udiProbeRequestRx > 29999 THEN
    udiProbeResponseTx := 0;
    xClearObserved := FALSE;
    udiDiagStatus := 4;
ELSIF NOT xClearObserved THEN
    // Nonzero request without a preceding observed zero: do not re-echo it.
    udiDiagStatus := 2;
ELSIF udiProbeRequestRx <= udiLastSeq THEN
    // Duplicate / out-of-order request within this running session.
    udiProbeResponseTx := 0;
    xClearObserved := FALSE;
    udiDiagStatus := 5;
ELSIF (udiSb1StateTx <> 1) AND (udiSb1StateTx <> 2) THEN
    udiProbeResponseTx := 0;
    xClearObserved := FALSE;
    udiDiagStatus := 6;
ELSE
    // Capture the SB1 status at this scan; no future auto-refresh.
    udiProbeResponseTx := 2 * udiProbeRequestRx;
    IF udiSb1StateTx = 2 THEN
        udiProbeResponseTx := udiProbeResponseTx + 1;
    END_IF;
    udiLastSeq := udiProbeRequestRx;
    udiLastHandledSeq := udiLastSeq;
    xClearObserved := FALSE;
    xDiagResponseUpdatedPulse := TRUE;
    udiDiagStatus := 3;
END_IF;
END_FUNCTION_BLOCK
