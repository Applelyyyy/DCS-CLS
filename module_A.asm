; =============================================================================
; Module A implementation - Shell Core & FSM Command Parser
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; =============================================================================

.386
.model flat, stdcall
option casemap:none

INCLUDE module_A.inc
INCLUDE module_B.inc
INCLUDE module_C.inc
INCLUDE module_D.inc

PUBLIC ShellMain, ReadCommandLine, ParseCommandFSM, ValidateCommand
PUBLIC DispatchCommand, ReadWholeFile, WriteWholeFile, PrintShellError

; ========================= MODULE A DATA BEGIN HERE ============================

.data?
commandState           DWORD ?
commandType            DWORD ?
argumentCount          DWORD ?
tokenStart             DWORD ?
tokenLength            DWORD ?
inputFileHandle        DWORD ?
outputFileHandle       DWORD ?
bytesRead              DWORD ?
bytesWritten           DWORD ?
commandPromptPtr       DWORD ?
errorMessageTablePtr   DWORD ?

; ========================== MODULE A DATA END HERE =============================

; ======================== MODULE A LOGIC BEGIN HERE ============================

.code
ShellMain PROC
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ShellMain ENDP

ReadCommandLine PROC bufferPtr:PTR BYTE, capacity:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ReadCommandLine ENDP

ParseCommandFSM PROC textPtr:PTR BYTE, textLength:DWORD, commandPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ParseCommandFSM ENDP

ValidateCommand PROC commandPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ValidateCommand ENDP

DispatchCommand PROC commandPtr:PTR BYTE
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
DispatchCommand ENDP

ReadWholeFile PROC pathPtr:PTR BYTE, bufferPtr:PTR BYTE, capacity:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
ReadWholeFile ENDP

WriteWholeFile PROC pathPtr:PTR BYTE, bufferPtr:PTR BYTE, dataLength:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
WriteWholeFile ENDP

PrintShellError PROC errorCode:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
PrintShellError ENDP

; ========================= MODULE A LOGIC END HERE =============================

END
