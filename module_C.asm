; =============================================================================
; Module C implementation - DES Feistel Core, ECB, and PKCS#7
; Owner: Panabordee Panitchakit (68010697)
; =============================================================================
; Tables use FIPS 46-3 MSB-first numbering.
.386
.model flat, stdcall
option casemap:none
INCLUDE module_C.inc
PUBLIC EncryptBufferECB, DecryptBufferECB, EncryptDESBlock, DecryptDESBlock

MODE_ENCRYPT EQU 0
MODE_DECRYPT EQU 1
STATUS_OK EQU 0
ERR_BUFFER EQU 13
ERR_CIPHER_LENGTH EQU 14
ERR_PADDING EQU 15
ERR_PARAM EQU 16

PermuteBits PROTO :PTR BYTE,:PTR BYTE,:PTR BYTE,:DWORD
GetFipsBitC PROTO :PTR BYTE,:DWORD
ReadBE32 PROTO :PTR BYTE
WriteBE32 PROTO :DWORD,:PTR BYTE
ApplyInitialPermutation PROTO :PTR BYTE,:PTR BYTE
RunFeistelRounds PROTO :PTR BYTE,:PTR BYTE,:DWORD
FeistelFunction PROTO :DWORD,:PTR BYTE
ExpandRightHalf PROTO :DWORD,:PTR BYTE
ApplySBoxes PROTO :PTR BYTE
ApplyPPermutation PROTO :DWORD
ApplyInversePermutation PROTO :PTR BYTE,:PTR BYTE

.data
ipTable BYTE 58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4
        BYTE 62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8
        BYTE 57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3
        BYTE 61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7
inverseIpTable BYTE 40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31
               BYTE 38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29
               BYTE 36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27
               BYTE 34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25
expansionTable BYTE 32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13
               BYTE 12,13,14,15,16,17,16,17,18,19,20,21
               BYTE 20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1
pTable BYTE 16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10
       BYTE 2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25
sBoxTable BYTE 14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7
          BYTE 0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8
          BYTE 4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0
          BYTE 15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13
          BYTE 15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10
          BYTE 3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5
          BYTE 0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15
          BYTE 13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9
          BYTE 10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8
          BYTE 13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1
          BYTE 13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7
          BYTE 1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12
          BYTE 7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15
          BYTE 13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9
          BYTE 10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4
          BYTE 3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14
          BYTE 2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9
          BYTE 14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6
          BYTE 4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14
          BYTE 11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3
          BYTE 12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11
          BYTE 10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8
          BYTE 9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6
          BYTE 4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13
          BYTE 4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1
          BYTE 13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6
          BYTE 1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2
          BYTE 6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12
          BYTE 13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7
          BYTE 1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2
          BYTE 7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8
          BYTE 2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11

.data?
permutationBlock BYTE 8 DUP(?)
rightBytes BYTE 4 DUP(?)
expandedBuffer BYTE 6 DUP(?)
pInputBytes BYTE 4 DUP(?)
pOutputBytes BYTE 4 DUP(?)
ecbBlock BYTE 8 DUP(?)
roundLeft DWORD ?
roundRight DWORD ?
sboxCombined DWORD ?

.code
EncryptDESBlock PROC USES ebx ecx edx esi edi,inputPtr:PTR BYTE,outputPtr:PTR BYTE,subkeysPtr:PTR BYTE
    mov esi,inputPtr
    mov edi,outputPtr
    test esi,esi
    jz edb_bad
    test edi,edi
    jz edb_bad
    mov eax,subkeysPtr
    test eax,eax
    jz edb_bad
    INVOKE ApplyInitialPermutation,esi,ADDR permutationBlock
    test eax,eax
    jnz edb_done
    INVOKE RunFeistelRounds,ADDR permutationBlock,subkeysPtr,MODE_ENCRYPT
    test eax,eax
    jnz edb_done
    INVOKE ApplyInversePermutation,ADDR permutationBlock,edi
edb_done:
    ret
edb_bad:
    mov eax,ERR_PARAM
    ret
EncryptDESBlock ENDP

