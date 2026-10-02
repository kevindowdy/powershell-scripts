# start-session-login.ps1

$AutomationName = "fetch-issues-and-maps-data-login"

$Python = "C:\Program Files\Python313\python.exe"
$BasePackagePath = "$env:USERPROFILE\Documents\Tools"

$Package = "$BasePackagePath\$AutomationName\login_setup.py"

Write-Host "Starting $AutomationName login setup..."

& $Python $Package

exit $LASTEXITCODE
