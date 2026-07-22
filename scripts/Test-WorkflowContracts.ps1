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

$edgeKeys = @{}
foreach ($edge in $edges) {
  $key = '{0}|{1}|{2}' -f ([string]$edge.from), ([string]$edge.to), ([string]$edge.kind)
  $edgeKeys[$key] = $true
}

$requiredFlowEdges = @(
  'roadmapgate|createroadmap|missing-roadmap-bootstrap',
  'createroadmap|goalnext|confirmed-handoff',
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
  'evidence: none | unconfirmed',
  'preferred_path:',
  'ai_assistance: Use $grill-me',
  'fallback: $createroadmap',
  'Should I invoke $createroadmap now',
  're-run this gate',
  'ROADMAP_REQUIRED',
  'Do not invoke CreateRoadmap without permission'
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
  '$grill-me',
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
foreach ($fragment in @('Do you confirm this Roadmap', '<!-- codex-roadmap: confirmed -->')) {
  if (-not $createRoadmapText.Contains($fragment)) {
    Add-ContractFailure "CreateRoadmap confirmation contract is missing: $fragment"
  }
}
if ($createRoadmapText -notmatch '(?i)fallback' -or $createRoadmapText.Contains('$grill-with-docs')) {
  Add-ContractFailure 'CreateRoadmap is not constrained to the grill-me-oriented fallback policy.'
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
if ($markerCount -ne 1) {
  Add-ContractFailure "Root Roadmap confirmation marker count must be 1, found $markerCount"
}

$readmeText = Read-Utf8Text (Join-Path $RepoRoot 'README.md')
foreach ($fragment in @(
  '<!-- roadmap-policy: user-owned; ai-assist: grill-me; bundled: fallback -->',
  '<!-- usage-mode: recommended -->',
  '<!-- usage-mode: retrofit -->',
  '<!-- usage-mode: manual -->',
  '<!-- recommended-skills: nameyou,goalnext -->',
  '$grill-me'
)) {
  if (-not $readmeText.Contains($fragment)) {
    Add-ContractFailure "First-time README guidance is missing: $fragment"
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
