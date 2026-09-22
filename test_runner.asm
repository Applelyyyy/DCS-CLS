option casemap:none
INCLUDE Irvine32.inc
INCLUDE module_A.inc
INCLUDE module_B.inc
INCLUDE module_C.inc
INCLUDE module_D.inc

.data
msgPass BYTE "PASS: ",0
msgFail BYTE "FAIL: ",0
nameK1 BYTE "DES K1",0
nameK16 BYTE "DES K16",0
nameEncrypt BYTE "DES official encryption vector",0
nameDecrypt BYTE "DES official decryption vector",0
nameRoundTrip BYTE "ECB/PKCS#7 lengths 0..17",0
nameHistogram BYTE "Histogram all 256 byte values",0
nameParser BYTE "Parser valid and invalid command matrix",0
nameInvalidCipher BYTE "Reject invalid ciphertext lengths",0
nameInvalidPadding BYTE "Reject invalid PKCS#7 padding",0
nameFileIO BYTE "File write/read round trip",0
nameMaxFile BYTE "1 MiB file boundary and overflow",0
nameRegisters BYTE "Public register preservation and EAX return",0
nameAutoCrypto BYTE "Automatic .enc/.dec end-to-end flow",0
officialKey BYTE 13h,34h,57h,79h,9Bh,0BCh,0DFh,0F1h
officialPlain BYTE 01h,23h,45h,67h,89h,0ABh,0CDh,0EFh
officialCipher BYTE 85h,0E8h,13h,54h,0Fh,0Ah,0B4h,05h
expectedK1 BYTE 1Bh,02h,0EFh,0FCh,70h,72h
expectedK16 BYTE 0CBh,3Dh,8Bh,0Eh,17h,0F5h
parserHelp BYTE "  hElP  ",0
parserUnknown BYTE "unknown",0
parserBadQuote BYTE "dump ",34,"file.txt",0
parserUnquoted BYTE "dump file.txt",0
parserBadKey BYTE "keygen 1234",0
parserExtra BYTE "help extra",0
parserEncryptAuto BYTE "eNcRyPt ",34,"secret file.txt",34," 0x133457799BBCDFF1",0
parserEncryptExplicit BYTE "ENCRYPT ",34,"in.bin",34," ",34,"out.bin",34," 133457799BBCDFF1",0
expectedAutoEnc BYTE "secret file.txt.enc",0
autoInputName BYTE "test_auto.bin",0
autoEncryptedName BYTE "test_auto.bin.enc",0
autoDecryptedName BYTE "test_auto.bin.enc.dec",0
autoEncryptCommand BYTE "ENCRYPT ",34,"test_auto.bin",34," 133457799BBCDFF1",0
autoDecryptCommand BYTE "DECRYPT ",34,"test_auto.bin.enc",34," 133457799BBCDFF1",0
invalidPadPlain BYTE 1,2,3,4,5,6,7,0
testFileName BYTE "test_io_roundtrip.bin",0
largeFileName BYTE "test_io_large.bin",0
.data?
testSubkeys BYTE 96 DUP(?)
testBlock BYTE 8 DUP(?)
failureCount DWORD ?
roundTripSource BYTE 17 DUP(?)
roundTripCipher BYTE 32 DUP(?)
roundTripPlain BYTE 32 DUP(?)
roundTripCipherLength DWORD ?
roundTripPlainLength DWORD ?
histogramInput BYTE 256 DUP(?)
histogramOutput DWORD 256 DUP(?)
parserResult PARSED_COMMAND <>
fileTestLength DWORD ?
largeInput BYTE (FILE_BUFFER_CAPACITY+1) DUP(?)
largeOutput BYTE FILE_BUFFER_CAPACITY DUP(?)

.code
AssertBytes PROC USES esi edi ecx edx,leftPtr:PTR BYTE,rightPtr:PTR BYTE,itemCount:DWORD,namePtr:PTR BYTE
    mov esi,leftPtr
    mov edi,rightPtr
    mov ecx,itemCount
assert_loop:
    test ecx,ecx
    jz assert_pass
    mov al,[esi]
    cmp al,[edi]
    jne assert_fail
    inc esi
    inc edi
    dec ecx
    jmp assert_loop
assert_pass:
    mov edx,OFFSET msgPass
    call WriteString
    mov edx,namePtr
    call WriteString
    call Crlf
    xor eax,eax
    ret
