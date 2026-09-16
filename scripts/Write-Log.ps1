<#
.TITLE
    Write-Log

.SYNOPSIS
    Canonical CLI logging functions for enterprise PowerShell tools.

.DESCRIPTION
    The single source of truth for CLI script logging (Intune remediation/detection, AD, WinRM, event logs).
    Provides Initialize-Log, Write-Banner, Write-Log, Write-Summary, and Finish-Script helpers with standardized formatting.
    Write-Banner reads $SolutionName and $ScriptMode from the caller's scope (set by every template before dot-sourcing).

.TAGS
    Logging,CLI,Intune

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.4.0

.CHANGELOG
    1.4.0 (2026-09-15)
    - Clean console style: Write-Log now prints plain $Message with level color
      (no [timestamp] [LEVEL] prefix); file keeps [timestamp] [LEVEL] for fleet
      troubleshooting. Write-Banner title now includes live timestamp
      "Solution | Mode | yyyy-MM-dd HH:mm:ss" to match operator-facing output.
    1.3.0 (2026-08-30)
    - Add canonical Write-Summary helper: colored status line + aligned
      per-target result table (Target/Result/Skipped/Error). Single source so
      every generated CLI prints identical output (Lesson 2026-08-30
      Windows-Scripts console output polish).
    1.2.0 (2026-08-30)
    - AllowEmptyString on Write-Log -Message + early-return guard (Lesson
      2026-08-30 Find-IntunePolicyConflict). Mandatory + empty was a binding
      crash; visual spacers (`Write-Log -Message ""`) now no-op cleanly.
    1.1.0 (2026-08-20)
    - Canonical rich header upgrade to Enterprise Standards field order
    1.0.0 - Initial release

.LASTUPDATE
    2026-09-15

.PARAMETER ExitCode
    Process exit code to terminate with (0=success/compliant, 1=failure/non-compliant, 2=script error).

.PARAMETER NoExit
    If specified in Finish-Script, logs the final line but does not call exit (safe for interactive/testing).

.PARAMETER Message
    The message to log.

.PARAMETER Level
    Log level ('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG'). Default is 'INFO'.

.EXAMPLE
    $script:LogReady = Initialize-Log -SolutionName 'BitLockerRemediation' -ScriptMode 'detect'
    Write-Banner
    Write-Log -Message 'Starting detection' -Level 'INFO'
    $results = @($targets | ForEach-Object { Invoke-TargetAction -TargetName $_ })
    Write-Summary -Results $results
    Finish-Script -ExitCode 0 -Message 'Compliant' -Level 'SUCCESS'
