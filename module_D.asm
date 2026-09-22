; Hex dump and byte-frequency analytics.
option casemap:none
INCLUDE Irvine32.inc
INCLUDE module_D.inc
PUBLIC DisplayHexDump, ComputeBufferStats, DisplayTopOccurrences
IsPrintableASCII PROTO :DWORD

.data
dumpHeader BYTE "Offset    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  | ASCII",13,10,0
dumpRule BYTE "--------------------------------------------------------------------------",13,10,0
asciiBar BYTE " | ",0
rankText BYTE "Rank ",0
byteText BYTE "  Byte ",0
countText BYTE "  Count ",0
asciiText BYTE "  ASCII ",0
.data?
selectedFlags BYTE 256 DUP(?)

.code
DisplayHexDump PROC USES ebx ecx edx esi edi,bufferPtr:PTR BYTE,dataLength:DWORD
    mov esi,bufferPtr
    test esi,esi
    jz dhd_bad
    mov edx,OFFSET dumpHeader
    call WriteString
    mov edx,OFFSET dumpRule
    call WriteString
    xor ebx,ebx                    ; row offset
dhd_row:
    cmp ebx,dataLength
    jae dhd_ok
    mov eax,ebx
    call WriteHex
    mov al,' '
    call WriteChar
    mov al,' '
    call WriteChar
    xor ecx,ecx
dhd_hex:
    cmp ecx,16
    jae dhd_ascii_start
    mov eax,ebx
    add eax,ecx
    cmp eax,dataLength
    jae dhd_hex_blank
    movzx eax,BYTE PTR [esi+eax]
    push ebx
    mov ebx,1
    call WriteHexB
    pop ebx
    mov al,' '
    call WriteChar
    jmp dhd_hex_next
dhd_hex_blank:
    mov al,' '
    call WriteChar
    call WriteChar
    call WriteChar
dhd_hex_next:
    inc ecx
    jmp dhd_hex
dhd_ascii_start:
    mov edx,OFFSET asciiBar
    call WriteString
    xor ecx,ecx
dhd_ascii:
    cmp ecx,16
    jae dhd_line_end
    mov eax,ebx
    add eax,ecx
    cmp eax,dataLength
    jae dhd_ascii_blank
    movzx eax,BYTE PTR [esi+eax]
    push eax
    INVOKE IsPrintableASCII,eax
    cmp eax,1
    pop eax
    jne dhd_ascii_dot
    call WriteChar
    jmp dhd_ascii_next
dhd_ascii_dot:
    mov al,'.'
    call WriteChar
    jmp dhd_ascii_next
dhd_ascii_blank:
    mov al,' '
    call WriteChar
dhd_ascii_next:
    inc ecx
    jmp dhd_ascii
dhd_line_end:
    call Crlf
    add ebx,16
    jmp dhd_row
dhd_ok:
    xor eax,eax
    ret
dhd_bad:
    mov eax,16
    ret
DisplayHexDump ENDP

ComputeBufferStats PROC USES ebx ecx edx esi edi,bufferPtr:PTR BYTE,dataLength:DWORD,histogramPtr:PTR DWORD
    mov esi,bufferPtr
    mov edi,histogramPtr
    test esi,esi
    jz cbs_bad
    test edi,edi
    jz cbs_bad
    push edi
    xor eax,eax
    mov ecx,256
    cld
    rep stosd
    pop edi
    xor ecx,ecx
cbs_loop:
    cmp ecx,dataLength
    jae cbs_ok
    movzx eax,BYTE PTR [esi+ecx]
    inc DWORD PTR [edi+eax*4]
    inc ecx
    jmp cbs_loop
cbs_ok:
    xor eax,eax
    ret
cbs_bad:
    mov eax,16
    ret
ComputeBufferStats ENDP

DisplayTopOccurrences PROC USES ebx ecx edx esi edi,histogramPtr:PTR DWORD,topCount:DWORD
    mov esi,histogramPtr
    test esi,esi
    jz dto_bad
    lea edi,selectedFlags
    push edi
    xor eax,eax
    mov ecx,256
    cld
    rep stosb
    pop edi
    xor ebx,ebx                    ; rank index
dto_rank:
    cmp ebx,topCount
    jae dto_ok
    xor ecx,ecx                    ; byte candidate
    xor edx,edx                    ; maximum count
    mov eax,0FFFFFFFFh             ; selected byte
dto_scan:
    cmp ecx,256
    jae dto_scan_done
    cmp BYTE PTR [edi+ecx],0
    jne dto_next
    cmp DWORD PTR [esi+ecx*4],edx
    jbe dto_next
    mov edx,[esi+ecx*4]
    mov eax,ecx
dto_next:
    inc ecx
    jmp dto_scan
dto_scan_done:
    test edx,edx
    jz dto_ok
    mov BYTE PTR [edi+eax],1
    push eax                       ; selected byte
    push edx                       ; count
    mov edx,OFFSET rankText
    call WriteString
    mov eax,ebx
    inc eax
    call WriteDec
    mov edx,OFFSET byteText
    call WriteString
    pop edx                        ; count
    pop eax                        ; selected byte
    push eax
    push edx
    push ebx
    mov ebx,1
    call WriteHexB
    pop ebx
    mov edx,OFFSET asciiText
    call WriteString
    pop edx
    pop eax
    push edx
    push eax
    INVOKE IsPrintableASCII,eax
    cmp eax,1
    pop eax
    jne dto_dot
    call WriteChar
    jmp dto_count
dto_dot:
    mov al,'.'
    call WriteChar
dto_count:
    mov edx,OFFSET countText
    call WriteString
    pop eax
    push eax
    call WriteDec
    mov al,' '
    call WriteChar
    mov al,'['
    call WriteChar
    pop ecx
    cmp ecx,50
    jbe dto_bar
    mov ecx,50
dto_bar:
    test ecx,ecx
    jz dto_bar_done
    mov al,'*'
    call WriteChar
    dec ecx
    jmp dto_bar
dto_bar_done:
    mov al,']'
    call WriteChar
    call Crlf
    inc ebx
    jmp dto_rank
dto_ok:
    xor eax,eax
    ret
dto_bad:
    mov eax,16
    ret
DisplayTopOccurrences ENDP

IsPrintableASCII PROC USES ebx ecx edx esi edi,byteValue:DWORD
    mov eax,byteValue
    cmp eax,20h
    jb ipa_no
    cmp eax,7Eh
    ja ipa_no
    mov eax,1
    ret
ipa_no:
    xor eax,eax
    ret
IsPrintableASCII ENDP
END
