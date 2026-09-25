# Builds the Snake Watch APK on this PC.
# Java can't use the default Temp folder here (the Windows user folder has a space in its name),
# so the build uses a local .tmp folder instead.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$tmp = Join-Path $here '.tmp'
New-Item -ItemType Directory -Force $tmp | Out-Null
$env:TEMP = $tmp
$env:TMP = $tmp
$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=$tmp -Djava.io.tmpdir=$tmp"
Set-Location $here
flutter build apk --release
Copy-Item "$here\build\app\outputs\flutter-apk\app-release.apk" "$here\SnakeWatch.apk" -Force
Write-Host "APK ready: $here\SnakeWatch.apk"
