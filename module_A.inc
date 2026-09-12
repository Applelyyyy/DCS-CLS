; =============================================================================
; Module A - Shell Core & FSM Command Parser
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; =============================================================================
;
; Responsibilities:
;   - REPL command loop
;   - FSM parser for KEYGEN, ENCRYPT, DECRYPT, DUMP, STATS, CLEAR, EXIT
;   - Syntax/argument validation and non-fatal error reporting
;   - File I/O through Win32 API or Irvine32
;
; Public procedure declarations. Implementation belongs in module_A.asm.

ShellMain          PROTO
ReadCommandLine    PROTO :PTR BYTE, :DWORD
ParseCommandFSM    PROTO :PTR BYTE, :DWORD, :PTR BYTE
ValidateCommand    PROTO :PTR BYTE
DispatchCommand    PROTO :PTR BYTE
ReadWholeFile      PROTO :PTR BYTE, :PTR BYTE, :DWORD
WriteWholeFile     PROTO :PTR BYTE, :PTR BYTE, :DWORD
PrintShellError    PROTO :DWORD
;
; Cross-module calls:
;   Module B: GenerateKeySchedule, DisplayKeySchedule
;   Module C: EncryptBufferECB, DecryptBufferECB
;   Module D: DisplayHexDump, ComputeBufferStats, DisplayTopOccurrences
;
; Parser/cipher loops must not use .IF, .WHILE or .REPEAT.
;
; Do not add implementation here. This file is the public interface only.