assert_fail:
    mov edx,OFFSET msgFail
    call WriteString
    mov edx,namePtr
    call WriteString
    call Crlf
    inc failureCount
    mov eax,1
    ret
AssertBytes ENDP

ReportResult PROC USES edx,statusValue:DWORD,namePtr:PTR BYTE
    cmp statusValue,0
    jne report_fail
    mov edx,OFFSET msgPass
    call WriteString
    mov edx,namePtr
    call WriteString
    call Crlf
    xor eax,eax
    ret
report_fail:
    mov edx,OFFSET msgFail
    call WriteString
    mov edx,namePtr
    call WriteString
    call Crlf
    inc failureCount
    mov eax,1
    ret
ReportResult ENDP

TestRoundTripLengths PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    xor ecx,ecx
init_round_source:
    cmp ecx,17
    jae round_start
    mov eax,ecx
    add eax,31h
    mov roundTripSource[ecx],al
    inc ecx
    jmp init_round_source
round_start:
    xor ebx,ebx
round_length_loop:
    cmp ebx,18
    jae round_pass
    INVOKE EncryptBufferECB,ADDR roundTripSource,ebx,ADDR roundTripCipher,32,ADDR testSubkeys,ADDR roundTripCipherLength
    test eax,eax
    jnz round_fail
    INVOKE DecryptBufferECB,ADDR roundTripCipher,roundTripCipherLength,ADDR roundTripPlain,32,ADDR testSubkeys,ADDR roundTripPlainLength
    test eax,eax
    jnz round_fail
    cmp roundTripPlainLength,ebx
    jne round_fail
    lea esi,roundTripSource
    lea edi,roundTripPlain
    mov ecx,ebx
    repe cmpsb
    jne round_fail
    inc ebx
    jmp round_length_loop
round_pass:
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
round_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestRoundTripLengths ENDP

TestHistogram PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    xor ecx,ecx
hist_init:
    cmp ecx,256
    jae hist_compute
    mov histogramInput[ecx],cl
    inc ecx
    jmp hist_init
hist_compute:
    INVOKE ComputeBufferStats,ADDR histogramInput,256,ADDR histogramOutput
    test eax,eax
    jnz hist_fail
    xor ecx,ecx
hist_check:
    cmp ecx,256
    jae hist_pass
    cmp DWORD PTR histogramOutput[ecx*4],1
    jne hist_fail
    inc ecx
    jmp hist_check
hist_pass:
    INVOKE ComputeBufferStats,0,256,ADDR histogramOutput
    cmp eax,ERROR_INVALID_PARAMETER
    jne hist_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
hist_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestHistogram ENDP

TestParserMatrix PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    INVOKE ParseCommandFSM,ADDR parserHelp,(LENGTHOF parserHelp-1),ADDR parserResult
    test eax,eax
    jnz tpm_fail
    INVOKE ValidateCommand,ADDR parserResult
    test eax,eax
    jnz tpm_fail
    cmp parserResult.commandType,COMMAND_HELP
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserUnknown,(LENGTHOF parserUnknown-1),ADDR parserResult
    cmp eax,ERROR_UNKNOWN_COMMAND
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserBadQuote,(LENGTHOF parserBadQuote-1),ADDR parserResult
    cmp eax,ERROR_UNTERMINATED_QUOTE
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserUnquoted,(LENGTHOF parserUnquoted-1),ADDR parserResult
    test eax,eax
    jnz tpm_fail
    INVOKE ValidateCommand,ADDR parserResult
    cmp eax,ERROR_PATH_MUST_BE_QUOTED
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserBadKey,(LENGTHOF parserBadKey-1),ADDR parserResult
    test eax,eax
    jnz tpm_fail
    INVOKE ValidateCommand,ADDR parserResult
    cmp eax,ERROR_INVALID_KEY
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserExtra,(LENGTHOF parserExtra-1),ADDR parserResult
    test eax,eax
    jnz tpm_fail
    INVOKE ValidateCommand,ADDR parserResult
    cmp eax,ERROR_WRONG_ARGUMENT_COUNT
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserEncryptAuto,(LENGTHOF parserEncryptAuto-1),ADDR parserResult
    test eax,eax
    jnz tpm_fail
    INVOKE ValidateCommand,ADDR parserResult
    test eax,eax
    jnz tpm_fail
    cmp parserResult.commandType,COMMAND_ENCRYPT
    jne tpm_fail
    cmp parserResult.outputPathLength,(LENGTHOF expectedAutoEnc-1)
    jne tpm_fail
    mov esi,parserResult.outputPathPtr
    mov edi,OFFSET expectedAutoEnc
    mov ecx,(LENGTHOF expectedAutoEnc)
    repe cmpsb
    jne tpm_fail
    cmp parserResult.hasInputPath,1
    jne tpm_fail
    cmp parserResult.hasOutputPath,1
    jne tpm_fail
    cmp parserResult.hasKey,1
    jne tpm_fail
    INVOKE ParseCommandFSM,ADDR parserEncryptExplicit,(LENGTHOF parserEncryptExplicit-1),ADDR parserResult
    test eax,eax
    jnz tpm_fail
    INVOKE ValidateCommand,ADDR parserResult
    test eax,eax
    jnz tpm_fail
    cmp parserResult.outputPathLength,7
    jne tpm_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
