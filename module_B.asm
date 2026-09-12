; =============================================================================
; Module B implementation - DES Key Schedule Generator
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; =============================================================================

.386
.model flat, stdcall
option casemap:none

INCLUDE module_B.inc

PUBLIC GenerateKeySchedule, DisplayKeySchedule

; ========================= MODULE B DATA BEGIN HERE ============================

.data?
desKey64               BYTE 8 DUP(?)
keyHalfC               DWORD ?
keyHalfD               DWORD ?
desSubkeys             BYTE 96 DUP(?)
pc1Table               BYTE 56 DUP(?)
pc2Table               BYTE 48 DUP(?)
keyShiftSchedule       BYTE 16 DUP(?)
currentKeyRound        DWORD ?

; ========================== MODULE B DATA END HERE =============================

; ======================== MODULE B LOGIC BEGIN HERE ============================

.code
GenerateKeySchedule PROC keyPtr:PTR BYTE, subkeysPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
GenerateKeySchedule ENDP

DisplayKeySchedule PROC subkeysPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
DisplayKeySchedule ENDP

ApplyPC1 PROC keyPtr:PTR BYTE, halvesPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ApplyPC1 ENDP

RotateKeyHalves PROC halvesPtr:PTR BYTE, shiftCount:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
RotateKeyHalves ENDP

ApplyPC2 PROC halvesPtr:PTR BYTE, subkeyPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ApplyPC2 ENDP

; ========================= MODULE B LOGIC END HERE =============================

END
