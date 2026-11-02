# Powershell Scripts
Collection of powershell scripts and batch files used in a Windows environment to automate the scheduling, running and management of different business workflows.

## Schedule a task using schtasks.exe in PS or CMD
```
schtasks /Create `
    /TN "Issues and MAPs refresh" `
    /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Documents\Tools\powershell-scripts\start-issues-and-maps-flow.ps1" `
    /SC DAILY `
    /ST 07:30 `
    /F
```
* TN - Task Name that appears in Task Scheduler
* TR - Specifies the Task Run that will execute when the task runs
* SC - Defines the frequency for the task to run
* ST - Defines the time the task should start
* F - Forces the creation of the task and overwrites existing tasks with the same name


## Run a task immediately for testing using schtasks.exe in PS or CMD
```
schtasks /Run /TN "P0 Vulnerability Management Bot"
```

## View a task using schtasks.exe in PS or CMD
```
schtasks /Query /TN "Vulnerability Management Pipeline" /V /FO LIST
```

## Delete a task using schtasks.exe in PS or CMD
```
schtasks /Delete /TN "Vulnerability Management Pipeline" /F
```


## Run the Archer login setup at log on
`start-session-login.ps1` runs `fetch-issues-and-maps-data\login_setup.py` with Python 3.13.
```
schtasks /Create `
    /TN "Session Login" `
    /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Documents\Tools\powershell-scripts\start-session-login.ps1" `
    /SC ONLOGON `
    /F
```
* Runs only while you are logged on, because `login_setup.py` opens a visible Chrome window
* `login_setup.py` ends with `input()`, so it still waits for Enter after you sign in

## Run the ServiceNow cloud vulnerability bot daily at 4 AM
`start-servicenow-bot.ps1` runs the `servicenow-bot` UiPath package (fetch -> process -> upload to SharePoint). Run it by hand first: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\start-servicenow-bot.ps1`
```
schtasks /Create `
    /TN "ServiceNow Cloud Vulnerabilities Bot" `
    /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Documents\Tools\powershell-scripts\start-servicenow-bot.ps1" `
    /SC DAILY `
    /ST 04:00 `
    /F
```
* Needs `UiRobot.exe`, `Documents\Packages\servicenow-bot.<version>.nupkg` (bump `$Version` in the script on each publish) and the `fetch-cloud-vulnerabilities` / `process-cloud-vulnerabilities` repos under `Documents\Tools`.
* Runs as the creating user and only while that user is logged on (no `/RU`): UiPath and the Playwright session in `storage_state.json` are per-user. The machine must be logged in and unlocked at 04:00; a locked/logged-out session is a failure mode.
* `schtasks /Create` defaults to "do not start a new instance" if the previous run is still going, so overlapping runs are skipped.
* `-ExecutionPolicy Bypass` is used only because the scripts are unsigned; it is a per-process flag, not a machine setting.
* Run on demand: `schtasks /Run /TN "ServiceNow Cloud Vulnerabilities Bot"`

| Exit code | Meaning |
|---|---|
| 0 | Success |
| 1 | Unexpected failure in the launcher |
| 3 | Missing dependency (UiRobot.exe or the .nupkg) |
| 4 | UiRobot could not be launched |
| 5 | Bot ran and failed after exhausting retries |

Task Scheduler shows the exit code under *Last Run Result* (`0x5` = 5). The launcher log is `Documents\Temporary\FIG_App_Logs\servicenow-bot_<yyyyMMdd>.log`; the bot's own logs are in Orchestrator/UiRobot logs and `FIG_App_Logs\app_<yyyyMMdd>.log`. A failed run can be rerun safely: the bot deletes and recreates the day's outputs and the upload replaces the existing file.

Tests (Windows, Pester 5): `Invoke-Pester -Output Detailed`
