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
rem synthetic memory model). No lua on PATH (CI runners): build the
rem interpreter from the vendored 5.4.7 sources (same version the DLL
rem links) rather than pulling one from a package feed.
set "LSRC=third-party\lua54\lua-5.4.7\src"
set "LUA=lua"
where lua >nul 2>&1
if errorlevel 1 (
  mkdir lua_ci_tmp 2>nul
  cl /nologo /O2 /MD /DLUA_BUILD_AS_DLL=0 "%LSRC%\lua.c" "%LSRC%\lapi.c" "%LSRC%\lcode.c" "%LSRC%\lctype.c" "%LSRC%\ldebug.c" "%LSRC%\ldo.c" "%LSRC%\ldump.c" "%LSRC%\lfunc.c" "%LSRC%\lgc.c" "%LSRC%\llex.c" "%LSRC%\lmem.c" "%LSRC%\lobject.c" "%LSRC%\lopcodes.c" "%LSRC%\lparser.c" "%LSRC%\lstate.c" "%LSRC%\lstring.c" "%LSRC%\ltable.c" "%LSRC%\ltm.c" "%LSRC%\lundump.c" "%LSRC%\lvm.c" "%LSRC%\lzio.c" "%LSRC%\lauxlib.c" "%LSRC%\lbaselib.c" "%LSRC%\lcorolib.c" "%LSRC%\ldblib.c" "%LSRC%\liolib.c" "%LSRC%\lmathlib.c" "%LSRC%\loadlib.c" "%LSRC%\loslib.c" "%LSRC%\lstrlib.c" "%LSRC%\ltablib.c" "%LSRC%\lutf8lib.c" "%LSRC%\linit.c" /Fe:lua_ci.exe /Folua_ci_tmp\
  if errorlevel 1 (
    echo TESTS FAILED: vendored lua interpreter build
    exit /b 1
  )
  set "LUA=lua_ci.exe"
)
%LUA% tests\test_cont.lua
if errorlevel 1 (
  echo TESTS FAILED: test_cont.lua
  del lua_ci.exe >nul 2>&1
  rd /s /q lua_ci_tmp >nul 2>&1
  exit /b 1
)
del lua_ci.exe >nul 2>&1
rd /s /q lua_ci_tmp >nul 2>&1
echo TESTS OK
exit /b 0
