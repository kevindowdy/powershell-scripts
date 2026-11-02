<#
.SYNOPSIS
Runs the servicenow-bot UiPath package (EPS cloud vulnerabilities -> SharePoint).

.DESCRIPTION
Entry point for the 4 AM Windows Task Scheduler job. Validates dependencies,
launches UiRobot synchronously, waits for it to finish and maps the result to a
documented exit code so Task Scheduler records failures. Compatible with
Windows PowerShell 5.1 and PowerShell 7+. Never prompts for input.

Exit codes:
  0  Success
  1  Unexpected failure in this script
  3  Missing dependency (UiRobot.exe or the .nupkg not found)
  4  UiPath launch failure (UiRobot could not be started)
  5  UiPath execution failure (UiRobot ran and returned non-zero, i.e. the
     bot exhausted its retries and raised an error)

.PARAMETER AutomationName
UiPath package name.

.PARAMETER Version
Package version to run. Bump when a new build is published.

.PARAMETER UiRobotPath
Full path of UiRobot.exe.

.PARAMETER PackageDirectory
Folder that holds the published .nupkg files.

.PARAMETER LogDirectory
Folder for this launcher's log (one file per day, appended on re-runs).

.EXAMPLE
.\start-servicenow-bot.ps1
#>
[CmdletBinding()]
param(
    [string]$AutomationName = "servicenow-bot",
    [string]$Version = "1.0.0",
    [string]$UiRobotPath = "C:\Program Files\UiPath\Studio\UiRobot.exe",
    [string]$PackageDirectory = (Join-Path $env:USERPROFILE "Documents\Packages"),
    [string]$LogDirectory = (Join-Path $env:USERPROFILE "Documents\Temporary\FIG_App_Logs")
)

$ErrorActionPreference = 'Stop'

function Write-AutomationLog {
    <#
    .SYNOPSIS
    Writes one structured log line to the console and the daily log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Event,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO',
        [string]$Detail = "",
        [string]$LogFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    $line = "{0} {1,-5} automation={2} host={3} event={4}" -f $timestamp, $Level, $script:AutomationLogName, $env:COMPUTERNAME, $Event
    if ($Detail) { $line = "$line $Detail" }
    Write-Host $line
    if ($LogFile) {
        try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 }
        catch { Write-Warning "Unable to write log file '$LogFile': $($_.Exception.Message)" }
    }
}

function Invoke-ServiceNowBot {
    <#
    .SYNOPSIS
    Validates dependencies, runs UiRobot synchronously and returns the exit code.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$AutomationName,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$UiRobotPath,
        [Parameter(Mandatory)][string]$PackageDirectory,
        [Parameter(Mandatory)][string]$LogDirectory
    )

    $script:AutomationLogName = $AutomationName
    $logFile = $null
    try {
        # Logging must never be the reason the bot does not run.
        if (-not (Test-Path -LiteralPath $LogDirectory)) {
            New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        }
        $logFile = Join-Path $LogDirectory ("{0}_{1}.log" -f $AutomationName, (Get-Date -Format "yyyyMMdd"))
    }
    catch {
        Write-Warning "Log directory unavailable, logging to console only: $($_.Exception.Message)"
    }

    try {
        $package = Join-Path $PackageDirectory "$AutomationName.$Version.nupkg"
        Write-AutomationLog -Event started -Detail "version=$Version user=$env:USERNAME package=`"$package`"" -LogFile $logFile

        if (-not (Test-Path -LiteralPath $UiRobotPath -PathType Leaf)) {
            Write-AutomationLog -Event missing_dependency -Level ERROR -Detail "uirobot=`"$UiRobotPath`" exit_code=3" -LogFile $logFile
            return 3
        }
        if (-not (Test-Path -LiteralPath $package -PathType Leaf)) {
            Write-AutomationLog -Event missing_dependency -Level ERROR -Detail "package=`"$package`" exit_code=3" -LogFile $logFile
            return 3
        }

        try {
            # -Wait: the exit code only means something once UiPath has finished.
            $process = Start-Process -FilePath $UiRobotPath `
                -ArgumentList @("execute", "--file", "`"$package`"") `
                -Wait -PassThru -NoNewWindow
        }
        catch {
            Write-AutomationLog -Event uipath_launch_failed -Level ERROR -Detail "error=`"$($_.Exception.Message)`" exit_code=4" -LogFile $logFile
            return 4
        }
        Write-AutomationLog -Event uipath_started -Detail "pid=$($process.Id)" -LogFile $logFile

        if ($process.ExitCode -ne 0) {
            Write-AutomationLog -Event uipath_failed -Level ERROR -Detail "uipath_exit_code=$($process.ExitCode) exit_code=5" -LogFile $logFile
            return 5
        }

        Write-AutomationLog -Event completed -Detail "exit_code=0" -LogFile $logFile
        return 0
    }
    catch {
        Write-AutomationLog -Event unexpected_failure -Level ERROR -Detail "error=`"$($_.Exception.Message)`" exit_code=1" -LogFile $logFile
        return 1
    }
}

# Skipped when dot-sourced (Pester) so the functions can be tested without running the bot.
if ($MyInvocation.InvocationName -ne '.') {
    $result = Invoke-ServiceNowBot -AutomationName $AutomationName -Version $Version `
        -UiRobotPath $UiRobotPath -PackageDirectory $PackageDirectory -LogDirectory $LogDirectory
    exit $result
}