DecryptDESBlock PROC USES ebx ecx edx esi edi,inputPtr:PTR BYTE,outputPtr:PTR BYTE,subkeysPtr:PTR BYTE
    mov esi,inputPtr
    mov edi,outputPtr
    test esi,esi
    jz ddb_bad
    test edi,edi
    jz ddb_bad
    mov eax,subkeysPtr
    test eax,eax
    jz ddb_bad
    INVOKE ApplyInitialPermutation,esi,ADDR permutationBlock
    test eax,eax
    jnz ddb_done
    INVOKE RunFeistelRounds,ADDR permutationBlock,subkeysPtr,MODE_DECRYPT
    test eax,eax
    jnz ddb_done
    INVOKE ApplyInversePermutation,ADDR permutationBlock,edi
ddb_done:
    ret
ddb_bad:
    mov eax,ERR_PARAM
    ret
DecryptDESBlock ENDP

EncryptBufferECB PROC USES ebx esi edi ecx edx,inputPtr:PTR BYTE,inputLength:DWORD,outputPtr:PTR BYTE,outputCapacity:DWORD,subkeysPtr:PTR BYTE,outputLengthPtr:PTR DWORD
    mov esi,inputPtr
    mov edi,outputPtr
    mov edx,outputLengthPtr
    test esi,esi
    jz ebe_bad
    test edi,edi
    jz ebe_bad
    test edx,edx
    jz ebe_bad
    mov DWORD PTR [edx],0
    mov eax,inputLength
    xor edx,edx
    mov ecx,8
    div ecx
    inc eax
    shl eax,3
    mov ecx,eax                    ; padded length
    cmp outputCapacity,ecx
    jb ebe_small
    mov ebx,ecx
    sub ebx,inputLength            ; padding byte
    xor edx,edx                    ; absolute offset
ebe_block_loop:
    cmp edx,ecx
    jae ebe_done_blocks
    push ecx
    xor ecx,ecx
ebe_fill:
    cmp ecx,8
    jae ebe_encrypt
    mov eax,edx
    add eax,ecx
    cmp eax,inputLength
    jae ebe_pad
    mov al,[esi+eax]
    jmp ebe_store
ebe_pad:
    mov eax,ebx
ebe_store:
    mov ecbBlock[ecx],al
    inc ecx
    jmp ebe_fill
ebe_encrypt:
    push edx
    add edi,edx
    INVOKE EncryptDESBlock,ADDR ecbBlock,edi,subkeysPtr
    sub edi,edx
    pop edx
    pop ecx
    test eax,eax
    jnz ebe_return
    add edx,8
    jmp ebe_block_loop
ebe_done_blocks:
    mov eax,outputLengthPtr
    mov [eax],ecx
    xor eax,eax
ebe_return:
    ret
ebe_small:
    mov eax,ERR_BUFFER
    ret
ebe_bad:
    mov eax,ERR_PARAM
    ret
EncryptBufferECB ENDP

DecryptBufferECB PROC USES ebx esi edi ecx edx,inputPtr:PTR BYTE,inputLength:DWORD,outputPtr:PTR BYTE,outputCapacity:DWORD,subkeysPtr:PTR BYTE,outputLengthPtr:PTR DWORD
    mov esi,inputPtr
    mov edi,outputPtr
    mov edx,outputLengthPtr
    test esi,esi
    jz dbe_bad
    test edi,edi
    jz dbe_bad
    test edx,edx
    jz dbe_bad
    mov DWORD PTR [edx],0
    mov eax,inputLength
    test eax,eax
    jz dbe_length
    test eax,7
    jnz dbe_length
    cmp outputCapacity,eax
    jb dbe_small
    xor ebx,ebx
dbe_loop:
    cmp ebx,inputLength
    jae dbe_padding
    mov eax,esi
    add eax,ebx
    mov edx,edi
    add edx,ebx
    INVOKE DecryptDESBlock,eax,edx,subkeysPtr
    test eax,eax
    jnz dbe_return
    add ebx,8
    jmp dbe_loop
