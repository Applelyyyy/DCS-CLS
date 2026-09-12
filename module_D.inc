; =============================================================================
; Module D - Memory Dumper & Buffer Analytics
; Owner: YOUR_NAME (YOUR_STUDENT_ID)
; =============================================================================
;
; Responsibilities:
;   - Hex dump: 16 bytes per row with offset, hexadecimal and ASCII columns
;   - Display bytes outside 20h-7Eh as '.'
;   - Histogram with 256 bins
;   - Display the most frequent byte patterns
;
; Public procedure declarations. Implementation belongs in module_D.asm.
; The first two names are required explicitly by the assignment PDF.

DisplayHexDump        PROTO :PTR BYTE, :DWORD
ComputeBufferStats    PROTO :PTR BYTE, :DWORD, :PTR DWORD
DisplayTopOccurrences PROTO :PTR DWORD, :DWORD
;
; IMPORTANT: DisplayHexDump and ComputeBufferStats are the exact procedure names
; required by the assignment PDF. The other names are proposed by this template.
;
; IsPrintableASCII is private to module_D.asm and is not exported here.
