# Intune Proactive Remediation Patterns

Patterns for Microsoft Intune Proactive Remediation scripts.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Script Header Format (Enterprise Standard)](#script-header-format-enterprise-standard)
3. [Module Validation Pattern](#module-validation-pattern)
4. [Detection Script Pattern](#detection-script-pattern)
5. [Remediation Script Pattern](#remediation-script-pattern)
6. [CLI Script Helpers (No GUI)](#cli-script-helpers-no-gui)
   - [Write-Banner Pattern](#write-banner-pattern)
   - [Finish-Script Helper](#finish-script-helper)
   - [Config-Driven Command Execution](#config-driven-command-execution)
   - [Complete CLI Script Template](#complete-cli-script-template)
7. [Common Remediations](#common-remediations)
8. [Microsoft Graph API Integration](#microsoft-graph-api-integration)
9. [Logging and Output](#logging-and-output)
10. [Error Handling](#error-handling)
11. [Custom Compliance Policies](#custom-compliance-policies)
12. [Packaging for Intune](#packaging-for-intune)
13. [Cross-Service Device Lifecycle Management & Safeguards](#cross-service-device-lifecycle-management--safeguards)
14. [Fleet Health & Playbook Queries](#fleet-health--playbook-queries)
15. [Managed Identity Graph Permission Granting (`AppRoleAssignment`)](#managed-identity-graph-permission-granting-approleassignment)
16. [Azure Log Analytics Workspace (LAW) Ingestion Pattern](#azure-log-analytics-workspace-law-ingestion-pattern)
17. [The 6 Intune Operational Automation Domains](#the-6-intune-operational-automation-domains)
18. [Always-Run Detection Pattern (Scheduled Maintenance Action)](#always-run-detection-pattern-scheduled-maintenance-action)
19. [Multi-Target Resilient Remediation (Per-Target Failure Tracking)](#multi-target-resilient-remediation-per-target-failure-tracking)
20. [Multi-User Profile Operations in SYSTEM Context (`C:\Users\*`)](#multi-user-profile-operations-in-system-context-cusers)
21. [Metric Reporting Pattern (`Format-FileSize`)](#metric-reporting-pattern-format-filesize)

---

## Architecture

Each remediation is a self-contained folder:

```
<intune-remediation-name>/
├── detect-<name>.ps1     # Exit 0 = compliant, Exit 1 = non-compliant
├── remediate-<name>.ps1  # Fix the issue
└── README.md             # Description, requirements, version
```

### Detection → Remediation Flow

```
Detection.ps1 runs
  ├── Exit 0 → Compliant (no remediation needed)
  └── Exit 1 → Non-compliant → Remediation.ps1 runs
        ├── Exit 0 → Remediation succeeded
        └── Exit 1 → Remediation failed
```

### Exit Code Reference

| Code | Meaning |
|------|---------|
| 0 | Success / Compliant |
| 1 | Failure / Non-compliant (triggers remediation) |
| 2 | Script error (detection crashed, not a compliance issue) |
| 1603 | Fatal error (Intune marks as failed) |
| 1618 | Another installation in progress |
| 1641 | Reboot initiated |
| 3010 | Reboot required |

---

## Script Header Format (Enterprise Standard)

Every script uses this structured header with metadata blocks. The header is the API contract — without it, `Get-Help` returns nothing and reviewers cannot understand the tool.

```powershell
<#
.TITLE
    [ToolName Mode] - [Brief descriptive name]

.SYNOPSIS
    [One-line description of what the script does]

.DESCRIPTION
    [Detailed description of the script's functionality, purpose, and use cases.
    Explain what the script accomplishes and any important considerations.
    Include information about prerequisites, dependencies, or special requirements.]

.TAGS
    [Category],[Subcategory] (e.g., Operational,Devices or Security,Compliance)

.REMEDIATIONTYPE
    [Detection | Remediation - REQUIRED for detect/remediate pairs, omit otherwise]

.PAIRSCRIPT
    [Counterpart filename - REQUIRED for detect/remediate pairs, omit otherwise]

.PLATFORM
    Windows

.MINROLE
    [Minimum Intune/Entra ID role required - e.g., Intune Administrator.
    Omit for local-only tools that never touch Graph or Intune resources.]

.PERMISSIONS
    [Required Microsoft Graph permissions - comma separated list.
    If the script makes NO Graph API calls (local SYSTEM-context actions like
    ipconfig/flushdns, service restarts, disk cleanup), write:
    None (local SYSTEM context) - do NOT invent Graph scopes]

.AUTHOR
    AI Generated

.VERSION
    [Version number - start with 1.0]

.CHANGELOG
    [Newest version FIRST. Document fixes with their cause, not just features:]
    1.1 - Fixed invalid return statement in Get-FolderSize that caused folder sizes to always report 0 bytes
    1.0 - Initial release

.LASTUPDATE
    [YYYY-MM-DD - Date of last modification]

.EXAMPLE
    .\scriptname.ps1 -ParameterName "Value"
    [Description of what this example does]

.NOTES
    [Additional notes, requirements, or important information]
    - [Execution context: elevated / SYSTEM / runbook-only]
    - Exit codes: 0 = ..., 1 = ..., 2 = ...
    - Log: <full log path>
#>
```

### Header Fields Reference

Canonical field order (matches the Enterprise Standards standard):

`.TITLE` → `.SYNOPSIS` → `.DESCRIPTION` → `.TAGS` → `[.REMEDIATIONTYPE]` → `[.PAIRSCRIPT]` → `.PLATFORM` → `[.MINROLE]` → `.PERMISSIONS` → `.AUTHOR` → `.VERSION` → `.CHANGELOG` → `.LASTUPDATE` → `.EXAMPLE`(s) → `.NOTES`

| Field | Required | Purpose |
|-------|----------|---------|
| `.TITLE` | Yes | `ToolName Mode - Brief descriptive name` |
| `.SYNOPSIS` | Yes | One-line summary (< 100 chars) |
| `.DESCRIPTION` | Yes | Detailed explanation including "why" |
| `.TAGS` | Yes | `Category,Subcategory` for discoverability |
| `.REMEDIATIONTYPE` | Pairs only | `Detection` or `Remediation` |
| `.PAIRSCRIPT` | Pairs only | Counterpart script filename |
| `.PLATFORM` | Yes | `Windows` or `macOS` |
| `.MINROLE` | Graph/Intune tools only | Minimum Entra ID role required; omit for local-only tools |
| `.PERMISSIONS` | Yes | Graph API permissions, or `None (local SYSTEM context)` |
| `.AUTHOR` | Yes | Author name (`AI Generated` for generated tools) |
| `.VERSION` | Yes | Semantic version (start with 1.0) |
| `.CHANGELOG` | Yes | Newest first; document fixes with their cause |
| `.LASTUPDATE` | Yes | Date of last modification (YYYY-MM-DD) |
| `.EXAMPLE` | Yes | At least 2 realistic examples with explanations |
| `.NOTES` | Yes | Execution context, exit codes, log path, limitations |

**Why these fields matter:** `.PLATFORM` prevents accidental deployment to wrong OS. `.PERMISSIONS` lets reviewers audit least-privilege. `.REMEDIATIONTYPE` (for remediation scripts) tells Intune whether this script detects or remediates.

### Notification-Specific Header Fields

For notification scripts (Azure Automation runbooks that send email alerts), add these fields:

```powershell
.EXECUTION
    RunbookOnly

.OUTPUT
    Email

.SCHEDULE
    Daily

.CATEGORY
    Notification
```

| Field | Required | Purpose |
|-------|----------|---------|
| `.EXECUTION` | Yes (notifications) | `RunbookOnly` — indicates Azure Automation requirement |
| `.OUTPUT` | Yes (notifications) | `Email` — indicates primary output type |
| `.SCHEDULE` | Yes (notifications) | `Daily`, `Weekly`, `Hourly` — expected run frequency |
| `.CATEGORY` | Yes (notifications) | `Notification` — script category for discoverability |

**Why these fields matter:** `.EXECUTION` tells reviewers this script requires Azure Automation (not local-only). `.OUTPUT` indicates email sending (needs `Mail.Send` permission). `.SCHEDULE` helps operators plan runbook frequency. See `references/notification-patterns.md` for complete notification patterns.

### Remediation-Specific Header Fields

For detection and remediation scripts, add these fields:

```powershell
.REMEDIATIONTYPE
    Detection  # or Remediation

.PAIRSCRIPT
    remediate-<name>.ps1  # The paired script filename
```

---

## Module Validation Pattern

Always validate required modules exist before importing. This prevents cryptic errors halfway through execution:

```powershell
# Required modules for this script
$RequiredModules = @(
    "Microsoft.Graph.Authentication"
)

foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Error "$Module module is required. Install it using: Install-Module $Module -Scope CurrentUser"
        exit 2  # Missing module = script error (2), not a detection result (1)
    }
}

# Import required modules
foreach ($Module in $RequiredModules) {
    Import-Module $Module -Force
}
```

### Environment-Aware Module Initialization

For scripts that may run in different contexts (local, scheduled task, CI/CD):

```powershell
function Initialize-RequiredModule {
    param(
        [string[]]$ModuleNames,
        [bool]$ForceInstall = $false
    )

    foreach ($ModuleName in $ModuleNames) {
        $module = Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1

        if (-not $module) {
            Write-Information "Module '$ModuleName' not found. Attempting to install..." -InformationAction Continue

            if (-not $ForceInstall) {
                $response = Read-Host "Install module '$ModuleName'? (Y/N)"
                if ($response -notmatch '^[Yy]') {
                    throw "Module '$ModuleName' is required but installation was declined."
                }
            }

            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
            $scope = if ($isAdmin) { 'AllUsers' } else { 'CurrentUser' }

            Install-Module -Name $ModuleName -Scope $scope -Force -AllowClobber -Repository PSGallery
            Write-Information "Successfully installed '$ModuleName'" -InformationAction Continue
        }

        Import-Module -Name $ModuleName -Force -ErrorAction Stop
    }
}
```

**Why this matters:** Azure Automation Runbooks can't install modules interactively. Local execution can auto-install. This function handles both with clear error messages.

---

## Detection Script Pattern

```powershell
<#
.TITLE
    Detection - Reboot Pending.

.SYNOPSIS
    Checks for pending reboot signals and uptime threshold.

.DESCRIPTION
    Checks whether the device has pending reboot conditions that require remediation.
    Returns exit code 0 if compliant, 1 if non-compliant (needs remediation).

.TAGS
    Remediation,Detection

.REMEDIATIONTYPE
    Detection

.PAIRSCRIPT
    remediate-reboot-pending.ps1

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    None (local SYSTEM context) - local service/registry/disk checks, no Graph API calls

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.EXAMPLE
    .\detect-reboot-pending.ps1
    Returns exit 1 if a reboot is pending and uptime exceeds the threshold

.NOTES
    Runs in SYSTEM context via Intune Remediations
#>

$exitCode = 0

try {
    # === CHECK LOGIC HERE ===

    # Example: Check if a service is running
    $service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    if ($service.Status -ne 'Running') {
        Write-Output "Windows Search service is not running"
        $exitCode = 1  # Non-compliant
    }

    # Example: Check registry value
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $value = Get-ItemProperty -Path $regPath -Name "DoNotConnectToWindowsUpdateInternetLocations" -ErrorAction SilentlyContinue
    if ($value -eq 1) {
        Write-Output "Windows Update is blocked by policy"
        $exitCode = 1
    }

    # Example: Check disk space
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    if ($freeGB -lt 10) {
        Write-Output "Low disk space: ${freeGB}GB free"
        $exitCode = 1
    }
}
catch {
    Write-Output "Detection error: $($_.Exception.Message)"
    $exitCode = 2  # Script error — never 1 (Intune would run remediation needlessly)
}

# Exit 0 = compliant, Exit 1 = non-compliant
exit $exitCode
```

### Key Rules

- Detection scripts MUST be idempotent (safe to run repeatedly)
- Detection scripts MUST NOT modify the system
- Use `Write-Output` for status messages (Intune captures this)
- Use `exit 0` for compliant, `exit 1` for non-compliant, `exit 2` for script error
- Always wrap in try/catch
- Keep detection fast (under 30 seconds)

### Complex Detection: Function Returning Reasons

When a detection checks multiple conditions, use a function that returns a list of reasons instead of a single boolean. This gives operators clear visibility into *why* the device is non-compliant:

```powershell
function Test-PendingCondition {
    $reasons = [System.Collections.Generic.List[string]]::new()

    if (Test-Path "HKLM:\SOFTWARE\...\RebootPending") {
        $reasons.Add("Component Based Servicing")
    }

    if (Test-Path "HKLM:\SOFTWARE\...\WindowsUpdate\Auto Update\RebootRequired") {
        $reasons.Add("Windows Update")
    }

    # ... more checks ...

    return @($reasons)
}

try {
    $reasons = Test-PendingCondition

    if ($reasons.Count -eq 0) {
        Write-Output "All conditions clear."
        exit 0
    }

    # Optional: threshold check to avoid false positives
    $uptimeDays = [math]::Round(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalDays, 1)
    if ($uptimeDays -lt 2) {
        Write-Output "Issues found ($($reasons -join '; ')) but device rebooted recently ($uptimeDays days) - skipping."
        exit 0
    }

    Write-Output "Non-compliant: $($reasons -join '; ')"
    exit 1
}
catch {
    Write-Error $_
    exit 2
}
```

**Why a function?** Separating check logic from exit-code logic makes the detection testable. The `[Generic.List[string]]` collects all failure reasons so operators see a complete picture in Intune device output, not just the first failure.

### Always-Run Detection (Scheduled Actions)

For scheduled actions that should run on every Intune cycle (not health-based remediation), use an "always-run" detection script that intentionally returns exit code 1.

The detection should include the full helper function stack (`Initialize-Log`, `Write-Log`) for audit trail purposes, even though it always returns the same exit code. Operators reviewing logs months later need to see that the detection ran successfully and intentionally triggered remediation.

```powershell
<#
.TITLE
    Detection - DNS Cache Flush (Always-Run).

.SYNOPSIS
    Always triggers DNS cache flush remediation.

.DESCRIPTION
    This detection script intentionally always returns exit code 1 (non-compliant)
    to ensure the paired remediation script runs and executes `ipconfig /flushdns`.
    It does not evaluate actual DNS health — it is designed to force periodic
    DNS cache clearing on managed devices.

.TAGS
    Remediation,Detection

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    None (local SYSTEM context) - runs `ipconfig /flushdns` locally, no Graph API calls

.REMEDIATIONTYPE
    Detection

.PAIRSCRIPT
    remediate-dns-cache-flush.ps1

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.LASTUPDATE
    [YYYY-MM-DD]

.EXAMPLE
    .\detect-dns-cache-flush.ps1
    Always returns exit code 1 to trigger paired remediation script.

.NOTES
    - Runs in SYSTEM context via Intune Proactive Remediations
    - Intentionally always returns non-compliant (exit 1)
    - Pair with remediation script that executes ipconfig /flushdns
    - No DNS health evaluation performed
#>

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptName   = "detect-dns-cache-flush.ps1"
$SolutionName = "DNS-Cache-Flush"
$SystemDrive  = if ($env:SystemDrive) { $env:SystemDrive.TrimEnd('\') } else {
    [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
}
$LogRoot      = Join-Path $SystemDrive "IntuneLogs\$SolutionName"
$LogFile      = Join-Path $LogRoot "detect-dns-cache-flush.txt"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Initialize-Log {
    try {
        if (-not (Test-Path -Path $LogRoot)) {
            $null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction Stop
        }
        if (-not (Test-Path -Path $LogFile)) {
            $null = New-Item -Path $LogFile -ItemType File -Force -ErrorAction Stop
        }
        return $true
    }
    catch {
        Write-Host "Log initialization failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp | $Level | $Message"

    switch ($Level) {
        "SUCCESS" { Write-Host $logLine -ForegroundColor Green }
        "WARNING" { Write-Host $logLine -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logLine -ForegroundColor Red }
        default   { Write-Host $logLine -ForegroundColor Cyan }
    }

    if ($script:LogReady) {
        try {
            Add-Content -Path $LogFile -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch {
            # Suppress log write errors
        }
    }
}

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

try {
    $script:LogReady = Initialize-Log

    Write-Log -Message "DNS Cache Flush Detection started" -Level "INFO"
    Write-Log -Message "This detection intentionally returns non-compliant to trigger remediation" -Level "WARNING"

    # Always return non-compliant (exit 1) to ensure remediation runs
    Write-Log -Message "Returning non-compliant status to trigger DNS cache flush remediation" -Level "WARNING"
    exit 1
}
catch {
    Write-Log -Message "Detection script error: $($_.Exception.Message)" -Level "ERROR"
    exit 2
}
```

**When to use Always-Run Detection:**
- DNS cache flushing on a schedule
- Temp file cleanup (daily/weekly)
- Service restarts on a schedule
- Any "scheduled action" that doesn't depend on a health condition

**Key difference from health-based detection:** The detection script does NOT check any condition. It always returns exit code 1 to force the remediation script to run on every Intune cycle.

**Why include Initialize-Log even in always-run detections?** The log file serves as an audit trail. When an operator wonders "did the DNS flush actually run on this device last Tuesday?", the detection log proves it did. Without logging, the only evidence is in the Intune agent logs, which are harder to access.

---

## Remediation Script Pattern

```powershell
<#
.TITLE
    Remediation - Reboot Pending.

.SYNOPSIS
    Fixes pending reboot conditions by scheduling a restart.

.DESCRIPTION
    This remediation script fixes pending reboot conditions detected by the paired detection script.
    This script runs only when the detection script returns exit code 1 (non-compliant).

    The script performs:
    1. Pre-remediation validation
    2. Remediation actions
    3. Post-remediation verification
    4. Result reporting

.TAGS
    Remediation,Action,Compliance

.REMEDIATIONTYPE
    Remediation

.PAIRSCRIPT
    detect-reboot-pending.ps1

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    None (local SYSTEM context) - schedules restart locally via shutdown.exe, no Graph API calls

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.EXAMPLE
    .\remediate-reboot-pending.ps1
    Schedules a restart to clear pending reboot conditions

.NOTES
    Runs in SYSTEM context via Intune Remediations
#>

$exitCode = 0
$remediationResult = @{
    Status = "Unknown"
    PreCheckStatus = @()
    RemediationActions = @()
    PostCheckStatus = @()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ComputerName = $env:COMPUTERNAME
}

#region Helper Functions
# Operational logging: use Write-Log (canonical: scripts/Write-Log.ps1).
# Write-RemediationLog ALSO records each line into $remediationResult.RemediationActions
# for the structured JSON output — that is its only unique job.
function Write-RemediationLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Info' { Write-Output $logMessage }
        'Warning' { Write-Warning $logMessage }
        'Error' { Write-Error $logMessage }
    }

    $remediationResult.RemediationActions += @{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
    }
}
#endregion

try {
    Write-RemediationLog "Starting remediation script..." -Level Info

    #region Pre-Remediation Validation
    Write-RemediationLog "Performing pre-remediation checks..." -Level Info

    # Check prerequisites
    $currentPrincipal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-RemediationLog "Script is not running with administrative privileges" -Level Warning
    }

    $remediationResult.PreCheckStatus += "Pre-remediation validation completed successfully"
    #endregion

    #region Main Remediation Logic
    Write-RemediationLog "Executing remediation actions..." -Level Info

    # === REMEDIATION LOGIC HERE ===

    # Example: Start a stopped service
    $service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    if ($service.Status -ne 'Running') {
        Start-Service -Name "WSearch" -ErrorAction Stop
        Write-RemediationLog "Windows Search service started successfully" -Level Info

        # Verify fix
        $service.Refresh()
        if ($service.Status -ne 'Running') {
            throw "Failed to start Windows Search service"
        }
    }

    $remediationResult.RemediationActions += "Remediation completed"
    #endregion

    #region Post-Remediation Verification
    Write-RemediationLog "Performing post-remediation verification..." -Level Info

    # Verify the remediation was successful
    $verificationPassed = $true  # Set based on actual verification

    $remediationResult.PostCheckStatus += "Post-remediation verification completed"
    #endregion

    #region Process Results
    if ($verificationPassed) {
        $remediationResult.Status = "Success"
        Write-RemediationLog "Remediation completed successfully" -Level Info

        # Output detailed result as JSON for logging
        $jsonOutput = $remediationResult | ConvertTo-Json -Compress
        Write-Output $jsonOutput

        # Exit with code 0 - Remediation successful
        exit 0
    }
    else {
        $remediationResult.Status = "Failed"
        Write-RemediationLog "Remediation completed but verification failed" -Level Error

        # Output detailed result as JSON for logging
        $jsonOutput = $remediationResult | ConvertTo-Json -Compress
        Write-Output $jsonOutput

        # Exit with code 1 - Remediation failed
        exit 1
    }
    #endregion
}
catch {
    # Capture error details
    $remediationResult.Status = "Error"
    $remediationResult.Error = @{
        Message = $_.Exception.Message
        Type = $_.Exception.GetType().FullName
        StackTrace = $_.ScriptStackTrace
    }

    Write-RemediationLog "Remediation script failed: $_" -Level Error

    # Output error details
    $jsonOutput = $remediationResult | ConvertTo-Json -Compress
    Write-Output $jsonOutput

    # Exit with code 2 - Script error (differentiates crash from failed remediation)
    exit 2
}
finally {
    Write-RemediationLog "Performing cleanup..." -Level Info
}
```

### Key Rules

- Always verify the fix succeeded after applying it
- Use `Write-Output` for status messages
- Use `exit 0` for success, `exit 1` for failure, `exit 2` for script error
- Always wrap in try/catch/finally
- Log what was changed for audit purposes
- Output JSON result for structured logging in Intune

### Pre-Remediation Validation Pattern

Always validate prerequisites before attempting remediation:

```powershell
function Test-RemediationPrerequisites {
    param()

    $prereqMet = $true

    try {
        # Check if running with required privileges
        $currentPrincipal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-RemediationLog "Script is not running with administrative privileges" -Level Warning
            $prereqMet = $false
        }

        # Add your specific prerequisite checks:
        # - Check if required services are accessible
        # - Verify network connectivity if needed
        # - Check disk space for file operations
        # - Validate required PowerShell modules

        return $prereqMet
    }
    catch {
        Write-RemediationLog "Error checking prerequisites: $_" -Level Error
        return $false
    }
}
```

**Why this matters:** Running remediation without prerequisites wastes an Intune cycle and may leave the device in a partially-modified state. Catching issues early prevents cascading failures.

### Backup Before Remediation Pattern

Create a backup of current state before making changes:

```powershell
function Backup-CurrentState {
    param()

    try {
        Write-RemediationLog "Creating backup of current state..." -Level Info

        # Implement backup logic based on what you're remediating:
        # - Export current registry values
        # - Copy configuration files
        # - Document current service states

        $backupInfo = @{
            BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            BackupLocation = $null  # Set this if creating actual backups
        }

        $remediationResult.BackupInfo = $backupInfo
        return $true
    }
    catch {
        Write-RemediationLog "Failed to create backup: $_" -Level Warning
        return $true  # Continue anyway (adjust based on risk tolerance)
    }
}
```

**Why backup matters:** When remediation fails mid-execution, the device may be left in an inconsistent state. A backup enables rollback. For low-risk changes (starting a service), backup may be unnecessary. For high-risk changes (registry modifications, file operations), always backup.

### External Process Management

When a remediation needs to run an external tool (shutdown.exe, msiexec, DISM, etc.), use `Start-Process -Wait -PassThru` to capture the exit code and handle specific return values:

```powershell
try {
    $process = Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" `
        -ArgumentList "/r /t 14400 /c `"Your IT department scheduled a restart.`"" `
        -Wait -PassThru -NoNewWindow

    switch ($process.ExitCode) {
        0    { Write-Output "Action completed successfully"; exit 0 }
        1190 { Write-Output "Action already scheduled - leaving in place"; exit 0 }
        default { Write-Output "Process returned exit code $($process.ExitCode)"; exit 1 }
    }
}
catch {
    Write-Error $_
    exit 2  # Script error, not a remediation failure
}
```

**Why `-Wait -PassThru`:** `-Wait` blocks until the process finishes (required for correct exit code). `-PassThru` returns the process object so you can read `.ExitCode`. Without both, you're guessing whether the action succeeded.

### Process Timeout Handling

Some external processes (like `cleanmgr.exe`) can hang indefinitely. Use `Wait-Process -Timeout` to prevent a stuck process from blocking the entire remediation. Always stop the process if it exceeds the timeout, and count it as a failure so the script continues with other targets:

```powershell
$targetCount++
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Get-ChildItem $regPath -ErrorAction SilentlyContinue | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "StateFlags0100" -Value 2 -Type DWORD -ErrorAction SilentlyContinue
    }

    $cleanmgrProcess = Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:100" -NoNewWindow -PassThru
    Wait-Process -Id $cleanmgrProcess.Id -Timeout 300 -ErrorAction Stop
}
catch {
    # Stop cleanmgr if it is still running after timeout
    if ($cleanmgrProcess -and -not $cleanmgrProcess.HasExited) {
        Stop-Process -Id $cleanmgrProcess.Id -Force -ErrorAction SilentlyContinue
    }
    $failedCount++
}
```

**Why timeout matters:** `cleanmgr.exe` and similar tools can block on user-profile locks or network-mounted folders. A 5-minute timeout (300 seconds) is generous enough for legitimate operations but prevents infinite hangs that would leave Intune thinking the remediation is still running.

### Per-Target Failure Tracking

When a remediation handles multiple independent targets (multiple folders, services, registry keys), track success/failure counts and only exit 1 if ALL targets failed. This is more resilient than fail-fast — partial success still fixes some devices or some issues on a single device:

```powershell
$targetCount = 0
$failedCount = 0

# Clean Windows Temp
$targetCount++
try {
    Remove-FolderContent "$env:WINDIR\Temp"
}
catch { $failedCount++ }

# Clean User Temp folders
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $targetCount++
    try {
        Remove-FolderContent "$($_.FullName)\AppData\Local\Temp"
    }
    catch { $failedCount++ }
}

# Empty Recycle Bin
$targetCount++
try {
    Clear-RecycleBin -Force -ErrorAction Stop
}
catch { $failedCount++ }

# Report results
if ($failedCount -ge $targetCount) {
    Write-Error "All $targetCount cleanup targets failed"
    exit 1
}

Write-Output "Completed ($($targetCount - $failedCount) of $targetCount targets succeeded)"
exit 0
```

**Why partial-success is better than fail-fast:** In a disk cleanup scenario, if the Windows Temp folder is locked by a running process, that shouldn't prevent the Recycle Bin from being emptied. The per-target pattern means Intune reports "partially succeeded" instead of "failed" — and the next cycle will try the failed target again.

### Space Freed Reporting

After a cleanup operation, report how much space was reclaimed. This gives operators visibility into whether the remediation is actually helping and helps tune thresholds:

```powershell
$freeBefore = (Get-PSDrive C).Free

# ... cleanup operations here ...

$freeAfter = (Get-PSDrive C).Free
$freedMB = [math]::Round(($freeAfter - $freeBefore) / 1MB, 2)

Write-Output "Freed space: $freedMB MB"
```

**Why report freed space:** Intune device output only shows "succeeded" or "failed" — operators have no visibility into *how much* was cleaned. Adding freed-space reporting to the output gives them data to tune thresholds (e.g., "this device only freed 12MB, maybe the threshold is too aggressive").

---

## CLI Script Helpers (No GUI)

For Intune remediation scripts that run headless (no WPF), use these helper functions to keep the code clean and consistent.

### Write-Banner Pattern

Prints a visual separator at script start so the log file and console output are easy to scan. The banner includes the solution name and script mode (Detection/Remediation).

```powershell
$BannerLine = "=" * 78

function Write-Banner {
    # Banner title includes live timestamp - canonical since Write-Log.ps1 v1.4.0
    $title = "{0} | {1} | {2}" -f $SolutionName, $ScriptMode, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $lines = @('', $BannerLine, $title, $BannerLine)

    foreach ($line in $lines) {
        if ($line -eq $title) {
            Write-Host $line -ForegroundColor White
        }
        else {
            Write-Host $line -ForegroundColor DarkGray
        }

        if ($script:LogReady) {
            Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    }
}
```

**Why a banner?** When you're scrolling through 200 remediation log files looking for the right one, the banner line `======= Clear-DnsClientCache | Remediation ========' tells you immediately which script this is and what mode it ran in.

### Finish-Script Helper

A clean way to handle exit codes — logs the final message and exits in one call. This replaces scattered `Write-Log` + `exit` pairs throughout the script.
Console output is clean (plain message + level color); file keeps `[timestamp] [LEVEL]` — see Canonical Logging.

```powershell
function Finish-Script {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ExitCode,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    Write-Log -Message $Message -Level $Level
    exit $ExitCode
}
```

**Usage pattern:**

```powershell
# Success path
Finish-Script -ExitCode 0 -Message "Remediation completed successfully" -Level "SUCCESS"

# Failure path
Finish-Script -ExitCode 1 -Message "DNS cache flush failed" -Level "ERROR"

# Error path (in catch block)
Finish-Script -ExitCode 2 -Message "Script execution error: $($_.Exception.Message)" -Level "ERROR"
```

**Why this matters:** Without `Finish-Script`, you end up with `Write-Log` + `exit` duplicated in every branch. With it, each exit point is a single readable line — and the log level matches the exit code semantics.

**Per-target result block:** when a script processes multiple targets (see Per-Target Failure Tracking), print the canonical end-of-run block with `Write-Summary -Results $results` (from `scripts/Write-Log.ps1`) immediately before `Finish-Script`. It renders one colored status line plus an aligned `Target/Result/Skipped/Error` table and computes `ok/skipped/failed` internally — do not hand-build a second summary line or table, or output drifts across the fleet. See `SKILL.md` → CLI `Write-Summary` for the exact block.

### Config-Driven Command Execution

When a remediation runs an external command (ipconfig, shutdown, msiexec, etc.), define the command in a configuration block at the top. This makes the script easy to adapt — change the command without touching the logic.

```powershell
# ============================================================================
# CONFIGURATION
# ============================================================================

$SolutionName     = "Clear-DnsClientCache"
$ScriptMode       = "Remediation"
$CommandPath      = "ipconfig.exe"
$CommandArguments = @("/flushdns")

$SystemDrive = if ($env:SystemDrive) { $env:SystemDrive.TrimEnd('\') } else {
    [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
}
$LogRoot = Join-Path $SystemDrive "IntuneLogs\$SolutionName"
$LogFile = Join-Path $LogRoot "$SolutionName-$ScriptMode.txt"

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

Write-Log -Message "Running command: $CommandPath $($CommandArguments -join ' ')" -Level "INFO"

try {
    $commandOutput = & $CommandPath @CommandArguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Log -Message "Command completed successfully" -Level "SUCCESS"
        if ($commandOutput) {
            Write-Log -Message "Command output: $commandOutput" -Level "INFO"
        }
        Finish-Script -ExitCode 0 -Message "Remediation completed successfully" -Level "SUCCESS"
    }
    else {
        Write-Log -Message "Command failed with exit code: $exitCode" -Level "ERROR"
        if ($commandOutput) {
            Write-Log -Message "Command output: $commandOutput" -Level "ERROR"
        }
        Finish-Script -ExitCode 1 -Message "Command execution failed" -Level "ERROR"
    }
}
catch {
    Write-Log -Message "Exception occurred: $($_.Exception.Message)" -Level "ERROR"
    Finish-Script -ExitCode 2 -Message "Script execution error: $($_.Exception.Message)" -Level "ERROR"
}
```

**Why `& $CommandPath @CommandArguments`?** Splatting the arguments array makes it trivial to add/remove arguments in the CONFIGURATION block without rewriting the execution logic. The `2>&1` captures both stdout and stderr into `$commandOutput` so you can log whatever the command produced.

### SystemDrive Detection

For scripts that run in SYSTEM context, `$env:SystemDrive` is usually available but not always. This pattern handles the fallback:

```powershell
$SystemDrive = if ($env:SystemDrive) {
    $env:SystemDrive.TrimEnd('\')
} else {
    [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
}
$LogRoot = Join-Path $SystemDrive "IntuneLogs\$SolutionName"
$LogFile = Join-Path $LogRoot "$SolutionName-$ScriptMode.txt"
```

**Why the fallback?** In rare edge cases (Azure Automation Runbooks, certain CI/CD contexts), `$env:SystemDrive` can be empty. The fallback using `GetPathRoot` ensures the log path is always valid.

### Complete CLI Script Template

Putting it all together — a production-ready Intune remediation script:

```powershell
<#
.TITLE
    [Solution Name] Remediation

.SYNOPSIS
    [One-line description]

.DESCRIPTION
    [Detailed description]

.TAGS
    Remediation,Action

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    DeviceManagementManagedDevices.ReadWrite.All

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.LASTUPDATE
    [YYYY-MM-DD]

.EXAMPLE
    .\remediate-[name].ps1
    [Description]

.NOTES
    - Runs in SYSTEM context via Intune Proactive Remediations
    - Exit 0 = success, Exit 1 = failure, Exit 2 = error
    - Logs written to <SystemDrive>\IntuneLogs\[SolutionName]\
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$SolutionName = "[SolutionName]"
$ScriptMode   = "Remediation"

$SystemDrive = if ($env:SystemDrive) { $env:SystemDrive.TrimEnd('\') } else {
    [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
}
$LogRoot  = Join-Path $SystemDrive "IntuneLogs\$SolutionName"
$LogFile  = Join-Path $LogRoot "$SolutionName-$ScriptMode.txt"
$BannerLine = "=" * 78

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Initialize-Log { <# ... same as above ... #> }
function Write-Banner  { <# ... same as above ... #> }
function Write-Log     { <# ... same as above ... #> }
function Finish-Script { <# ... same as above ... #> }

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

$script:LogReady = Initialize-Log
Write-Banner

if ($script:LogReady) {
    Write-Log -Message "Log file ready: $LogFile"
}

try {
    # === REMEDIATION LOGIC HERE ===

    Finish-Script -ExitCode 0 -Message "Remediation completed successfully" -Level "SUCCESS"
}
catch {
    Finish-Script -ExitCode 2 -Message "Script execution error: $($_.Exception.Message)" -Level "ERROR"
}
```

---

## Common Remediations

### Disk Cleanup

```powershell
# Detection
$tempPath = $env:TEMP
$oldFiles = Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
$totalSizeMB = [math]::Round(($oldFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

if ($totalSizeMB -gt 500) {
    Write-Output "Temp files: ${totalSizeMB}MB (threshold: 500MB)"
    exit 1
}
exit 0

# Remediation
$tempPath = $env:TEMP
Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Temp files cleaned"
exit 0
```

### Windows Update Repair

```powershell
# Detection
$wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
$bitsService = Get-Service -Name "BITS" -ErrorAction SilentlyContinue

if ($wuService.Status -ne 'Running' -or $bitsService.Status -ne 'Running') {
    Write-Output "Windows Update services not running"
    exit 1
}
exit 0

# Remediation
try {
    Restart-Service -Name "wuauserv" -Force -ErrorAction Stop
    Restart-Service -Name "BITS" -Force -ErrorAction Stop
    Write-Output "Windows Update services restarted"
    exit 0
}
catch {
    Write-Output "Failed to restart services: $($_.Exception.Message)"
    exit 2  # Script error
}
```

### Registry Fix

```powershell
# Detection
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
$value = Get-ItemProperty -Path $regPath -Name "Scancode Map" -ErrorAction SilentlyContinue
if ($null -eq $value) {
    Write-Output "Registry key missing"
    exit 1
}
exit 0

# Remediation
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
New-ItemProperty -Path $regPath -Name "Scancode Map" -Value 0 -PropertyType Binary -Force | Out-Null
Write-Output "Registry key created"
exit 0
```

### Certificate Expiration Check

```powershell
# Detection
$certPath = "Cert:\LocalMachine\My"
$certs = Get-ChildItem -Path $certPath -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -like "*yourdomain.com*" }

$expiringCerts = $certs | Where-Object { $_.NotAfter -lt (Get-Date).AddDays(30) }

if ($expiringCerts.Count -gt 0) {
    foreach ($cert in $expiringCerts) {
        Write-Output "Certificate expiring: $($cert.Subject) - Expires: $($cert.NotAfter)"
    }
    exit 1
}
exit 0

# Remediation
# Certificate renewal typically requires manual intervention or automated enrollment
Write-Output "Certificate renewal requires manual enrollment or SCEP/NDES configuration"
exit 1
```

### Remote Diagnostics Collection

Trigger Intune's "Collect diagnostics" remote action on devices and download the resulting log packages. This pattern is useful for large-scale troubleshooting — instead of clicking through the portal for each device, the script collects diagnostics from hundreds of devices in one run:

```powershell
<#
.TITLE
    Collect Device Diagnostics.

.SYNOPSIS
    Triggers remote diagnostics collection on Windows devices and downloads log packages.

.DESCRIPTION
    Starts the Intune "Collect diagnostics" remote action on one or more
    Windows devices (by device name or Entra ID group), waits for collection
    to complete, and downloads the resulting diagnostic ZIP packages.

.TAGS
    Diagnostics,Devices

.MINROLE
    Intune Administrator

.PERMISSIONS
    DeviceManagementManagedDevices.ReadWrite.All,GroupMember.Read.All

.EXECUTION
    LocalOnly

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.LASTUPDATE
    [YYYY-MM-DD]

.EXAMPLE
    .\collect-device-diagnostics.ps1 -DeviceNames "PC-001","PC-002"
    Triggers diagnostics collection on two devices and downloads the packages

.EXAMPLE
    .\collect-device-diagnostics.ps1 -GroupName "Support - Troubleshooting"
    Collects diagnostics from all Windows devices in the group

.NOTES
    - Requires Microsoft.Graph.Authentication module
    - Collect diagnostics only supports Windows 10/11 devices
    - Uses beta Graph endpoints for the log collection surface
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$DeviceNames,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupName,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 120)]
    [int]$TimeoutMinutes = 15
)

# Validate exactly one target mode
$selectedTargets = @(
    if (@($DeviceNames).Count -gt 0) { 'ByDevice' }
    if (-not [string]::IsNullOrWhiteSpace($GroupName)) { 'ByGroup' }
)
if ($selectedTargets.Count -ne 1) {
    throw "Specify exactly one target: DeviceNames or GroupName."
}
$TargetMode = $selectedTargets[0]

# Resolve devices to Intune managed devices
function Get-TargetDevice {
    $devices = [System.Collections.Generic.List[Object]]::new()

    if ($TargetMode -eq "ByDevice") {
        foreach ($deviceName in $DeviceNames) {
            $escapedName = $deviceName -replace "'", "''"
            $found = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$escapedName'&`$select=id,deviceName,operatingSystem,lastSyncDateTime"
            foreach ($device in @($found)) { $devices.Add($device) }
        }
    }
    else {
        $escapedGroup = $GroupName -replace "'", "''"
        $groups = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/groups?`$filter=displayName eq '$escapedGroup'&`$select=id,displayName"
        if (@($groups).Count -ne 1) {
            throw "Expected exactly one group named '$GroupName', found $(@($groups).Count)"
        }
        $members = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/groups/$(@($groups)[0].id)/members?`$select=id,displayName,deviceId"
        foreach ($member in $members) {
            if (-not $member.deviceId) { continue }
            $managed = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=azureADDeviceId eq '$($member.deviceId)'&`$select=id,deviceName,operatingSystem,lastSyncDateTime"
            foreach ($device in $managed) { $devices.Add($device) }
        }
    }

    # Collect diagnostics is Windows-only
    $windowsDevices = @($devices | Where-Object { $_.operatingSystem -eq "Windows" })
    $skipped = @($devices).Count - $windowsDevices.Count
    if ($skipped -gt 0) {
        Write-Warning "Skipped $skipped non-Windows device(s) - collect diagnostics only supports Windows"
    }
    return $windowsDevices
}

# Download a completed diagnostic package
function Save-DiagnosticPackage {
    param([object]$Device, [object]$Request)
    try {
        $downloadResponse = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($Device.id)/logCollectionRequests/$($Request.id)/createDownloadUrl" -Method POST
        $downloadUrl = $downloadResponse.value
        if (-not $downloadUrl) { return $false }

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $zipPath = Join-Path $OutputPath "DeviceDiagnostics_$($Device.deviceName)_$timestamp.zip"

        # Use plain Invoke-WebRequest (not Invoke-MgGraphRequest) for Azure Storage URLs
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
        Write-Information "Downloaded: $zipPath" -InformationAction Continue
        return $true
    }
    catch {
        Write-Warning "Failed to download package for '$($Device.deviceName)': $($_.Exception.Message)"
        return $false
    }
}

# Main execution
try {
    $null = New-Item -Path $OutputPath -ItemType Directory -Force
    $targetDevices = Get-TargetDevice

    if (@($targetDevices).Count -eq 0) {
        throw "No Windows devices found to collect diagnostics from"
    }

    Write-Output "Targeting $(@($targetDevices).Count) Windows device(s)"
    $downloaded = 0
    $failed = 0
    $pendingRequests = @{}

    # Trigger collection on each device
    foreach ($device in $targetDevices) {
        try {
            $body = @{ templateType = @{ templateType = "predefined" } } | ConvertTo-Json
            $request = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)/createDeviceLogCollectionRequest" -Method POST -Body $body -ContentType "application/json"
            $pendingRequests[$device.id] = @{ Device = $device; RequestId = $request.id }
            Write-Output "Collection triggered on '$($device.deviceName)'"
        }
        catch {
            Write-Warning "Failed to trigger collection on '$($device.deviceName)': $($_.Exception.Message)"
            $failed++
        }
    }

    # Poll until complete or timeout
    if ($pendingRequests.Count -gt 0) {
        Write-Output "Waiting for $($pendingRequests.Count) collection(s) (timeout: $TimeoutMinutes minutes)..."
        $deadline = (Get-Date).AddMinutes($TimeoutMinutes)

        while ($pendingRequests.Count -gt 0 -and (Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 30
            foreach ($deviceId in @($pendingRequests.Keys)) {
                $entry = $pendingRequests[$deviceId]
                try {
                    $status = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/logCollectionRequests/$($entry.RequestId)" -Method GET
                    if ($status.status -eq "completed") {
                        if (Save-DiagnosticPackage -Device $entry.Device -Request $status) { $downloaded++ } else { $failed++ }
                        $pendingRequests.Remove($deviceId)
                    }
                    elseif ($status.status -eq "failed") {
                        $failed++
                        $pendingRequests.Remove($deviceId)
                    }
                }
                catch { Write-Verbose "Status check pending: $($_.Exception.Message)" }
            }
        }

        foreach ($deviceId in @($pendingRequests.Keys)) {
            Write-Warning "Collection on '$($pendingRequests[$deviceId].Device.deviceName)' timed out after $TimeoutMinutes minutes"
        }
    }

    # Summary
    Write-Output "`n========================================"
    Write-Output "Devices targeted: $(@($targetDevices).Count)"
    Write-Output "Packages saved: $downloaded"
    Write-Output "Failures/timeouts: $($failed + $pendingRequests.Count)"
    Write-Output "Output folder: $OutputPath"
    Write-Output "========================================"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 2  # Script error
}
finally {
    try { $null = Disconnect-MgGraph } catch { Write-Verbose "Graph disconnection completed" }
}
```

**Key patterns in this script:**
- **Beta Graph endpoints**: The log collection surface (`logCollectionRequests`, `createDeviceLogCollectionRequest`) only exists on beta. Use beta endpoints when the stable API doesn't have the surface you need.
- **Plain Invoke-WebRequest for download URLs**: Azure Storage URLs returned by `createDownloadUrl` are pre-authenticated links — they don't need Graph auth headers. Using `Invoke-MgGraphRequest` here would add unnecessary headers that might confuse the storage service.
- **Polling with deadline**: Collections can take minutes. Poll every 30 seconds with a timeout deadline to prevent infinite waits.
- **Windows-only filtering**: Non-Windows devices are skipped early with a warning, not silently ignored.
- **Exactly-one target validation**: Prevents accidental execution against the entire fleet by requiring either `DeviceNames` OR `GroupName`, not both, not neither.

---

## Microsoft Graph API Integration

### Authentication

#### Azure Automation Context Detection

Detect whether the script is running in Azure Automation or locally:

```powershell
$RunningInAzureAutomation = $null -ne $env:AUTOMATION_ASSET_ACCOUNTID
```

**Why this matters:** Azure Automation Runbooks use Managed Identity (no user interaction). Local execution requires interactive sign-in. The same script should support both contexts.

#### Interactive Authentication (Local Execution)

For scripts that run locally (not Azure Automation):

```powershell
try {
    $scopes = @(
        'DeviceManagementManagedDevices.Read.All'
        'DeviceManagementManagedDevices.PrivilegedOperations.All'
    )

    Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
    Write-Output 'Connected to Microsoft Graph'
}
catch {
    throw "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
}
```

#### Managed Identity Authentication (Azure Automation)

```powershell
try {
    Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
    Write-Output 'Connected to Microsoft Graph using Managed Identity'
}
catch {
    throw "Failed to connect using Managed Identity: $($_.Exception.Message)"
}
```

#### Client Credentials (App Registration / Service Principal)

For **unattended service contexts** — scheduled tasks, CI/CD, tools running as a service account that cannot do interactive sign-in and have no Managed Identity. The App Registration gets an application permission (e.g. `DeviceManagementManagedDevices.Read.All`) and a client secret or certificate:

```powershell
# Pre-requisites (one time, in Entra ID):
#   1. App registration → API permissions → add application permission
#   2. Certificates & secrets → new client secret (or upload a certificate)
#   3. Grant admin consent for the tenant
$TenantId     = "contoso.onmicrosoft.com"   # or the tenant GUID
$ClientId     = "11111111-2222-3333-4444-555555555555"
$ClientSecret = "SECRET_PLACEHOLDER"        # NEVER hard-code in production —
                                            # read from a Key Vault / env var / encrypted file

try {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "https://graph.microsoft.com/.default"
    }
    $token = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body
    $headers = @{ Authorization = "Bearer $($token.access_token)" }
    # Now call Graph with the token:
    $devices = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices" -Headers $headers

    # Alternatively with the Microsoft.Graph.Authentication module:
    Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret -NoWelcome
    $devices = Get-MgDeviceManagementManagedDevice -All
}
catch {
    throw "Failed to connect using client credentials: $($_.Exception.Message)"
}
```

**When to use Client Credentials:** no user will be present (service context) AND the workload has no Managed Identity (e.g. on-prem scheduled task, VM without identity, external automation). If a user is present, prefer interactive; if a Managed Identity exists, prefer `-Identity`. The canonical matrix is in `scripts/Connect-GraphAuth.ps1`.

#### Combined Pattern (Recommended)

Supports both local and Azure Automation execution:

```powershell
try {
    if ($RunningInAzureAutomation) {
        Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
        Write-Output 'Connected using Managed Identity'
    } else {
        $scopes = @(
            'DeviceManagementManagedDevices.Read.All'
            'DeviceManagementManagedDevices.PrivilegedOperations.All'
        )
        Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
        Write-Output 'Connected with interactive authentication'
    }
}
catch {
    throw "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
}
```

#### WAM-Free Interactive Sign-In (MgGraphCommunity)

The standard `Connect-MgGraph` uses WAM (Web Account Manager) broker on Windows, which can fail in non-interactive contexts (RDP sessions, service accounts, CI/CD). The `MgGraphCommunity` module bypasses WAM entirely:

```powershell
# Install once (requires PSGallery access)
Install-Module -Name MgGraphCommunity -Scope CurrentUser -Force

# Use in scripts
Connect-MgGraphCommunity -Scopes $scopes -NoWelcome -ErrorAction Stop
```

**When to use MgGraphCommunity over Connect-MgGraph:**
- Running in RDP sessions where WAM broker fails silently
- CI/CD pipelines that don't have WAM configured
- Scripts that need to work on both Windows and non-Windows (PowerShell 7+)
- When `Connect-MgGraph` throws "Response from the daemon was unexpected"

**When to use standard Connect-MgGraph:**
- Azure Automation (always use `-Identity`, no WAM involved)
- Local interactive sessions where WAM works fine (most developer machines)

### Multi-Method Auth Dialog (GUI Tools)

Type 1 (WPF) tools that connect to Graph should offer the user a choice of auth methods — no single method works in every environment, and the user knows their context best. Battle-tested method set from the [Device Offboarding Manager]() by [@enterprise](https://github.com/enterprise) (Intune/Entra/Autopilot tool):

| Method | When it wins | Notes |
|--------|--------------|-------|
| **Interactive** | Normal admin workstation | Classic browser authorization-code flow (PKCE). Use `Connect-MgGraphCommunity` — never plain `Connect-MgGraph` for GUI tools: WAM broker fails silently in RDP/service sessions |
| **Device Code** | Locked-down machines, remote sessions, localhost-redirect failures | `Connect-MgGraphCommunity -Scopes $scopes -UseDeviceCode`. No browser redirect needed — user enters a code on another device |
| **Certificate** | Automated / service principal | Requires AppId + TenantId + Thumbprint — validate all three before attempting |
| **Client Secret** | Service principal fallback | Build a `PSCredential` from a `SecureString`; **null out the plaintext secret immediately after use** |

**Disconnect before reconnecting:** Always `Disconnect-MgGraphCommunity -ErrorAction SilentlyContinue` before switching methods (especially certificate/secret) — a stale connection from a previous method makes the new one fail with confusing errors:

```powershell
function Connect-ToGraph {
    param([hashtable]$AuthDetails)

    $permissionsList = ($script:RequiredPermissions | ForEach-Object { $_.Permission })

    switch ($AuthDetails.Method) {
        'Interactive' {
            $result = Connect-MgGraphCommunity -Scopes $permissionsList -NoWelcome -ErrorAction Stop
        }
        'DeviceCode' {
            $result = Connect-MgGraphCommunity -Scopes $permissionsList -UseDeviceCode -NoWelcome -ErrorAction Stop
        }
        'Certificate' {
            if ([string]::IsNullOrWhiteSpace($AuthDetails.AppId))  { throw "App ID is required for certificate authentication" }
            if ([string]::IsNullOrWhiteSpace($AuthDetails.TenantId)){ throw "Tenant ID is required for certificate authentication" }
            if ([string]::IsNullOrWhiteSpace($AuthDetails.Thumbprint)) { throw "Certificate Thumbprint is required for certificate authentication" }
            Disconnect-MgGraphCommunity -ErrorAction SilentlyContinue
            $result = Connect-MgGraphCommunity -ClientId $AuthDetails.AppId -TenantId $AuthDetails.TenantId `
                -CertificateThumbprint $AuthDetails.Thumbprint -NoWelcome -ErrorAction Stop
        }
        'Secret' {
            if ([string]::IsNullOrWhiteSpace($AuthDetails.AppId))  { throw "App ID is required for client secret authentication" }
            if ([string]::IsNullOrWhiteSpace($AuthDetails.TenantId)){ throw "Tenant ID is required for client secret authentication" }
            if ([string]::IsNullOrWhiteSpace($AuthDetails.Secret)) { throw "Client Secret is required for client secret authentication" }
            $secureSecret = ConvertTo-SecureString $AuthDetails.Secret -AsPlainText -Force
            $credential = New-Object PSCredential -ArgumentList $AuthDetails.AppId, $secureSecret
            Disconnect-MgGraphCommunity -ErrorAction SilentlyContinue
            $result = Connect-MgGraphCommunity -ClientId $AuthDetails.AppId -TenantId $AuthDetails.TenantId `
                -ClientSecretCredential $credential -NoWelcome -ErrorAction Stop
            # Wipe the secret from memory — never let it linger
            $secureSecret = $null; $credential = $null
            $AuthDetails.Remove('Secret')
        }
        default { throw "Invalid authentication method specified" }
    }
    return $result
}
```

**Audit the admin identity:** after connecting, capture who authenticated and write it to the log — operators troubleshooting destructive operations later need to know whose account performed them:

```powershell
$context = Get-MgGraphCommunityContext
if (-not $context) { throw "Failed to get Microsoft Graph context after connection" }
$script:AdminUPN = if ($context.Account) { $context.Account } else { "AppId:$($context.ClientId)" }
Write-Log "Authenticated as $($script:AdminUPN)" 'INFO'
```

**Verification step after connect:** Graph scopes that were *granted* differ from scopes that were *consented*; a tool should verify each required scope is present in `$context.Scopes` and surface missing ones instead of failing deep in a later operation. Allow `.Read` to satisfy `.ReadWrite` checks (a user with read-write consent also has read).

### Azure Automation Portal-Safe Parameters

Azure Automation passes boolean parameters as strings through the portal UI. A parameter declared as `[bool]$DownloadExisting` may arrive as the string `"true"` or `"$true"`. Normalize these once at the top of the script:

```powershell
param(
    [string]$ForceModuleInstall,   # Declare as string, not bool
    [string]$DownloadExisting      # Same — string, not bool
)

# Normalize boolean parameters for Azure Automation
foreach ($runbookBooleanParameter in @('ForceModuleInstall', 'DownloadExisting')) {
    $rawValue = [string](Get-Variable -Name $runbookBooleanParameter -ValueOnly)
    Remove-Variable -Name $runbookBooleanParameter

    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        Set-Variable -Name $runbookBooleanParameter -Value $false
        continue
    }

    switch ($rawValue.Trim().ToLowerInvariant()) {
        { $_ -in @("true", "1", '$true') } {
            Set-Variable -Name $runbookBooleanParameter -Value $true
        }
        { $_ -in @("false", "0", '$false') } {
            Set-Variable -Name $runbookBooleanParameter -Value $false
        }
        default {
            throw "Parameter '$runbookBooleanParameter' accepts only true, false, 1, 0, `$true, or `$false."
        }
    }
}
```

**Why this pattern:** If you declare `[bool]$ForceModuleInstall` and Azure Automation sends `"true"` (a string), PowerShell will coerce it to `$true` in most cases — but not always. The string `"$true"` (with dollar sign) will NOT coerce correctly and will throw a type conversion error. Declaring as `[string]` and normalizing explicitly is the only safe approach.

Also use `[ValidateSet("true", "false", "1", "0", '$true', '$false')]` on the string parameter for documentation and input validation:

```powershell
[ValidateSet("true", "false", "1", "0", '$true', '$false')]
[string]$DownloadExisting
```

### Azure Automation Job Metadata

Detect Azure Automation context using `$PSPrivateMetadata.JobId.Guid` (more reliable than `$env:AUTOMATION_ASSET_ACCOUNTID`):

```powershell
$IsAzureAutomation = $null -ne $PSPrivateMetadata.JobId.Guid
```

When running in Azure Automation, write progress and status to the job history so operators can see what happened:

```powershell
if ($IsAzureAutomation) {
    # Azure Automation job history shows these in the portal
    Write-Output "Starting diagnostics collection on $deviceCount device(s)..."
    Write-Output "Collection triggered on '$($device.deviceName)'"
    Write-Output "Waiting for collection to complete (timeout: $TimeoutMinutes minutes)..."
}
```

### Graph API Retry (Canonical `Invoke-GraphRequestWithRetry`)

For Graph API calls that may hit transient failures (429 throttling, 503 service unavailable, network blips), wrap the call in the canonical `Invoke-GraphRequestWithRetry` (`scripts/Invoke-GraphRequestWithRetry.ps1` — copy verbatim):

```powershell
# Canonical usage — single call with retry:
$device = Invoke-GraphRequestWithRetry -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')" -Method GET

# POST with body:
Invoke-GraphRequestWithRetry -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')/syncDevice" -Method POST
```

Key behaviors (why this design):
- **Status codes are extracted from error strings** with `(?:Graph error|HTTP)\s+(\d{3})\b` — the SDK surfaces errors as strings, not typed HTTP statuses. Never string-match on `'throttl'` — it misses 503 and matches false positives.
- **429 → fixed delay** (2s). Retry-After is honored *inside* the request library; do not double the delay for throttling.
- **5xx → exponential backoff** (2s, 4s, 8s). Linear delays waste time on persistent throttling; exponential gives Graph time to recover without blocking forever.
- **Non-retryable → throw immediately** — no pointless retries on 4xx.
- **403 → actionable guidance** via `Get-Graph403Message` (`scripts/Get-Graph403Message.ps1`): pass `-Service EntraID|Intune|Autopilot` and the operator sees the missing role + scope instead of raw HTTP text. See [403 Handling: Missing Roles and Multi-Admin Approval](#403-handling-missing-roles-and-multi-admin-approval).

### Graph Batch API (Bulk Operations)

For bulk writes — deleting 100 devices, updating 50 users, reassigning licenses — one request per item is a mistake. Graph's `$batch` endpoint accepts up to **20 sub-requests per POST**, cutting a 100-item operation from 100 round trips to 5. The canonical `Invoke-GraphBatchRequest` is in `scripts/Invoke-GraphBatchRequest.ps1` — copy it verbatim:

```powershell
# Canonical usage — build one request per item, then fire:
$requests = foreach ($device in $devices) {
    @{
        id     = $device.id          # unique within the batch — used to correlate responses
        method = 'DELETE'
        url    = "/deviceManagement/managedDevices('$($device.id)')"
    }
}
$responses = Invoke-GraphBatchRequest -Requests @($requests)

# Correlate results back to the items that failed
$failed = $responses | Where-Object { $_.status -ge 400 }
foreach ($failure in $failed) {
    $deviceId = $failure.id
    Write-Log "Delete failed for $deviceId (HTTP $($failure.status))" 'WARNING'
}
```

Key behaviors (why this design):

- **Auto-chunks at 20** — the caller never thinks about the limit; `for ($i = 0; $i -lt $Requests.Count; $i += 20)` handles it.
- **Individual sub-request retry** — a batch where 3 of 20 sub-requests get throttled re-sends *only those 3* (matched by `id`), with exponential backoff (2s, 4s, 8s). Re-sending the whole batch would duplicate the 17 successful writes.
- **`id` is the correlation key** — each sub-request needs a unique `id` so failures can be mapped back to the item. Use the target object's own id (device id, user id) — it's unique and makes the failure report self-explanatory.
- **Runs through `Invoke-GraphRequestWithRetry`** — the outer POST itself gets 429/5xx retry, so batching never loses the retry guarantees of single calls.
- **Payload limits still apply** — each sub-request is a normal Graph call; `$batch` saves round trips, not payload size. Huge JSON bodies still need `$select`/`$top` discipline.
- **`/$batch` on beta** (`https://graph.microsoft.com/beta/$batch`) supports a wider surface; use v1.0 (`/v1.0/$batch`) only when the operations you need exist there.

### 403 Handling: Missing Roles and Multi-Admin Approval

Graph `403` during a *destructive* operation (delete device, delete user, wipe) is almost never a missing permission scope — interactive admins already consented to scopes at sign-in. The real cause is almost always a **missing directory/Intune role**, which Graph permission checks don't see. A tool that reports "Authorization_RequestDenied" with raw HTTP text makes the admin file an app registration ticket that won't fix anything.

**Rule:** catch the 403, map it to the role fix via `Get-Graph403Message` (`scripts/Get-Graph403Message.ps1`), and *tell the operator what to assign*:

```powershell
catch {
    $statusCode = $null
    if ($_.Exception.Message -match '(?:Graph error|HTTP)\s+(\d{3})\b') {
        $statusCode = [int]$Matches[1]
    }
    if ($statusCode -eq 403) {
        # Delete from Intune failed — almost certainly a missing Intune role, not a scope
        $message = Get-Graph403Message -Service 'Intune'
        Write-Log "Offboarding $deviceName failed: $message" 'ERROR'
    }
}
```

Role-to-operation table (the mapping that matters for device lifecycle tools):

| Operation | Required role |
|-----------|---------------|
| Delete device from Entra ID | Cloud Device Administrator (or Intune Administrator) |
| Delete device from Intune | Intune Administrator, or Intune RBAC with *Managed devices – Delete* |
| Delete Autopilot identity / set group tags | Intune Administrator |
| Read BitLocker recovery keys | Cloud Device Administrator / Intune Administrator / Helpdesk Administrator |
| Read LAPS passwords | Cloud Device Administrator or Intune Administrator |

**Multi-Admin Approval (MAA):** tenants that protect destructive operations with MAA return a different failure — the operation is *not* rejected, it's *queued for approval*. Detect it and tell the admin to approve in Intune and re-run, instead of treating it as a failure:

```powershell
if ($_.Exception.Message -match 'Multi-Admin|multi.admin.approval|requires approval') {
    Write-Log "Operation requires Multi-Admin Approval — approve it in Intune and re-run" 'WARNING'
    # Do NOT count as a hard failure; the request is pending, not denied
}
```

**Why this matters:** every helpdesk admin has seen "403 Authorization_RequestDenied" and guessed wrong about the fix. The difference between "assign Intune Administrator role" and "check your Graph permissions" is the difference between a 2-minute fix and a 2-day ticket.

### Date Parsing (Canonical `ConvertTo-SafeDateTime`)

Graph API timestamps (`2025-12-31T10:30:00Z`) and CSV exports break under regional PowerShell versions — `[datetime]` casts use the machine culture. Parse with the canonical `ConvertTo-SafeDateTime` (`scripts/ConvertTo-SafeDateTime.ps1` — copy verbatim); it tries 8 formats with `InvariantCulture` and returns `$null` on unparseable/empty input instead of crashing:

```powershell
# Canonical usage:
$lastSync = ConvertTo-SafeDateTime -Value $device.lastSyncDateTime
if ($null -eq $lastSync) { Write-Log "Unparseable date: $($device.lastSyncDateTime)" "WARNING" }
```

### Disconnect (Always in a `finally` block)

```powershell
try {
    if (Get-MgContext) {
        $null = Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Output 'Disconnected from Microsoft Graph'
    }
}
catch {
    Write-Verbose 'Graph disconnection completed'
}
```

### Pagination Helper (Handles Throttling)

Microsoft Graph paginates large result sets. **The canonical `Get-MgGraphAllPages` is in `scripts/Get-MgGraphAllPages.ps1` — copy it verbatim.** It walks `@odata.nextLink`, uses a strongly-typed `List[T]` accumulator (O(1) per add — never `$results += $item`, which rebuilds the whole array per item), retries on 429 throttling, and reports progress every 10 pages:

```powershell
# Canonical usage:
$devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=id,deviceName,userPrincipalName,operatingSystem,osVersion,model,lastSyncDateTime"
```

**Why strongly-typed `List`?** `$results += $item` rebuilds the array on every addition. With 10,000 devices, that's 10,000 array copies — easily 30+ seconds of overhead. The `List[T]` is O(1) per add and finishes in milliseconds.

### Common Graph Operations

```powershell
# List all managed devices (with field selection for speed)
$devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=id,deviceName,azureADDeviceId,userPrincipalName,operatingSystem,osVersion,model,lastSyncDateTime"

# Find a device by serial number
$device = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=serialNumber eq 'ABC1234'&`$select=id,deviceName"

# Find devices by Entra ID group
$group = (Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/groups?`$filter=displayName eq 'IT-Devices'") | Select-Object -First 1
$members = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/groups/$($group.id)/members"

# Sync a device
$deviceId = "12345678-1234-1234-1234-123456789012"
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')/syncDevice" -Method POST

# Restart a device
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')/reboot" -Method POST

# Upload Autopilot hardware hash
$body = @{
    deviceHardwareIdentificationProperties = @{
        serialNumber       = 'ABC1234'
        hardwareIdentifier = 'BASE64HASH=='
    }
    groupTag = 'IT-Devices'
} | ConvertTo-Json
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/importedWindowsAutopilotDeviceIdentities" -Method POST -Body $body
```

### Dry-Run Pattern

Always support a `-DryRun` flag for any script that writes to the tenant:

```powershell
foreach ($device in $devices) {
    if ($DryRun) {
        Write-Output "[DRY RUN] Would sync $($device.deviceName)"
        continue
    }

    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$($device.id)')/syncDevice" -Method POST
    Write-Output "Synced $($device.deviceName)"
}
```

### Progress Tracking for Long-Running Operations

```powershell
$processed = 0
$total = $devices.Count

foreach ($device in $devices) {
    $processed++
    $percent = [math]::Round(($processed / $total) * 100)
    Write-Progress -Activity 'Processing Devices' `
        -Status "Processing $processed of $total`: $($device.deviceName)" `
        -PercentComplete $percent

    # ... your operation here ...
}

Write-Progress -Activity 'Processing Devices' -Completed
```

---

## Logging and Output

### Intune-Specific Logging

**One logger, canonical in `scripts/Write-Log.ps1`** — `Initialize-Log` + `Write-Log` (+ `Finish-Script` for exit points). There is no `Write-IntuneLog`, `Write-RemediationLog`, or any other logger; older copies invented `C:\ProgramData\IntuneRemediation\Logs` — the unified path is **`<SystemDrive>\IntuneLogs\<SolutionName>\`**.

```powershell
$SolutionName = "MyRemediation"
$SystemDrive = if ($env:SystemDrive) { $env:SystemDrive.TrimEnd('\') } else { [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\') }
$LogRoot = Join-Path $SystemDrive "IntuneLogs\$SolutionName"
$LogFile = Join-Path $LogRoot "remediation.log"

# Initialize-Log: creates $LogRoot + $LogFile (returns $false on failure)
# Write-Log:   "[timestamp] [LEVEL] Message" to console (colored) + file (UTF8)
# Finish-Script: logs final message and exits with the given code in one call
$script:LogReady = Initialize-Log
Write-Log "Remediation started" "INFO"
```

**Why this pattern:**
- Log path: `<SystemDrive>\IntuneLogs\<SolutionName>\` (standardized location — the same one used by the classic Intune remediation script template)
- Writes to both console (colored) and file (UTF8)
- Timestamp format: `[yyyy-MM-dd HH:mm:ss] [LEVEL] Message`
- Level-based coloring for console output (Tailwind Slate palette, see SKILL.md)
- Suppresses log write errors to prevent cascading failures

---

## Error Handling

Classify errors by keyword for clear reporting:

```powershell
catch {
    $msg = $_.Exception.Message
    if ($msg -match 'Access is denied') {
        Write-Log "ACCESS DENIED - Run as Administrator" "ERROR"
    }
    elseif ($msg -match 'The system cannot find') {
        Write-Log "FILE NOT FOUND - Required component missing" "ERROR"
    }
    elseif ($msg -match 'timeout') {
        Write-Log "TIMEOUT - Operation took too long" "ERROR"
    }
    else {
        Write-Log "FAILED: $msg" "ERROR"
    }
    $exitCode = 2  # Script error
}
```

---

## Custom Compliance Policies

Custom compliance scripts are a THIRD script format, distinct from Proactive Remediation pairs: a **discovery script** runs on the device and emits ONE line of JSON that Intune validates against a **JSON settings definition** uploaded beside it. Distilled from production App Presence / App Version compliance scripts (see  → `Intune-Compliance-Policies`).

### Folder contract

```
<compliance-name>/
├── <name>-settings.json     # Rules Intune evaluates (uploaded as the custom compliance policy settings)
├── detect-<name>.ps1        # Discovery script - emits one JSON line
└── README.md
```

### Discovery script output contract

The script MUST print exactly one compressed JSON line whose top-level object carries at minimum a boolean `Compliant` property. Extra properties become evidence in the device compliance report:

```powershell
$result = [ordered]@{
    Compliant   = $script:isCompliant          # REQUIRED boolean - Intune reads this
    Scenario    = "AppPresence"                # free-form context
    Details     = @("App version 4.2.1 found") # optional evidence array
}
Write-Output ($result | ConvertTo-Json -Compress)
exit 0
```

Rules:

- **Never emit anything else to stdout** — banners and progress lines corrupt the JSON payload. Log to `<SystemDrive>\IntuneLogs\` with `Initialize-Log`/`Write-Log` instead of console output.
- **`Compliant` is the only field Intune acts on.** Missing or non-boolean values mark the device as non-compliant-with-error, so guard every property access in try/catch.
- Exit code stays `0` even when non-compliant — unlike remediation detection, compliance here is carried by the JSON, not the exit code. Use exit 2 only for genuine script crashes.
- Keep discovery read-only and fast (< 30s), same idempotency rules as detection scripts.
- The `-settings.json` defines the rule operators (`operator`: greaterEquals/equals, `value`, `dataType`) that Intune applies against your JSON properties — generate both files together so keys never drift.

---

## Packaging for Intune

### Win32 App Packaging

```powershell
# Using IntuneWinAppUtil.exe
$source = "C:\Package\MyApp"
$output = "C:\Package\Output"
$installer = "setup.exe"

& "C:\Tools\IntuneWinAppUtil.exe" -c $source -o $output -i $installer -q
```

### Detection Rules for Win32 Apps

```powershell
# Registry-based detection
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{GUID}"
$version = Get-ItemProperty -Path $regPath -Name "DisplayVersion" -ErrorAction SilentlyContinue
if ($version.DisplayVersion -ge "1.0.0") {
    exit 0  # App detected
}
exit 1  # App not detected
```

### Script-based Detection

```powershell
# File-based detection
$exePath = "C:\Program Files\MyApp\app.exe"
if (Test-Path $exePath) {
    $version = (Get-Item $exePath).VersionInfo.ProductVersion
    if ($version -ge "2.0.0") {
        exit 0
    }
}
exit 1
```

---

## Cross-Service Device Lifecycle Management & Safeguards

In modern enterprise environments, managing device offboarding or state changes requires correlating device records across **four distinct services**:
1. **Microsoft Intune** (`/deviceManagement/managedDevices`) — Managed device record.
2. **Windows Autopilot** (`/deviceManagement/windowsAutopilotDeviceIdentities`) — Hardware hash and deployment profile.
3. **Microsoft Entra ID** (`/devices`) — Cloud identity and directory object.
4. **Microsoft Defender for Endpoint (MDE)** (`/machines`) — Security onboarding state.

### 1. Cross-Service Device Correlation Pattern

Matching devices across services using serial number or Azure AD Device ID:

```powershell
function Get-CrossServiceDevice {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$SerialNumber)

    $result = [PSCustomObject]@{
        SerialNumber   = $SerialNumber
        IntuneId       = $null
        EntraDeviceId  = $null
        AutopilotId    = $null
        PrimaryUser    = $null
        OS             = $null
        LastSyncDate   = $null
        BitLockerKeys  = @()
        LapsPassword   = $null
    }

    # 1. Query Intune
    $intuneQuery = Invoke-GraphRequestWithRetry -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=serialNumber eq '$SerialNumber'&`$select=id,deviceName,azureADDeviceId,userPrincipalName,operatingSystem,lastSyncDateTime"
    if ($intuneQuery.value) {
        $dev = $intuneQuery.value[0]
        $result.IntuneId      = $dev.id
        $result.EntraDeviceId = $dev.azureADDeviceId
        $result.PrimaryUser   = $dev.userPrincipalName
        $result.OS            = $dev.operatingSystem
        $result.LastSyncDate  = $dev.lastSyncDateTime
    }

    # 2. Query Autopilot
    $autopilotQuery = Invoke-GraphRequestWithRetry -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=serialNumber eq '$SerialNumber'&`$select=id,serialNumber,groupTag,azureActiveDirectoryDeviceId"
    if ($autopilotQuery.value) {
        $result.AutopilotId = $autopilotQuery.value[0].id
        if (-not $result.EntraDeviceId) {
            $result.EntraDeviceId = $autopilotQuery.value[0].azureActiveDirectoryDeviceId
        }
    }

    return $result
}
```

### 2. Pre-Destructive Action Safeguards (BitLocker & LAPS)

Before wiping, deleting, or offboarding any corporate device, production tools **MUST** query and present/backup recovery keys to prevent irreversible data loss.

#### BitLocker Recovery Key Query (`BitlockerKey.Read.All`):
```powershell
function Get-DeviceBitLockerKeys {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$DeviceId)

    # Queries Entra ID BitLocker keys registered to this device ID
    $uri = "https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId eq '$DeviceId'"
    $keys = Get-MgGraphAllPages -Uri $uri

    $detailedKeys = foreach ($k in $keys) {
        # Retrieve actual key payload
        Invoke-GraphRequestWithRetry -Uri "https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys('$($k.id)')?`$select=key,createdDateTime,volumeType"
    }
    return @($detailedKeys)
}
```

#### Windows LAPS Password Query (`DeviceLocalCredential.Read.All`):
```powershell
function Get-DeviceLapsPassword {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$EntraObjectId)

    $uri = "https://graph.microsoft.com/beta/directory/deviceLocalCredentials('$EntraObjectId')?`$select=credentials"
    try {
        $laps = Invoke-GraphRequestWithRetry -Uri $uri
        return $laps.credentials
    } catch {
        Write-Warning "Could not retrieve LAPS password: $($_.Exception.Message)"
        return $null
    }
}
```

---

## Fleet Health & Playbook Queries

Pre-built operational audit queries for proactive tenant hygiene:

### 1. Orphaned Autopilot Devices (In Autopilot, Missing from Intune)
```powershell
function Get-OrphanedAutopilotDevices {
    $autopilot = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$select=id,serialNumber,groupTag,azureActiveDirectoryDeviceId"
    $intune = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=serialNumber"

    $intuneSerials = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($d in $intune) { if ($d.serialNumber) { $null = $intuneSerials.Add($d.serialNumber) } }

    $orphans = $autopilot | Where-Object { -not $intuneSerials.Contains($_.serialNumber) }
    return @($orphans)
}
```

### 2. Stale Device Analysis (30 / 90 / 180 Days Inactive)
```powershell
function Get-StaleDevicesReport {
    param([int]$DaysInactive = 90)

    $cutoffDate = (Get-Date).AddDays(-$DaysInactive).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $filter = "lastSyncDateTime le $cutoffDate"
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=$filter&`$select=id,deviceName,userPrincipalName,operatingSystem,lastSyncDateTime"
    return Get-MgGraphAllPages -Uri $uri
}
```

### 3. Corporate vs Personal (BYOD) Device Ownership Split
```powershell
function Get-DeviceOwnershipDistribution {
    $devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=managedDeviceOwnerType,operatingSystem"
    return ($devices | Group-Object -Property managedDeviceOwnerType -NoElement | Select-Object Name, Count)
}
```

---

## Managed Identity Graph Permission Granting (`AppRoleAssignment`)

When deploying Azure Automation Runbooks that access Microsoft Graph via System-Assigned or User-Assigned Managed Identity, Azure Portal **does not support assigning Graph Application permissions via the UI**. You must assign them programmatically via `AppRoleAssignment`:

```powershell
function Grant-GraphManagedIdentityPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManagedIdentityDisplayName,
        [Parameter(Mandatory = $true)]
        [string[]]$Permissions # e.g. @('DeviceManagementManagedDevices.Read.All', 'User.Read.All')
    )

    # Constant Microsoft Graph App ID
    $graphAppId = "00000003-0000-0000-c000-000000000000"

    # Connect if not connected
    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
        Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All" -NoWelcome -ErrorAction Stop
    }

    $sp = Get-MgServicePrincipal -Filter "DisplayName eq '$ManagedIdentityDisplayName'" -ErrorAction Stop | Select-Object -First 1
    if (-not $sp) { throw "Managed Identity '$ManagedIdentityDisplayName' not found." }

    $graphSPN = Get-MgServicePrincipal -Filter "AppId eq '$graphAppId'" -ErrorAction Stop | Select-Object -First 1
    if (-not $graphSPN) { throw "Microsoft Graph Service Principal not found." }

    foreach ($permission in $Permissions) {
        $appRole = $graphSPN.AppRoles | Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application" }
        if (-not $appRole) {
            Write-Warning "App role '$permission' not found in Microsoft Graph."
            continue
        }

        # Check existing assignment
        $existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id |
            Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $graphSPN.Id }

        if ($existing) {
            Write-Verbose "Permission '$permission' is already granted to '$ManagedIdentityDisplayName'."
            continue
        }

        $params = @{
            PrincipalId = $sp.Id
            ResourceId  = $graphSPN.Id
            AppRoleId   = $appRole.Id
        }
        $null = New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -BodyParameter $params -ErrorAction Stop
        Write-Information "Successfully granted '$permission' to Managed Identity '$ManagedIdentityDisplayName'." -InformationAction Continue
    }
}
```

---

## Azure Log Analytics Workspace (LAW) Ingestion Pattern

For enterprise audit, compliance tracking, and workbook visualization, Intune runbooks can send structured JSON telemetry directly to Log Analytics using the Logs Ingestion API or Data Collector API:

```powershell
function Send-IntuneTelemetryToLogAnalytics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceId,
        [Parameter(Mandatory = $true)][string]$SharedKey,
        [Parameter(Mandatory = $true)][string]$LogType, # e.g. "IntuneDeviceInventory_CL"
        [Parameter(Mandatory = $true)][object[]]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 10
    $body = [System.Text.Encoding]::UTF8.GetBytes($json)

    $date = [System.DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length

    # Build signature for HMAC-SHA256
    $stringToSign = "POST`n$contentLength`napplication/json`nx-ms-date:$date`n/api/logs"
    $bytesToSign = [System.Text.Encoding]::UTF8.GetBytes($stringToSign)
    $keyBytes = [System.Convert]::FromBase64String($SharedKey)
    $hasher = [System.Security.Cryptography.HMACSHA256]::new($keyBytes)
    $signature = [System.Convert]::ToBase64String($hasher.ComputeHash($bytesToSign))

    $authHeader = "SharedKey ${WorkspaceId}:$signature"

    $headers = @{
        "Authorization"        = $authHeader
        "Log-Type"             = $LogType
        "x-ms-date"            = $date
        "time-generated-field" = "lastSyncDateTime"
    }

    $uri = "https://$WorkspaceId.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body -ContentType "application/json"
    Write-Verbose "Ingested $($Data.Count) records into Log Analytics ($LogType)"
}
```

---

## The 6 Intune Operational Automation Domains

Every enterprise Intune automation script falls into one of these 6 domains:

| Domain | Key Operations | Graph Endpoints |
|---|---|---|
| **1. Operational** | Reboot, Sync, Remote Wipe, Retire, Collect Diagnostics | `/deviceManagement/managedDevices('{id}')/syncDevice`<br>`/deviceManagement/managedDevices('{id}')/cleanWindowsDevice` |
| **2. Applications** | Win32 app detection, assignments, supersedence | `/deviceManagement/mobileApps`<br>`/deviceManagement/mobileApps('{id}')/assignments` |
| **3. Compliance** | Compliance states, non-compliant alerts, auto-tagging | `/deviceManagement/deviceCompliancePolicyDeviceStateSummary`<br>`/deviceManagement/managedDevices?$filter=complianceState eq 'noncompliant'` |
| **4. Security** | BitLocker key rotation, Defender offboarding, ASR policies | `/informationProtection/bitlocker/recoveryKeys`<br>`/deviceManagement/deviceConfigurations` |
| **5. Devices** | Primary User set/remove, Autopilot Group Tags, bulk rename | `/deviceManagement/managedDevices('{id}')/users/$ref`<br>`/deviceManagement/windowsAutopilotDeviceIdentities('{id}')/setDeviceTag` |
| **6. Monitoring** | Health digests (HTML email via Graph Mail), LAW export | `/users('{adminUPN}')/sendMail`<br>`Log Analytics Ingestion REST API` |

---

## Always-Run Detection Pattern (Scheduled Maintenance Action)

In Intune Proactive Remediations, there are scenarios where the goal is **not to test compliance**, but to execute a **scheduled recurring maintenance action** (e.g. daily Downloads/Temp cleanup, log rotation, cache purging).

Because Intune requires a Detection script to return non-compliant before it triggers Remediation, the Detection script is designed as an intentional trigger:

```powershell
# Detection Script: Always-Run Pattern
try {
    $script:LogReady = Initialize-Log
    Write-Banner

    Write-Log -Message 'Always-Run Detection: returning non-compliant to trigger recurring maintenance' -Level 'WARNING'
    Finish-Script -Message 'Non-Compliant: Scheduled maintenance action is required.' -ExitCode 1 -Level 'WARNING'
}
catch {
    Finish-Script -Message "Detection initialization failed: $($_.Exception.Message)" -ExitCode 2 -Level 'ERROR'
}
```

---

## Multi-Target Resilient Remediation (Per-Target Failure Tracking)

When a remediation script operates across multiple targets (multiple user profiles under `C:\Users`, multiple drives, or multiple services), it must **never fail entirely due to a single locked file or inaccessible target**.

### The Rule:
- **Exit 0 (Success):** At least one target succeeded.
- **Exit 1 (Failure):** ALL targets failed.
- **Exit 2 (Script Error):** Fatal uncaught exception during initialization.

```powershell
$targetCount     = 0
$failedCount     = 0
$totalFreedBytes = 0

foreach ($target in $targets) {
    $targetCount++
    try {
        # Process individual target
        # ... logic ...
        Write-Log -Message "Successfully processed target: $target" -Level 'SUCCESS'
    }
    catch {
        $failedCount++
        Write-Log -Message "Failed to process target $target`: $($_.Exception.Message)" -Level 'ERROR'
    }
}

# Determine exit code based on aggregate results
$successCount = $targetCount - $failedCount
if ($targetCount -eq 0) {
    Finish-Script -Message 'No targets found to process.' -ExitCode 0 -Level 'WARNING'
}
if ($failedCount -ge $targetCount) {
    Finish-Script -Message "All $targetCount targets failed." -ExitCode 1 -Level 'ERROR'
}
Finish-Script -Message "Remediation completed successfully for $successCount of $targetCount targets." -ExitCode 0 -Level 'SUCCESS'
```

---

## Multi-User Profile Operations in SYSTEM Context (`C:\Users\*`)

Intune remediation scripts running under `NT AUTHORITY\SYSTEM` often need to clean or configure all user profiles on a shared or multi-user device:

```powershell
$UserProfilesRoot = 'C:\Users'
$userFolders = @(Get-ChildItem -Path $UserProfilesRoot -Directory -ErrorAction Stop |
    ForEach-Object {
        $targetSubDir = Join-Path $_.FullName 'Downloads' # Or 'AppData\Local\Temp'
        if (Test-Path -Path $targetSubDir) {
            $targetSubDir
        }
    })
```

---

## Metric Reporting Pattern (`Format-FileSize`)

Reporting human-readable metrics (space freed, items removed) in the final line of output allows operators to see results directly in the Intune portal:

```powershell
function Format-FileSize {
    param([Parameter(Mandatory = $true)][long]$Bytes)

    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return '{0:N2} MB' -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { return '{0:N2} KB' -f ($Bytes / 1KB) }
    else { return '{0} Bytes' -f $Bytes }
}
```



