# DCS-CLS

Command-Line Shell & File Encryption Engine (Classical DES)

[Thai translation](README.th.md)

This repository implements the 32-bit x86 MASM assembly assignment: a command-line shell and DES file-encryption engine based on FIPS 46-3. DES is included for coursework compatibility and must not be used for modern security systems.

## Project structure

```text
DCS-CLS/
|-- DES_Shell.asm       # Main entry point and shared application state
|-- module_A.inc        # Public PROTO declarations for Module A
|-- module_A.asm        # Module A variables and implementation
|-- module_B.inc        # Public PROTO declarations for Module B
|-- module_B.asm        # Module B variables and implementation
|-- module_C.inc        # Public PROTO declarations for Module C
|-- module_C.asm        # Module C variables and implementation
|-- module_D.inc        # Public PROTO declarations for Module D
|-- module_D.asm        # Module D variables and implementation
|-- build.bat           # Assemble, link, and run the project
|-- README.md           # English documentation
|-- README.th.md        # Thai translation
|-- LICENSE
```

Each `.inc` file is a public interface containing `PROTO` declarations. Each corresponding `.asm` file owns its variables, procedure bodies, and internal helpers. `DES_Shell.asm` contains only the entry point and genuinely shared application state.

MASM assembles every `.asm` file into a separate `.obj`. The linker then combines all object files into one executable.

## Procedure naming status

The assignment PDF explicitly requires only these procedure names:

- `DisplayHexDump`
- `ComputeBufferStats`

All other names are interfaces proposed by this template. The team may change them, but every caller, callee, `PROTO`, and interface document must be updated together.

## Module A - Shell Core & FSM Command Parser (6 points)

Files: `module_A.inc`, `module_A.asm`

Responsibilities:

- Run the REPL until the user enters `EXIT`.
- Parse `KEYGEN`, `ENCRYPT`, `DECRYPT`, `DUMP`, `STATS`, `CLEAR`, `HELP`, and `EXIT` with an FSM.
- Validate command syntax, filenames, and keys.
- Report invalid input without terminating the REPL.
- Perform file I/O through the permitted Win32 API or Irvine32 procedures.

| Procedure | Responsibility | Uses modules |
|---|---|---|
| `ShellMain` | Run the main REPL | B, C, D |
| `ReadCommandLine` | Read a command into the input buffer | - |
| `ParseCommandFSM` | Parse the command, filename, and key | - |
| `ValidateCommand` | Validate syntax and argument count | - |
| `DispatchCommand` | Dispatch a parsed command | B, C, D |
| `ReadWholeFile` | Read a file into a buffer | - |
| `WriteWholeFile` | Write a buffer to a file | - |
| `PrintShellError` | Display a non-fatal shell error | - |
| `HELP` command | Display command names, syntax, and descriptions | - |

## Module B - DES Key Schedule Generator (4 points)

Files: `module_B.inc`, `module_B.asm`

Responsibilities:

- Accept a 64-bit DES key containing 56 effective bits and 8 parity bits.
- Apply PC-1, rotate the 28-bit C/D halves, and apply PC-2.
- Produce sixteen 48-bit subkeys, K1 through K16.

| Procedure | Responsibility | Visibility |
|---|---|---|
| `GenerateKeySchedule` | Generate K1-K16 | Public |
| `DisplayKeySchedule` | Display K1-K16 for `KEYGEN` | Public |
| `ApplyPC1` | Convert the 64-bit key to C0/D0 | Internal |
| `RotateKeyHalves` | Rotate C/D left by one or two bits | Internal |
| `ApplyPC2` | Produce one 48-bit subkey | Internal |

Required shift schedule:

```text
1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1
```

## Module C - DES 16-Round Feistel Core Engine (6 points)

Files: `module_C.inc`, `module_C.asm`

Responsibilities:

- Apply IP and inverse IP.
- Execute 16 Feistel rounds.
- Perform E expansion, subkey XOR, S-box lookup, and P permutation.
- Process data in ECB mode with PKCS#7 padding for an 8-byte block.
- Decrypt by applying subkeys from K16 back to K1.

| Procedure | Responsibility | Visibility |
|---|---|---|
| `EncryptBufferECB` | Encrypt a buffer in ECB mode with padding | Public |
| `DecryptBufferECB` | Decrypt and validate/remove padding | Public |
| `EncryptDESBlock` | Encrypt one 64-bit block | Public |
| `DecryptDESBlock` | Decrypt one 64-bit block | Public |
| `ApplyInitialPermutation` | Apply IP | Internal |
| `RunFeistelRounds` | Execute 16 rounds in the selected key order | Internal |
| `FeistelFunction` | Calculate f(R, K) | Internal |
| `ExpandRightHalf` | Expand 32 bits to 48 bits | Internal |
| `ApplySBoxes` | Convert eight 6-bit groups into 32 bits | Internal |
| `ApplyPPermutation` | Apply P | Internal |
| `ApplyInversePermutation` | Apply inverse IP | Internal |
| `AddPKCS7Padding` | Add PKCS#7 padding | Internal |
| `RemovePKCS7Padding` | Validate and remove padding | Internal |

## Module D - Memory Dumper & Buffer Analytics (4 points)

Files: `module_D.inc`, `module_D.asm`

Responsibilities:

- Display 16 bytes per line with offset, hexadecimal, and ASCII columns.
- Display bytes outside `20h`-`7Eh` as `.`.
- Build a 256-bin byte-frequency histogram.
- Display the most frequently occurring byte patterns.

