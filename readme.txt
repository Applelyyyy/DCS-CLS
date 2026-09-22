DCS-CLS - Command-Line Shell & File Encryption Engine (Classical DES)
01476105 Computer Organization and Assembly Language

TEAM MEMBERS AND RESPONSIBILITIES

68010321  Nutthawat  Module A - Shell Core, FSM Parser, validation, and File I/O
YOUR_ID   YOUR_NAME  Module B - DES Key Schedule Generator
YOUR_ID   YOUR_NAME  Module C - DES Feistel Core, ECB mode, and PKCS#7 padding
YOUR_ID   YOUR_NAME  Module D - Hex Dump and byte-frequency statistics

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
- Replace every YOUR_ID and YOUR_NAME entry before submission.
