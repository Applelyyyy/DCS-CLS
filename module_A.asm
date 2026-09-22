; =============================================================================
; Module A implementation - Shell Core & FSM Command Parser
; Owner: Nutthawat (68010321)
; =============================================================================

option casemap:none

INCLUDE Irvine32.inc
INCLUDE module_A.inc
INCLUDE module_B.inc
INCLUDE module_C.inc
INCLUDE module_D.inc

PUBLIC ShellMain, ReadCommandLine, ParseCommandFSM, ValidateCommand
PUBLIC DispatchCommand, ReadWholeFile, WriteWholeFile, PrintShellError

ResetParsedCommand PROTO :PTR BYTE
IdentifyCommand    PROTO :PTR BYTE, :DWORD
CompareTokenCI     PROTO :PTR BYTE, :DWORD, :PTR BYTE, :DWORD
IsValidHexKey      PROTO :PTR BYTE, :DWORD
ParseHexKey64      PROTO :PTR BYTE, :DWORD, :PTR BYTE
HexCharToNibble    PROTO :DWORD
HandleKeygen       PROTO :PTR BYTE
HandleEncrypt      PROTO :PTR BYTE
HandleDecrypt      PROTO :PTR BYTE
HandleDump         PROTO :PTR BYTE
HandleStats        PROTO :PTR BYTE
PathsEqualCI       PROTO :PTR BYTE,:DWORD,:PTR BYTE,:DWORD
BuildAutoOutputPath PROTO :PTR BYTE

; ========================= MODULE A DATA BEGIN HERE ============================

.data
shellPrompt            BYTE "DES-SHELL> ", 0
loadingText            BYTE "Loading ",0
openParenText          BYTE " (",0
bytesText              BYTE " bytes)...",13,10,0
keyScheduleText        BYTE "Executing DES 16-round key generation...",13,10,0
processingText         BYTE "Processing ",0
blocksText             BYTE " block(s) in ECB mode...",13,10,0
encryptSuccessMessage  BYTE "File encrypted successfully -> ",34,0
decryptSuccessMessage  BYTE "File decrypted successfully -> ",34,0
closingQuoteText       BYTE 34,13,10,0
statsSizeLabel         BYTE "Total File Size: ",0
statsSizeUnit          BYTE " Bytes",13,10,0
extEnc                 BYTE ".enc",0
extDec                 BYTE ".dec",0

helpTextHeader  BYTE "Available commands:",13,10,0
helpTextHelp    BYTE "  HELP",13,10,"      Show this help message.",13,10,0
helpTextKeygen  BYTE "  KEYGEN <key>",13,10,"      Generate and display 16 DES subkeys.",13,10,0
helpTextEncrypt BYTE "  ENCRYPT ",34,"<input-path>",34," [",34,"<output-path>",34,"] <key>",13,10,"      Encrypt using DES-ECB; default output is <input-path>.enc.",13,10,0
helpTextDecrypt BYTE "  DECRYPT ",34,"<input-path>",34," [",34,"<output-path>",34,"] <key>",13,10,"      Decrypt DES-ECB; default output is <input-path>.dec.",13,10,0
helpTextDump    BYTE "  DUMP ",34,"<input-path>",34,13,10,"      Display file bytes as hexadecimal and ASCII.",13,10,0
helpTextStats   BYTE "  STATS ",34,"<input-path>",34,13,10,"      Display the byte-frequency histogram and top occurrences.",13,10,0
helpTextClear   BYTE "  CLEAR",13,10,"      Clear the console.",13,10,0
helpTextExit    BYTE "  EXIT",13,10,"      Exit the program.",13,10,0
helpTextPolicy  BYTE "Key: exactly 16 hexadecimal digits; optional 0x prefix.",13,10,"Commands are case-insensitive. File paths must use double quotes.",13,10,0

keywordKeygen          BYTE "KEYGEN"
keywordEncrypt         BYTE "ENCRYPT"
keywordDecrypt         BYTE "DECRYPT"
keywordDump            BYTE "DUMP"
keywordStats           BYTE "STATS"
keywordClear           BYTE "CLEAR"
keywordExit            BYTE "EXIT"
keywordHelp            BYTE "HELP"

errorEmptyCommand      BYTE "Error: empty command.", 0
errorUnknownCommand    BYTE "Error: unknown command. Type HELP for usage.", 0
errorArgumentCount     BYTE "Error: wrong number of arguments. Type HELP for usage.", 0
errorUnterminatedQuote BYTE "Error: unterminated quoted path.", 0
errorEmptyFilename     BYTE "Error: file path cannot be empty.", 0
errorInvalidKey        BYTE "Error: key must contain exactly 16 hexadecimal digits (optional 0x).", 0
errorInvalidParameter  BYTE "Error: invalid internal parameter.", 0
errorPathMustBeQuoted  BYTE "Error: file paths must be enclosed in double quotes.", 0
errorFileOpen          BYTE "Error: unable to open the file.",0
errorFileRead          BYTE "Error: unable to read the file.",0
errorFileWrite         BYTE "Error: unable to write the file.",0
errorBufferSmall       BYTE "Error: destination buffer is too small.",0
errorCipherLength      BYTE "Error: ciphertext length must be a positive multiple of 8.",0
errorPadding           BYTE "Error: invalid PKCS#7 padding or wrong key.",0
errorFileTooLarge      BYTE "Error: file exceeds the supported size limit.",0
errorSamePath          BYTE "Error: input and output paths must be different.",0
errorGeneric           BYTE "Error: command could not be processed.", 0

