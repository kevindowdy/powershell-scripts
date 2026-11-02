# Pester 5 tests. Run on Windows: Invoke-Pester -Output Detailed
# A fake "UiRobot" .cmd returns the exit code held in $env:FAKE_ROBOT_EXIT.
BeforeAll {
    . (Join-Path $PSScriptRoot "..\start-servicenow-bot.ps1")
    $script:Root = Join-Path ([IO.Path]::GetTempPath()) ("sn-bot-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $script:Root | Out-Null
    $script:FakeRobot = Join-Path $script:Root "UiRobot.cmd"
    Set-Content -LiteralPath $script:FakeRobot -Value "@echo off`r`nexit /b %FAKE_ROBOT_EXIT%"
    Set-Content -LiteralPath (Join-Path $script:Root "servicenow-bot.1.0.0.nupkg") -Value "x"

    function Invoke-Bot([string]$Robot = $script:FakeRobot, [string]$Version = "1.0.0") {
        Invoke-ServiceNowBot -AutomationName "servicenow-bot" -Version $Version `
            -UiRobotPath $Robot -PackageDirectory $script:Root -LogDirectory (Join-Path $script:Root "logs") 6>$null
    }
}
AfterAll { Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue }

Describe "Invoke-ServiceNowBot exit codes" {
    It "returns 0 when UiRobot succeeds" { $env:FAKE_ROBOT_EXIT = "0"; Invoke-Bot | Should -Be 0 }
    It "returns 5 when UiRobot returns non-zero" { $env:FAKE_ROBOT_EXIT = "1"; Invoke-Bot | Should -Be 5 }
    It "returns 3 when UiRobot.exe is missing" { Invoke-Bot -Robot (Join-Path $script:Root "nope.exe") | Should -Be 3 }
    It "returns 3 when the package is missing" { Invoke-Bot -Version "9.9.9" | Should -Be 3 }
    It "returns 4 when UiRobot cannot be launched" {
        $notExe = Join-Path $script:Root "notexe.exe"; Set-Content -LiteralPath $notExe -Value "not a program"
        Invoke-Bot -Robot $notExe | Should -Be 4
    }
    It "writes a log file with the final exit code" {
        $env:FAKE_ROBOT_EXIT = "0"; Invoke-Bot | Out-Null
        (Get-Content (Get-ChildItem (Join-Path $script:Root "logs") -Filter *.log | Select-Object -First 1).FullName -Raw) | Should -Match "event=completed exit_code=0"
    }
}
