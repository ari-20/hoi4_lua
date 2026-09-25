@echo off
rem Unit tests for the pure modules (the LDE decoder and the path sandbox).
rem No framework: cl + asserts, exit code 1 on any failure.
setlocal EnableExtensions
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath 2^>nul`) do set "VCVARS=%%i\VC\Auxiliary\Build\vcvars64.bat"
call "%VCVARS%" >nul 2>&1
rem %~dp0 = this script's dir (repo tools\); repo root = one level up
cd /d "%~dp0.."

rem One test binary per pure module. Each is self-contained (its own main),
rem so they are built and run separately and the first failure stops the run.
for %%T in (test_lde test_policy) do (
  cl /nologo /O2 /W4 tests\%%T.cpp /Fe:%%T.exe
  if errorlevel 1 (
    echo TESTS FAILED: %%T compile error
    exit /b 1
  )
  %%T.exe
  if errorlevel 1 (
    del %%T.exe >nul 2>&1
    echo TESTS FAILED: %%T
    exit /b 1
  )
  del %%T.exe >nul 2>&1
)
rem Lua-side pure tests (no game needed; the container primitives take a
rem synthetic memory model). Needs lua on PATH.
where lua >nul 2>&1
if errorlevel 1 (
  echo TESTS SKIPPED: tests\test_cont.lua ^(no lua on PATH^)
) else (
  lua tests\test_cont.lua
  if errorlevel 1 (
    echo TESTS FAILED: test_cont.lua
    exit /b 1
  )
)
echo TESTS OK
