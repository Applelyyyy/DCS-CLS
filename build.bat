@echo off
setlocal

set "PROJECT_NAME=DES_Shell"
set "IRVINE_DIR=C:\Irvine"

echo ========================================
echo Building %PROJECT_NAME%.asm...
echo ========================================

where ml >nul 2>nul
if errorlevel 1 (
    echo ERROR: ml.exe was not found.
    echo Run this script from x86 Native Tools Command Prompt for VS.
    goto error
)

echo [1/3] Assembling main and Modules A-D...
ml -Zi -c -Fl -coff %PROJECT_NAME%.asm module_A.asm module_B.asm module_C.asm module_D.asm
if errorlevel 1 goto error

echo [2/3] Linking...
link /SUBSYSTEM:CONSOLE /LIBPATH:"%IRVINE_DIR%" /OPT:NOREF /OPT:NOICF /DEBUG /NOLOGO /OUT:%PROJECT_NAME%.exe %PROJECT_NAME%.obj module_A.obj module_B.obj module_C.obj module_D.obj
if errorlevel 1 goto error

echo [3/3] Running...
echo ========================================
echo Build successful. Running %PROJECT_NAME%.exe...
echo ========================================
echo.
%PROJECT_NAME%.exe
goto end

:error
echo.
echo ========================================
echo Build failed. Check the errors above.
echo ========================================

:end
echo.
pause
endlocal
