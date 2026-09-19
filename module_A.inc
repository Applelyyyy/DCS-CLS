; =============================================================================
; Module A - Shell Core & FSM Command Parser
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; =============================================================================
;
; Responsibilities:
;   - REPL command loop
;   - FSM parser for KEYGEN, ENCRYPT, DECRYPT, DUMP, STATS, CLEAR, HELP, EXIT
;   - Syntax/argument validation and non-fatal error reporting
;   - File I/O through Win32 API or Irvine32
;
; Public procedure declarations. Implementation belongs in module_A.asm.

; -----------------------------------------------------------------------------
; Command grammar
; -----------------------------------------------------------------------------
; KEYGEN  <key>
; ENCRYPT "<input-path>" "<output-path>" <key>
; DECRYPT "<input-path>" "<output-path>" <key>
; DUMP    "<input-path>"
; STATS   "<input-path>"
; CLEAR
; HELP
; EXIT
;
; Policy:
;   - Command names are case-insensitive.
;   - File paths must be enclosed in double quotes.
;   - A key contains exactly 16 hexadecimal digits.
;   - The optional 0x/0X key prefix is accepted.
;   - Extra arguments are rejected.

COMMAND_BUFFER_CAPACITY EQU 512
FILE_BUFFER_CAPACITY    EQU 1048576
DES_KEY_SIZE            EQU 8
DES_SUBKEY_BUFFER_SIZE  EQU 96
HISTOGRAM_BIN_COUNT     EQU 256

; Command types
COMMAND_INVALID EQU 0
COMMAND_KEYGEN  EQU 1
COMMAND_ENCRYPT EQU 2
COMMAND_DECRYPT EQU 3
COMMAND_DUMP    EQU 4
COMMAND_STATS   EQU 5
COMMAND_CLEAR   EQU 6
COMMAND_EXIT    EQU 7
COMMAND_HELP    EQU 8

; Parser states
STATE_START                 EQU 0
STATE_COMMAND               EQU 1
STATE_AFTER_COMMAND         EQU 2
STATE_BEFORE_ARGUMENT       EQU 3
STATE_UNQUOTED_ARGUMENT     EQU 4
STATE_QUOTED_ARGUMENT       EQU 5
STATE_AFTER_QUOTED_ARGUMENT EQU 6
STATE_KEY_PREFIX            EQU 7
STATE_KEY_DIGITS            EQU 8
STATE_END                   EQU 9
STATE_ERROR                 EQU 10

; Return and error codes: EAX = STATUS_SUCCESS or one of these errors.
STATUS_SUCCESS                  EQU 0
ERROR_EMPTY_COMMAND             EQU 1
ERROR_UNKNOWN_COMMAND           EQU 2
ERROR_WRONG_ARGUMENT_COUNT      EQU 3
ERROR_MISSING_ARGUMENT          EQU 4
ERROR_EXTRA_ARGUMENT            EQU 5
ERROR_UNTERMINATED_QUOTE        EQU 6
ERROR_EMPTY_FILENAME            EQU 7
ERROR_INVALID_KEY               EQU 8
ERROR_INVALID_KEY_LENGTH        EQU 9
ERROR_FILE_OPEN                 EQU 10
ERROR_FILE_READ                 EQU 11
ERROR_FILE_WRITE                EQU 12
ERROR_BUFFER_TOO_SMALL          EQU 13
ERROR_INVALID_CIPHERTEXT_LENGTH EQU 14
ERROR_INVALID_PADDING           EQU 15
ERROR_INVALID_PARAMETER         EQU 16
ERROR_PATH_MUST_BE_QUOTED       EQU 17
ERROR_FILE_TOO_LARGE            EQU 18
ERROR_SAME_INPUT_OUTPUT         EQU 19

; Parser output. Pointers refer to tokens inside the command input buffer and
; remain valid only while that buffer remains unchanged.
PARSED_COMMAND STRUCT
    commandType      DWORD ?
    argumentCount    DWORD ?
    inputPathPtr     DWORD ?
    inputPathLength  DWORD ?
    outputPathPtr    DWORD ?
    outputPathLength DWORD ?
    keyTextPtr       DWORD ?
    keyTextLength    DWORD ?
    keyBytes         BYTE DES_KEY_SIZE DUP(?)
    hasInputPath     DWORD ?
    hasOutputPath    DWORD ?
    hasKey           DWORD ?
    inputPathQuoted  DWORD ?
    outputPathQuoted DWORD ?
PARSED_COMMAND ENDS

ShellMain          PROTO
ReadCommandLine    PROTO :PTR BYTE, :DWORD, :PTR DWORD
ParseCommandFSM    PROTO :PTR BYTE, :DWORD, :PTR BYTE
ValidateCommand    PROTO :PTR BYTE
DispatchCommand    PROTO :PTR BYTE
ReadWholeFile      PROTO :PTR BYTE, :PTR BYTE, :DWORD, :PTR DWORD
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