.data?
commandBuffer          BYTE COMMAND_BUFFER_CAPACITY DUP(?)
inputLength            DWORD ?
currentCommand         PARSED_COMMAND <>
parserTokenStart       DWORD ?
parserTokenLength      DWORD ?
parserArgumentQuoted   DWORD ?
inputFileHandle        DWORD ?
outputFileHandle       DWORD ?
fileInputBuffer        BYTE (FILE_BUFFER_CAPACITY + 9) DUP(?)
fileOutputBuffer       BYTE (FILE_BUFFER_CAPACITY + 8) DUP(?)
moduleSubkeys          BYTE DES_SUBKEY_BUFFER_SIZE DUP(?)
moduleHistogram        DWORD HISTOGRAM_BIN_COUNT DUP(?)
moduleInputLength      DWORD ?
moduleOutputLength     DWORD ?
ioBytesTransferred    DWORD ?
overflowByte           BYTE ?
autoOutputPath         BYTE (COMMAND_BUFFER_CAPACITY + 8) DUP(?)

; ========================== MODULE A DATA END HERE =============================

; ======================== MODULE A LOGIC BEGIN HERE ============================

.code
ShellMain PROC
    push ebp
    mov ebp,esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
shell_read_next:
    mov  edx, OFFSET shellPrompt
    call WriteString

    INVOKE ReadCommandLine,
           ADDR commandBuffer,
           LENGTHOF commandBuffer,
           ADDR inputLength

    cmp eax, STATUS_SUCCESS
    jne shell_report_error

    cmp inputLength, 0
    je shell_read_next

    INVOKE ParseCommandFSM,
           ADDR commandBuffer,
           inputLength,
           ADDR currentCommand

    cmp eax, STATUS_SUCCESS
    jne shell_report_error

    INVOKE ValidateCommand, ADDR currentCommand
    cmp eax, STATUS_SUCCESS
    jne shell_report_error

    mov eax, currentCommand.commandType
    cmp eax, COMMAND_EXIT
    je shell_success

    INVOKE DispatchCommand, ADDR currentCommand
    cmp eax, STATUS_SUCCESS
    jne shell_report_error

    jmp shell_read_next

shell_report_error:
    INVOKE PrintShellError, eax
    jmp shell_read_next

shell_success:
    mov eax, STATUS_SUCCESS

shell_finished:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    mov esp,ebp
    pop ebp
    ret
ShellMain ENDP

ReadCommandLine PROC USES ebx ecx edx esi edi,
                    bufferPtr:PTR BYTE,
                    capacity:DWORD,
                    lengthOut:PTR DWORD

    mov eax, lengthOut
    test eax, eax
    jz read_invalid_parameter

    mov DWORD PTR [eax], 0

    mov eax, bufferPtr
    test eax, eax
    jz read_invalid_parameter

    mov eax, capacity
    cmp eax, 2
    jb read_buffer_too_small

    mov edx, bufferPtr
    mov ecx, capacity
    dec ecx
    call ReadString

    mov edx, lengthOut
    mov DWORD PTR [edx], eax
    mov eax, STATUS_SUCCESS
    ret

read_buffer_too_small:
    mov eax, ERROR_BUFFER_TOO_SMALL
    ret

read_invalid_parameter:
    mov eax, ERROR_INVALID_PARAMETER
    ret
ReadCommandLine ENDP

ParseCommandFSM PROC USES ebx ecx edx esi edi,textPtr:PTR BYTE, textLength:DWORD, commandPtr:PTR BYTE

    mov esi, textPtr
    test esi, esi
    jz parse_invalid_parameter

    mov edi, commandPtr
    test edi, edi
    jz parse_invalid_parameter

    INVOKE ResetParsedCommand, edi

    mov ecx, textLength
    xor ebx, ebx

parse_skip_leading:
    cmp ebx, ecx
    jae parse_empty_command
    mov al, BYTE PTR [esi + ebx]
    cmp al, ' '
    je parse_skip_leading_next
    cmp al, 9
    jne parse_command_start

parse_skip_leading_next:
    inc ebx
    jmp parse_skip_leading

parse_command_start:
    mov parserTokenStart, ebx

parse_command_loop:
    cmp ebx, ecx
    jae parse_command_done
    mov al, BYTE PTR [esi + ebx]
    cmp al, ' '
    je parse_command_done
    cmp al, 9
    je parse_command_done
    inc ebx
    jmp parse_command_loop

parse_command_done:
    mov eax, ebx
    sub eax, parserTokenStart
    mov parserTokenLength, eax
    mov edx, esi
    add edx, parserTokenStart
    INVOKE IdentifyCommand, edx, parserTokenLength
    cmp eax, COMMAND_INVALID
    je parse_unknown_command
    mov [edi].PARSED_COMMAND.commandType, eax

parse_next_argument:
parse_skip_argument_space:
    cmp ebx, ecx
    jae parse_success
    mov al, BYTE PTR [esi + ebx]
    cmp al, ' '
    je parse_argument_space_next
    cmp al, 9
    jne parse_argument_start

parse_argument_space_next:
    inc ebx
    jmp parse_skip_argument_space