.NOTES
    - Canonical CLI logging — copy verbatim; handles AllowEmptyString spacer (Pitfall 30).

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
# --- Logging (CLI Configuration) --------------------------------------------
$script:SystemDrive = if ($env:SystemDrive) { $env:SystemDrive.TrimEnd('\') } else {
    [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
}
$script:LogRoot  = $null
$script:LogFile  = $null
$script:LogReady = $false

function Initialize-Log {
    [CmdletBinding()]
    param(
        [string]$SolutionName = 'EnterpriseAdminTool',
        [string]$ScriptMode = 'run',
        [ValidateSet('Intune', 'General')]
        [string]$Type = 'General'
    )

    try {
        if ($Type -eq 'Intune') {
            $script:LogRoot = Join-Path $script:SystemDrive "IntuneLogs\$SolutionName"
            $script:LogFile = Join-Path $script:LogRoot "$SolutionName-$ScriptMode.txt"
        } else {
            $script:LogRoot = Join-Path $env:ProgramData "$SolutionName\Logs"
            $script:LogFile = Join-Path $script:LogRoot "$SolutionName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        }

        if (-not (Test-Path -LiteralPath $script:LogRoot)) {
            $null = [System.IO.Directory]::CreateDirectory($script:LogRoot)
        }
        if (-not (Test-Path -LiteralPath $script:LogFile)) {
            $null = [System.IO.File]::Create($script:LogFile).Dispose()
        }

        $script:LogReady = $true
        return $true
    }
    catch {
        Write-Host "Log initialization failed: $($_.Exception.Message)" -ForegroundColor Red
        $script:LogReady = $false
        return $false
    }
}

function Write-Banner {
    [CmdletBinding()]
    [Alias('Show-Banner')]
    param()

    # Clean enterprise banner: title includes live timestamp so file+console match
    # the user-facing shape:
    #   ==============================================================================
    #   Solution | Mode | yyyy-MM-dd HH:mm:ss
    #   ==============================================================================
    $title      = '{0} | {1} | {2}' -f $SolutionName, $ScriptMode, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $bannerLine = '=' * 78
    $lines      = @('', $bannerLine, $title, $bannerLine)

    foreach ($line in $lines) {
        if ($line -eq $title) {
            Write-Host $line -ForegroundColor White
        } else {
            Write-Host $line -ForegroundColor DarkGray
        }

        if ($script:LogReady -and $script:LogFile) {
            Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue -WhatIf:$false
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Message = "",
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    # Visual spacer support: callers commonly use `Write-Log -Message ""` to break
    # sections vertically. PowerShell's Mandatory binding treats an empty string
    # as a missing value, so the canonical helper MUST early-return on empty -
    # see Lesson 2026-08-30 | Find-IntunePolicyConflict | CLI logging / Mandatory parameter.
    if ([string]::IsNullOrEmpty($Message)) { return }

    # Console = clean, no timestamp/level prefix - color alone conveys severity.
    # File    = detailed - keeps [timestamp] [LEVEL] for fleet troubleshooting.
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fileLine  = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        "DEBUG"   { "DarkGray" }
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
    }
    Write-Host $Message -ForegroundColor $color

    if ($script:LogReady -and $script:LogFile) {
        Add-Content -LiteralPath $script:LogFile -Value $fileLine -Encoding UTF8 -ErrorAction SilentlyContinue -WhatIf:$false
    }
}

# Renders the canonical end-of-run summary: one colored status line followed by
# an aligned per-target result table. Accepts the aggregate array of result
# objects returned by Invoke-TargetAction (Target/Success/Skipped/Error). This
# is the single formatting helper so every generated CLI prints identical output.
function Write-Summary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Results
    )

    $results = @($Results | Where-Object { $null -ne $_ })
    $ok      = @($results | Where-Object { $_.Success -and -not $_.Skipped }).Count
    $skipped = @($results | Where-Object { $_.Skipped }).Count
    $failed  = @($results | Where-Object { -not $_.Success }).Count

    $summary      = if ($failed -gt 0) { "FAILED" } elseif ($skipped -gt 0 -and $ok -eq 0) { "SKIPPED" } else { "OK" }
    $colorSummary = if ($failed -gt 0) { 'Red' } elseif ($skipped -gt 0 -and $ok -eq 0) { 'Yellow' } else { 'Green' }

    Write-Host ("  Summary : {0} ok, {1} skipped, {2} failed  ->  {3}" -f $ok, $skipped, $failed, $summary) -ForegroundColor $colorSummary

    $maxLen = 4
    if ($results.Count -gt 0) {
        $maxLen = [Math]::Max(($results | ForEach-Object { $_.Target.Length } | Measure-Object -Maximum).Maximum, 4)
    }
    Write-Host ("  {0,-$($maxLen + 2)} {1,-9} {2,-9} {3}" -f 'Target', 'Result', 'Skipped', 'Error') -ForegroundColor DarkGray
    Write-Host ("  {0}" -f ('-' * ($maxLen + 35))) -ForegroundColor DarkGray

    foreach ($r in $results) {
        if     ($r.Success) { $color = 'Green';  $resultText = 'OK' }
        elseif ($r.Skipped) { $color = 'Yellow'; $resultText = 'SKIPPED' }
        else               { $color = 'Red';    $resultText = 'FAILED' }
        $skippedText = if ($r.Skipped) { 'yes' } else { 'no' }
        $errorText   = if ($r.Error) { $r.Error } else { '' }
        Write-Host ("  {0,-$($maxLen + 2)} {1,-9} {2,-9} {3}" -f $r.Target, $resultText, $skippedText, $errorText) -ForegroundColor $color
    }
}

function Finish-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ExitCode,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [switch]$NoExit
    )

    Write-Log -Message $Message -Level $Level
    if (-not $NoExit) {
        exit $ExitCode
    }
}