FUNCTION_BLOCK V2_SB1_RX_DECODE
VAR_INPUT
    udiRxState : UDINT;
    xDeviceCommOk : BOOL;
    xFreshWindowValid : BOOL;
    xNewVerifiedFramePulse : BOOL;
END_VAR
VAR_OUTPUT
    xWordWellFormed : BOOL;
    xSb1Valid : BOOL;
    xSb1Stop : BOOL;
    xFreshEdge : BOOL;
    xRxUntrusted : BOOL;
    udiRxQuality : UDINT;
END_VAR
// RemoteShutdownOfOwen V2-A; SIM_ONLY; 14.11.2026.
// Modbus Master FC03 receives one 16-bit word from PR205, DEC 16416.
// Word: 0=UNKNOWN, 1=SB1 released, 2=SB1 STOP, other=INVALID.
// This block ONLY decodes already-received data.
// xDeviceCommOk is device communication status, NOT freshness.
// xFreshWindowValid and xNewVerifiedFramePulse MUST come from a
// separately demonstrated transaction freshness mechanism (D-01/D-04).
// DO NOT tie either of these inputs to xDeviceCommOk or to the value
// changing. Until D-01/D-04 are resolved, drive both FALSE.
// xFreshEdge is a single-cycle acceptance event for a fresh release frame;
// it is NOT generated from the presence or steady value of SB1=0.
// These outputs are logic diagnostics only; no physical Q/K1/SB2.

xWordWellFormed := (udiRxState = 1) OR (udiRxState = 2);
xSb1Valid := xDeviceCommOk AND xWordWellFormed AND xFreshWindowValid;
xSb1Stop := xSb1Valid AND (udiRxState = 2);
xFreshEdge := xSb1Valid AND xNewVerifiedFramePulse AND (udiRxState = 1);
xRxUntrusted := NOT xSb1Valid;

// Diagnostics: 0=COMM LOST, 1=INVALID/UNKNOWN,
// 2=VALID WORD BUT UNVERIFIED, 3=TRUSTED STOP, 4=TRUSTED RELEASE.
IF NOT xDeviceCommOk THEN
    udiRxQuality := 0;
ELSIF NOT xWordWellFormed THEN
    udiRxQuality := 1;
ELSIF NOT xFreshWindowValid THEN
    udiRxQuality := 2;
ELSIF udiRxState = 2 THEN
    udiRxQuality := 3;
ELSE
    udiRxQuality := 4;
END_IF;
END_FUNCTION_BLOCK