parse_argument_start:
    mov parserArgumentQuoted, 0
    mov parserTokenStart, ebx
    cmp BYTE PTR [esi + ebx], '"'
    jne parse_unquoted_argument

    mov parserArgumentQuoted, 1
    inc ebx
    mov parserTokenStart, ebx

parse_quoted_loop:
    cmp ebx, ecx
    jae parse_unterminated_quote
    cmp BYTE PTR [esi + ebx], '"'
    je parse_quoted_done
    inc ebx
    jmp parse_quoted_loop

parse_quoted_done:
    mov eax, ebx
    sub eax, parserTokenStart
    test eax, eax
    jz parse_empty_filename
    mov parserTokenLength, eax
    mov BYTE PTR [esi + ebx], 0
    inc ebx
    cmp ebx, ecx
    jae parse_store_argument
    mov al, BYTE PTR [esi + ebx]
    cmp al, ' '
    je parse_store_argument
    cmp al, 9
    je parse_store_argument
    mov eax, ERROR_EXTRA_ARGUMENT
    jmp parse_finished

parse_unquoted_argument:
    inc ebx
parse_unquoted_loop:
    cmp ebx, ecx
    jae parse_unquoted_done
    mov al, BYTE PTR [esi + ebx]
    cmp al, ' '
    je parse_unquoted_done
    cmp al, 9
    je parse_unquoted_done
    inc ebx
    jmp parse_unquoted_loop

parse_unquoted_done:
    mov eax, ebx
    sub eax, parserTokenStart
    mov parserTokenLength, eax

parse_store_argument:
    mov eax, [edi].PARSED_COMMAND.argumentCount
    cmp eax, 3
    jae parse_extra_argument

    mov edx, esi
    add edx, parserTokenStart

    cmp eax, 0
    jne parse_store_second
    mov [edi].PARSED_COMMAND.inputPathPtr, edx
    mov edx, parserTokenLength
    mov [edi].PARSED_COMMAND.inputPathLength, edx
    mov edx, parserArgumentQuoted
    mov [edi].PARSED_COMMAND.inputPathQuoted, edx
    jmp parse_argument_stored

parse_store_second:
    cmp eax, 1
    jne parse_store_third
    mov [edi].PARSED_COMMAND.outputPathPtr, edx
    mov edx, parserTokenLength
    mov [edi].PARSED_COMMAND.outputPathLength, edx
    mov edx, parserArgumentQuoted
    mov [edi].PARSED_COMMAND.outputPathQuoted, edx
    jmp parse_argument_stored

parse_store_third:
    mov [edi].PARSED_COMMAND.keyTextPtr, edx
    mov edx, parserTokenLength
    mov [edi].PARSED_COMMAND.keyTextLength, edx

parse_argument_stored:
    inc [edi].PARSED_COMMAND.argumentCount
    jmp parse_next_argument

parse_success:
    mov eax, STATUS_SUCCESS
    jmp parse_finished

parse_empty_command:
    mov eax, ERROR_EMPTY_COMMAND
    jmp parse_finished

parse_unknown_command:
    mov eax, ERROR_UNKNOWN_COMMAND
    jmp parse_finished

parse_unterminated_quote:
    mov eax, ERROR_UNTERMINATED_QUOTE
    jmp parse_finished

parse_empty_filename:
    mov eax, ERROR_EMPTY_FILENAME
    jmp parse_finished

parse_extra_argument:
    mov eax, ERROR_EXTRA_ARGUMENT
    jmp parse_finished

parse_invalid_parameter:
    mov eax, ERROR_INVALID_PARAMETER

parse_finished:
    ret
ParseCommandFSM ENDP

ValidateCommand PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov esi, commandPtr
    test esi, esi
    jz validate_invalid_parameter

    mov eax, [esi].PARSED_COMMAND.commandType
    mov ecx, [esi].PARSED_COMMAND.argumentCount

    cmp eax, COMMAND_HELP
    je validate_no_arguments
    cmp eax, COMMAND_CLEAR
    je validate_no_arguments
    cmp eax, COMMAND_EXIT
    je validate_no_arguments

    cmp eax, COMMAND_KEYGEN
    je validate_keygen
    cmp eax, COMMAND_DUMP
    je validate_one_path
    cmp eax, COMMAND_STATS
    je validate_one_path
    cmp eax, COMMAND_ENCRYPT
    je validate_crypto
    cmp eax, COMMAND_DECRYPT
    je validate_crypto

    mov eax, ERROR_UNKNOWN_COMMAND
    jmp validate_finished

validate_no_arguments:
    cmp ecx, 0
    jne validate_wrong_count
    jmp validate_success

validate_keygen:
    cmp ecx, 1
    jne validate_wrong_count
    mov eax, [esi].PARSED_COMMAND.inputPathPtr
    mov edx, [esi].PARSED_COMMAND.inputPathLength
    mov [esi].PARSED_COMMAND.keyTextPtr, eax
    mov [esi].PARSED_COMMAND.keyTextLength, edx
    INVOKE IsValidHexKey, eax, edx
    cmp eax, 1
    jne validate_invalid_key
    lea ecx,[esi].PARSED_COMMAND.keyBytes
    INVOKE ParseHexKey64,[esi].PARSED_COMMAND.keyTextPtr,[esi].PARSED_COMMAND.keyTextLength,ecx
    test eax,eax
    jnz validate_invalid_key
    mov [esi].PARSED_COMMAND.hasKey, 1
    jmp validate_success