dbe_padding:
    mov ecx,inputLength
    movzx eax,BYTE PTR [edi+ecx-1]
    cmp eax,1
    jb dbe_pad_error
    cmp eax,8
    ja dbe_pad_error
    mov edx,eax                    ; padding count
    mov ebx,ecx
    sub ebx,edx                    ; plaintext length
dbe_pad_loop:
    cmp edx,0
    je dbe_pad_ok
    dec ecx
    cmp BYTE PTR [edi+ecx],al
    jne dbe_pad_error
    dec edx
    jmp dbe_pad_loop
dbe_pad_ok:
    mov eax,outputLengthPtr
    mov [eax],ebx
    xor eax,eax
dbe_return:
    ret
dbe_length:
    mov eax,ERR_CIPHER_LENGTH
    ret
dbe_small:
    mov eax,ERR_BUFFER
    ret
dbe_pad_error:
    mov eax,ERR_PADDING
    ret
dbe_bad:
    mov eax,ERR_PARAM
    ret
DecryptBufferECB ENDP

ApplyInitialPermutation PROC USES ebx ecx edx esi edi,inputPtr:PTR BYTE,blockPtr:PTR BYTE
    INVOKE PermuteBits,inputPtr,blockPtr,ADDR ipTable,64
    ret
ApplyInitialPermutation ENDP
ApplyInversePermutation PROC USES ebx ecx edx esi edi,blockPtr:PTR BYTE,outputPtr:PTR BYTE
    INVOKE PermuteBits,blockPtr,outputPtr,ADDR inverseIpTable,64
    ret
ApplyInversePermutation ENDP

RunFeistelRounds PROC USES ebx esi edi ecx edx,blockPtr:PTR BYTE,subkeysPtr:PTR BYTE,cipherMode:DWORD
    mov esi,blockPtr
    mov edi,subkeysPtr
    test esi,esi
    jz rfr_bad
    test edi,edi
    jz rfr_bad
    INVOKE ReadBE32,esi
    mov roundLeft,eax
    add esi,4
    INVOKE ReadBE32,esi
    mov roundRight,eax
    xor ebx,ebx
rfr_loop:
    cmp ebx,16
    jae rfr_finish
    mov eax,cipherMode
    cmp eax,MODE_DECRYPT
    je rfr_reverse_key
    mov eax,ebx
    jmp rfr_key_ready
rfr_reverse_key:
    mov eax,15
    sub eax,ebx
rfr_key_ready:
    imul eax,6
    add eax,edi
    INVOKE FeistelFunction,roundRight,eax
    mov edx,roundLeft
    xor edx,eax
    mov eax,roundRight
    mov roundLeft,eax
    mov roundRight,edx
    inc ebx
    jmp rfr_loop
rfr_finish:
    mov esi,blockPtr
    INVOKE WriteBE32,roundRight,esi
    add esi,4
    INVOKE WriteBE32,roundLeft,esi
    xor eax,eax
    ret
rfr_bad:
    mov eax,ERR_PARAM
    ret
RunFeistelRounds ENDP

FeistelFunction PROC USES ebx esi ecx edx,rightHalfValue:DWORD,subkeyPtr:PTR BYTE
    INVOKE ExpandRightHalf,rightHalfValue,ADDR expandedBuffer
    test eax,eax
    jnz ff_done
    mov esi,subkeyPtr
    xor ecx,ecx
ff_xor:
    cmp ecx,6
    jae ff_sboxes
    mov al,[esi+ecx]
    xor expandedBuffer[ecx],al
    inc ecx
    jmp ff_xor
ff_sboxes:
    INVOKE ApplySBoxes,ADDR expandedBuffer
    INVOKE ApplyPPermutation,eax
ff_done:
    ret
FeistelFunction ENDP

ExpandRightHalf PROC USES ebx ecx edx esi edi,rightHalfValue:DWORD,expandedPtr:PTR BYTE
    INVOKE WriteBE32,rightHalfValue,ADDR rightBytes
    INVOKE PermuteBits,ADDR rightBytes,expandedPtr,ADDR expansionTable,48
    ret
ExpandRightHalf ENDP

