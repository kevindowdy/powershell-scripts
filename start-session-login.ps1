<#
.SYNOPSIS
Runs the Archer login setup (login_setup.py) at Windows log on.

.DESCRIPTION
Wrapper intended for a Task Scheduler "At log on" trigger. It validates that
Python and login_setup.py exist, runs the script, logs to a file, and returns
the Python exit code to the caller.

Requires an interactive desktop: login_setup.py opens a headed Chrome window
(passkey / SSO), so the task must run "only when user is logged on".
Compatible with Windows PowerShell 5.1 and PowerShell 7+.

.PARAMETER PythonExecutablePath
Path to python.exe.

.PARAMETER ScriptPath
Path to login_setup.py.

.PARAMETER LogDirectory
Directory for the log file. Created if missing.

.NOTES
Exit codes:
  0  Success
  1  General failure
  3  Missing dependency (python.exe or login_setup.py not found)
  5  login_setup.py exited non-zero
#>
[CmdletBinding()]
param(
    [string]$PythonExecutablePath = "C:\Program Files\Python313\python.exe",
    [string]$ScriptPath = (Join-Path $env:USERPROFILE "Documents\Tools\fetch-issues-and-maps-data\login_setup.py"),
    [string]$LogDirectory = (Join-Path $PSScriptRoot "logs")
)

$AutomationName = "session-login"
$ErrorActionPreference = 'Stop'
$LogPath = Join-Path $LogDirectory "$AutomationName.log"

function Write-AutomationLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Event,
        [string]$Level = "INFO",
        [string]$Detail = ""
    )
    $line = "{0} {1,-5} automation={2} host={3} event={4} {5}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"), $Level, $AutomationName, $env:COMPUTERNAME, $Event, $Detail
    Write-Host $line.TrimEnd()
    Add-Content -LiteralPath $LogPath -Value $line.TrimEnd()
}

function Invoke-SessionLogin {
    [CmdletBinding()]
    param()

    foreach ($dependency in @($PythonExecutablePath, $ScriptPath)) {
        if (-not (Test-Path -LiteralPath $dependency)) {
            Write-AutomationLog -Event missing_dependency -Level ERROR -Detail "path=`"$dependency`""
            return 3
        }
    }

    Write-AutomationLog -Event python_started -Detail "script=`"$ScriptPath`""
    # Run from the script's own directory so relative files resolve
    # regardless of Task Scheduler's working directory (e.g. System32).
    $process = Start-Process -FilePath $PythonExecutablePath `
        -ArgumentList @("`"$ScriptPath`"") `
        -WorkingDirectory (Split-Path -Parent $ScriptPath) `
        -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        Write-AutomationLog -Event python_failed -Level ERROR -Detail "exit_code=$($process.ExitCode)"
        return 5
    }
    return 0
}

$ExitCode = 1
try {
    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    Write-AutomationLog -Event started -Detail "user=$env:USERNAME"
    $ExitCode = Invoke-SessionLogin
}
catch {
    Write-AutomationLog -Event failed -Level ERROR -Detail "error=`"$($_.Exception.Message)`""
    $ExitCode = 1
}
finally {
    try { Write-AutomationLog -Event completed -Detail "exit_code=$ExitCode" } catch { Write-Host "log write failed: $_" }
}

exit $ExitCode