validate_one_path:
    cmp ecx, 1
    jne validate_wrong_count
    cmp [esi].PARSED_COMMAND.inputPathQuoted, 1
    jne validate_path_not_quoted
    mov [esi].PARSED_COMMAND.hasInputPath, 1
    jmp validate_success

validate_crypto:
    cmp ecx, 2
    je validate_crypto_auto
    cmp ecx, 3
    jne validate_wrong_count
    cmp [esi].PARSED_COMMAND.inputPathQuoted, 1
    jne validate_path_not_quoted
    cmp [esi].PARSED_COMMAND.outputPathQuoted, 1
    jne validate_path_not_quoted
    jmp validate_crypto_key

validate_crypto_auto:
    cmp [esi].PARSED_COMMAND.inputPathQuoted, 1
    jne validate_path_not_quoted
    mov edx, [esi].PARSED_COMMAND.outputPathPtr
    mov [esi].PARSED_COMMAND.keyTextPtr, edx
    mov edx, [esi].PARSED_COMMAND.outputPathLength
    mov [esi].PARSED_COMMAND.keyTextLength, edx
    INVOKE BuildAutoOutputPath, esi
    test eax, eax
    jnz validate_finished

validate_crypto_key:
    mov eax, [esi].PARSED_COMMAND.keyTextPtr
    mov edx, [esi].PARSED_COMMAND.keyTextLength
    INVOKE IsValidHexKey, eax, edx
    cmp eax, 1
    jne validate_invalid_key
    lea ecx,[esi].PARSED_COMMAND.keyBytes
    INVOKE ParseHexKey64,[esi].PARSED_COMMAND.keyTextPtr,[esi].PARSED_COMMAND.keyTextLength,ecx
    test eax,eax
    jnz validate_invalid_key
    mov [esi].PARSED_COMMAND.hasInputPath, 1
    mov [esi].PARSED_COMMAND.hasOutputPath, 1
    mov [esi].PARSED_COMMAND.hasKey, 1
    jmp validate_success

validate_success:
    mov eax, STATUS_SUCCESS
    jmp validate_finished

validate_wrong_count:
    mov eax, ERROR_WRONG_ARGUMENT_COUNT
    jmp validate_finished

validate_invalid_key:
    mov eax, ERROR_INVALID_KEY
    jmp validate_finished

validate_path_not_quoted:
    mov eax, ERROR_PATH_MUST_BE_QUOTED
    jmp validate_finished

validate_invalid_parameter:
    mov eax, ERROR_INVALID_PARAMETER

validate_finished:
    ret
ValidateCommand ENDP

DispatchCommand PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov edx, commandPtr
    test edx, edx
    jz dispatch_invalid_parameter

    mov eax, [edx].PARSED_COMMAND.commandType
    cmp eax, COMMAND_HELP
    je dispatch_help
    cmp eax, COMMAND_CLEAR
    je dispatch_clear
    cmp eax,COMMAND_KEYGEN
    je dispatch_keygen
    cmp eax,COMMAND_ENCRYPT
    je dispatch_encrypt
    cmp eax,COMMAND_DECRYPT
    je dispatch_decrypt
    cmp eax,COMMAND_DUMP
    je dispatch_dump
    cmp eax,COMMAND_STATS
    je dispatch_stats
    mov eax,ERROR_UNKNOWN_COMMAND
    ret

dispatch_keygen:
    INVOKE HandleKeygen,commandPtr
    ret
dispatch_encrypt:
    INVOKE HandleEncrypt,commandPtr
    ret
dispatch_decrypt:
    INVOKE HandleDecrypt,commandPtr
    ret
dispatch_dump:
    INVOKE HandleDump,commandPtr
    ret
dispatch_stats:
    INVOKE HandleStats,commandPtr
    ret

dispatch_help:
    mov edx, OFFSET helpTextHeader
    call WriteString
    mov edx, OFFSET helpTextHelp
    call WriteString
    mov edx, OFFSET helpTextKeygen
    call WriteString
    mov edx, OFFSET helpTextEncrypt
    call WriteString
    mov edx, OFFSET helpTextDecrypt
    call WriteString
    mov edx, OFFSET helpTextDump
    call WriteString
    mov edx, OFFSET helpTextStats
    call WriteString
    mov edx, OFFSET helpTextClear
    call WriteString
    mov edx, OFFSET helpTextExit
    call WriteString
    mov edx, OFFSET helpTextPolicy
    call WriteString
    mov eax, STATUS_SUCCESS
    ret

dispatch_clear:
    call Clrscr
    mov eax, STATUS_SUCCESS
    ret

dispatch_invalid_parameter:
    mov eax, ERROR_INVALID_PARAMETER
    ret
DispatchCommand ENDP

ReadWholeFile PROC USES ebx ecx edx esi edi,pathPtr:PTR BYTE, bufferPtr:PTR BYTE, capacity:DWORD, lengthOut:PTR DWORD
    push ebx
    push esi
    push edi
    mov esi,pathPtr
    mov edi,bufferPtr
    mov ebx,lengthOut
    test esi,esi
    jz rwf_bad
    test edi,edi
    jz rwf_bad
    test ebx,ebx
    jz rwf_bad
    mov DWORD PTR [ebx],0
    mov edx,esi
    call OpenInputFile
    cmp eax,INVALID_HANDLE_VALUE
    je rwf_open_error
    mov inputFileHandle,eax
    xor esi,esi