ApplySBoxes PROC USES ebx esi edi ecx edx,expandedPtr:PTR BYTE
    mov esi,expandedPtr
    test esi,esi
    jz asb_bad
    mov sboxCombined,0
    xor ebx,ebx
asb_box:
    cmp ebx,8
    jae asb_done
    xor edx,edx                    ; six-bit value
    xor ecx,ecx
asb_six_bits:
    cmp ecx,6
    jae asb_lookup
    shl edx,1
    mov eax,ebx
    imul eax,6
    add eax,ecx
    inc eax
    INVOKE GetFipsBitC,esi,eax
    or edx,eax
    inc ecx
    jmp asb_six_bits
asb_lookup:
    mov eax,edx
    and eax,1
    mov ecx,edx
    and ecx,20h
    shr ecx,4
    or eax,ecx                    ; row
    shl eax,4
    mov ecx,edx
    shr ecx,1
    and ecx,0Fh                   ; column
    add eax,ecx
    mov ecx,ebx
    shl ecx,6
    add eax,ecx
    movzx eax,BYTE PTR sBoxTable[eax]
    mov edx,sboxCombined
    shl edx,4
    or edx,eax
    mov sboxCombined,edx
    inc ebx
    jmp asb_box
asb_done:
    mov eax,sboxCombined
    ret
asb_bad:
    xor eax,eax
    ret
ApplySBoxes ENDP

ApplyPPermutation PROC USES ebx ecx edx esi edi,inputValue:DWORD
    INVOKE WriteBE32,inputValue,ADDR pInputBytes
    INVOKE PermuteBits,ADDR pInputBytes,ADDR pOutputBytes,ADDR pTable,32
    INVOKE ReadBE32,ADDR pOutputBytes
    ret
ApplyPPermutation ENDP

PermuteBits PROC USES ebx esi edi ecx edx,sourcePtr:PTR BYTE,destPtr:PTR BYTE,tablePtr:PTR BYTE,bitCount:DWORD
    mov esi,sourcePtr
    mov edi,destPtr
    test esi,esi
    jz pb_bad
    test edi,edi
    jz pb_bad
    mov eax,tablePtr
    test eax,eax
    jz pb_bad
    mov ecx,bitCount
    add ecx,7
    shr ecx,3
    push edi
    xor eax,eax
    cld
    rep stosb
    pop edi
    xor ebx,ebx
pb_loop:
    cmp ebx,bitCount
    jae pb_ok
    mov edx,tablePtr
    movzx eax,BYTE PTR [edx+ebx]
    INVOKE GetFipsBitC,esi,eax
    test eax,eax
    jz pb_next
    mov edx,ebx
    shr edx,3
    mov ecx,ebx
    and ecx,7
    mov al,80h
    shr al,cl
    or BYTE PTR [edi+edx],al
pb_next:
    inc ebx
    jmp pb_loop
pb_ok:
    xor eax,eax
    ret
pb_bad:
    mov eax,ERR_PARAM
    ret
PermuteBits ENDP

GetFipsBitC PROC USES ebx ecx edx esi,sourcePtr:PTR BYTE,bitPosition:DWORD
    mov esi,sourcePtr
    mov eax,bitPosition
    dec eax
    xor edx,edx
    mov ebx,8
    div ebx
    movzx eax,BYTE PTR [esi+eax]
    mov ecx,7
    sub ecx,edx
    shr eax,cl
    and eax,1
    ret
GetFipsBitC ENDP

ReadBE32 PROC USES ebx ecx edx esi edi,sourcePtr:PTR BYTE
    mov esi,sourcePtr
    movzx eax,BYTE PTR [esi]
    shl eax,8
    mov al,[esi+1]
    shl eax,8
    mov al,[esi+2]
    shl eax,8
    mov al,[esi+3]
    ret
ReadBE32 ENDP

WriteBE32 PROC USES ebx ecx edx esi edi,value:DWORD,destPtr:PTR BYTE
    mov edi,destPtr
    mov eax,value
    mov [edi+3],al
    shr eax,8
    mov [edi+2],al
    shr eax,8
    mov [edi+1],al
    shr eax,8
    mov [edi],al
    xor eax,eax
    ret
WriteBE32 ENDP
END