| Procedure | Responsibility | Visibility |
|---|---|---|
| `DisplayHexDump` | Display offset, hexadecimal, and ASCII | Required public name |
| `ComputeBufferStats` | Count bytes `00h`-`FFh` | Required public name |
| `DisplayTopOccurrences` | Display the most frequent patterns | Public |
| `IsPrintableASCII` | Test whether a byte is in `20h`-`7Eh` | Internal |

## Variables and data ownership

Variables are declared in the `.data?` section of their owning `.asm` file. The `?` initializer means that no initial value is provided; the module developer must populate it during implementation.

DES lookup tables currently reserve uninitialized storage. Once their FIPS 46-3 values are supplied, move those initialized tables from `.data?` to `.data`.

Specification-defined sizes:

- DES block: 8 bytes
- DES subkeys: 16 x 6 bytes = 96 bytes
- PC-1: 56 entries
- PC-2: 48 entries
- IP and inverse IP: 64 entries each
- Expansion table: 48 entries
- Eight S-boxes: 512 entries in total
- P permutation: 32 entries
- Histogram: 256 `DWORD` bins

Before implementation, agree on buffer ownership, maximum file size, error codes, allocation strategy, and responsibility for releasing memory.

## Procedure convention

- Use a stack frame: `push ebp`, `mov ebp, esp`, restore the frame, and return.
- Preserve caller registers according to the team's calling contract.
- Return the primary result through `EAX`.
- Use `EAX = 0` for success and a non-zero error code where appropriate.
- Pass pointers and lengths through the stack according to each `PROTO`.
- Do not use `.IF`, `.WHILE`, or `.REPEAT` in parser or cipher loops.
- Implement DES and its key schedule manually; external encryption libraries are prohibited.
- Use only the permitted Win32 API or Irvine32 procedures for file I/O.

## Build and run

1. Open **x86 Native Tools Command Prompt for VS**.
2. Confirm Irvine32 is installed at `C:\Irvine`, or edit `IRVINE_DIR` in `build.bat`.
3. Change to the repository directory.
4. Run:

```bat
build.bat
```

Main build commands:

```bat
ml -Zi -c -Fl -coff DES_Shell.asm module_A.asm module_B.asm module_C.asm module_D.asm
link /SUBSYSTEM:CONSOLE /LIBPATH:"C:\Irvine" /OPT:NOREF /OPT:NOICF /DEBUG /NOLOGO /OUT:DES_Shell.exe DES_Shell.obj module_A.obj module_B.obj module_C.obj module_D.obj
```

If Irvine32 procedures are used, add `Irvine32.lib`, `kernel32.lib`, and `user32.lib` to the link command as required by the local installation.

The project includes executable logic for all four modules and a separate automated test runner.

## Automated tests

From **x86 Native Tools Command Prompt for VS**, run:

```bat
test.bat
```

The runner checks the official DES vector, K1/K16, block encryption/decryption, ECB/PKCS#7 lengths 0-17, invalid ciphertext and padding, the 256-bin histogram, parser behavior, file I/O round trips, and the 1 MiB file boundary. It returns a non-zero process status if any test fails.

## Contribution workflow

Assign one module to each member and create a branch from the latest `main`:

```bat
git switch main
git pull
git switch -c module-a-shell
```

Recommended branches:

- `module-a-shell`
- `module-b-key-schedule`
- `module-c-feistel-core`
- `module-d-dump-stats`

Write logic in `module_X.asm`. Modify `module_X.inc` only when its public interface changes.

```bat
git status
git add module_A.asm module_A.inc
git commit -m "Implement module A shell and parser"
git push -u origin module-a-shell
```

Open a pull request into `main` and require at least one reviewer to verify:

- Procedure names and parameters match the public contract.
- Register preservation and stack balance are correct.
- Parser and cipher loops do not use prohibited directives.
- No external encryption library is used.
- Generated objects, executables, listings, and debug files are not committed.
- The branch builds and module-level tests pass.

The integration owner should update `DES_Shell.asm`, merge one module at a time, and avoid overwriting each module owner's work.

## Recommended integration order

1. Implement and verify Module B key generation.
2. Connect Module C to B and verify single-block DES.
3. Test Module D dump and histogram procedures independently.
4. Connect Module A to all modules and add file I/O.
5. Test complete command flows and error paths.

Official DES test vector:

```text
Plaintext:           0123456789ABCDEF
Key:                 133457799BBCDFF1
Expected ciphertext: 85E813540F0AB405
```

## Submission checklist

- The application runs on Windows 10/11 and the REPL continues until `EXIT`.
- All eight commands are supported and invalid input does not crash the program.
- DES encryption/decryption, ECB, and PKCS#7 padding are correct.
- `DUMP` displays non-printable bytes as `.`.
- `STATS` uses 256 bins and displays the top occurrences.
- The official DES test vector passes.
- Team member names, IDs, and responsibilities are completed below.
- Assembly sources and the required `readme.txt` are included.

## Team members

| Student ID | Name | Module / responsibility |
|---|---|---|
| `YOUR_ID` | `YOUR_NAME` | Module A |
| `YOUR_ID` | `YOUR_NAME` | Module B |
| `YOUR_ID` | `YOUR_NAME` | Module C |
| `YOUR_ID` | `YOUR_NAME` | Module D |