rwf_loop:
    cmp esi,capacity
    jae rwf_probe
    mov eax,capacity
    sub eax,esi
    lea edx,[edi+esi]
    INVOKE ReadFile,inputFileHandle,edx,eax,ADDR ioBytesTransferred,0
    test eax,eax
    jz rwf_read_error
    mov eax,ioBytesTransferred
    test eax,eax
    jz rwf_success
    add esi,eax
    jmp rwf_loop
rwf_probe:
    INVOKE ReadFile,inputFileHandle,ADDR overflowByte,1,ADDR ioBytesTransferred,0
    test eax,eax
    jz rwf_read_error
    cmp ioBytesTransferred,0
    jne rwf_too_large
rwf_success:
    mov eax,inputFileHandle
    call CloseFile
    mov [ebx],esi
    xor eax,eax
    jmp rwf_done
rwf_read_error:
    mov eax,inputFileHandle
    call CloseFile
    mov eax,ERROR_FILE_READ
    jmp rwf_done
rwf_too_large:
    mov eax,inputFileHandle
    call CloseFile
    mov eax,ERROR_FILE_TOO_LARGE
    jmp rwf_done
rwf_open_error:
    mov eax,ERROR_FILE_OPEN
    jmp rwf_done
rwf_bad:
    mov eax,ERROR_INVALID_PARAMETER
rwf_done:
    pop edi
    pop esi
    pop ebx
    ret
ReadWholeFile ENDP

WriteWholeFile PROC USES ebx ecx edx esi edi,pathPtr:PTR BYTE, bufferPtr:PTR BYTE, dataLength:DWORD
    push ebx
    push esi
    push edi
    mov esi,pathPtr
    mov edi,bufferPtr
    test esi,esi
    jz wwf_bad
    test edi,edi
    jz wwf_bad
    mov edx,esi
    call CreateOutputFile
    cmp eax,INVALID_HANDLE_VALUE
    je wwf_open_error
    mov outputFileHandle,eax
    xor ebx,ebx
wwf_loop:
    cmp ebx,dataLength
    jae wwf_success
    mov eax,dataLength
    sub eax,ebx
    lea edx,[edi+ebx]
    INVOKE WriteFile,outputFileHandle,edx,eax,ADDR ioBytesTransferred,0
    test eax,eax
    jz wwf_write_error
    cmp ioBytesTransferred,0
    je wwf_write_error
    add ebx,ioBytesTransferred
    jmp wwf_loop
wwf_success:
    mov eax,outputFileHandle
    call CloseFile
    xor eax,eax
    jmp wwf_done
wwf_write_error:
    mov eax,outputFileHandle
    call CloseFile
    mov eax,ERROR_FILE_WRITE
    jmp wwf_done
wwf_open_error:
    mov eax,ERROR_FILE_OPEN
    jmp wwf_done
wwf_bad:
    mov eax,ERROR_INVALID_PARAMETER
wwf_done:
    pop edi
    pop esi
    pop ebx
    ret
WriteWholeFile ENDP

PrintShellError PROC USES ebx ecx edx esi edi,errorCode:DWORD
    mov eax, errorCode
    cmp eax, ERROR_EMPTY_COMMAND
    je print_empty_command
    cmp eax, ERROR_UNKNOWN_COMMAND
    je print_unknown_command
    cmp eax, ERROR_WRONG_ARGUMENT_COUNT
    je print_argument_count
    cmp eax, ERROR_EXTRA_ARGUMENT
    je print_argument_count
    cmp eax, ERROR_UNTERMINATED_QUOTE
    je print_unterminated_quote
    cmp eax, ERROR_EMPTY_FILENAME
    je print_empty_filename
    cmp eax, ERROR_INVALID_KEY
    je print_invalid_key
    cmp eax, ERROR_INVALID_KEY_LENGTH
    je print_invalid_key
    cmp eax, ERROR_INVALID_PARAMETER
    je print_invalid_parameter
    cmp eax, ERROR_PATH_MUST_BE_QUOTED
    je print_path_not_quoted
    cmp eax,ERROR_FILE_OPEN
    je print_file_open
    cmp eax,ERROR_FILE_READ
    je print_file_read
    cmp eax,ERROR_FILE_WRITE
    je print_file_write
    cmp eax,ERROR_BUFFER_TOO_SMALL
    je print_buffer_small
    cmp eax,ERROR_INVALID_CIPHERTEXT_LENGTH
    je print_cipher_length
    cmp eax,ERROR_INVALID_PADDING
    je print_padding
    cmp eax,ERROR_FILE_TOO_LARGE
    je print_file_large
    cmp eax,ERROR_SAME_INPUT_OUTPUT
    je print_same_path
    mov edx, OFFSET errorGeneric
    jmp print_error_message

print_empty_command:
    mov edx, OFFSET errorEmptyCommand
    jmp print_error_message
print_unknown_command:
    mov edx, OFFSET errorUnknownCommand
    jmp print_error_message
print_argument_count:
    mov edx, OFFSET errorArgumentCount
    jmp print_error_message
print_unterminated_quote:
    mov edx, OFFSET errorUnterminatedQuote
    jmp print_error_message
print_empty_filename:
    mov edx, OFFSET errorEmptyFilename
    jmp print_error_message
