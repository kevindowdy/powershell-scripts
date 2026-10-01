$AutomationName = "custom-datadog-log-forwarder"

$BasePackagePath = "$env:USERPROFILE\Documents\Tools"
$ProjectPath = "$BasePackagePath\$AutomationName"
$Package = "$ProjectPath\src\main.go"

Write-Host "Starting $AutomationName..."

Push-Location $ProjectPath

try {
    & go run $Package
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
