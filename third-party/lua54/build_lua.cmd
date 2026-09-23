@echo off
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VCVARS="
if exist "%VSWHERE%" for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do set "VCVARS=%%i\VC\Auxiliary\Build\vcvars64.bat"
if not defined VCVARS set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
call "%VCVARS%" >nul 2>&1
rem %~dp0 = this script's dir (third-party\lua54\); lua source = one level down
cd /d "%~dp0lua-5.4.7\src"

rem core + libs (all of them; linit.c excluded, we provide our own luaL_openlibs subset later if needed)
set SRCS=lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c

cl /nologo /c /O2 /W3 /MT /DLUA_BUILD_AS_DLL=0 %SRCS%
if errorlevel 1 (
  echo BUILD FAILED
  exit /b 1
)

lib /nologo /OUT:..\..\lua54_static.lib *.obj
if errorlevel 1 (
  echo LIB FAILED
  exit /b 1
)

del *.obj >nul 2>&1
echo BUILD OK lua54_static.lib