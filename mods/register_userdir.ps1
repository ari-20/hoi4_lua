# register_userdir.ps1 — generate the userdir descriptor files for every mod
# under mods/.
#
# Dual-descriptor layout (see README):
#   - mods/<name>/descriptor.mod  : committed, NO path= (machine-specific)
#   - <Documents>\Paradox Interactive\Hearts of Iron IV\mod\<name>.mod
#     : the registered copy the game/launcher actually reads, WITH path=
#       pointing back at this repo's mod directory.
#
# This script (re)generates the registered copies from the committed
# descriptors. Re-run it after cloning this repo on a new machine, or after
# moving the repo. Safe to re-run (idempotent overwrite).
$ErrorActionPreference = 'Stop'

# mods/ = the directory containing this script
$modsRoot = $PSScriptRoot
if (-not $modsRoot) { throw 'PScriptRoot unavailable - run as a script file' }

# Documents via the known-folder API (handles redirected Documents)
$docs = [Environment]::GetFolderPath('MyDocuments')
if (-not $docs) { throw 'could not resolve the Documents folder' }
$target = Join-Path $docs 'Paradox Interactive\Hearts of Iron IV\mod'
New-Item -ItemType Directory -Force -Path $target | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$count = 0
Get-ChildItem $modsRoot -Directory | ForEach-Object {
    $desc = Join-Path $_.FullName 'descriptor.mod'
    if (-not (Test-Path $desc)) { return }   # not a mod dir

    # committed descriptor = metadata WITHOUT path=; append the absolute path
    $content = (Get-Content $desc -Raw).TrimEnd() + "`r`n"
    $abs = ($_.FullName -replace '\\', '/')
    $content += "path=`"$abs`"`r`n"

    $out = Join-Path $target ($_.Name + '.mod')
    [IO.File]::WriteAllText($out, $content, $utf8NoBom)
    Write-Host ("registered: {0}" -f $out)
    Write-Host ("    path=    {0}" -f $abs)
    $count++
}
if ($count -eq 0) { Write-Warning 'no mod directories found under mods/' }
else { Write-Host ("DONE: {0} mod descriptor(s) registered" -f $count) }
