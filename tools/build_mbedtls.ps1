# Build the Mbed TLS static libs (/MT) the DLL links against.
# Output: third-party\mbedtls\build\library\Release\{mbedcrypto,mbedx509,mbedtls}.lib
# Matches the configuration this project shipped with since 3.6.4 was first
# vendored: MSVC generator, static libs, /MT runtime, no programs, no tests.
# Kept intentionally compatible with Windows PowerShell 5.1 (no pwsh needed).
$ErrorActionPreference = 'Stop'

# repo root = parent of this script's directory (repo tools\)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# ---- VS discovery (vswhere; direct default fallback) ----
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsPath = $null
if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -property installationPath
}
if (-not $vsPath) {
    $vsPath = Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Community'
}
$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) { throw "vcvars64.bat not found under: $vsPath" }

# ---- import the vcvars environment into this session ----
# vcvars is a .bat; harvest its resulting environment via cmd /c ... && set.
$envDump = cmd /c "`"$vcvars`" >nul 2>&1 && set"
if ($LASTEXITCODE -ne 0) { throw "vcvars64.bat failed (exit $LASTEXITCODE)" }
foreach ($line in $envDump) {
    $i = $line.IndexOf('=')
    if ($i -gt 0) {
        Set-Item -Path ('Env:' + $line.Substring(0, $i)) -Value $line.Substring($i + 1)
    }
}

# vcvars does NOT put cmake on PATH; use the VS-bundled one if present
$vcmake = Join-Path $vsPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin'
if (Test-Path (Join-Path $vcmake 'cmake.exe')) {
    $env:PATH = "$vcmake;$env:PATH"
}
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw 'cmake not found (install CMake or Visual Studio with the C++ CMake tools component)'
}

# ---- submodule sanity ----
if (-not (Test-Path 'third-party\mbedtls\library\CMakeLists.txt')) {
    throw 'third-party\mbedtls missing - run: git submodule update --init'
}
if (-not (Test-Path 'third-party\mbedtls\framework\CMakeLists.txt')) {
    throw "third-party\mbedtls\framework missing (mbedtls's own nested submodule) - run: git -C third-party\mbedtls submodule update --init"
}

# ---- configure + build ----
# CMP0091=NEW makes CMAKE_MSVC_RUNTIME_LIBRARY actually control the runtime:
# mbedtls's low cmake_minimum_required leaves the policy at OLD, which bakes
# the default /MD into CMAKE_C_FLAGS_RELEASE and ignores the /MT request; the
# resulting libs then fail to link against our /MT DLL (__imp_rand unresolved).
# CMAKE_C_FLAGS_RELEASE is also passed explicitly without /MD to match the
# originally shipped build.
cmake -S third-party/mbedtls -B third-party/mbedtls/build `
    -G 'Visual Studio 17 2022' `
    -DCMAKE_POLICY_DEFAULT_CMP0091=NEW `
    -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded `
    '-DCMAKE_C_FLAGS_RELEASE=/O2 /Ob2 /DNDEBUG' `
    -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF `
    -DGEN_FILES=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS=OFF
if ($LASTEXITCODE -ne 0) { throw 'cmake configure failed' }

cmake --build third-party/mbedtls/build --config Release
if ($LASTEXITCODE -ne 0) { throw 'cmake build failed' }

if (-not (Test-Path 'third-party\mbedtls\build\library\Release\mbedcrypto.lib')) {
    throw 'expected lib not produced'
}
Write-Host 'BUILD OK mbedtls libs (Release, /MT)'
