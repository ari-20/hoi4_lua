@echo off
rem vcvars: vswhere discovery (standard VS2017+ layout), direct call fallback
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
  src\hoi4_memgate.cpp src\hoi4_sampler.cpp ^
  src\hoi4_defines.cpp src\hoi4_defines_lua.cpp src\hoi4_hook.cpp ^
  src\hoi4_pdata.cpp

cl /nologo /LD /O2 /W3 /EHsc /MT /D_CRT_SECURE_NO_WARNINGS %SRCS% /Fe:hoi4_bridge.dll /I. /Isrc /I third-party\mbedtls\include /DCPPHTTPLIB_MBEDTLS_SUPPORT /link /DLL /MAP:hoi4_bridge.map third-party\lua54\lua54_static.lib user32.lib ws2_32.lib winhttp.lib advapi32.lib bcrypt.lib third-party\mbedtls\build\library\Release\mbedtls.lib third-party\mbedtls\build\library\Release\mbedx509.lib third-party\mbedtls\build\library\Release\mbedcrypto.lib
if errorlevel 1 (
  echo BUILD FAILED
  exit /b 1
)
rem launcher (pure passthrough, all args go to hoi4.exe) - same window, both artifacts
cl /nologo /O2 /W3 /MT /D_CRT_SECURE_NO_WARNINGS src\hoi4_launcher.cpp /Fe:hoi4_launcher.exe
if errorlevel 1 (
  echo BUILD FAILED
  exit /b 1
)
del *.obj hoi4_bridge.exp hoi4_bridge.lib >nul 2>&1
rem optional deploy: set HOI4_DEPLOY_DIR to have both artifacts copied there
rem (the game-side launcher loads hoi4_bridge.dll from its own directory).
rem The path lives in YOUR environment, not in this script.
if defined HOI4_DEPLOY_DIR (
  copy /y hoi4_bridge.dll "%HOI4_DEPLOY_DIR%\" >nul
  copy /y hoi4_launcher.exe "%HOI4_DEPLOY_DIR%\" >nul
  echo BUILD OK ^(deployed to %HOI4_DEPLOY_DIR%^)
) else (
  echo BUILD OK
)
