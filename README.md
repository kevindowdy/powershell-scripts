# Powershell Scripts
Collection of powershell scripts and batch files used in a Windows environment to automate the scheduling, running and management of different business workflows.

## Schedule a task using schtasks.exe in PS or CMD
```
schtasks /Create `
    /TN "Vulnerability Management Pipeline" `
    /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Automation\run-vulnerability-pipeline.ps1" `
    /SC DAILY `
    /ST 06:00 `
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
