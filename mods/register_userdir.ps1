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
#
# Filename prefix: registered copies are written as zzz_<name>.mod. The
# registry id (the .mod filename) decides search-path priority among
# equal-weight mods: lexicographically LAST mounts last and wins the search
# path (book §4.29.4). zzz_ sorts after every workshop ugc_* name, so the
# framework mods outrank big mods' replace_path exclusivity. A stale
# no-prefix copy of the same mod is removed on sight (two same-name
# registrations would race the launcher's name-based save sync).
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

    $out = Join-Path $target ('zzz_' + $_.Name + '.mod')
    [IO.File]::WriteAllText($out, $content, $utf8NoBom)
    Write-Host ("registered: {0}" -f $out)
    Write-Host ("    path=    {0}" -f $abs)

    # remove a stale pre-prefix registration of the same mod, if any
    $stale = Join-Path $target ($_.Name + '.mod')
    if (Test-Path $stale) {
        Remove-Item $stale
        Write-Host ("removed stale: {0}" -f $stale)
    }
    $count++
}
if ($count -eq 0) { Write-Warning 'no mod directories found under mods/' }
else { Write-Host ("DONE: {0} mod descriptor(s) registered" -f $count) }
