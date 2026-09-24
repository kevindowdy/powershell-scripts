# CLAUDE.md

## Repository Purpose

This repository contains Windows automation tooling built primarily with PowerShell and Windows batch files.

The repository is used to automate Windows actions and orchestrate UiPath automations. Batch (`.bat` / `.cmd`) files may be scheduled through Windows Task Scheduler and used as stable entry points for PowerShell scripts, UiPath processes, or other Windows automation workflows.

Primary technologies:

- PowerShell
- Windows Batch (`.bat` / `.cmd`)
- Windows Task Scheduler
- UiPath
- Windows filesystem, processes, services, registry, and environment
- Git

Automation must be designed for unattended execution. Do not assume an interactive terminal, logged-in user, current working directory, mapped network drive, or user-specific environment unless the automation explicitly requires one.

---

## How to Work

The marginal cost of completeness is near zero with AI. Do the whole thing. Do it right. Do it with tests. Do it with documentation. Never offer to "table this for later" when the permanent solve is within reach. Never leave a dangling thread when tying it off takes five more minutes. Never present a workaround when the real fix exists.

Search before building. Test before shipping. Ship the complete thing.

You can outsource the typing. You cannot outsource the understanding.

Before calling anything DONE, be able to explain:

- Why the automation works.
- What Windows context it executes under.
- What external dependencies it requires.
- What happens when a dependency is unavailable.
- What happens when UiPath fails.
- What happens when the script is executed twice.
- What exit code is returned.
- Where execution is logged.
- What permissions are required.
- Where the automation could fail.

Tests passing is not sufficient if the runtime behavior is not understood.

---

## Branching — One Branch Per Task

This section is non-negotiable and runs before task triage.

Nothing lands directly on `main`.

Multiple Claude Code sessions may operate against the repository simultaneously.

Branches must follow:

```text
kd/<task-id>-<task-title>
```

Examples:

```text
kd/123-add-uipath-launcher
kd/124-add-task-scheduler-script
kd/125-fix-automation-logging
```

Before creating a branch:

1. Fetch the latest remote state.
2. Switch to `main`.
3. Update `main`.
4. Create the task branch from the updated `main`.

Multiple sessions working on the same task should continue using the branch already created for that task.

Never create a second branch for the same task unless explicitly instructed.

---

## Task Sizing

Every task starts with a printed triage block before implementation.

The branching setup runs first because the triage block reports the resulting branch.

Required format:

```text
Size: small | medium | large — <reason>
Tests: local (<specific tests>) | full suite — <reason>
Branch: <branch name>
```

Never skip this block.

---

## Completion Status Protocol

Every task must end with exactly one status:

### DONE

All work is complete.

Provide evidence including:

- Tests executed.
- Test results.
- Files changed.
- Relevant manual validation.
- Exit-code validation when applicable.
- Any UiPath or Task Scheduler validation performed.

Ready to merge.

### DONE_WITH_CONCERNS

Implementation is complete, but operational or technical concerns remain.

For every concern include:

- Severity
- Description
- Impact
- Recommended follow-up

### BLOCKED

Work cannot continue.

State:

- What is blocking progress.
- What was attempted.
- What information, permission, dependency, or environment is required.

### NEEDS_CONTEXT

Required information is missing.

State exactly what information is needed.

"Partially done" is not a valid status.

---

# Development Flow

Use the following development lifecycle:

1. Define the task.
2. Fetch the latest `main`.
3. Create or reuse the task branch.
4. Inspect existing automation patterns.
5. Identify execution context and dependencies.
6. Implement the change.
7. Test locally.
8. Validate failure behavior.
9. Validate logging and exit codes.
10. Update documentation.
11. Commit the change.
12. Open a pull request.

---

# PowerShell Standards

PowerShell is the primary scripting language for Windows automation in this repository.

Prefer PowerShell over batch files for application logic.

Batch files should generally serve as thin entry points into PowerShell or external automation tools.

## PowerShell Version

