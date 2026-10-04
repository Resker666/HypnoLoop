param(
    [string]$DeviceId = '',
    [switch]$SkipBuild,
    [switch]$Attach
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    . "$PSScriptRoot\Build-Android.ps1" -PrepareOnly
    if (-not $SkipBuild) { & "$PSScriptRoot\Build-Android.ps1" }
    $taskAdb = (Get-Command adb.exe -ErrorAction Stop).Source
    $taskDevices = @(& $taskAdb devices | ForEach-Object {
        if ($_ -match '^(\S+)\s+device$') { $Matches[1] }
    })
    if (-not $DeviceId) {
        if ($taskDevices.Count -ne 1) { throw 'Specify -DeviceId when there is not exactly one connected device.' }
        $DeviceId = $taskDevices[0]
    }
    if ($DeviceId -notin $taskDevices) { throw "Device is not connected or authorized: $DeviceId" }
    $taskApk = Join-Path $taskRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $taskApk)) { throw 'Build the debug APK before using -SkipBuild.' }
    & $taskAdb -s $DeviceId install -r $taskApk
    if ($LASTEXITCODE -ne 0) { throw 'APK installation failed' }
    # Flutter 3.41's default APK entry is B; it may be disabled after icon changes.
    # The target activity stays enabled regardless of the selected launcher alias.
    $taskLaunch = & $taskAdb -s $DeviceId shell am start -W -n 'com.hypnoloop.app/.MainActivity'
    $taskLaunch | Write-Output
    if ($LASTEXITCODE -ne 0 -or -not ($taskLaunch -match '^Status: ok$')) { throw 'App launch failed' }
    if ($Attach) {
        & "$taskRoot\.tools\flutter\bin\flutter.bat" attach -d $DeviceId --app-id com.hypnoloop.app
        if ($LASTEXITCODE -ne 0) { throw 'Flutter attach failed' }
    }
} finally { Pop-Location }
