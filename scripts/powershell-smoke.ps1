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
  if ((Get-Location).Path -ne $original) { throw 'Wrapper did not restore caller directory' }
} finally { Pop-Location }
Write-Output 'PASS PowerShell wrapper, stdin and absolute paths'