Check repository documentation before assuming a PowerShell version.

Where practical, prefer compatibility with:

```text
PowerShell 7+
```

If Windows PowerShell 5.1 compatibility is required, document that requirement.

Do not introduce PowerShell 7-only functionality into scripts expected to execute under Windows PowerShell 5.1.

---

## PowerShell Naming

Follow standard PowerShell naming conventions.

Functions should use approved `Verb-Noun` naming:

```powershell
Start-UiPathAutomation
Get-AutomationConfig
Write-AutomationLog
Test-AutomationDependency
```

Variables should be descriptive:

```powershell
$UiPathExecutablePath
$AutomationName
$LogDirectory
$ExitCode
```

Avoid unclear names such as:

```powershell
$x
$temp
$data1
$thing
```

unless the scope makes their purpose immediately obvious.

---

## PowerShell Functions

Keep functions focused on a single responsibility.

Prefer:

```powershell
function Start-UiPathAutomation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    # Implementation
}
```

over large procedural scripts containing unrelated operations.

Reusable behavior should be extracted into functions or modules.

---

## Parameters

Scripts intended for automation should expose configurable values through parameters rather than hardcoded values.

Prefer:

```powershell
param(
    [Parameter(Mandatory)]
    [string]$ProcessName,

    [string]$LogDirectory = "$PSScriptRoot\logs"
)
```

Avoid:

```powershell
$ProcessName = "MyAutomation"
$LogDirectory = "C:\Users\Kevin\Desktop\logs"
```

unless the value is intentionally repository-specific and documented.

---

## Paths

Never assume the current working directory.

Scheduled tasks may execute with a working directory such as:

```text
C:\Windows\System32
```

Resolve repository-relative files using:

```powershell
$PSScriptRoot
```

Example:

```powershell
$ConfigPath = Join-Path $PSScriptRoot "config\automation.json"
```

Prefer `Join-Path` over manually concatenating Windows paths.

---

# Batch File Standards

Batch files should be minimal orchestration wrappers.

Do not implement substantial business logic in batch files when PowerShell can perform the operation more safely and clearly.

A typical batch file should:

1. Determine its own directory.
2. Invoke the appropriate PowerShell script or UiPath command.
3. Capture the process exit code.
4. Return that exit code to Task Scheduler.

Example:

```bat
@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\Start-Automation.ps1"

set "EXIT_CODE=%ERRORLEVEL%"

exit /b %EXIT_CODE%
```

Use `pwsh.exe` instead when the automation explicitly targets PowerShell 7.

Do not silently discard exit codes.

---

# UiPath Automation Standards

UiPath automations launched from this repository must be treated as external processes.

The orchestration layer is responsible for:

- Starting the intended automation.
- Supplying required parameters.
- Detecting launch failures.
- Detecting non-zero exit codes when available.
- Logging execution.
- Returning meaningful status to the caller.
- Preventing unintended concurrent executions when necessary.

Do not assume that successfully starting a UiPath executable means the automation successfully completed.

Distinguish between:

```text
Launcher started successfully
```

and:

```text
UiPath automation completed successfully
```

These are different states.

---

## UiPath Paths

Do not assume the UiPath executable is installed in the same location on every Windows machine.

Where practical, make executable locations configurable.

For example:

```powershell
param(
    [string]$UiPathExecutablePath
)
```

Validate executable existence before attempting execution:

```powershell
if (-not (Test-Path -LiteralPath $UiPathExecutablePath)) {
    throw "UiPath executable not found: $UiPathExecutablePath"
}
```

---

# Windows Task Scheduler Standards

Automations should be designed with Windows Task Scheduler behavior in mind.

Before considering a scheduled automation production-ready, determine:

- Which Windows account runs the task.
- Whether it runs when the user is logged out.
- Whether UiPath requires an interactive desktop session.
- Whether the account has filesystem permissions.
- Whether the account has network permissions.
- Whether mapped drives are required.
- Whether environment variables exist for that account.
- Whether the task requires elevated privileges.
- What happens when the previous execution is still running.
- What happens after a machine restart.