tpm_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestParserMatrix ENDP

TestInvalidCipher PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    INVOKE DecryptBufferECB,ADDR roundTripCipher,0,ADDR roundTripPlain,32,ADDR testSubkeys,ADDR roundTripPlainLength
    cmp eax,ERROR_INVALID_CIPHERTEXT_LENGTH
    jne tic_fail
    INVOKE DecryptBufferECB,ADDR roundTripCipher,7,ADDR roundTripPlain,32,ADDR testSubkeys,ADDR roundTripPlainLength
    cmp eax,ERROR_INVALID_CIPHERTEXT_LENGTH
    jne tic_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
tic_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestInvalidCipher ENDP

TestInvalidPadding PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    INVOKE EncryptDESBlock,ADDR invalidPadPlain,ADDR roundTripCipher,ADDR testSubkeys
    test eax,eax
    jnz tip_fail
    INVOKE DecryptBufferECB,ADDR roundTripCipher,8,ADDR roundTripPlain,32,ADDR testSubkeys,ADDR roundTripPlainLength
    cmp eax,ERROR_INVALID_PADDING
    jne tip_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
tip_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestInvalidPadding ENDP

TestFileIO PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    INVOKE WriteWholeFile,ADDR testFileName,ADDR roundTripSource,17
    test eax,eax
    jnz tfio_fail
    INVOKE ReadWholeFile,ADDR testFileName,ADDR roundTripPlain,32,ADDR fileTestLength
    test eax,eax
    jnz tfio_cleanup_fail
    cmp fileTestLength,17
    jne tfio_cleanup_fail
    lea esi,roundTripSource
    lea edi,roundTripPlain
    mov ecx,17
    repe cmpsb
    jne tfio_cleanup_fail
    INVOKE ReadWholeFile,ADDR testFileName,ADDR roundTripPlain,16,ADDR fileTestLength
    cmp eax,ERROR_FILE_TOO_LARGE
    jne tfio_cleanup_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
tfio_cleanup_fail:
tfio_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestFileIO ENDP

TestMaxFile PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    xor ecx,ecx
tmf_fill:
    cmp ecx,(FILE_BUFFER_CAPACITY+1)
    jae tmf_write_max
    mov eax,ecx
    mov largeInput[ecx],al
    inc ecx
    jmp tmf_fill
tmf_write_max:
    INVOKE WriteWholeFile,ADDR largeFileName,ADDR largeInput,FILE_BUFFER_CAPACITY
    test eax,eax
    jnz tmf_fail
    INVOKE ReadWholeFile,ADDR largeFileName,ADDR largeOutput,FILE_BUFFER_CAPACITY,ADDR fileTestLength
    test eax,eax
    jnz tmf_fail
    cmp fileTestLength,FILE_BUFFER_CAPACITY
    jne tmf_fail
    cmp BYTE PTR largeOutput,0
    jne tmf_fail
    cmp BYTE PTR largeOutput[12345],39h
    jne tmf_fail
    cmp BYTE PTR largeOutput[FILE_BUFFER_CAPACITY-1],0FFh
    jne tmf_fail
    INVOKE WriteWholeFile,ADDR largeFileName,ADDR largeInput,(FILE_BUFFER_CAPACITY+1)
    test eax,eax
    jnz tmf_fail
    INVOKE ReadWholeFile,ADDR largeFileName,ADDR largeOutput,FILE_BUFFER_CAPACITY,ADDR fileTestLength
    cmp eax,ERROR_FILE_TOO_LARGE
    jne tmf_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
tmf_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestMaxFile ENDP

