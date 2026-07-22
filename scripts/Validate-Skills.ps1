[CmdletBinding()]
param(
  [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).ProviderPath

$script:failures = New-Object System.Collections.Generic.List[string]
$script:utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

function Add-Failure {
  param([string]$Message)
  $script:failures.Add($Message)
}

function Read-StrictUtf8 {
  param([string]$Path)

  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    Add-Failure "UTF-8 BOM is not allowed: $Path"
  }

  try {
    return $script:utf8Strict.GetString($bytes)
  } catch {
    Add-Failure "Invalid UTF-8: $Path"
    return ""
  }
}

function Assert-QuotedInterfaceField {
  param(
    [string]$Text,
    [string]$Field,
    [string]$Path
  )

  $pattern = '(?m)^  ' + [regex]::Escape($Field) + ':\s*"(?<value>[^"]+)"\s*$'
  $match = [regex]::Match($Text, $pattern)
  if (-not $match.Success) {
    Add-Failure "Missing or unquoted interface.$Field in $Path"
    return ""
  }
  return $match.Groups['value'].Value
}

$manifestPath = Join-Path $RepoRoot "skill-set.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Missing skill-set.json at repository root."
}

$manifestText = Read-StrictUtf8 $manifestPath
try {
  $manifest = $manifestText | ConvertFrom-Json
} catch {
  throw "skill-set.json is invalid JSON: $($_.Exception.Message)"
}

if ([int]$manifest.schemaVersion -ne 2) {
  Add-Failure "skill-set.json schemaVersion must be 2."
}

$declared = @{}
$displayNames = @{}
$invocationClasses = @{}
$optionalDependencies = @{}
$allowedInvocationClasses = @('core-entry', 'support', 'workflow-transition', 'internal')
foreach ($entry in @($manifest.skills)) {
  $name = [string]$entry.name
  $relativePath = [string]$entry.path
  $displayName = [string]$entry.displayName
  $invocation = [string]$entry.invocation
  if ($name -notmatch '^[a-z0-9-]{1,64}$') {
    Add-Failure "Invalid skill name in manifest: $name"
    continue
  }
  if ($declared.ContainsKey($name)) {
    Add-Failure "Duplicate skill in manifest: $name"
    continue
  }
  if ($invocation -notin $allowedInvocationClasses) {
    Add-Failure "Invalid invocation class for ${name}: $invocation"
  }

  $optionalNames = @()
  $optionalProperty = $entry.PSObject.Properties['optionalDependencies']
  if ($null -ne $optionalProperty) {
    foreach ($optionalNameValue in @($optionalProperty.Value)) {
      $optionalName = [string]$optionalNameValue
      if ($optionalName -notmatch '^[a-z0-9-]{1,64}$') {
        Add-Failure "Invalid optional dependency for ${name}: $optionalName"
        continue
      }
      if ($optionalName -eq $name) {
        Add-Failure "Skill cannot optionally depend on itself: $name"
        continue
      }
      if ($optionalNames -contains $optionalName) {
        Add-Failure "Duplicate optional dependency for ${name}: $optionalName"
        continue
      }
      $optionalNames += $optionalName
    }
  }

  $declared[$name] = $relativePath
  $displayNames[$name] = $displayName
  $invocationClasses[$name] = $invocation
  $optionalDependencies[$name] = $optionalNames
}

$skillsRoot = Join-Path $RepoRoot "skills"
if (-not (Test-Path -LiteralPath $skillsRoot)) {
  Add-Failure "Missing skills directory: $skillsRoot"
} else {
  foreach ($directory in Get-ChildItem -LiteralPath $skillsRoot -Directory) {
    if (-not $declared.ContainsKey($directory.Name)) {
      Add-Failure "Skill directory is not declared in skill-set.json: $($directory.Name)"
    }
  }
}

