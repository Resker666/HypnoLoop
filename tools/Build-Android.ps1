param(
    [switch]$Online,
    [switch]$PrepareOnly,
    [string[]]$Tasks = @('lintDebug', 'testDebugUnitTest', 'assembleDebug'),
    [string]$JavaHome = 'E:\develop\github\minimal-sleep\.tools\jdk\jdk17.0.20_10',
    [string]$SharedAndroidSdk = 'E:\develop\github\minimal-sleep\.tools\android-sdk-ready',
    [string]$AdbDirectory = 'D:\soft\platform-tools',
    [string]$GradleHome = 'E:\develop\github\minimal-sleep\.tools\gradle-home',
    [string]$GradleExecutable = 'E:\develop\github\minimal-sleep\.tools\gradle\gradle-8.13\bin\gradle.bat'
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskFlutter = Join-Path $taskRoot '.tools\flutter'
$taskSdkView = Join-Path $taskRoot '.tools\android-sdk'
foreach ($taskRequired in @("$JavaHome\bin\java.exe", "$taskFlutter\bin\flutter.bat", $GradleExecutable, "$AdbDirectory\adb.exe")) {
    if (-not (Test-Path -LiteralPath $taskRequired)) { throw "Missing installed tool: $taskRequired" }
}
New-Item -ItemType Directory -Path $taskSdkView -Force | Out-Null
$taskLinks = @{
    'platforms' = Join-Path $SharedAndroidSdk 'platforms'
    'build-tools' = Join-Path $SharedAndroidSdk 'build-tools'
    'platform-tools' = $AdbDirectory
}
foreach ($taskName in $taskLinks.Keys) {
    $taskLink = Join-Path $taskSdkView $taskName
    if (-not (Test-Path -LiteralPath $taskLinks[$taskName])) { throw "Missing shared SDK component: $($taskLinks[$taskName])" }
    if (-not (Test-Path -LiteralPath $taskLink)) {
        New-Item -ItemType Junction -Path $taskLink -Target $taskLinks[$taskName] | Out-Null
    } elseif ((Get-Item -LiteralPath $taskLink).Target -ne $taskLinks[$taskName]) {
        throw "SDK view already points elsewhere: $taskLink"
    }
}
$env:JAVA_HOME = $JavaHome
$env:ANDROID_HOME = $taskSdkView
$env:ANDROID_SDK_ROOT = $taskSdkView
$env:GRADLE_USER_HOME = $GradleHome
$env:PUB_CACHE = Join-Path $taskRoot '.tools\pub-cache'
$env:CI = 'true'
$env:Path = "$JavaHome\bin;$AdbDirectory;$taskFlutter\bin;$env:Path"
# Allow these known checkouts for this process only, including sandbox identities.
$env:GIT_CONFIG_COUNT = '2'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = $taskRoot.Replace('\', '/')
$env:GIT_CONFIG_KEY_1 = 'safe.directory'
$env:GIT_CONFIG_VALUE_1 = $taskFlutter.Replace('\', '/')
$taskProperties = @(
    "sdk.dir=$($taskSdkView.Replace('\', '/'))",
    "flutter.sdk=$($taskFlutter.Replace('\', '/'))",
    'flutter.buildMode=debug',
    'flutter.versionName=0.1.0',
    'flutter.versionCode=1'
)
Set-Content -LiteralPath (Join-Path $taskRoot 'android\local.properties') -Value $taskProperties -Encoding ascii
if ($PrepareOnly) { return }
Push-Location $taskRoot
try {
    $taskPubArgs = @('pub', 'get')
    if (-not $Online) { $taskPubArgs += '--offline' }
    & "$taskFlutter\bin\flutter.bat" @taskPubArgs
    if ($LASTEXITCODE -ne 0) { throw 'Pub resolution failed' }
    Push-Location (Join-Path $taskRoot 'android')
    try {
        $taskGradleArgs = @('--no-daemon', '--console', 'plain', '-Pkotlin.compiler.execution.strategy=in-process')
        if (-not $Online) { $taskGradleArgs += '--offline' }
        & $GradleExecutable @taskGradleArgs @Tasks
        if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
    } finally { Pop-Location }
} finally { Pop-Location }
