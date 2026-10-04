param(
    [string]$Dart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe',
    [int]$Rounds = 9
)
$ErrorActionPreference = 'Stop'
if ($Rounds -lt 1) { throw 'Rounds must be positive' }
$workRoot = & "$PSScriptRoot\prepare-baseline.ps1"
& $Dart compile exe "$workRoot\benchmark\baseline\tool\benchmark.dart" -o "$workRoot\baseline.exe"
if ($LASTEXITCODE -ne 0) { throw 'Baseline build failed' }
& $Dart compile exe "$workRoot\tool\benchmark.dart" -o "$workRoot\optimized.exe"
if ($LASTEXITCODE -ne 0) { throw 'Optimized build failed' }
$rows = [Collections.Generic.List[string]]::new()
for ($round = 0; $round -lt $Rounds; $round++) {
    $order = if ($round % 2 -eq 0) { @('baseline','optimized') } else { @('optimized','baseline') }
    foreach ($variant in $order) {
        $lines = & "$workRoot\$variant.exe" $round
        if ($LASTEXITCODE -ne 0) { throw "$variant benchmark failed" }
        foreach ($line in $lines) {
            $entry = $line | ConvertFrom-Json
            $entry | Add-Member -NotePropertyName variant -NotePropertyValue $variant
            $rows.Add(($entry | ConvertTo-Json -Compress))
        }
        Write-Output "Round $($round+1)/${Rounds}: $variant complete"
    }
}
$rows | Set-Content "$workRoot\timings.jsonl" -Encoding utf8
& $Dart --version
Write-Output "AOT, 250ms warmup per case. Raw results: $workRoot\timings.jsonl"
