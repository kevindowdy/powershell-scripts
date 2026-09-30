# start-custom-datadog-log-forwarder.ps1


$AutomationName = "custom-datadog-log-forwarder"

$Python = "C:\Program Files\Python313\python.exe"
$BasePackagePath = "$env:USERPROFILE\Documents\Tools"

$Package = "$BasePackagePath\$AutomationName\src\main.go"

Write-Host "Starting $AutomationName..."

& $Python execute --file $Package

exit $LASTEXITCODE