TestRegisterContract PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    mov ebx,11223344h
    mov ecx,22334455h
    mov edx,33445566h
    mov esi,44556677h
    mov edi,55667788h
    INVOKE ComputeBufferStats,ADDR histogramInput,0,ADDR histogramOutput
    test eax,eax
    jnz trc_fail
    cmp ebx,11223344h
    jne trc_fail
    cmp ecx,22334455h
    jne trc_fail
    cmp edx,33445566h
    jne trc_fail
    cmp esi,44556677h
    jne trc_fail
    cmp edi,55667788h
    jne trc_fail
    INVOKE ComputeBufferStats,0,0,ADDR histogramOutput
    cmp eax,ERROR_INVALID_PARAMETER
    jne trc_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
trc_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestRegisterContract ENDP

TestAutoCryptoFlow PROC USES ebx ecx edx esi edi
    push ebp
    mov ebp,esp
    INVOKE WriteWholeFile,ADDR autoInputName,ADDR roundTripSource,17
    test eax,eax
    jnz tac_fail
    INVOKE ParseCommandFSM,ADDR autoEncryptCommand,(LENGTHOF autoEncryptCommand-1),ADDR parserResult
    test eax,eax
    jnz tac_fail
    INVOKE ValidateCommand,ADDR parserResult
    test eax,eax
    jnz tac_fail
    INVOKE DispatchCommand,ADDR parserResult
    test eax,eax
    jnz tac_fail
    INVOKE ReadWholeFile,ADDR autoEncryptedName,ADDR roundTripCipher,32,ADDR roundTripCipherLength
    test eax,eax
    jnz tac_fail
    cmp roundTripCipherLength,24
    jne tac_fail
    INVOKE ParseCommandFSM,ADDR autoDecryptCommand,(LENGTHOF autoDecryptCommand-1),ADDR parserResult
    test eax,eax
    jnz tac_fail
    INVOKE ValidateCommand,ADDR parserResult
    test eax,eax
    jnz tac_fail
    INVOKE DispatchCommand,ADDR parserResult
    test eax,eax
    jnz tac_fail
    INVOKE ReadWholeFile,ADDR autoDecryptedName,ADDR roundTripPlain,32,ADDR roundTripPlainLength
    test eax,eax
    jnz tac_fail
    cmp roundTripPlainLength,17
    jne tac_fail
    lea esi,roundTripSource
    lea edi,roundTripPlain
    mov ecx,17
    repe cmpsb
    jne tac_fail
    xor eax,eax
    mov esp,ebp
    pop ebp
    ret
tac_fail:
    mov eax,1
    mov esp,ebp
    pop ebp
    ret
TestAutoCryptoFlow ENDP

main PROC
    push ebp
    mov ebp,esp
    mov failureCount,0
    INVOKE GenerateKeySchedule,ADDR officialKey,ADDR testSubkeys
    INVOKE AssertBytes,ADDR testSubkeys,ADDR expectedK1,6,ADDR nameK1
    INVOKE AssertBytes,ADDR testSubkeys+90,ADDR expectedK16,6,ADDR nameK16
    INVOKE EncryptDESBlock,ADDR officialPlain,ADDR testBlock,ADDR testSubkeys
    INVOKE AssertBytes,ADDR testBlock,ADDR officialCipher,8,ADDR nameEncrypt
    INVOKE DecryptDESBlock,ADDR officialCipher,ADDR testBlock,ADDR testSubkeys
    INVOKE AssertBytes,ADDR testBlock,ADDR officialPlain,8,ADDR nameDecrypt
    call TestRoundTripLengths
    INVOKE ReportResult,eax,ADDR nameRoundTrip
    call TestHistogram
    INVOKE ReportResult,eax,ADDR nameHistogram
    call TestInvalidCipher
    INVOKE ReportResult,eax,ADDR nameInvalidCipher
    call TestInvalidPadding
    INVOKE ReportResult,eax,ADDR nameInvalidPadding
    call TestParserMatrix
    INVOKE ReportResult,eax,ADDR nameParser
    call TestFileIO
    INVOKE ReportResult,eax,ADDR nameFileIO
    call TestMaxFile
    INVOKE ReportResult,eax,ADDR nameMaxFile
    call TestRegisterContract
    INVOKE ReportResult,eax,ADDR nameRegisters
    call TestAutoCryptoFlow
    INVOKE ReportResult,eax,ADDR nameAutoCrypto
    mov eax,failureCount
    mov esp,ebp
    pop ebp
    INVOKE ExitProcess,eax
main ENDP
END main