foreach ($name in $declared.Keys) {
  $skillDirectory = Join-Path $RepoRoot $declared[$name]
  $skillPath = Join-Path $skillDirectory "SKILL.md"
  $agentPath = Join-Path $skillDirectory "agents\openai.yaml"

  if ((Split-Path -Leaf $skillDirectory) -cne $name) {
    Add-Failure "Skill folder does not match manifest name: $skillDirectory -> $name"
  }
  if (-not (Test-Path -LiteralPath $skillPath)) {
    Add-Failure "Missing SKILL.md: $skillPath"
    continue
  }
  if (-not (Test-Path -LiteralPath $agentPath)) {
    Add-Failure "Missing agents/openai.yaml: $agentPath"
    continue
  }

  $skillText = Read-StrictUtf8 $skillPath
  $agentText = Read-StrictUtf8 $agentPath

  $frontmatter = [regex]::Match(
    $skillText,
    '\A---\r?\n(?<yaml>.*?)\r?\n---(?:\r?\n|\z)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )
  if (-not $frontmatter.Success) {
    Add-Failure "SKILL.md must start with valid frontmatter: $skillPath"
  } else {
    $yaml = $frontmatter.Groups['yaml'].Value
    $keys = @([regex]::Matches($yaml, '(?m)^([A-Za-z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value })
    foreach ($key in $keys) {
      if ($key -notin @('name', 'description')) {
        Add-Failure "Unexpected SKILL.md frontmatter key '$key': $skillPath"
      }
    }
    $nameMatch = [regex]::Match($yaml, '(?m)^name:\s*(?<name>[a-z0-9-]+)\s*$')
    if (-not $nameMatch.Success -or $nameMatch.Groups['name'].Value -cne $name) {
      Add-Failure "SKILL.md name does not match folder '$name': $skillPath"
    }
    if ($yaml -notmatch '(?m)^description:\s*\S.+$') {
      Add-Failure "SKILL.md description is missing: $skillPath"
    }
  }

  if ($agentText -notmatch '\Ainterface:\r?\n') {
    Add-Failure "agents/openai.yaml must start with interface:: $agentPath"
  }
  $displayName = Assert-QuotedInterfaceField $agentText "display_name" $agentPath
  $shortDescription = Assert-QuotedInterfaceField $agentText "short_description" $agentPath
  $defaultPrompt = Assert-QuotedInterfaceField $agentText "default_prompt" $agentPath
  if ($shortDescription.Length -lt 25 -or $shortDescription.Length -gt 64) {
    Add-Failure "interface.short_description must be 25-64 characters: $agentPath"
  }
  if (-not $defaultPrompt.Contains('$' + $name)) {
    Add-Failure ("interface.default_prompt must mention {0}: {1}" -f ('$' + $name), $agentPath)
  }
  if ([string]::IsNullOrWhiteSpace($displayName)) {
    Add-Failure "interface.display_name must not be empty: $agentPath"
  }
  if ($displayName -cne $displayNames[$name]) {
    Add-Failure "interface.display_name does not match skill-set.json for ${name}: $agentPath"
  }
  if ($invocationClasses[$name] -eq 'internal' -and $agentText -notmatch '(?m)^  allow_implicit_invocation:\s*false\s*$') {
    Add-Failure "Internal skill must disable implicit invocation: $agentPath"
  }

  $combined = $skillText + "`n" + $agentText
  foreach ($reference in [regex]::Matches($combined, '\$([a-z][a-z0-9-]*)')) {
    $referencedName = $reference.Groups[1].Value
    $isOptional = @($optionalDependencies[$name]) -contains $referencedName
    if ($referencedName -ne $name -and -not $declared.ContainsKey($referencedName) -and -not $isOptional) {
      Add-Failure ("Undeclared cross-skill reference {0} in {1}" -f ('$' + $referencedName), $skillPath)
    }
  }

  if ($name -notin @('createroadmap', 'roadmapgate')) {
    if ($skillText -notmatch '(?m)^## Mandatory Roadmap Gate\s*$') {
      Add-Failure "Workflow skill is missing its Mandatory Roadmap Gate section: $skillPath"
    }
    if ($skillText -notmatch '\$roadmapgate') {
      Add-Failure "Workflow skill does not explicitly invoke roadmapgate: $skillPath"
    }
  }

  if ($name -in @('askme', 'listtodecide')) {
    if ($skillText -notmatch 'caller: createroadmap' -or $skillText -notmatch 'roadmap_bootstrap: true') {
      Add-Failure "Roadmap bootstrap support skill is missing its bounded CreateRoadmap exception: $skillPath"
    }
  }

  if ($name -eq 'roadmapgate') {
    if (
      $skillText -notmatch '<!-- codex-roadmap: confirmed -->' -or
      $skillText -notmatch '\$createroadmap' -or
      $skillText -notmatch '\$grill-me' -or
      $skillText -notmatch 'preferred_path:' -or
      $skillText -notmatch 'fallback:'
    ) {
      Add-Failure "RoadmapGate is missing confirmation evidence, preferred paths, or fallback handoff: $skillPath"
    }
  }

  if ($name -eq 'createroadmap') {
    if ($skillText -notmatch '<!-- codex-roadmap: confirmed -->' -or $skillText -notmatch 'Do you confirm this Roadmap') {
      Add-Failure "CreateRoadmap is missing its exact marker or explicit confirmation question: $skillPath"
    }
    if ($invocationClasses[$name] -ne 'support') {
      Add-Failure "CreateRoadmap must be classified as support: $skillPath"
    }
    if ($agentText -notmatch '(?m)^  allow_implicit_invocation:\s*false\s*$') {
      Add-Failure "CreateRoadmap must disable implicit invocation: $agentPath"
    }
    if ($skillText -notmatch '(?i)fallback' -or $skillText -notmatch '\$grill-me') {
      Add-Failure "CreateRoadmap must present itself as fallback and recommend grill-me: $skillPath"
    }
    if ($skillText -match '\$grill-with-docs') {
      Add-Failure "CreateRoadmap must recommend grill-me instead of grill-with-docs: $skillPath"
    }
  }

  if ($name -eq 'choosemodel') {
    if ($invocationClasses[$name] -ne 'support') {
      Add-Failure "ChooseModel must be classified as support: $skillPath"
    }
    if ($agentText -notmatch '(?m)^  allow_implicit_invocation:\s*false\s*$') {
      Add-Failure "ChooseModel must disable implicit invocation: $agentPath"
    }
    foreach ($requiredFragment in @(
      'selection_mode: configured-default | explicit-override',
      'OVERRIDE_PROPOSED',
      'CONFIRMED_PROFILE',
      'plan_tier: <explicit value or unknown>',
      'quota: <explicit value or unknown>',
      'thread-creation tool schema'
    )) {
      if (-not $skillText.Contains($requiredFragment)) {
        Add-Failure "ChooseModel contract is missing '$requiredFragment': $skillPath"
      }
    }
    if ($skillText -match '(?i)\bgpt-[0-9]') {
      Add-Failure "ChooseModel must not hardcode model ids: $skillPath"
    }
  }
}

foreach ($edge in @($manifest.workflowEdges)) {
  if (-not $declared.ContainsKey([string]$edge.from)) {
    Add-Failure "Workflow edge has unknown source: $($edge.from)"
  }
  if (-not $declared.ContainsKey([string]$edge.to)) {
    Add-Failure "Workflow edge has unknown target: $($edge.to)"
  }
}

foreach ($name in $declared.Keys) {
  if ($name -in @('createroadmap', 'roadmapgate')) {
    continue
  }
  $gateEdges = @(
    $manifest.workflowEdges | Where-Object {
      [string]$_.from -eq $name -and
      [string]$_.to -eq 'roadmapgate' -and
      [string]$_.kind -eq 'confirmed-roadmap-prerequisite'
    }
  )
  if ($gateEdges.Count -ne 1) {
    Add-Failure "Workflow skill must declare exactly one confirmed-roadmap-prerequisite edge: $name"
  }
}

$rootRoadmapPath = Join-Path $RepoRoot 'ROADMAP.md'
if (-not (Test-Path -LiteralPath $rootRoadmapPath)) {
  Add-Failure "Missing canonical repository Roadmap: $rootRoadmapPath"
} else {
  $rootRoadmapText = Read-StrictUtf8 $rootRoadmapPath
  $confirmationMarkers = [regex]::Matches(
    $rootRoadmapText,
    '(?m)^<!-- codex-roadmap: confirmed -->\r?$'
  )
  if ($confirmationMarkers.Count -ne 1) {
    Add-Failure "Canonical repository Roadmap must contain exactly one confirmed marker: $rootRoadmapPath"
  }
}

$textExtensions = @('.md', '.yaml', '.yml', '.json', '.ps1', '.py', '.sh', '.txt')
$gitRoot = Join-Path $RepoRoot ".git"
$validatorPath = [System.IO.Path]::GetFullPath($MyInvocation.MyCommand.Path)
$sensitivePatterns = [ordered]@{
  "user-specific Windows path" = '(?i)\b[A-Z]:\\Users\\[^\\\s<>]+'
  "personal workspace path" = '(?i)\b[A-Z]:\\(?:Desktop|Documents|Downloads|Projects|LabProjects|Workspaces)\\'
  "literal UUID or thread id" = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
  "email address" = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
  "OpenAI-style secret" = '\bsk-[A-Za-z0-9_-]{16,}\b'
  "GitHub-style token" = '\bgh[pousr]_[A-Za-z0-9]{20,}\b'
  "AWS access key" = '\bAKIA[A-Z0-9]{16}\b'
  "private key" = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
}

foreach ($file in Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force) {
  if ($file.FullName.StartsWith($gitRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    continue
  }
  if ($file.Extension -notin $textExtensions) {
    continue
  }
  $text = Read-StrictUtf8 $file.FullName
  if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) {
    Add-Failure "Missing final newline: $($file.FullName)"
  }
  if ([regex]::IsMatch($text, '(?m)[ \t]+\r?$')) {
    Add-Failure "Trailing whitespace: $($file.FullName)"
  }
  if ([System.IO.Path]::GetFullPath($file.FullName) -eq $validatorPath) {
    continue
  }
  foreach ($label in $sensitivePatterns.Keys) {
    if ([regex]::IsMatch($text, $sensitivePatterns[$label])) {
      Add-Failure "Possible $label in $($file.FullName)"
    }
  }
}

if ($script:failures.Count -gt 0) {
  Write-Host "Skill validation failed:" -ForegroundColor Red
  foreach ($failure in $script:failures) {
    Write-Host "- $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Skill validation passed for $($declared.Count) skills." -ForegroundColor Green
