param([string]$Dart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe')
$ErrorActionPreference = 'Stop'
$workRoot = & "$PSScriptRoot\prepare-baseline.ps1"
& $Dart analyze "$workRoot\tool\equivalence.dart"
if ($LASTEXITCODE -ne 0) { throw 'Equivalence analyzer failed' }
& $Dart "$workRoot\tool\equivalence.dart"
if ($LASTEXITCODE -ne 0) { throw 'Equivalence check failed' }
