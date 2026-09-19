@echo off
setlocal

set "IRVINE_DIR=C:\Irvine"
set "TEST_EXIT=2"

echo ========================================
echo Clean rebuilding DES test runner...
echo ========================================

where ml >nul 2>nul
if errorlevel 1 (
    echo ERROR: ml.exe was not found.
    echo Run this script from x86 Native Tools Command Prompt for VS.
    goto build_error
)

where link >nul 2>nul
if errorlevel 1 (
    echo ERROR: link.exe was not found.
    echo Run this script from x86 Native Tools Command Prompt for VS.
    goto build_error
)

echo [1/8] Cleaning old test artifacts...
for %%F in (
    "test_runner.obj" "test_runner.exe"
    "test_runner.ilk" "test_runner.pdb" "test_runner.lst"
    "module_A.obj" "module_A.lst" "module_B.obj" "module_B.lst"
    "module_C.obj" "module_C.lst" "module_D.obj" "module_D.lst"
) do (
    if exist "%%~F" (
        del /Q "%%~F"
        if errorlevel 1 (
            echo ERROR: Could not delete %%~F.
            goto build_error
        )
    )
)

echo [2/8] Assembling module_A.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_A.asm
if errorlevel 1 goto build_error

echo [3/8] Assembling module_B.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_B.asm
if errorlevel 1 goto build_error

echo [4/8] Assembling module_C.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_C.asm
if errorlevel 1 goto build_error

echo [5/8] Assembling module_D.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_D.asm
if errorlevel 1 goto build_error

echo [6/8] Assembling test_runner.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" test_runner.asm
if errorlevel 1 goto build_error

echo [7/8] Linking test_runner.exe...
link /SUBSYSTEM:CONSOLE /LIBPATH:"%IRVINE_DIR%" /DEBUG /NOLOGO /OUT:test_runner.exe test_runner.obj module_A.obj module_B.obj module_C.obj module_D.obj Irvine32.lib kernel32.lib user32.lib
if errorlevel 1 goto build_error

echo [8/8] Running test_runner.exe...
echo ========================================
test_runner.exe
set "TEST_EXIT=%errorlevel%"
if not "%TEST_EXIT%"=="0" echo Test runner failed with exit code %TEST_EXIT%.
goto end

:build_error
echo.
echo ========================================
echo Test build failed. The test runner was not run.
echo Check the stage and errors above.
echo ========================================
set "TEST_EXIT=2"

:end
endlocal & exit /b %TEST_EXIT%