print_invalid_key:
    mov edx, OFFSET errorInvalidKey
    jmp print_error_message
print_invalid_parameter:
    mov edx, OFFSET errorInvalidParameter
    jmp print_error_message
print_path_not_quoted:
    mov edx, OFFSET errorPathMustBeQuoted
    jmp print_error_message
print_file_open:
    mov edx,OFFSET errorFileOpen
    jmp print_error_message
print_file_read:
    mov edx,OFFSET errorFileRead
    jmp print_error_message
print_file_write:
    mov edx,OFFSET errorFileWrite
    jmp print_error_message
print_buffer_small:
    mov edx,OFFSET errorBufferSmall
    jmp print_error_message
print_cipher_length:
    mov edx,OFFSET errorCipherLength
    jmp print_error_message
print_padding:
    mov edx,OFFSET errorPadding
    jmp print_error_message
print_file_large:
    mov edx,OFFSET errorFileTooLarge
    jmp print_error_message
print_same_path:
    mov edx,OFFSET errorSamePath

print_error_message:
    call WriteString
    call Crlf
    mov eax, STATUS_SUCCESS
    ret
PrintShellError ENDP

ResetParsedCommand PROC USES ebx ecx edx esi edi, commandPtr:PTR BYTE
    mov edi, commandPtr
    mov ecx, SIZEOF PARSED_COMMAND
    xor eax, eax
reset_command_loop:
    mov BYTE PTR [edi], al
    inc edi
    dec ecx
    jnz reset_command_loop
    ret
ResetParsedCommand ENDP

IdentifyCommand PROC USES ebx ecx edx esi edi,tokenPtr:PTR BYTE, commandLength:DWORD
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordKeygen, LENGTHOF keywordKeygen
    cmp eax, 1
    je identify_keygen
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordEncrypt, LENGTHOF keywordEncrypt
    cmp eax, 1
    je identify_encrypt
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordDecrypt, LENGTHOF keywordDecrypt
    cmp eax, 1
    je identify_decrypt
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordDump, LENGTHOF keywordDump
    cmp eax, 1
    je identify_dump
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordStats, LENGTHOF keywordStats
    cmp eax, 1
    je identify_stats
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordClear, LENGTHOF keywordClear
    cmp eax, 1
    je identify_clear
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordExit, LENGTHOF keywordExit
    cmp eax, 1
    je identify_exit
    INVOKE CompareTokenCI, tokenPtr, commandLength, ADDR keywordHelp, LENGTHOF keywordHelp
    cmp eax, 1
    je identify_help
    mov eax, COMMAND_INVALID
    ret
identify_keygen:
    mov eax, COMMAND_KEYGEN
    ret
identify_encrypt:
    mov eax, COMMAND_ENCRYPT
    ret
identify_decrypt:
    mov eax, COMMAND_DECRYPT
    ret
identify_dump:
    mov eax, COMMAND_DUMP
    ret
identify_stats:
    mov eax, COMMAND_STATS
    ret
identify_clear:
    mov eax, COMMAND_CLEAR
    ret
identify_exit:
    mov eax, COMMAND_EXIT
    ret
identify_help:
    mov eax, COMMAND_HELP
    ret
IdentifyCommand ENDP

CompareTokenCI PROC USES ebx ecx edx esi edi,
                    tokenPtr:PTR BYTE,
                    comparisonLength:DWORD,
                    expectedPtr:PTR BYTE,
                    expectedLength:DWORD
    mov eax, comparisonLength
    cmp eax, expectedLength
    jne compare_not_equal
    mov esi, tokenPtr
    mov edi, expectedPtr
    mov ecx, comparisonLength
compare_character_loop:
    test ecx, ecx
    jz compare_equal
    mov al, BYTE PTR [esi]
    mov bl, BYTE PTR [edi]
    cmp al, 'a'
    jb compare_token_ready
    cmp al, 'z'
    ja compare_token_ready
    sub al, 20h
compare_token_ready:
    cmp al, bl
    jne compare_not_equal
    inc esi
    inc edi
    dec ecx
    jmp compare_character_loop
compare_equal:
    mov eax, 1
    ret
compare_not_equal:
    xor eax, eax
    ret
CompareTokenCI ENDP

IsValidHexKey PROC USES ebx ecx edx esi edi, keyPtr:PTR BYTE, keyLength:DWORD
    mov esi, keyPtr
    mov ecx, keyLength
    cmp ecx, 18
    jne key_check_plain_length
    cmp BYTE PTR [esi], '0'
    jne key_invalid
    mov al, BYTE PTR [esi + 1]
    cmp al, 'x'
    je key_skip_prefix
    cmp al, 'X'
    jne key_invalid
key_skip_prefix:
    add esi, 2
    sub ecx, 2
    jmp key_check_digits
key_check_plain_length:
    cmp ecx, 16
    jne key_invalid
key_check_digits:
    test ecx, ecx
    jz key_valid
    mov al, BYTE PTR [esi]
    cmp al, '0'
    jb key_invalid
    cmp al, '9'
    jbe key_next_digit
    cmp al, 'A'
    jb key_check_lower
    cmp al, 'F'
    jbe key_next_digit
key_check_lower:
    cmp al, 'a'
    jb key_invalid
    cmp al, 'f'
    ja key_invalid
key_next_digit:
    inc esi
    dec ecx
    jmp key_check_digits
