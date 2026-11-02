# start-servicenow-data-pipeline.ps1


$AutomationName = "servicenow-bot"
$Version = "1.0.0"

$UiRobot = "C:\Program Files\UiPath\Studio\UiRobot.exe"
$BasePackagePath = "$env:USERPROFILE\Documents\Packages"

$Package = "$BasePackagePath\$AutomationName.$Version.nupkg"

Write-Host "Starting $AutomationName..."

& $UiRobot execute --file $Package

exit $LASTEXITCODE
