; =============================================================================
; DCS-CLS - Command-Line Shell & File Encryption Engine (Classical DES)
; Target: x86 (32-bit Protected Mode), MASM
; =============================================================================
;
; Main-file responsibilities:
;   1. Configure MASM, stack and libraries.
;   2. Include the public interfaces for Modules A-D.
;   3. Define shared application state only when ownership cannot belong to a module.
;   4. Define the program entry point, call ShellMain and terminate cleanly.
;
; Do not put Module A-D implementation in this file.

option casemap:none

INCLUDE Irvine32.inc

INCLUDE module_A.inc       ; Public interface only
INCLUDE module_B.inc       ; Public interface only
INCLUDE module_C.inc       ; Public interface only
INCLUDE module_D.inc       ; Public interface only

.code
main PROC
    push ebp
    mov ebp,esp
    INVOKE ShellMain
    mov esp,ebp
    pop ebp
    exit
main ENDP

END main
