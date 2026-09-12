# DCS-CLS

Command-Line Shell & File Encryption Engine (Classical DES)

[Read in English](README.md)

โครงงาน x86 Assembly (32-bit Protected Mode, MASM) สำหรับแบ่งงานเป็น 4 โมดูล
ตามเอกสาร `2026s1 Assembly Assignment` และใช้อัลกอริทึม DES ตาม FIPS 46-3


## File structure

```text
DCS-CLS/
|-- DES_Shell.asm       # Main/entry point; เรียกใช้โมดูลผ่าน public interface
|-- module_A.inc        # Public PROTO ของ Module A
|-- module_A.asm        # Logic: Shell Core, FSM parser และ File I/O
|-- module_B.inc        # Public PROTO ของ Module B
|-- module_B.asm        # Logic: DES Key Schedule Generator
|-- module_C.inc        # Public PROTO ของ Module C
|-- module_C.asm        # Logic: DES Feistel Core, ECB และ PKCS#7
|-- module_D.inc        # Public PROTO ของ Module D
|-- module_D.asm        # Logic: Hex dump และ buffer statistics
|-- build.bat           # Assemble, link และ run ด้วย Visual Studio tools
|-- README.md           # เอกสารหลักภาษาอังกฤษ
|-- README.th.md        # เอกสารฉบับแปลภาษาไทย
|-- LICENSE
```

ไฟล์ `.inc` เป็น header/interface และมี `PROTO` ที่ caller ใช้ตรวจ parameter
ส่วน implementation อยู่ใน `.asm` ของแต่ละโมดูล `DES_Shell.asm` include เฉพาะ
interface และไม่ได้รวม logic ของ Module A-D ไว้ในไฟล์เดียว ระหว่าง build นั้น MASM
จะ assemble `.asm` แต่ละไฟล์เป็น `.obj` แล้ว linker จึงรวมทั้งหมดเป็น executable เดียว

ชื่อ procedure ใน template คือข้อตกลงกลางของทีม หากจะเปลี่ยนชื่อหรือ parameter
ต้องแก้ทั้ง caller, callee และตาราง interface ใน README พร้อมกัน

### สถานะชื่อ procedure จากเอกสารโจทย์

- **ชื่อที่โจทย์กำหนดโดยตรง:** `DisplayHexDump`, `ComputeBufferStats`
- **ชื่อที่ template เสนอเพื่อแบ่ง interface:** procedure อื่นทั้งหมดในตารางด้านล่าง

เอกสารโจทย์กำหนดหน้าที่ของ Module A, B และ C แต่ไม่ได้บังคับชื่อ procedure
ของสามโมดูลนี้ ชื่อที่เสนอจึงเปลี่ยนได้เมื่อทีมตกลงร่วมกัน ส่วนสองชื่อใน Module D
ควรคงไว้ตามตัวสะกดและตัวพิมพ์ที่แสดงใน PDF

## Module ownership

### Module A - Shell Core & FSM Command Parser (6 คะแนน)

ไฟล์: `module_A.inc`

รับผิดชอบ REPL, FSM parser, validation และ File I/O สำหรับคำสั่ง:
`KEYGEN`, `ENCRYPT`, `DECRYPT`, `DUMP`, `STATS`, `CLEAR`, `EXIT`

Procedure contracts:

| Procedure | หน้าที่ | เรียกใช้ Module |
|---|---|---|
| `ShellMain` | ลูปหลักของโปรแกรม | B, C, D |
| `ReadCommandLine` | อ่าน command line เข้า input buffer | - |
| `ParseCommandFSM` | แยก command, filename และ key | - |
| `ValidateCommand` | ตรวจ syntax และจำนวน argument | - |
| `DispatchCommand` | ส่งคำสั่งไป procedure ที่เกี่ยวข้อง | B, C, D |
| `ReadWholeFile` | เปิดและอ่านไฟล์เข้า buffer | - |
| `WriteWholeFile` | เขียน buffer ลงไฟล์ | - |
| `PrintShellError` | แสดง error โดย REPL ไม่ crash | - |

### Module B - DES Key Schedule Generator (4 คะแนน)

ไฟล์: `module_B.inc`

รับผิดชอบ key 64 bits, PC-1, การหมุน C/D ขนาด 28 bits ตามรอบ และ PC-2
เพื่อสร้าง subkeys ขนาด 48 bits จำนวน 16 ชุด

Procedure contracts:

