<#
.TITLE
    Add-LogLine

.SYNOPSIS
    Canonical WPF GUI logging helper.

.DESCRIPTION
    The single source of truth for WPF tool logging (Type 1).
    Logs color-coded messages to console, appends timestamped entries to a session log file,
    updates the UI status bar via Dispatcher, and filters immediate consecutive duplicate messages.

.TAGS
    Logging,GUI,WPF

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.3.0

.CHANGELOG
    1.3.0 (2026-09-15)
    - Clean console style: prints plain $Message with level color (no
      [timestamp] [LEVEL] prefix on console); file keeps [timestamp] [LEVEL]
      and RichTextBox keeps structured entry. Matches CLI Write-Log clean style.
    1.2.0 (2026-08-30)
    - AllowEmptyString on Add-LogLine -Message + early-return guard (Lesson
      2026-08-30 Find-IntunePolicyConflict). Mandatory + empty was a binding
      crash; visual spacers (`Add-LogLine -Message ""`) now no-op cleanly.
    1.1.0 (2026-08-20)
    - Canonical rich header upgrade to Enterprise Standards field order
    1.0.0 - Initial release

.LASTUPDATE
    2026-09-15

.PARAMETER Level
    Log level ('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG'). Default is 'INFO'.

.PARAMETER Message
    The text message to log.

.EXAMPLE
    Add-LogLine -Message 'Operation completed successfully' -Level 'SUCCESS'
.NOTES
    - Canonical GUI logging helper — copy verbatim; do not retype (Identity Lock).

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
# --- Logging Initialization (GUI) -------------------------------------------
if (-not $ToolName) { $ToolName = 'PowerShellApp' }
$script:LogDir = Join-Path $env:LOCALAPPDATA "$ToolName\Logs"
if (-not (Test-Path -LiteralPath $script:LogDir)) {
    try { $null = [System.IO.Directory]::CreateDirectory($script:LogDir) } catch [System.Exception] { Write-Host "Log dir unavailable: $($_.Exception.Message)" -ForegroundColor DarkGray }
}
$script:LogFile = Join-Path $script:LogDir "$ToolName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:lastLogKey = $null

function Add-LogLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Message = "",
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )

    # Visual spacer support: callers commonly use `Add-LogLine -Message ""` to
    # break sections vertically. PowerShell's Mandatory binding treats an empty
    # string as a missing value, so the canonical helper MUST early-return on
    # empty - see Lesson 2026-08-30 | Find-IntunePolicyConflict | CLI logging /
    # Mandatory parameter. The Add-LogLine sibling of Write-Log has the same fix.
    if ([string]::IsNullOrEmpty($Message)) { return }

    # Log noise guard: drop exact duplicate lines sent consecutively
    $currentLogKey = "$Level|$Message"
    if ($script:lastLogKey -eq $currentLogKey) {
        return
    }
    $script:lastLogKey = $currentLogKey

    # Console = clean (plain message + color) for operator readability.
    # File + RichTextBox keep [timestamp] [LEVEL] for troubleshooting.
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $fileLine  = "[$timestamp] [$Level] $Message"

    # File output
    Add-Content -LiteralPath $script:LogFile -Value $fileLine -Encoding UTF8 -ErrorAction SilentlyContinue -WhatIf:$false

    # Console output — Tailwind Slate log palette (clean)
    $color = switch ($Level) {
        'DEBUG'   { 'DarkGray' }
        'INFO'    { 'Cyan' }
        'SUCCESS' { 'Green' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
    }
    Write-Host $Message -ForegroundColor $color

    # Live log-viewer bridge (Pattern E): notify subscriber with entry parts.
    if ($script:OnLogEntry) { & $script:OnLogEntry -Timestamp $timestamp -Level $Level -Message $Message }

    # Status bar update (if UI control is bound)
    if ($script:lblStatusText -and $script:lblStatusText.Dispatcher) {
        try {
            $script:lblStatusText.Dispatcher.Invoke([Action]{
                $script:lblStatusText.Text = "[$Level] $Message"
            })
        }
        catch [System.Exception] {
            # Window closing or thread unavailable during dispatch
            $null = $_
        }
    }
}