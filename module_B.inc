; =============================================================================
; Module B - DES Key Schedule Generator
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; Reference: FIPS 46-3, Appendix 1
; =============================================================================
;
; Responsibilities:
;   - Accept a 64-bit DES key (56 effective bits plus 8 parity bits)
;   - Apply PC-1
;   - Rotate 28-bit C/D halves for 16 rounds
;   - Apply PC-2 and store sixteen 48-bit subkeys
;
; Public procedure declarations. Implementation belongs in module_B.asm.

GenerateKeySchedule PROTO :PTR BYTE, :PTR BYTE
DisplayKeySchedule  PROTO :PTR BYTE
;
; Required left shifts by round:
;   1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1
;
; ApplyPC1, RotateKeyHalves and ApplyPC2 are private procedures. Declare and
; implement them only in module_B.asm so other modules do not depend on them.
