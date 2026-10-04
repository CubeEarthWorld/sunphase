$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workRoot = Join-Path $repoRoot '.dart_tool\sunphase-check'
$baseline = '6d2a063cc36ac353fc7a941a82303685df9c1aac'
New-Item -ItemType Directory -Path "$workRoot\tool", "$workRoot\benchmark\baseline\tool" -Force | Out-Null
git -C $repoRoot archive --format=zip "--output=$workRoot\baseline.zip" $baseline lib
if ($LASTEXITCODE -ne 0) { throw "Baseline missing. Run: git fetch origin $baseline" }
Expand-Archive -LiteralPath "$workRoot\baseline.zip" -DestinationPath "$workRoot\benchmark\baseline" -Force
Copy-Item -LiteralPath "$repoRoot\lib" -Destination $workRoot -Recurse -Force
Copy-Item -LiteralPath "$repoRoot\tool\benchmark.dart", "$repoRoot\tool\workloads.dart" -Destination "$workRoot\tool" -Force
Copy-Item -LiteralPath "$repoRoot\tool\benchmark.dart", "$repoRoot\tool\workloads.dart" -Destination "$workRoot\benchmark\baseline\tool" -Force
Copy-Item -LiteralPath "$repoRoot\tool\equivalence.dart.in" -Destination "$workRoot\tool\equivalence.dart" -Force
Write-Output $workRoot
