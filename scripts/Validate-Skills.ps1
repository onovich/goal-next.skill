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
      $skillText -notmatch 'ROADMAP\.md' -or
      $skillText -notmatch 'ROADMAP\.proposed\.md' -or
      $skillText -notmatch '\$createroadmap' -or
      $skillText -notmatch 'preferred_path:' -or
      $skillText -notmatch 'fallback:' -or
      $skillText -notmatch 'without invoking external planning skills'
    ) {
      Add-Failure "RoadmapGate is missing filename evidence, preferred paths, or fallback handoff: $skillPath"
    }
    if ($skillText -match '<!--\s*codex-roadmap:') {
      Add-Failure "RoadmapGate must use filenames instead of an embedded confirmation marker: $skillPath"
    }
  }

  if ($name -eq 'createroadmap') {
    if (
      $skillText -notmatch 'ROADMAP\.md' -or
      $skillText -notmatch 'ROADMAP\.proposed\.md' -or
      $skillText -notmatch 'Do you confirm this Roadmap' -or
      $skillText -notmatch 'confirmation_evidence: canonical-filename \| none'
    ) {
      Add-Failure "CreateRoadmap is missing its filename promotion or explicit confirmation contract: $skillPath"
    }
    if ($skillText -match '<!--\s*codex-roadmap:') {
      Add-Failure "CreateRoadmap must use filenames instead of an embedded confirmation marker: $skillPath"
    }
    if ($invocationClasses[$name] -ne 'support') {
      Add-Failure "CreateRoadmap must be classified as support: $skillPath"
    }
    if ($agentText -notmatch '(?m)^  allow_implicit_invocation:\s*false\s*$') {
      Add-Failure "CreateRoadmap must disable implicit invocation: $agentPath"
    }
    if ($skillText -notmatch '(?i)fallback' -or $skillText -notmatch '(?i)self-contained' -or $skillText -notmatch '\$askme') {
      Add-Failure "CreateRoadmap must be a self-contained fallback using bundled AskMe: $skillPath"
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

  if ($name -eq 'createrole') {
    if ($invocationClasses[$name] -ne 'core-entry') {
      Add-Failure "CreateRole must be classified as core-entry: $skillPath"
    }
    if ($agentText -notmatch '(?m)^  allow_implicit_invocation:\s*false\s*$') {
      Add-Failure "CreateRole must disable implicit invocation: $agentPath"
    }
    foreach ($requiredFragment in @(
      'Role.proposed.md',
      'list_projects',
      'create_thread',
      'Sequential creation is a safety property',
      'Do you approve this Role Graph and authorize CreateRole to create exactly',
      'selection_mode: configured-default',
      'current workspace differs from the saved project path',
      'goal_token_budget',
      'createrole: READY | PROPOSED | PARTIAL | BLOCKED | CANCELLED',
      'Never substitute collaboration subagents'
    )) {
      if (-not $skillText.Contains($requiredFragment)) {
        Add-Failure "CreateRole contract is missing '$requiredFragment': $skillPath"
      }
    }
    if ($skillText -match '(?i)\bgpt-[0-9]') {
      Add-Failure "CreateRole must not hardcode model ids: $skillPath"
    }
    if ($skillText -match '<!--\s*(?:codex-role|role-graph):') {
      Add-Failure "CreateRole must use Role filenames instead of embedded evidence markers: $skillPath"
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
  if ($rootRoadmapText -match '<!--\s*codex-roadmap:') {
    Add-Failure "Canonical repository Roadmap must use its filename instead of an embedded confirmation marker: $rootRoadmapPath"
  }
  foreach ($requiredRoadmapPattern in @(
    '(?m)^Status:\s*confirmed\s*$',
    '(?m)^## Phase Map\s*$',
    '(?m)^## Next Ready Phase\s*$'
  )) {
    if ($rootRoadmapText -notmatch $requiredRoadmapPattern) {
      Add-Failure "Canonical repository Roadmap is missing substantive confirmed content matching '$requiredRoadmapPattern': $rootRoadmapPath"
    }
  }
}

$gitWorkTree = (& git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null)
$isGitWorkTree = $LASTEXITCODE -eq 0 -and $gitWorkTree -eq 'true'
if ($isGitWorkTree) {
  $commitMetadata = @(& git -C $RepoRoot log --all --format='%H%x09%ae%x09%ce')
  foreach ($metadataLine in $commitMetadata) {
    $metadataParts = $metadataLine -split "`t", 3
    if ($metadataParts.Count -ne 3) {
      Add-Failure 'Unable to parse Git commit privacy metadata.'
      continue
    }

    $commitId = $metadataParts[0].Substring(0, 7)
    if ($metadataParts[1] -notmatch '(?i)^[^@\s]+@users\.noreply\.github\.com$') {
      Add-Failure "Git commit $commitId has a non-private author email. Use a GitHub noreply address before publishing."
    }
    if ($metadataParts[2] -notmatch '(?i)^[^@\s]+@users\.noreply\.github\.com$') {
      Add-Failure "Git commit $commitId has a non-private committer email. Use a GitHub noreply address before publishing."
    }
  }
}

$textExtensions = @('.md', '.yaml', '.yml', '.json', '.ps1', '.py', '.sh', '.txt')
$gitRoot = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot ".git")) + [System.IO.Path]::DirectorySeparatorChar
$validatorPath = [System.IO.Path]::GetFullPath($MyInvocation.MyCommand.Path)
$externalRoadmapSkillNames = @(
  ('grill' + '-me'),
  ('grill' + '-with-docs')
)
$readmeOnlyRecommendationPaths = @(
  [System.IO.Path]::GetFullPath((Join-Path $RepoRoot 'README.md')),
  [System.IO.Path]::GetFullPath((Join-Path $RepoRoot 'README.zh-CN.md'))
)
$sensitivePatterns = [ordered]@{
  "user-specific Windows path" = '(?i)\b[A-Z]:\\Users\\[^\\\s<>]+'
  "user-specific Unix path" = '(?i)/(?:Users|home)/(?!<)[^/\s<>]+'
  "personal workspace path" = '(?i)\b[A-Z]:\\(?:Desktop|Documents|Downloads|Projects|LabProjects|Workspaces)\\'
  "literal UUID or thread id" = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
  "literal thread route id" = '(?im)\b(?:thread[_ -]?id|threadId)\s*[:=]\s*(?!<|none|unknown)[0-9a-z][0-9a-z-]{7,}'
  "email address" = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
  "OpenAI-style secret" = '\bsk-[A-Za-z0-9_-]{16,}\b'
  "GitHub-style token" = '\bgh[pousr]_[A-Za-z0-9]{20,}\b'
  "GitHub fine-grained token" = '\bgithub_pat_[A-Za-z0-9_]{20,}\b'
  "AWS access key" = '\bAKIA[A-Z0-9]{16}\b'
  "Google API key" = '\bAIza[A-Za-z0-9_-]{30,}\b'
  "Slack token" = '\bxox[baprs]-[A-Za-z0-9-]{10,}\b'
  "JWT" = '\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'
  "credentialed URL" = '(?i)https?://[^/\s:@]+:[^@\s/]+@'
  "private network address" = '(?<![0-9])(?:10\.(?:[0-9]{1,3}\.){2}[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(?:1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})(?![0-9])'
  "high-entropy literal" = '(?<![A-Za-z0-9_-])[A-Za-z0-9_-]{48,}(?![A-Za-z0-9_-])'
  "private key" = '-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
}

foreach ($file in Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force) {
  if ($file.FullName.StartsWith($gitRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    continue
  }
  if (
    $file.Name -match '(?i)^(?:\.env(?:\..*)?|id_rsa|id_ed25519|credentials(?:\..*)?|cookies(?:\..*)?|auth(?:\..*)?)$' -or
    $file.Extension -match '(?i)^\.(?:pem|p12|pfx|key|kdbx)$'
  ) {
    Add-Failure "Possible sensitive file by name: $($file.FullName)"
  }
  if ($file.Extension -notin $textExtensions) {
    continue
  }
  $text = Read-StrictUtf8 $file.FullName
  $fullPath = [System.IO.Path]::GetFullPath($file.FullName)
  if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) {
    Add-Failure "Missing final newline: $($file.FullName)"
  }
  if ([regex]::IsMatch($text, '(?m)[ \t]+\r?$')) {
    Add-Failure "Trailing whitespace: $($file.FullName)"
  }
  if ($fullPath -notin $readmeOnlyRecommendationPaths) {
    foreach ($externalName in $externalRoadmapSkillNames) {
      if ($text.IndexOf($externalName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Add-Failure "README-only external Roadmap recommendation appears outside README: $($file.FullName)"
      }
    }
  }
  if ($fullPath -eq $validatorPath) {
    continue
  }
  foreach ($label in $sensitivePatterns.Keys) {
    if ([regex]::IsMatch($text, $sensitivePatterns[$label])) {
      Add-Failure "Possible $label in $($file.FullName)"
    }
  }
}

if ($isGitWorkTree) {
  $historyFindingKeys = New-Object 'System.Collections.Generic.HashSet[string]'
  $historyObjects = @(& git -C $RepoRoot rev-list --objects --all)
  foreach ($historyObject in $historyObjects) {
    $objectParts = $historyObject -split ' ', 2
    if ($objectParts.Count -ne 2) {
      continue
    }

    $objectId = $objectParts[0]
    $historyPath = $objectParts[1]
    if ([System.IO.Path]::GetExtension($historyPath) -notin $textExtensions) {
      continue
    }
    if ($historyPath.Replace('/', '\') -eq 'scripts\Validate-Skills.ps1') {
      continue
    }

    $objectType = (& git -C $RepoRoot cat-file -t $objectId 2>$null)
    if ($LASTEXITCODE -ne 0 -or $objectType -ne 'blob') {
      continue
    }
    $historyText = @(& git -C $RepoRoot cat-file blob $objectId) -join "`n"
    foreach ($label in $sensitivePatterns.Keys) {
      if ([regex]::IsMatch($historyText, $sensitivePatterns[$label])) {
        $findingKey = "$objectId|$label|$historyPath"
        if ($historyFindingKeys.Add($findingKey)) {
          Add-Failure "Possible $label in reachable Git history object $($objectId.Substring(0, 7)) at $historyPath"
        }
      }
    }
  }

  $historyCommits = @(& git -C $RepoRoot rev-list --all)
  foreach ($historyCommit in $historyCommits) {
    $commitMessage = @(& git -C $RepoRoot show -s --format='%B' $historyCommit) -join "`n"
    foreach ($label in $sensitivePatterns.Keys) {
      if ([regex]::IsMatch($commitMessage, $sensitivePatterns[$label])) {
        Add-Failure "Possible $label in commit message $($historyCommit.Substring(0, 7))"
      }
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
