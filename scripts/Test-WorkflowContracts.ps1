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

$failures = New-Object System.Collections.Generic.List[string]

function Add-ContractFailure {
  param([string]$Message)
  $failures.Add($Message)
}

function Read-Utf8Text {
  param([string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false, $true))
}

$manifestPath = Join-Path $RepoRoot 'skill-set.json'
$manifest = (Read-Utf8Text $manifestPath) | ConvertFrom-Json
$skillEntries = @($manifest.skills)
$edges = @($manifest.workflowEdges)
$externalRoadmapSkillNames = @(
  ('grill' + '-me'),
  ('grill' + '-with-docs')
)
$externalRoadmapInvocation = '$' + $externalRoadmapSkillNames[0]
$readmeOnlyRecommendationPaths = @(
  [System.IO.Path]::GetFullPath((Join-Path $RepoRoot 'README.md')),
  [System.IO.Path]::GetFullPath((Join-Path $RepoRoot 'README.zh-CN.md'))
)
$contractTextExtensions = @('.md', '.yaml', '.yml', '.json', '.ps1', '.py', '.sh', '.txt')
$contractGitRoot = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot '.git')) + [System.IO.Path]::DirectorySeparatorChar
foreach ($file in Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force) {
  $fullPath = [System.IO.Path]::GetFullPath($file.FullName)
  if (
    $fullPath.StartsWith($contractGitRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    $file.Extension -notin $contractTextExtensions -or
    $fullPath -in $readmeOnlyRecommendationPaths
  ) {
    continue
  }

  $text = Read-Utf8Text $fullPath
  foreach ($externalName in $externalRoadmapSkillNames) {
    if ($text.IndexOf($externalName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
      Add-ContractFailure "External Roadmap Skill recommendation or dependency appears outside README: $fullPath"
    }
  }
}

$validatorText = Read-Utf8Text (Join-Path $RepoRoot 'scripts\Validate-Skills.ps1')
foreach ($fragment in @(
  'users\.noreply\.github\.com',
  'non-private author email',
  'non-private committer email',
  'rev-list --objects --all',
  'Possible sensitive file by name',
  'high-entropy literal',
  'README-only external Roadmap recommendation'
)) {
  if (-not $validatorText.Contains($fragment)) {
    Add-ContractFailure "Privacy validator is missing Git metadata protection: $fragment"
  }
}

$edgeKeys = @{}
foreach ($edge in $edges) {
  $key = '{0}|{1}|{2}' -f ([string]$edge.from), ([string]$edge.to), ([string]$edge.kind)
  $edgeKeys[$key] = $true
}

$requiredFlowEdges = @(
  'roadmapgate|createroadmap|missing-roadmap-bootstrap',
  'createroadmap|goalnext|confirmed-handoff',
  'createrole|askme|role-graph-interview',
  'createrole|choosemodel|thread-profile',
  'createrole|nameyou|role-route-registration',
  'createrole|goalnext|ready-handoff',
  'nameyou|goalnext|route-bootstrap',
  'goalnext|donextgoal|dispatch',
  'donextgoal|checkandgoal|completion-report',
  'checkandgoal|goalnext|pass-loop',
  'checkandgoal|donextgoal|repair-dispatch'
)
foreach ($requiredEdge in $requiredFlowEdges) {
  if (-not $edgeKeys.ContainsKey($requiredEdge)) {
    Add-ContractFailure "Missing workflow edge: $requiredEdge"
  }
}

$bootstrapSkills = @('createroadmap', 'roadmapgate')
foreach ($entry in $skillEntries) {
  $name = [string]$entry.name
  if ($name -in $bootstrapSkills) {
    continue
  }
  $gateEdge = "$name|roadmapgate|confirmed-roadmap-prerequisite"
  if (-not $edgeKeys.ContainsKey($gateEdge)) {
    Add-ContractFailure "Missing Roadmap prerequisite edge: $name"
  }
}

$firstWorkSections = [ordered]@{
  createrole = '## Input And Defaults'
  choosemodel = '## Input Contract'
  nameyou = '## Workflow'
  listtodecide = '## Canonical Prompt'
  askme = '## Boundaries'
  goalnext = '## Mandatory Role Gate'
  donextgoal = '## Mandatory Role Gate'
  checkandgoal = '## Mandatory Role Gate'
}
foreach ($name in $firstWorkSections.Keys) {
  $skillPath = Join-Path $RepoRoot ("skills\{0}\SKILL.md" -f $name)
  $skillText = Read-Utf8Text $skillPath
  $gateIndex = $skillText.IndexOf('## Mandatory Roadmap Gate', [System.StringComparison]::Ordinal)
  $workIndex = $skillText.IndexOf([string]$firstWorkSections[$name], [System.StringComparison]::Ordinal)
  if ($gateIndex -lt 0 -or $workIndex -lt 0 -or $gateIndex -gt $workIndex) {
    Add-ContractFailure "RoadmapGate is not before work/preflight for $name"
  }
}

$roadmapGateText = Read-Utf8Text (Join-Path $RepoRoot 'skills\roadmapgate\SKILL.md')
foreach ($fragment in @(
  'ROADMAP.md',
  'ROADMAP.proposed.md',
  'evidence: none | unconfirmed',
  'preferred_path:',
  'fallback: $createroadmap',
  'Should I invoke $createroadmap now',
  're-run this gate',
  'ROADMAP_REQUIRED',
  'Do not invoke CreateRoadmap without permission',
  'without invoking external planning skills'
)) {
  if (-not $roadmapGateText.Contains($fragment)) {
    Add-ContractFailure "RoadmapGate scenario contract is missing: $fragment"
  }
}

$createRoadmapText = Read-Utf8Text (Join-Path $RepoRoot 'skills\createroadmap\SKILL.md')
$sourceSectionIndex = $createRoadmapText.IndexOf('## Source Priority', [System.StringComparison]::Ordinal)
if ($sourceSectionIndex -lt 0) {
  Add-ContractFailure 'CreateRoadmap Source Priority section is missing.'
  $sourcePriorityText = $createRoadmapText
} else {
  $sourcePriorityText = $createRoadmapText.Substring($sourceSectionIndex)
}
$sourcePriority = @(
  'Existing user-owned Roadmap material',
  "user's free-form project positioning",
  '$askme'
)
$previousIndex = -1
foreach ($fragment in $sourcePriority) {
  $fragmentIndex = $sourcePriorityText.IndexOf($fragment, [System.StringComparison]::Ordinal)
  if ($fragmentIndex -le $previousIndex) {
    Add-ContractFailure "CreateRoadmap source priority is missing or out of order: $fragment"
  }
  $previousIndex = $fragmentIndex
}
foreach ($fragment in @(
  'Do you confirm this Roadmap',
  'ROADMAP.proposed.md',
  'canonical `ROADMAP.md` filename',
  'confirmation_evidence: canonical-filename | none'
)) {
  if (-not $createRoadmapText.Contains($fragment)) {
    Add-ContractFailure "CreateRoadmap confirmation contract is missing: $fragment"
  }
}
if ($createRoadmapText -notmatch '(?i)fallback' -or $createRoadmapText -notmatch '(?i)self-contained') {
  Add-ContractFailure 'CreateRoadmap is not constrained to the self-contained fallback policy.'
}

$chooseModelText = Read-Utf8Text (Join-Path $RepoRoot 'skills\choosemodel\SKILL.md')
foreach ($fragment in @(
  'DEFAULT_READY',
  'OVERRIDE_PROPOSED',
  'CONFIRMED_PROFILE',
  'selection_mode: configured-default | explicit-override',
  'plan_tier: <explicit value or unknown>',
  'quota: <explicit value or unknown>',
  'A recommendation alone is not authorization'
)) {
  if (-not $chooseModelText.Contains($fragment)) {
    Add-ContractFailure "ChooseModel contract is missing: $fragment"
  }
}
if ($chooseModelText -match '(?i)\bgpt-[0-9]') {
  Add-ContractFailure 'ChooseModel contains a hardcoded model id.'
}

$createRoleText = Read-Utf8Text (Join-Path $RepoRoot 'skills\createrole\SKILL.md')
foreach ($fragment in @(
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
  if (-not $createRoleText.Contains($fragment)) {
    Add-ContractFailure "CreateRole contract is missing: $fragment"
  }
}
if ($createRoleText -match '(?i)\bgpt-[0-9]' -or $createRoleText.Contains('roadmap_bootstrap: true')) {
  Add-ContractFailure 'CreateRole hardcodes a model id or exposes the Roadmap bootstrap exception.'
}

$nameYouText = Read-Utf8Text (Join-Path $RepoRoot 'skills\nameyou\SKILL.md')
foreach ($fragment in @('workflow_role', 'upstream', 'downstream', 'default_executor', 'goal_token_budget', 'must not be committed')) {
  if (-not $nameYouText.Contains($fragment)) {
    Add-ContractFailure "NameYou is missing CreateRole-compatible route support: $fragment"
  }
}

$gitignoreText = Read-Utf8Text (Join-Path $RepoRoot '.gitignore')
foreach ($routeFile in @('Role.md', 'Role.proposed.md')) {
  if ($gitignoreText -notmatch ('(?m)^' + [regex]::Escape($routeFile) + '$')) {
    Add-ContractFailure "Local route file is not ignored by default: $routeFile"
  }
}

$goalNextText = Read-Utf8Text (Join-Path $RepoRoot 'skills\goalnext\SKILL.md')
$doNextGoalText = Read-Utf8Text (Join-Path $RepoRoot 'skills\donextgoal\SKILL.md')
$checkAndGoalText = Read-Utf8Text (Join-Path $RepoRoot 'skills\checkandgoal\SKILL.md')
foreach ($workflowContract in @(
  @{ Name = 'GoalNext'; Text = $goalNextText; Fragments = @('Role Graph Target Selection', 'target_role', 'default_executor', 'active_goal_target_role') },
  @{ Name = 'DoNextGoal'; Text = $doNextGoalText; Fragments = @('target_role', 'active_goal_target_role', 'goal_token_budget', 'last_executor_report_role') },
  @{ Name = 'CheckAndGoal'; Text = $checkAndGoalText; Fragments = @('Repair Target Selection', 'active_goal_target_role', 'last_executor_report_role', 'Bounded Execution-Role Resolution') }
)) {
  foreach ($fragment in $workflowContract.Fragments) {
    if (-not $workflowContract.Text.Contains($fragment)) {
      Add-ContractFailure "$($workflowContract.Name) is missing multi-role routing support: $fragment"
    }
  }
}

$installerText = Read-Utf8Text (Join-Path $RepoRoot 'scripts\Install-Skills.ps1')
foreach ($fragment in @('$LASTEXITCODE -ne 0', 'installation stopped before copying files')) {
  if (-not $installerText.Contains($fragment)) {
    Add-ContractFailure "Installer does not stop after validation failure: $fragment"
  }
}

$trueFlagSkills = @()
foreach ($entry in $skillEntries) {
  $name = [string]$entry.name
  $skillText = Read-Utf8Text (Join-Path $RepoRoot ("skills\{0}\SKILL.md" -f $name))
  if ($skillText.Contains('roadmap_bootstrap: true')) {
    $trueFlagSkills += $name
  }
}
$actualFlags = ($trueFlagSkills | Sort-Object) -join ','
$expectedFlags = 'askme,createroadmap,listtodecide,roadmapgate'
if ($actualFlags -ne $expectedFlags) {
  Add-ContractFailure "Unexpected Roadmap bootstrap surface: $actualFlags"
}

$rootRoadmapText = Read-Utf8Text (Join-Path $RepoRoot 'ROADMAP.md')
$markerCount = [regex]::Matches($rootRoadmapText, '<!-- codex-roadmap: confirmed -->').Count
if ($markerCount -ne 0) {
  Add-ContractFailure "Root Roadmap must use filename evidence and contain no legacy confirmation marker, found $markerCount"
}
foreach ($fragment in @('Status: confirmed', '## Phase Map', '## Next Ready Phase')) {
  if (-not $rootRoadmapText.Contains($fragment)) {
    Add-ContractFailure "Root ROADMAP.md is missing substantive confirmed content: $fragment"
  }
}

$readmeText = Read-Utf8Text (Join-Path $RepoRoot 'README.md')
$readmeFirstLine = ($readmeText -split "`r?`n", 2)[0]
if ($readmeFirstLine -notmatch 'README\.zh-CN\.md') {
  Add-ContractFailure 'README.md must link to README.zh-CN.md on its first line.'
}
if ($readmeText -match '(?m)^#{1,6}\s+.*[^\x00-\x7F].*$') {
  Add-ContractFailure 'README.md headings must remain English-first.'
}
foreach ($fragment in @(
  '### A.',
  '### B.',
  '### C.',
  '`ROADMAP.proposed.md`',
  $externalRoadmapInvocation
)) {
  if (-not $readmeText.Contains($fragment)) {
    Add-ContractFailure "First-time README guidance is missing: $fragment"
  }
}
if ($readmeText -notmatch '(?m)^\| A\..*`CreateRole`.*`GoalNext`.*\|\s*$') {
  Add-ContractFailure 'First-time README recommended mode must list CreateRole and GoalNext.'
}
if ($readmeText.Contains('CreateRole is not implemented') -or $readmeText.Contains('installer does not include CreateRole')) {
  Add-ContractFailure 'README still describes CreateRole as unavailable.'
}
foreach ($hiddenComment in @('<!-- roadmap-policy:', '<!-- usage-mode:', '<!-- recommended-skills:')) {
  if ($readmeText.Contains($hiddenComment)) {
    Add-ContractFailure "README must use human-readable guidance instead of hidden contract comments: $hiddenComment"
  }
}

$chineseReadmePath = Join-Path $RepoRoot 'README.zh-CN.md'
if (-not (Test-Path -LiteralPath $chineseReadmePath)) {
  Add-ContractFailure 'Missing complete Chinese README: README.zh-CN.md'
} else {
  $chineseReadmeText = Read-Utf8Text $chineseReadmePath
  $chineseFirstLine = ($chineseReadmeText -split "`r?`n", 2)[0]
  if ($chineseFirstLine -notmatch 'README\.md') {
    Add-ContractFailure 'README.zh-CN.md must link back to README.md on its first line.'
  }
  foreach ($fragment in @('### A.', '### B.', '### C.', '`ROADMAP.proposed.md`', $externalRoadmapInvocation)) {
    if (-not $chineseReadmeText.Contains($fragment)) {
      Add-ContractFailure "Chinese README guidance is missing: $fragment"
    }
  }
  if ($chineseReadmeText.Contains('尚未实现 CreateRole') -or $chineseReadmeText.Contains('安装脚本目前不包含 CreateRole')) {
    Add-ContractFailure 'Chinese README still describes CreateRole as unavailable.'
  }
  foreach ($hiddenComment in @('<!-- roadmap-policy:', '<!-- usage-mode:', '<!-- recommended-skills:')) {
    if ($chineseReadmeText.Contains($hiddenComment)) {
      Add-ContractFailure "Chinese README must use human-readable guidance instead of hidden comments: $hiddenComment"
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host 'Workflow contract test failed:' -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host "- $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Workflow contract test passed for $($skillEntries.Count) skills." -ForegroundColor Green
