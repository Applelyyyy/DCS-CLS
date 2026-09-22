@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_NAME=DES_Shell"
set "IRVINE_DIR=C:\Irvine"
set "VCVARS32=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars32.bat"
set "BUILD_EXIT=1"

echo ========================================
echo Clean rebuilding %PROJECT_NAME%.asm...
echo ========================================

where ml >nul 2>nul
if errorlevel 1 (
    echo Initializing Visual Studio x86 build environment...
    if not exist "!VCVARS32!" (
        echo ERROR: vcvars32.bat was not found:
        echo        !VCVARS32!
        goto error
    )
    call "!VCVARS32!"
    if errorlevel 1 (
        echo ERROR: Visual Studio x86 environment initialization failed.
        goto error
    )
    where ml >nul 2>nul
    if errorlevel 1 (
        echo ERROR: ml.exe was not found after running vcvars32.bat.
        goto error
    )
)

where link >nul 2>nul
if errorlevel 1 (
    echo ERROR: link.exe was not found.
    echo Run this script from x86 Native Tools Command Prompt for VS.
    goto error
)

echo [1/8] Cleaning old production artifacts...
for %%F in (
    "%PROJECT_NAME%.obj" "%PROJECT_NAME%.exe"
    "%PROJECT_NAME%.ilk" "%PROJECT_NAME%.pdb" "%PROJECT_NAME%.lst"
    "module_A.obj" "module_A.lst" "module_B.obj" "module_B.lst"
    "module_C.obj" "module_C.lst" "module_D.obj" "module_D.lst"
) do (
    if exist "%%~F" (
        del /Q "%%~F"
        if errorlevel 1 (
            echo ERROR: Could not delete %%~F.
            goto error
        )
    )
)

echo [2/8] Assembling module_A.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_A.asm
if errorlevel 1 goto error

echo [3/8] Assembling module_B.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_B.asm
if errorlevel 1 goto error

echo [4/8] Assembling module_C.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_C.asm
if errorlevel 1 goto error

echo [5/8] Assembling module_D.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" module_D.asm
if errorlevel 1 goto error

echo [6/8] Assembling %PROJECT_NAME%.asm...
ml -nologo -Zi -c -Fl -coff /I"%IRVINE_DIR%" %PROJECT_NAME%.asm
if errorlevel 1 goto error

echo [7/8] Linking %PROJECT_NAME%.exe...
link /SUBSYSTEM:CONSOLE /LIBPATH:"%IRVINE_DIR%" /OPT:NOREF /OPT:NOICF /DEBUG /NOLOGO /OUT:%PROJECT_NAME%.exe %PROJECT_NAME%.obj module_A.obj module_B.obj module_C.obj module_D.obj Irvine32.lib kernel32.lib user32.lib
if errorlevel 1 goto error

echo [8/8] Running %PROJECT_NAME%.exe...
echo ========================================
echo Build successful. Running %PROJECT_NAME%.exe...
echo ========================================
echo.
%PROJECT_NAME%.exe
set "BUILD_EXIT=0"
goto end

:error
echo.
echo ========================================
echo Build failed. The executable was not run.
echo Check the stage and errors above.
echo ========================================

:end
echo.
pause
endlocal & exit /b %BUILD_EXIT%
