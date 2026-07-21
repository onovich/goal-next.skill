[CmdletBinding()]
param(
  [string]$DestinationRoot = "",
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "skill-set.json"
$validatorPath = Join-Path $PSScriptRoot "Validate-Skills.ps1"

& $validatorPath -RepoRoot $repoRoot

if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
  $codexRoot = $env:CODEX_HOME
  if ([string]::IsNullOrWhiteSpace($codexRoot)) {
    $userProfilePath = [Environment]::GetFolderPath('UserProfile')
    $codexRoot = Join-Path $userProfilePath ".codex"
  }
  $DestinationRoot = Join-Path $codexRoot "skills"
}

$DestinationRoot = [System.IO.Path]::GetFullPath($DestinationRoot)
[System.IO.Directory]::CreateDirectory($DestinationRoot) | Out-Null
$manifest = Get-Content -LiteralPath $manifestPath -Encoding UTF8 -Raw | ConvertFrom-Json
$installed = New-Object System.Collections.Generic.List[string]
$installPlan = New-Object System.Collections.Generic.List[object]

foreach ($entry in @($manifest.skills)) {
  $sourceDirectory = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$entry.path)))
  $targetDirectory = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot ([string]$entry.name)))

  if ($sourceDirectory.Equals($targetDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Source and destination are the same directory: $sourceDirectory"
  }
  if ((Test-Path -LiteralPath $targetDirectory) -and -not $Force) {
    throw "Skill already exists: $targetDirectory. Re-run with -Force to update it."
  }

  $installPlan.Add([pscustomobject]@{
    Name = [string]$entry.name
    Source = $sourceDirectory
    Target = $targetDirectory
  })
}

foreach ($item in $installPlan) {
  [System.IO.Directory]::CreateDirectory($item.Target) | Out-Null
  foreach ($sourceFile in Get-ChildItem -LiteralPath $item.Source -Recurse -File) {
    $relativePath = $sourceFile.FullName.Substring($item.Source.Length).TrimStart('\', '/')
    $targetFile = Join-Path $item.Target $relativePath
    $targetParent = Split-Path -Parent $targetFile
    [System.IO.Directory]::CreateDirectory($targetParent) | Out-Null
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetFile -Force
  }

  $installed.Add($item.Name)
}

Write-Host "Installed $($installed.Count) skills into $DestinationRoot"
foreach ($name in $installed) {
  Write-Host "- $name"
}
Write-Host "Restart Codex, then test both explicit `$skill loading and UI @DisplayName autocomplete."
