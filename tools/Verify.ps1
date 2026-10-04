$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    . "$PSScriptRoot\Build-Android.ps1" -PrepareOnly
    & "$taskRoot\.tools\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed lib test
    if ($LASTEXITCODE -ne 0) { throw 'Dart formatting check failed' }
    & "$taskRoot\.tools\flutter\bin\flutter.bat" analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed' }
    & "$taskRoot\.tools\flutter\bin\flutter.bat" test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed' }
    & "$PSScriptRoot\Build-Android.ps1"
} finally { Pop-Location }
