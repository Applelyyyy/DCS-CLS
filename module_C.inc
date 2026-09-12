; =============================================================================
; Module C - DES 16-Round Feistel Core Engine
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; Reference: FIPS 46-3, Data Encryption Algorithm and Appendix 1
; =============================================================================
;
; Responsibilities:
;   - IP and inverse IP for 64-bit blocks
;   - 16 Feistel rounds
;   - E expansion, subkey XOR, S1-S8 lookups and P permutation
;   - ECB buffer processing
;   - PKCS#7 padding for an 8-byte DES block
;
; Public procedure declarations. Implementation belongs in module_C.asm.

EncryptBufferECB PROTO :PTR BYTE, :DWORD, :PTR BYTE, :PTR BYTE
DecryptBufferECB PROTO :PTR BYTE, :DWORD, :PTR BYTE, :PTR BYTE
EncryptDESBlock  PROTO :PTR BYTE, :PTR BYTE, :PTR BYTE
DecryptDESBlock  PROTO :PTR BYTE, :PTR BYTE, :PTR BYTE
;
; Decryption uses the same DES core with K16 through K1.
; Cipher loops must not use .IF, .WHILE or .REPEAT.
;
; Feistel helper procedures are private to module_C.asm and are not exported here.
