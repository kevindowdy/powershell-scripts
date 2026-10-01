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
`start-session-login.ps1` wraps `fetch-issues-and-maps-data\login_setup.py` so it can run when you log on.
```
schtasks /Create `
    /TN "Session Login" `
    /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Documents\Tools\powershell-scripts\start-session-login.ps1" `
    /SC ONLOGON `
    /RL LIMITED `
    /F
```
* ONLOGON - triggers at log on of any user; add `/RU <account>` to restrict it to the intended account
* Runs only while the user is logged on (no `/RP`), because `login_setup.py` opens a headed Chrome window
* Parameters: `-PythonExecutablePath`, `-ScriptPath`, `-LogDirectory` (defaults: `C:\Program Files\Python313\python.exe`, `%USERPROFILE%\Documents\Tools\fetch-issues-and-maps-data\login_setup.py`, `logs\` next to the script)
* Log: `logs\session-login.log` (key=value lines, git-ignored)
* Exit codes: `0` success, `1` general failure, `3` python.exe or login_setup.py not found, `5` login_setup.py exited non-zero
* Note: `login_setup.py` currently ends with `input()`, so it waits for Enter after you sign in; it will not finish unattended.
