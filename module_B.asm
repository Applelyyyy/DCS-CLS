; DES Key Schedule - FIPS positions are 1-based and MSB-first.
option casemap:none
INCLUDE Irvine32.inc
INCLUDE module_B.inc
PUBLIC GenerateKeySchedule, DisplayKeySchedule
GetFipsBitB PROTO :PTR BYTE, :DWORD
ApplyPC1 PROTO :PTR BYTE, :PTR BYTE
RotateKeyHalves PROTO :PTR BYTE, :DWORD
ApplyPC2 PROTO :PTR BYTE, :PTR BYTE

.data
pc1Table BYTE 57,49,41,33,25,17,9,1,58,50,42,34,26,18
         BYTE 10,2,59,51,43,35,27,19,11,3,60,52,44,36
         BYTE 63,55,47,39,31,23,15,7,62,54,46,38,30,22
         BYTE 14,6,61,53,45,37,29,21,13,5,28,20,12,4
pc2Table BYTE 14,17,11,24,1,5,3,28,15,6,21,10
         BYTE 23,19,12,4,26,8,16,7,27,20,13,2
         BYTE 41,52,31,37,47,55,30,40,51,45,33,48
         BYTE 44,49,39,56,34,53,46,42,50,36,29,32
keyShiftSchedule BYTE 1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1
keyLabel BYTE "K",0
keySeparator BYTE ": ",0
.data?
keyHalves DWORD 2 DUP(?)

.code
GenerateKeySchedule PROC USES ebx ecx edx esi edi, keyPtr:PTR BYTE, subkeysPtr:PTR BYTE
    mov esi,keyPtr
    test esi,esi
    jz gks_bad
    mov edi,subkeysPtr
    test edi,edi
    jz gks_bad
    INVOKE ApplyPC1,esi,ADDR keyHalves
    test eax,eax
    jnz gks_done
    xor ebx,ebx
gks_loop:
    cmp ebx,16
    jae gks_ok
    movzx eax,BYTE PTR keyShiftSchedule[ebx]
    INVOKE RotateKeyHalves,ADDR keyHalves,eax
    test eax,eax
    jnz gks_done
    INVOKE ApplyPC2,ADDR keyHalves,edi
    test eax,eax
    jnz gks_done
    add edi,6
    inc ebx
    jmp gks_loop
gks_ok:
    xor eax,eax
    jmp gks_done
gks_bad:
    mov eax,16
gks_done:
    ret
GenerateKeySchedule ENDP

DisplayKeySchedule PROC USES ebx ecx edx esi edi, subkeysPtr:PTR BYTE
    mov esi,subkeysPtr
    test esi,esi
    jz dks_bad
    xor ebx,ebx
dks_round:
    cmp ebx,16
    jae dks_ok
    mov edx,OFFSET keyLabel
    call WriteString
    mov eax,ebx
    inc eax
    cmp eax,10
    jae dks_number
    push eax
    mov al,'0'
    call WriteChar
    pop eax
dks_number:
    call WriteDec
    mov edx,OFFSET keySeparator
    call WriteString
    xor ecx,ecx
dks_byte:
    cmp ecx,6
    jae dks_line
    movzx eax,BYTE PTR [esi+ecx]
    push ebx
    mov ebx,1
    call WriteHexB
    pop ebx
    inc ecx
    jmp dks_byte
dks_line:
    call Crlf
    add esi,6
    inc ebx
    jmp dks_round
dks_ok:
    xor eax,eax
    ret
dks_bad:
    mov eax,16
    ret
DisplayKeySchedule ENDP

ApplyPC1 PROC USES ebx ecx edx esi edi, keyPtr:PTR BYTE, halvesPtr:PTR BYTE
    mov esi,keyPtr
    mov edi,halvesPtr
    test esi,esi
    jz pc1_bad
    test edi,edi
    jz pc1_bad
    xor ebx,ebx
    xor edx,edx
pc1_c:
    cmp edx,28
    jae pc1_c_done
    shl ebx,1
    movzx eax,BYTE PTR pc1Table[edx]
    INVOKE GetFipsBitB,esi,eax
    or ebx,eax
    inc edx
    jmp pc1_c
pc1_c_done:
    mov [edi],ebx
    xor ebx,ebx
pc1_d:
    cmp edx,56
    jae pc1_ok
    shl ebx,1
    movzx eax,BYTE PTR pc1Table[edx]
    INVOKE GetFipsBitB,esi,eax
    or ebx,eax
    inc edx
    jmp pc1_d
pc1_ok:
    mov [edi+4],ebx
    xor eax,eax
    ret
pc1_bad:
    mov eax,16
    ret
ApplyPC1 ENDP

RotateKeyHalves PROC USES ebx ecx edx esi edi, halvesPtr:PTR BYTE, shiftCount:DWORD
    mov esi,halvesPtr
    test esi,esi
    jz rkh_bad
    mov ecx,shiftCount
    cmp ecx,1
    je rkh_first
    cmp ecx,2
    jne rkh_bad
rkh_first:
    mov ebx,[esi]
    mov edx,ebx
    shl ebx,cl
    and ebx,0FFFFFFFh
    mov eax,28
    sub eax,ecx
    push ecx
    mov ecx,eax
    shr edx,cl
    pop ecx
    or ebx,edx
    and ebx,0FFFFFFFh
    mov [esi],ebx
    mov ebx,[esi+4]
    mov edx,ebx
    shl ebx,cl
    and ebx,0FFFFFFFh
    mov eax,28
    sub eax,ecx
    push ecx
    mov ecx,eax
    shr edx,cl
    pop ecx
    or ebx,edx
    and ebx,0FFFFFFFh
    mov [esi+4],ebx
    xor eax,eax
    ret
rkh_bad:
    mov eax,16
    ret
RotateKeyHalves ENDP

ApplyPC2 PROC USES ebx ecx edx esi edi, halvesPtr:PTR BYTE, subkeyPtr:PTR BYTE
    mov esi,halvesPtr
    mov edi,subkeyPtr
    test esi,esi
    jz pc2_bad
    test edi,edi
    jz pc2_bad
    xor edx,edx
    xor ecx,ecx
pc2_byte:
    cmp ecx,6
    jae pc2_ok
    xor ebx,ebx
    push ecx
    mov ecx,8
pc2_bit:
    shl ebx,1
    movzx eax,BYTE PTR pc2Table[edx]
    cmp eax,28
    ja pc2_d
    push ecx
    mov ecx,28
    sub ecx,eax
    mov eax,[esi]
    shr eax,cl
    pop ecx
    and eax,1
    jmp pc2_add
pc2_d:
    sub eax,28
    push ecx
    mov ecx,28
    sub ecx,eax
    mov eax,[esi+4]
    shr eax,cl
    pop ecx
    and eax,1
pc2_add:
    or ebx,eax
    inc edx
    dec ecx
    jnz pc2_bit
    pop ecx
    mov [edi+ecx],bl
    inc ecx
    jmp pc2_byte
pc2_ok:
    xor eax,eax
    ret
pc2_bad:
    mov eax,16
    ret
ApplyPC2 ENDP

GetFipsBitB PROC USES ebx ecx edx esi edi, sourcePtr:PTR BYTE, bitPosition:DWORD
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
GetFipsBitB ENDP
END
