param(
    [string]$Dart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe',
    [int]$Rounds = 9
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
$benchRoot = Join-Path $repoRoot 'benchmark'
Expand-Archive -LiteralPath (Join-Path $benchRoot 'baseline-source.zip') -DestinationPath (Join-Path $benchRoot 'baseline') -Force
New-Item -ItemType Directory -Path (Join-Path $benchRoot 'baseline\tool') -Force | Out-Null
Copy-Item -LiteralPath tool\benchmark.dart,tool\workloads.dart -Destination (Join-Path $benchRoot 'baseline\tool') -Force
$environment = [ordered]@{
    baseline_commit = '6d2a063cc36ac353fc7a941a82303685df9c1aac'
    baseline_archive_sha256 = (Get-FileHash benchmark\baseline-source.zip -Algorithm SHA256).Hash
    utc_started = (Get-Date).ToUniversalTime().ToString('o')
    dart_version = (& $Dart --version 2>&1 | Out-String).Trim()
    flutter_version = Get-Content 'C:\flutter\bin\cache\flutter.version.json' -Raw | ConvertFrom-Json
    cpu = Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors
    os = Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,TotalVisibleMemorySize
    gpu = Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion
    timezone = [TimeZoneInfo]::Local.Id
    rounds = $Rounds
    warmup_ms_per_case = 250
    mode = 'dart compile exe (AOT), windows_x64, same SDK and driver'
}
& $Dart compile exe benchmark\baseline\tool\benchmark.dart -o benchmark\baseline.exe
if ($LASTEXITCODE -ne 0) { throw 'Baseline compilation failed' }
& $Dart compile exe tool\benchmark.dart -o benchmark\optimized.exe
if ($LASTEXITCODE -ne 0) { throw 'Optimized compilation failed' }
$environment.binary_sizes = @{
    baseline_bytes = (Get-Item benchmark\baseline.exe).Length
    optimized_bytes = (Get-Item benchmark\optimized.exe).Length
}
$environment | ConvertTo-Json -Depth 10 | Set-Content benchmark\environment.json -Encoding utf8
$raw = [Collections.Generic.List[string]]::new()
$activity = [Collections.Generic.List[object]]::new()
for ($round = 0; $round -lt $Rounds; $round++) {
    $order = if ($round % 2 -eq 0) { @('baseline','optimized') } else { @('optimized','baseline') }
    foreach ($variant in $order) {
        $before = @{}
        Get-Process | ForEach-Object { $before[$_.Id] = $_.CPU }
        $started = Get-Date
        $lines = & (Join-Path $benchRoot "$variant.exe") $round 2>> benchmark\checksums.txt
        if ($LASTEXITCODE -ne 0) { throw "$variant benchmark failed" }
        foreach ($line in $lines) {
            $entry = $line | ConvertFrom-Json
            $entry | Add-Member -NotePropertyName variant -NotePropertyValue $variant
            $raw.Add(($entry | ConvertTo-Json -Compress))
        }
        $others = @(Get-Process | ForEach-Object {
            if ($before.ContainsKey($_.Id) -and $null -ne $_.CPU) {
                $delta = $_.CPU - $before[$_.Id]
                if ($delta -gt 0.5) {
                    [pscustomobject]@{ name=$_.ProcessName; cpu_seconds=$delta }
                }
            }
        })
        $activity.Add(@{ round=$round; variant=$variant; utc=$started.ToUniversalTime().ToString('o');
            wall_seconds=((Get-Date)-$started).TotalSeconds; other_process_cpu=$others })
        $raw | Set-Content benchmark\timings.jsonl -Encoding utf8
        $activity | ConvertTo-Json -Depth 8 | Set-Content benchmark\activity.json -Encoding utf8
        Write-Output "Round $($round+1)/${Rounds}: $variant complete"
    }
}
