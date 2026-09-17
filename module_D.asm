; =============================================================================
; Module D implementation - Memory Dumper & Buffer Analytics
; Owner: Punnawit Khamthorn (68010713)
; =============================================================================

.386
.model flat, stdcall
option casemap:none

INCLUDE module_D.inc

PUBLIC DisplayHexDump, ComputeBufferStats, DisplayTopOccurrences

; ========================= MODULE D DATA BEGIN HERE ============================

.data?
histogramBins          DWORD 256 DUP(?)
dumpOffset             DWORD ?
rowByteCount           DWORD ?
currentByte            BYTE ?
topOccurrenceCount     DWORD ?
hexHeaderTextPtr       DWORD ?
hexDigitTablePtr       DWORD ?
nonPrintableSymbol     BYTE ?

; ========================== MODULE D DATA END HERE =============================

; ======================== MODULE D LOGIC BEGIN HERE ============================

.code
DisplayHexDump PROC bufferPtr:PTR BYTE, dataLength:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
DisplayHexDump ENDP

ComputeBufferStats PROC bufferPtr:PTR BYTE, dataLength:DWORD, histogramPtr:PTR DWORD
    push esi
    push edi
    push ecx
    push ebx

    mov esi, bufferPtr      ; ESI ชี้ไปที่ข้อมูลต้นทาง
    mov ecx, dataLength     ; ECX ใช้เป็นตัวนับรอบลูปตามความยาวข้อมูล
    mov edi, histogramPtr   ; EDI ชี้ไปที่ตาราง Histogram

    test ecx, ecx           ; เช็คว่า length เป็น 0 หรือไม่
    jz EndCompute           ; ถ้าเป็น 0 ให้ออกเลย

ComputeLoop:
    xor eax, eax            ; เคลียร์ EAX ให้เป็น 0 ก่อน
    mov al, byte ptr [esi]  ; อ่านข้อมูลมา 1 ไบต์ใส่ AL
    
    ; เพิ่มค่าความถี่ในตาราง: histogramPtr[eax * 4]++ 
    ; (คูณ 4 เพราะแต่ละช่องมีขนาด DWORD = 4 bytes)
    inc dword ptr [edi + eax * 4]
    
    inc esi                 ; ขยับ Pointer ไปไบต์ถัดไป
    dec ecx                 ; ลดจำนวนรอบลง 1
    jnz ComputeLoop         ; ถ้า ECX ยังไม่เป็น 0 ให้วนต่อ

EndCompute:
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
ComputeBufferStats ENDP

DisplayTopOccurrences PROC histogramPtr:PTR DWORD, topCount:DWORD
    ; YOUR CODE BEGIN HERE
    ; YOUR CODE END HERE
DisplayTopOccurrences ENDP

IsPrintableASCII PROC byteValue:DWORD
    mov eax, byteValue      ; นำค่าที่ส่งมาเก็บใน EAX
    
    cmp al, 20h             ; เทียบกับ 20h (Space)
    jb NotPrintable         ; ถ้าต่ำกว่า (Jump if Below) แสดงว่าพิมพ์ไม่ได้
    
    cmp al, 7Eh             ; เทียบกับ 7Eh (~)
    ja NotPrintable         ; ถ้าสูงกว่า (Jump if Above) แสดงว่าพิมพ์ไม่ได้
    
    mov eax, 1              ; อยู่ในช่วง 20h - 7Eh ให้ Return 1
    ret
    
NotPrintable:
    xor eax, eax            ; เซ็ต EAX = 0 (Return 0)
    ret
IsPrintableASCII ENDP

; ========================= MODULE D LOGIC END HERE =============================

END