key_valid:
    mov eax, 1
    ret
key_invalid:
    xor eax, eax
    ret
IsValidHexKey ENDP

HexCharToNibble PROC USES ebx ecx edx esi edi,characterValue:DWORD
    mov eax,characterValue
    and eax,0FFh
    cmp al,'0'
    jb hcn_bad
    cmp al,'9'
    jbe hcn_digit
    cmp al,'A'
    jb hcn_lower
    cmp al,'F'
    jbe hcn_upper
hcn_lower:
    cmp al,'a'
    jb hcn_bad
    cmp al,'f'
    ja hcn_bad
    sub al,'a'-10
    movzx eax,al
    ret
hcn_upper:
    sub al,'A'-10
    movzx eax,al
    ret
hcn_digit:
    sub al,'0'
    movzx eax,al
    ret
hcn_bad:
    mov eax,0FFFFFFFFh
    ret
HexCharToNibble ENDP

ParseHexKey64 PROC USES ebx ecx edx esi edi,keyPtr:PTR BYTE,keyLength:DWORD,keyOut:PTR BYTE
    mov esi,keyPtr
    mov edi,keyOut
    test esi,esi
    jz phk_bad
    test edi,edi
    jz phk_bad
    cmp keyLength,18
    jne phk_no_prefix
    add esi,2
phk_no_prefix:
    xor ecx,ecx
phk_loop:
    cmp ecx,8
    jae phk_ok
    movzx eax,BYTE PTR [esi]
    INVOKE HexCharToNibble,eax
    cmp eax,0FFFFFFFFh
    je phk_bad
    mov ebx,eax
    shl ebx,4
    movzx eax,BYTE PTR [esi+1]
    INVOKE HexCharToNibble,eax
    cmp eax,0FFFFFFFFh
    je phk_bad
    or ebx,eax
    mov [edi+ecx],bl
    add esi,2
    inc ecx
    jmp phk_loop
phk_ok:
    xor eax,eax
    ret
phk_bad:
    mov eax,ERROR_INVALID_KEY
    ret
ParseHexKey64 ENDP

PathsEqualCI PROC USES ebx ecx edx esi edi,leftPtr:PTR BYTE,leftLength:DWORD,rightPtr:PTR BYTE,rightLength:DWORD
    mov eax,leftLength
    cmp eax,rightLength
    jne pec_no
    mov esi,leftPtr
    mov edi,rightPtr
    mov ecx,leftLength
pec_loop:
    test ecx,ecx
    jz pec_yes
    mov al,[esi]
    mov bl,[edi]
    cmp al,'a'
    jb pec_left_ready
    cmp al,'z'
    ja pec_left_ready
    sub al,20h
pec_left_ready:
    cmp bl,'a'
    jb pec_right_ready
    cmp bl,'z'
    ja pec_right_ready
    sub bl,20h
pec_right_ready:
    cmp al,bl
    jne pec_no
    inc esi
    inc edi
    dec ecx
    jmp pec_loop
pec_yes:
    mov eax,1
    ret
pec_no:
    xor eax,eax
    ret
PathsEqualCI ENDP

BuildAutoOutputPath PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov edx,commandPtr
    test edx,edx
    jz bao_bad
    mov ecx,[edx].PARSED_COMMAND.inputPathLength
    cmp ecx,COMMAND_BUFFER_CAPACITY
    ja bao_small
    mov esi,[edx].PARSED_COMMAND.inputPathPtr
    test esi,esi
    jz bao_bad
    mov edi,OFFSET autoOutputPath
bao_copy_path:
    test ecx,ecx
    jz bao_choose_extension
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    dec ecx
    jmp bao_copy_path
bao_choose_extension:
    mov esi,OFFSET extDec
    cmp [edx].PARSED_COMMAND.commandType,COMMAND_ENCRYPT
    jne bao_copy_extension
    mov esi,OFFSET extEnc
bao_copy_extension:
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    test al,al
    jnz bao_copy_extension
    mov [edx].PARSED_COMMAND.outputPathPtr,OFFSET autoOutputPath
    mov ecx,[edx].PARSED_COMMAND.inputPathLength
    add ecx,4
    mov [edx].PARSED_COMMAND.outputPathLength,ecx
    xor eax,eax
    ret
bao_small:
    mov eax,ERROR_BUFFER_TOO_SMALL
    ret
bao_bad:
    mov eax,ERROR_INVALID_PARAMETER
    ret
BuildAutoOutputPath ENDP

HandleKeygen PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov esi,commandPtr
    lea eax,[esi].PARSED_COMMAND.keyBytes
    INVOKE GenerateKeySchedule,eax,ADDR moduleSubkeys
    test eax,eax
    jnz hk_done
    INVOKE DisplayKeySchedule,ADDR moduleSubkeys
hk_done:
    ret
HandleKeygen ENDP

