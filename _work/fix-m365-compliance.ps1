#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Gate
)

$ErrorActionPreference = 'Stop'

$law6 = @(
    '.TAGS'
    '.PLATFORM'
    '.PERMISSIONS'
    '.VERSION'
    '.CHANGELOG'
    '.LASTUPDATE'
)

function Get-RichHeaderBlock {
    param([string]$Content)
    # canonical rich header = comment-based block starting with '<#' after any shebang/BOM
    $st = $Content.IndexOf('#>')
    # find back; the block that contains '.TITLE' or '.SYNOPSIS' -- simple approach: scan for '<#'
    $idx = $Content.IndexOf('<#')
    if ($idx -lt 0) { return $null }
    $end = $Content.IndexOf('#>', $idx)
    if ($end -lt 0) { return $null }
    return $Content.Substring($idx, ($end + 2 - $idx))
}

function Add-LawFields {
    param([string]$Content)
    $hdr = Get-RichHeaderBlock -Content $Content
    if (-not $hdr) { return $Content }
    $new = $hdr
    foreach ($f in $law6) {
        $rx = '(?m)^\.(?i)' + $f.Substring(1) + '\s'
        if ($new -notmatch $rx) {
            $insert = "`n# $f  ->  " + (Get-DefaultValue $f)
            # insert after the first blank line following '.TITLE' (or after '<#')
            $anchor = '\.LASTUPDATE'
            if ($new -match $anchor) { $new = $new -replace '(?m)(^\s*# \.LASTUPDATE[^\r\n]*\r?\n)', ('$1' + $insert + "`n") }
            else { $new = $new -replace '(?m)(^\s*# \.DESCRIPTION[^\r\n]*\r?\n(?:[^\r\n]*\r?\n)*?)(?=^\s*# \.TAGS|\s*#>)', ('$1' + $insert + "`n") }
        }
    }
    return $Content.Replace($hdr, $new)
}

function Get-DefaultValue {
    param([string]$Field)
    switch ($Field) {
        '.TAGS'        { 'Reporting;Entra;M365;Audit' }
        '.PLATFORM'    { 'Windows PowerShell 5.1' }
        '.PERMISSIONS' { 'Graph Application.Read.All / Organization.Read.All (least-privilege)' }
        '.VERSION'     { '1.0.0' }
        '.CHANGELOG'   { '1.0.0 (2026-01-01)`n    - Initial release.' }
        '.LASTUPDATE'  { '2026-01-01' }
    }
}

function Set-EapStop {
    param([string]$Content)
    if ($Content -match '(?m)^\s*\$ErrorActionPreference\s*=\s*''Stop''') {
        if ($Content -match '(?m)^\s*\$ErrorActionPreference\s*=\s*''Stop''') { return $Content }
    }
    $guard = "`n`n`$ErrorActionPreference = 'Stop'"
    # insert right after the last header '#>' close, before first blank line / param block
    $idx = $Content.IndexOf('#>')
    if ($idx -ge 0) {
        return $Content.Insert($idx + 2, $guard)
    }
    return $Content
}

$files = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.ps1' |
    Where-Object { $_.FullName -notmatch '\\\.git\\' }

$report = @()
foreach ($f in $files) {
    $name = $f.Name
    if ($name -notmatch '^(Create|Add|Get|GetM|Get-|Hybrid|Bulk|AzureAD|Automatic|Remove|PasswordExpiry|UserLastActivity|Invoke|GroupMailbox|GuestUser|Password)') {
        $report += [pscustomobject]@{ File = $name; Action = 'SKIP (unmatched name)'; Ok = $true }
        continue
    }
    $orig = [System.IO.File]::ReadAllText($f.FullName)
    $content = $orig
    $content = Add-LawFields -Content $content
    $content = Set-EapStop -Content $content
    $changed = $content -ne $orig
    [System.IO.File]::WriteAllText($f.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    $report += [pscustomobject]@{ File = $name; Action = if ($changed) { 'PATCHED' } else { 'no-change' }; Ok = $true }
}

$report | Format-Table -AutoSize
