; =============================================================================
; DCS-CLS - Command-Line Shell & File Encryption Engine (Classical DES)
; Target: x86 (32-bit Protected Mode), MASM
; =============================================================================
;
; TEMPLATE ONLY - NO IMPLEMENTATION IS PROVIDED.
; Read README.md before adding code.
;
; Main-file responsibilities:
;   1. Configure MASM, stack and libraries.
;   2. Include the public interfaces for Modules A-D.
;   3. Define shared application state only when ownership cannot belong to a module.
;   4. Define the program entry point, call ShellMain and terminate cleanly.
;
; Do not put Module A-D implementation in this file.

.386
.model flat, stdcall
option casemap:none
;
; ========================= YOUR SHARED DEFINITIONS BEGIN HERE =================

.data?
inputBufferPtr          DWORD ?
inputBufferSize         DWORD ?
inputLength             DWORD ?
fileBufferPtr           DWORD ?
fileBufferSize          DWORD ?
fileLength              DWORD ?
outputBufferPtr         DWORD ?
outputBufferSize        DWORD ?
outputLength            DWORD ?
parsedCommand           DWORD ?
parsedFileNamePtr       DWORD ?
parsedOutputNamePtr     DWORD ?
parsedKey               BYTE 8 DUP(?)
lastErrorCode           DWORD ?

; ========================== YOUR SHARED DEFINITIONS END HERE ==================

INCLUDE module_A.inc       ; Public interface only
INCLUDE module_B.inc       ; Public interface only
INCLUDE module_C.inc       ; Public interface only
INCLUDE module_D.inc       ; Public interface only

; ============================ YOUR MAIN CODE BEGIN HERE =======================

.code
; Add the program entry point here after all module contracts are agreed.

; ============================= YOUR MAIN CODE END HERE ========================

END
