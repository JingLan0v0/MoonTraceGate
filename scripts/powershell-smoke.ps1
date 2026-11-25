$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$moon = Join-Path $PSScriptRoot 'moon.ps1'
Push-Location ([IO.Path]::GetTempPath())
try {
  $original = (Get-Location).Path
  $baseline = Join-Path $root 'examples/baseline.json'
  $candidate = Join-Path $root 'examples/candidate-pass.json'
  $rules = Get-Content -LiteralPath (Join-Path $root 'examples/budgets.json') -Raw
  $output = $rules | & $moon run cmd/main --target js -- $baseline $candidate -
  if ($LASTEXITCODE -ne 0 -or ($output | ConvertFrom-Json).status -ne 'pass') {
    throw 'Pipeline failed to supply the budget to TraceGate'
  }
  $seriesBase = Join-Path $root 'examples/series-baseline.json'
  $seriesNext = Join-Path $root 'examples/series-candidate.json'
  $policy = Get-Content -LiteralPath (Join-Path $root 'examples/series-p50.json') -Raw
  $series = $policy | & $moon run cmd/main --target js -- --series $seriesBase $seriesNext -
  if ($LASTEXITCODE -ne 0 -or ($series | ConvertFrom-Json).rules[0].candidate_ns -ne 2000) {
    throw 'Pipeline failed to supply the series policy'
  }
  if ((Get-Location).Path -ne $original) { throw 'Wrapper did not restore caller directory' }
} finally { Pop-Location }
Write-Output 'PASS PowerShell wrapper, stdin and absolute paths'