| Procedure | หน้าที่ | ผู้เรียกใช้ |
|---|---|---|
| `GenerateKeySchedule` | สร้าง subkeys K1-K16 | A, C |
| `ApplyPC1` | 64-bit key เป็น C0/D0 รวม 56 bits | `GenerateKeySchedule` |
| `RotateKeyHalves` | left circular rotation 1 หรือ 2 bits | `GenerateKeySchedule` |
| `ApplyPC2` | Cn/Dn เป็น subkey 48 bits | `GenerateKeySchedule` |
| `DisplayKeySchedule` | แสดง K1-K16 สำหรับ `KEYGEN` | A |

ตาราง shift ต้องเป็น `1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1`
ตาม FIPS 46-3

### Module C - DES 16-Round Feistel Core Engine (6 คะแนน)

ไฟล์: `module_C.inc`

รับผิดชอบ IP, 16 Feistel rounds, E expansion, XOR subkey, S-box, P permutation,
IP inverse, ECB file processing และ PKCS#7 padding

Procedure contracts:

| Procedure | หน้าที่ | เรียกใช้ Module |
|---|---|---|
| `EncryptBufferECB` | เข้ารหัส buffer แบบ ECB พร้อม padding | B |
| `DecryptBufferECB` | ถอดรหัส ECB และตรวจ/นำ padding ออก | B |
| `EncryptDESBlock` | เข้ารหัสข้อมูล 64-bit หนึ่ง block | - |
| `DecryptDESBlock` | ถอดรหัสข้อมูล 64-bit หนึ่ง block | - |
| `ApplyInitialPermutation` | ทำ IP | - |
| `RunFeistelRounds` | ทำ 16 rounds; เลือกลำดับ key ตาม mode | - |
| `FeistelFunction` | คำนวณ f(R, K) | - |
| `ExpandRightHalf` | E expansion 32 เป็น 48 bits | - |
| `ApplySBoxes` | 8 กลุ่ม กลุ่มละ 6 bits เป็น 32 bits | - |
| `ApplyPPermutation` | ทำ P permutation | - |
| `ApplyInversePermutation` | ทำ IP inverse | - |
| `AddPKCS7Padding` | เติม padding ขนาด block 8 bytes | - |
| `RemovePKCS7Padding` | ตรวจและนำ padding ออก | - |

การ decrypt ใช้ core เดิมแต่เรียก subkeys จาก K16 ย้อนกลับถึง K1

### Module D - Memory Dumper & Buffer Analytics (4 คะแนน)

ไฟล์: `module_D.inc`

รับผิดชอบ dump 16 bytes ต่อบรรทัด พร้อม offset, hex, ASCII และ histogram 256 bins

Procedure contracts:

| Procedure | หน้าที่ | ผู้เรียกใช้ |
|---|---|---|
| `DisplayHexDump` | แสดง offset, hex และ ASCII | A |
| `ComputeBufferStats` | นับความถี่ byte 00h-FFh | A |
| `DisplayTopOccurrences` | แสดง byte pattern ที่พบบ่อยที่สุด | A |
| `IsPrintableASCII` | ตรวจช่วง 20h-7Eh | `DisplayHexDump` |

## Shared procedure convention

- ใช้ stack frame: `push ebp`, `mov ebp, esp` และคืน frame ก่อน return
- Callee ต้องรักษา register ของ caller ตาม contract ที่ทีมกำหนด
- ค่าส่งคืนหลักส่งผ่าน `EAX`; ให้ใช้ `EAX = 0` เมื่อสำเร็จและค่าที่ไม่เป็นศูนย์เมื่อผิดพลาด
- Pointer และ length ส่งผ่าน stack โดยระบุลำดับใน comment เหนือทุก procedure
- ห้ามใช้ `.IF`, `.WHILE`, `.REPEAT` ใน parser loop และ cipher loop
- DES/key schedule ต้องเขียนเอง ห้ามใช้ external encryption library
- File I/O ใช้ Win32 API หรือ Irvine32 procedures ตามที่โจทย์อนุญาต

ก่อนเริ่ม implementation ให้ทีมตกลง buffer ownership, maximum file size,
error codes และว่า procedure ใดเป็นผู้จอง/คืน memory ให้ชัดเจน

## Variable placeholders

ตัวแปรถูกประกาศจริงไว้ใน `.data?` ของ `DES_Shell.asm` และ `module_X.asm` โดยใช้
เครื่องหมาย `?` ซึ่งหมายถึงยังไม่มีค่าเริ่มต้นและรอผู้พัฒนาเติมหรือกำหนดระหว่างทำงาน
ไม่มี declaration ตัวแปรที่ถูก comment ไว้ใน `.inc`; ไฟล์ `.inc` เก็บ public `PROTO`
เท่านั้น สมาชิกเจ้าของโมดูลต้อง:

1. เติมค่าตาราง DES ตาม FIPS 46-3 และย้ายตารางที่มีค่าแล้วจาก `.data?` ไป `.data`
2. กำหนด pointer, buffer allocation และข้อความที่ Module A/main ต้องใช้
3. ตรวจว่าตัวแปรอยู่ใน `.data` หรือ `.data?` ที่เหมาะสม
4. แจ้งทีมเมื่อเปลี่ยนชื่อ shared variable หรือขนาด buffer

ค่าที่โจทย์กำหนดตายตัว เช่น DES block 8 bytes, 16 subkeys และ histogram 256 bins
ถูกระบุไว้ใน comment contract แล้ว แต่ยังเว้นการประกาศ storage ให้ผู้พัฒนาเติมเอง

## Build and run

1. เปิด **x86 Native Tools Command Prompt for VS**
2. ตรวจว่า Irvine32 อยู่ที่ `C:\Irvine` หรือแก้ `IRVINE_DIR` ใน `build.bat`
3. เข้าโฟลเดอร์ repository
4. รัน:

```bat
build.bat
```

คำสั่งหลักที่ script ใช้คือ:

```bat
ml -Zi -c -Fl -coff DES_Shell.asm module_A.asm module_B.asm module_C.asm module_D.asm
link /SUBSYSTEM:CONSOLE /LIBPATH:"C:\Irvine" /OPT:NOREF /OPT:NOICF /DEBUG /NOLOGO /OUT:DES_Shell.exe DES_Shell.obj module_A.obj module_B.obj module_C.obj module_D.obj
```

หากใช้ `INCLUDE Irvine32.inc` และเรียก Irvine32 procedures อาจต้องเพิ่ม
`Irvine32.lib`, `kernel32.lib` และ `user32.lib` ใน link command ตามการตั้งค่าเครื่อง

## Contribution workflow

หนึ่งคนรับหนึ่งโมดูล และสร้าง branch จาก branch หลักล่าสุด ห้ามทุกคนแก้
`DES_Shell.asm` พร้อมกันเพราะจะเกิด merge conflict ง่าย

```bat
git switch main
git pull
git switch -c module-a-shell
```

ชื่อ branch ที่แนะนำ:

- `module-a-shell`
- `module-b-key-schedule`
- `module-c-feistel-core`
- `module-d-dump-stats`

ให้แต่ละคนเขียน logic ใน `module_X.asm` ของตน ส่วน `.inc` แก้เฉพาะเมื่อ public
interface เปลี่ยน จากนั้น:

```bat
git status
git add module_A.asm module_A.inc
git commit -m "Implement module A shell and parser"
git push -u origin module-a-shell
```

เปิด Pull Request เข้า `main` และให้สมาชิกอย่างน้อยหนึ่งคน review โดยตรวจว่า:

- ชื่อ procedure และ parameter ตรงกับ contract
- รักษา registers และ stack balance ถูกต้อง
- ไม่มี directive ที่โจทย์ห้ามใน parser/cipher loops
- ไม่มี external encryption library
- build ผ่านและไม่สร้างไฟล์ generated เข้า Git โดยไม่จำเป็น

ผู้ดูแล integration ค่อยแก้ `DES_Shell.asm`, รวม branch ทีละโมดูล และแก้ conflict
โดยไม่เขียนทับ implementation ของเจ้าของโมดูล

## Integration order

1. Module B สร้างและตรวจ key schedule
2. Module C เชื่อม B แล้วทดสอบ DES block
3. Module D ทดสอบ dump และ histogram แยกได้
4. Module A เชื่อมทุก module เข้ากับ REPL และ File I/O
5. ทดสอบ end-to-end และ error paths

Official DES test vector ที่โจทย์กำหนด:

```text
Plaintext:          0123456789ABCDEF
Key:                133457799BBCDFF1
Expected ciphertext:85E813540F0AB405
```

## Submission checklist

- โปรแกรมทำงานบน Windows 10/11 และ REPL ทำงานจนถึง `EXIT`
- รองรับครบทั้ง 7 commands และ invalid input ไม่ทำให้โปรแกรม crash
- Encryption/decryption, ECB และ PKCS#7 ถูกต้อง
- DUMP แสดง non-printable byte เป็น `.` และ STATS มี 256 bins
- ทดสอบ official DES vector ผ่าน
- เติมชื่อ, รหัสนักศึกษา และความรับผิดชอบของสมาชิกด้านล่าง
- ส่ง Assembly source และ `readme.txt` ตามรูปแบบที่ผู้สอนกำหนด

## Team members

| Student ID | Name | Module / responsibility |
|---|---|---|
| `YOUR_ID` | `YOUR_NAME` | Module A |
| `YOUR_ID` | `YOUR_NAME` | Module B |
| `YOUR_ID` | `YOUR_NAME` | Module C |
| `YOUR_ID` | `YOUR_NAME` | Module D |