Do not assume behavior observed in an interactive PowerShell terminal will be identical under Task Scheduler.

---

## Scheduled Task Configuration

Where appropriate, configure or document:

```text
Program/script:
    <batch file or PowerShell executable>

Start in:
    <repository or automation directory>

Run whether user is logged on or not:
    depends on UiPath/session requirements

Run with highest privileges:
    only when required

If the task is already running:
    explicitly define desired behavior
```

Prefer the least privilege necessary for the automation.

---

# Unattended Execution

All automation should be evaluated for unattended execution.

Do not rely on:

- Interactive prompts.
- `Read-Host`.
- Message boxes.
- Manual confirmation.
- An open terminal.
- The current user's desktop.
- Current working directory.
- User-specific mapped drives.
- Manually established network connections.

unless the automation explicitly requires interactive execution.

Scheduled automation must fail clearly rather than wait indefinitely for input.

---

# Idempotency

Where practical, automations should be safe to execute more than once.

Before modifying system state, determine whether the desired state already exists.

Prefer:

```text
Check → Change if necessary → Verify
```

over:

```text
Blindly change every execution
```

Examples include:

- Creating directories.
- Copying files.
- Starting processes.
- Registering scheduled tasks.
- Modifying configuration.
- Creating registry values.
- Downloading artifacts.

Repeated execution should not corrupt state or produce unintended duplicate work.

---

# Concurrency

Assume scheduled automations may overlap unless explicitly prevented.

For automations that must have only one active execution, implement or configure concurrency protection.

Possible mechanisms include:

- Task Scheduler "Do not start a new instance."
- Lock files.
- Named mutexes.
- Process detection.

The selected approach should account for stale locks and abnormal process termination.

Do not add custom locking when Task Scheduler configuration alone provides the required guarantee unless there is a clear reason.

---

# Error Handling

PowerShell scripts should fail predictably.

For automation scripts, consider:

```powershell
$ErrorActionPreference = 'Stop'
```

when terminating behavior is appropriate.

Use:

```powershell
try {
    # operation
}
catch {
    # log contextual information
    throw
}
finally {
    # cleanup when required
}
```

Catch errors only when the script can:

- Add meaningful context.
- Perform cleanup.
- Retry safely.
- Translate the error into an appropriate exit status.

Do not catch exceptions simply to suppress them.

Avoid:

```powershell
try {
    # operation
}
catch {
}
```

---

# Exit Codes

Exit codes are part of the automation contract.

Use:

```text
0 = success
non-zero = failure
```

Where different failure modes need to be distinguished, define documented exit codes.

Example:

```text
0  Success
1  General failure
2  Invalid configuration
3  Missing dependency
4  UiPath launch failure
5  UiPath execution failure
6  Concurrent execution detected
```

Do not introduce arbitrary exit codes without documenting them.

Batch files must propagate PowerShell or UiPath exit codes to Task Scheduler.

PowerShell entry-point scripts should explicitly exit when appropriate:

```powershell
exit 0
```

or:

```powershell
exit 1
```

---

# Logging

Every scheduled automation should produce sufficient logs to determine:

- What started.
- When it started.
- Which automation ran.
- Which machine executed it.
- Whether dependencies were available.
- Major execution milestones.
- Whether UiPath launched.
- Whether UiPath completed.
- Whether execution succeeded or failed.
- The final exit code.
- When execution ended.

Never log:

- Passwords.
- API keys.
- Access tokens.
- Session tokens.
- Connection strings containing credentials.
- Sensitive business data unless explicitly required and approved.

Prefer structured, machine-readable logging where practical.

Example:

```text
2026-09-24T19:00:00-04:00 INFO  automation=DailyReport event=started
2026-09-24T19:00:03-04:00 INFO  automation=DailyReport event=uipath_started
2026-09-24T19:04:17-04:00 INFO  automation=DailyReport event=completed exit_code=0
```