HandleEncrypt PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov esi,commandPtr
    INVOKE PathsEqualCI,[esi].PARSED_COMMAND.inputPathPtr,[esi].PARSED_COMMAND.inputPathLength,[esi].PARSED_COMMAND.outputPathPtr,[esi].PARSED_COMMAND.outputPathLength
    cmp eax,1
    je he_same
    INVOKE ReadWholeFile,[esi].PARSED_COMMAND.inputPathPtr,ADDR fileInputBuffer,FILE_BUFFER_CAPACITY,ADDR moduleInputLength
    test eax,eax
    jnz he_done
    mov edx,OFFSET loadingText
    call WriteString
    mov edx,[esi].PARSED_COMMAND.inputPathPtr
    call WriteString
    mov edx,OFFSET openParenText
    call WriteString
    mov eax,moduleInputLength
    call WriteDec
    mov edx,OFFSET bytesText
    call WriteString
    mov edx,OFFSET keyScheduleText
    call WriteString
    lea eax,[esi].PARSED_COMMAND.keyBytes
    INVOKE GenerateKeySchedule,eax,ADDR moduleSubkeys
    test eax,eax
    jnz he_done
    mov edx,OFFSET processingText
    call WriteString
    mov eax,moduleInputLength
    shr eax,3
    inc eax
    call WriteDec
    mov edx,OFFSET blocksText
    call WriteString
    INVOKE EncryptBufferECB,ADDR fileInputBuffer,moduleInputLength,ADDR fileOutputBuffer,(FILE_BUFFER_CAPACITY+8),ADDR moduleSubkeys,ADDR moduleOutputLength
    test eax,eax
    jnz he_done
    INVOKE WriteWholeFile,[esi].PARSED_COMMAND.outputPathPtr,ADDR fileOutputBuffer,moduleOutputLength
    test eax,eax
    jnz he_done
    mov edx,OFFSET encryptSuccessMessage
    call WriteString
    mov edx,[esi].PARSED_COMMAND.outputPathPtr
    call WriteString
    mov edx,OFFSET closingQuoteText
    call WriteString
    xor eax,eax
he_done:
    ret
he_same:
    mov eax,ERROR_SAME_INPUT_OUTPUT
    ret
HandleEncrypt ENDP

HandleDecrypt PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov esi,commandPtr
    INVOKE PathsEqualCI,[esi].PARSED_COMMAND.inputPathPtr,[esi].PARSED_COMMAND.inputPathLength,[esi].PARSED_COMMAND.outputPathPtr,[esi].PARSED_COMMAND.outputPathLength
    cmp eax,1
    je hd_same
    INVOKE ReadWholeFile,[esi].PARSED_COMMAND.inputPathPtr,ADDR fileInputBuffer,(FILE_BUFFER_CAPACITY+8),ADDR moduleInputLength
    test eax,eax
    jnz hd_done
    mov edx,OFFSET loadingText
    call WriteString
    mov edx,[esi].PARSED_COMMAND.inputPathPtr
    call WriteString
    mov edx,OFFSET openParenText
    call WriteString
    mov eax,moduleInputLength
    call WriteDec
    mov edx,OFFSET bytesText
    call WriteString
    mov edx,OFFSET keyScheduleText
    call WriteString
    lea eax,[esi].PARSED_COMMAND.keyBytes
    INVOKE GenerateKeySchedule,eax,ADDR moduleSubkeys
    test eax,eax
    jnz hd_done
    mov edx,OFFSET processingText
    call WriteString
    mov eax,moduleInputLength
    shr eax,3
    call WriteDec
    mov edx,OFFSET blocksText
    call WriteString
    INVOKE DecryptBufferECB,ADDR fileInputBuffer,moduleInputLength,ADDR fileOutputBuffer,(FILE_BUFFER_CAPACITY+8),ADDR moduleSubkeys,ADDR moduleOutputLength
    test eax,eax
    jnz hd_done
    INVOKE WriteWholeFile,[esi].PARSED_COMMAND.outputPathPtr,ADDR fileOutputBuffer,moduleOutputLength
    test eax,eax
    jnz hd_done
    mov edx,OFFSET decryptSuccessMessage
    call WriteString
    mov edx,[esi].PARSED_COMMAND.outputPathPtr
    call WriteString
    mov edx,OFFSET closingQuoteText
    call WriteString
    xor eax,eax
hd_done:
    ret
hd_same:
    mov eax,ERROR_SAME_INPUT_OUTPUT
    ret
HandleDecrypt ENDP

HandleDump PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov esi,commandPtr
    INVOKE ReadWholeFile,[esi].PARSED_COMMAND.inputPathPtr,ADDR fileInputBuffer,(FILE_BUFFER_CAPACITY+8),ADDR moduleInputLength
    test eax,eax
    jnz hdu_done
    INVOKE DisplayHexDump,ADDR fileInputBuffer,moduleInputLength
hdu_done:
    ret
HandleDump ENDP

HandleStats PROC USES ebx ecx edx esi edi,commandPtr:PTR BYTE
    mov esi,commandPtr
    INVOKE ReadWholeFile,[esi].PARSED_COMMAND.inputPathPtr,ADDR fileInputBuffer,(FILE_BUFFER_CAPACITY+8),ADDR moduleInputLength
    test eax,eax
    jnz hs_done
    mov edx,OFFSET statsSizeLabel
    call WriteString
    mov eax,moduleInputLength
    call WriteDec
    mov edx,OFFSET statsSizeUnit
    call WriteString
    INVOKE ComputeBufferStats,ADDR fileInputBuffer,moduleInputLength,ADDR moduleHistogram
    test eax,eax
    jnz hs_done
    INVOKE DisplayTopOccurrences,ADDR moduleHistogram,10
hs_done:
    ret
HandleStats ENDP

; ========================= MODULE A LOGIC END HERE =============================

END
