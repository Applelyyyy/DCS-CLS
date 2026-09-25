DCS-CLS - Command-Line Shell & File Encryption Engine (Classical DES)
01476105 Computer Organization and Assembly Language

TEAM MEMBERS AND RESPONSIBILITIES

68010321  Nutthawat Charoensiriphong  Module A - Shell Core, FSM Parser, validation, and File I/O
68011000  Warithnan Baibua            Module B - DES Key Schedule Generator
68010697  Panabordee Panitchakit      Module C - DES Feistel Core, ECB mode, and PKCS#7 padding
68010713  Punnawit Khamthorn          Module D - Hex Dump and byte-frequency statistics

BUILD

1. Open x86 Native Tools Command Prompt for VS.
2. Confirm Irvine32 is installed at C:\Irvine.
3. Change to the project directory.
4. Run: build.bat

AUTOMATED TESTS

Run: test.bat

NOTES

- DES is implemented for coursework only and is not suitable for production security.
- ENCRYPT/DECRYPT accept an optional output path. If omitted, the program appends
  .enc or .dec to the input path.
