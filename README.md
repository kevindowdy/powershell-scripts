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
