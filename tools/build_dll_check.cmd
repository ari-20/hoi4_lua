@echo off
rem compile+link check only: same sources as build_dll.cmd but writes a temp
rem artifact (the live hoi4_bridge.dll is locked while the game runs)
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VCVARS="
if exist "%VSWHERE%" for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do set "VCVARS=%%i\VC\Auxiliary\Build\vcvars64.bat"
if not defined VCVARS set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
call "%VCVARS%" >nul 2>&1
rem %~dp0 = this script's dir (repo tools\); build root = one level up
cd /d "%~dp0.."

set SRCS=src\hoi4_main.cpp ^
  src\hoi4_paths.cpp src\hoi4_bridge.cpp src\hoi4_primitives.cpp src\hoi4_registry.cpp ^
  src\hoi4_vtable.cpp src\hoi4_console.cpp src\hoi4_detour.cpp ^
  src\hoi4_timer.cpp src\hoi4_async.cpp src\hoi4_frame.cpp ^
  src\hoi4_session.cpp src\hoi4_scope.cpp src\hoi4_game.cpp src\hoi4_call.cpp ^
  src\hoi4_offsets.cpp src\hoi4_http_client.cpp src\hoi4_http_server.cpp ^
  src\hoi4_harden.cpp src\hoi4_lua_policy.cpp src\hoi4_audit.cpp ^
  src\hoi4_memgate.cpp ^
  src\hoi4_defines.cpp src\hoi4_defines_lua.cpp src\hoi4_hook.cpp

cl /nologo /LD /O2 /W3 /EHsc /MT /D_CRT_SECURE_NO_WARNINGS %SRCS% /Fe:hoi4_bridge_check.dll /I. /Isrc /I third-party\mbedtls\include /DCPPHTTPLIB_MBEDTLS_SUPPORT /link /DLL third-party\lua54\lua54_static.lib user32.lib ws2_32.lib winhttp.lib advapi32.lib bcrypt.lib third-party\mbedtls\build\library\Release\mbedtls.lib third-party\mbedtls\build\library\Release\mbedx509.lib third-party\mbedtls\build\library\Release\mbedcrypto.lib
if errorlevel 1 (
  echo BUILD CHECK FAILED
  exit /b 1
)
del *.obj hoi4_bridge_check.dll hoi4_bridge_check.exp hoi4_bridge_check.lib >nul 2>&1
echo BUILD CHECK OK
