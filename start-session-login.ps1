# start-session-login.ps1

$AutomationName = "session-startup-bot"
$Version = "1.0.1"

$UiRobot = "C:\Program Files\UiPath\Studio\UiRobot.exe"
$BasePackagePath = "$env:USERPROFILE\Documents\Packages"

$Package = "$BasePackagePath\$AutomationName.$Version.nupkg"

Write-Host "Starting $AutomationName..."

& $UiRobot execute --file $Package

exit $LASTEXITCODE