Logs should support future ingestion into centralized monitoring platforms such as Datadog or enterprise SIEM tooling.

---

# Security

Automation frequently executes with elevated or service-account permissions and must be treated as privileged code.

Never:

- Hardcode credentials.
- Commit passwords.
- Commit API keys.
- Commit private certificates.
- Store plaintext credentials in batch files.
- Log secrets.
- Disable security controls simply to make automation work.

Prefer:

- Windows Credential Manager.
- Approved enterprise secret-management systems.
- Environment variables when appropriate.
- Managed service identities or service accounts where available.
- Least-privilege filesystem permissions.
- Least-privilege Windows accounts.

PowerShell execution-policy bypasses should not be treated as a security architecture.

If `-ExecutionPolicy Bypass` is required by the environment, document why.

---

# Windows Permissions

Always consider which identity executes the automation.

Interactive execution may run as:

```text
DOMAIN\Kevin
```

while Task Scheduler may run as:

```text
DOMAIN\AutomationService
```

Those identities can have different:

- NTFS permissions.
- Network permissions.
- Environment variables.
- UiPath configuration.
- User profiles.
- Registry hives.
- Credential stores.

Never assume permissions based solely on successful interactive execution.

---

# Network Resources

Prefer UNC paths:

```text
\\server\share\folder
```

over mapped drives:

```text
Z:\folder
```

Mapped drives are session-specific and may not exist for scheduled tasks.

Network operations must handle:

- DNS failures.
- Authentication failures.
- Unavailable shares.
- Timeouts.
- Temporary connectivity failures.

Retries should only be used for failures that are plausibly transient.

Use bounded retries with delays rather than infinite retry loops.

---

# Process Execution

When starting external programs from PowerShell, prefer explicit process control.

Example:

```powershell
$process = Start-Process `
    -FilePath $ExecutablePath `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru

if ($process.ExitCode -ne 0) {
    throw "Process failed with exit code $($process.ExitCode)"
}
```

Use `-Wait` when downstream logic depends on process completion.

Do not assume process creation equals process success.

---

# Configuration

Separate environment-specific configuration from automation logic.

Configuration may include:

- UiPath executable paths.
- Process names.
- Input directories.
- Output directories.
- Log directories.
- Timeouts.
- Retry limits.
- Network locations.

Prefer configuration files, environment variables, or script parameters over hardcoded values.

Do not store secrets in normal configuration files committed to Git.

---

# Documentation Standards

Every automation should document:

- Purpose.
- Entry point.
- Dependencies.
- Required PowerShell version.
- Required Windows permissions.
- Required UiPath components.
- Configuration.
- Inputs.
- Outputs.
- Exit codes.
- Logging location.
- Scheduling requirements.
- Failure behavior.
- Recovery procedure.

Public PowerShell functions should include comment-based help when appropriate:

```powershell
<#
.SYNOPSIS
Starts a UiPath automation.

.DESCRIPTION
Launches the configured UiPath process and waits for completion.

.PARAMETER ProcessName
Name of the UiPath process to execute.

.EXAMPLE
Start-UiPathAutomation -ProcessName "DailyReport"
#>
```

Comments should explain why behavior exists rather than restating obvious code.

---

# Manual Validation

Automation involving Windows Task Scheduler or UiPath often requires integration validation beyond unit tests.

Before production use, validate:

1. Run the PowerShell script manually.
2. Run the batch entry point manually.
3. Confirm the batch file propagates the exit code.
4. Run the automation from Task Scheduler.
5. Test under the actual scheduled-task account.
6. Verify logs are produced.
7. Verify failure behavior.
8. Verify Task Scheduler records the expected result.
9. Verify UiPath receives the expected inputs.
10. Verify repeated or overlapping execution behavior.

A script working from an interactive terminal is not sufficient evidence that scheduled execution works.

---

# PowerShell Testing Commands

## Pester

```powershell
Invoke-Pester
```

Detailed:

```powershell
Invoke-Pester -Output Detailed
```

---

# PowerShell Analysis

Use PSScriptAnalyzer when configured.

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse
```

Do not suppress analyzer rules without documenting why.

---

# Syntax Validation

PowerShell scripts should be syntax-validated before commit.

Example:

```powershell
$errors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    ".\scripts\Start-Automation.ps1",
    [ref]$null,
    [ref]$errors
)

$errors
```

---

# Recommended Project Structure

```text
.
├── CLAUDE.md
├── README.md
├── CHANGELOG.md
│
├── scripts/
│   ├── Start-Automation.ps1
│   ├── Install-ScheduledTask.ps1
│   └── Test-Environment.ps1
│
├── batch/
│   ├── Start-DailyReport.bat
│   └── Start-WeeklyReport.bat
│
├── modules/
│   └── Automation/
│       ├── Automation.psd1
│       └── Automation.psm1
│
├── config/
│   └── automation.example.json
│
├── logs/
│   └── .gitkeep
│
└── docs/
    ├── scheduling.md
    ├── operations.md
    └── troubleshooting.md
```

Do not commit generated logs.

---

# Git Standards

Commit small, logical changes.

Use descriptive commit messages.

Keep `main` deployable.

All production changes require pull requests.

Do not commit:

- Logs.
- Temporary files.
- Generated UiPath output.
- Credentials.
- Certificates containing private keys.
- Local configuration containing secrets.
- IDE-specific files unless intentionally shared.
- Machine-specific artifacts.

---

# Pull Request Requirements

Before opening a pull request verify:

- PowerShell syntax is valid.
- Pester tests pass.
- PSScriptAnalyzer passes when configured.
- Batch files propagate exit codes correctly.
- Paths work without relying on the current working directory.
- No credentials or sensitive information are committed.
- Logging is sufficient for unattended troubleshooting.
- Error behavior is deterministic.
- Documentation reflects behavior changes.
- `CHANGELOG.md` is updated for operational or user-facing changes.
- New dependencies are justified.
- Task Scheduler implications are documented.
- UiPath integration changes are documented.
- Testing evidence is included in the pull request.

---

# Automation Design Principles

## Reliability

Scheduled automation must be restartable whenever practical.

Prefer workflows that can safely recover after:

- Machine restart.
- Process termination.
- Network interruption.
- UiPath failure.
- Partial completion.

Do not leave the machine in an unknown state after a recoverable failure.

## Observability

Every automation should make its operational state discoverable.

At minimum, an operator should be able to determine:

```text
Did it start?
Is it running?
What is it doing?
Did UiPath start?
Did UiPath finish?
Did it succeed?
If it failed, why?
When did it fail?
Can it safely be rerun?
```

## Maintainability

Favor readability over cleverness.

Automation code will often be debugged during operational incidents. Optimize for the engineer who needs to understand the script quickly.

## Reusability

Centralize shared functionality such as:

- Logging.
- Configuration loading.
- UiPath execution.
- Process management.
- File validation.
- Retry behavior.
- Locking/concurrency control.

Avoid copying the same implementation into multiple scripts.

## Least Privilege

Do not run scheduled tasks as Administrator, SYSTEM, or a highly privileged domain account unless those privileges are actually required.

Determine the minimum Windows, filesystem, network, and UiPath permissions necessary.

---

# Definition of Done

An automation is not DONE merely because:

```text
"It worked when I ran it."
```

It is DONE when:

```text
The implementation is correct.
The PowerShell code is tested.
The batch entry point works.
Paths are deterministic.
Errors are handled.
Exit codes propagate correctly.
Logs explain execution.
Secrets are protected.
Required permissions are documented.
Task Scheduler behavior is understood.
UiPath behavior is understood.
Failure modes have been considered.
The automation can be operated and troubleshot unattended.
```

The target is not simply working automation.

The target is reliable Windows automation that can run unattended, fail predictably, and be understood by the next engineer responsible for operating it.
