# Lessons Learned Register

The skill learns from its own mistakes. The **Lessons Learned Register** lives INSIDE the skill at `<skill-dir>/lessons-learned.md` — one global register that travels with the skill and applies to every script, tool, and project it touches. Project-local copies are not used: a lesson learned in one project must protect every future build. This file defines the register's format and workflow; the actual entries live in the skill-root register.

## Workflow

1. **Before building anything**, read `<skill-dir>/lessons-learned.md`. If a listed lesson applies to the current task, follow its rule.
2. **During the build**, when a mistake happens, append an entry to `<skill-dir>/lessons-learned.md` immediately - do not wait for the end of the session.
3. **At the end of the session**, skim the register: any rule that has now prevented a mistake twice is a candidate for promotion into `references/pitfalls.md` (ask the user first; never edit reference files unilaterally).

## When to Log an Entry

Append an entry only when one of these actually happened (no speculation):

- **User correction** — the user corrected your output, naming, structure, or a rule you got wrong.
- **Runtime crash** — a delivered script failed on the user's machine or in testing (PS 5.1 incompatibility, XAML parse error, auth failure, culture-related date bug).
- **Non-obvious pitfall** — you hit a PS 5.1 trap, a Graph throttling/403 case, or a WinRM quirk that was not already in `references/pitfalls.md`.
- **Environment discovery** — a new constraint about the environment (PowerShell version, module availability, group policy, proxy).

## File Format

```markdown
# Lessons Learned Register

> Created by the powershell-enterprise-admin skill. One entry per mistake, appended at the bottom.
> A lesson is only logged once — check existing entries and references/pitfalls.md before appending.

## YYYY-MM-DD | <tool name> | <area>

- **Mistake:** what was done wrong, one sentence
- **Cause:** why it happened, one sentence
- **Fix:** what actually solved it, one sentence
- **Rule:** the reusable rule going forward, one sentence, imperative

```

## Example Entry

```markdown
## 2026-08-20 | Bulk-Password-Reset | logging

- **Mistake:** Wrote `Write-ADAuditLog` for the audit trail and `Add-LogLine` for console output in the same CLI script.
- **Cause:** Copied the GUI pattern from an older tool without checking the Canonical Conventions table.
- **Fix:** Replaced both with the canonical `Write-Log` + `Initialize-Log` (`scripts/Write-Log.ps1`); kept a structured CSV export for the compliance audit record.
- **Rule:** CLI scripts use Write-Log only — GUI's Add-LogLine never appears in a non-GUI script.
```

## Rules

- **Dedupe:** never append an entry whose rule already exists in this register or in `references/pitfalls.md`. Check both first.
- **Terse:** one line per field; the register is read by the model on later sessions, so keep entries scannable.
- **Evidence-based:** no entry without a concrete event — the register is for observed mistakes, not predictions.
- **Promotion:** when the same rule has prevented a mistake twice across sessions, propose moving it into `references/pitfalls.md` with the user's approval.

---

## 🏛️ Pre-Populated Enterprise Incident Register (Production Lessons)

### 2026-08-15 | Intune Management Extension (IME) | Architecture Redirection
- **Mistake:** Script attempted to query 64-bit Registry keys under `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion` and returned empty/wrong values on 64-bit endpoints.
- **Cause:** Intune Management Extension agent runs as a 32-bit process (`C:\Program Files (x86)\Microsoft Intune Management Extension\`) by default, invoking 32-bit PowerShell (`SysWOW64`).
- **Fix:** Added 64-bit relauncher check at the top of script:
  ```powershell
  if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
      & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoProfile -File $PSCommandPath @args
      exit $LASTEXITCODE
  }
  ```
- **Rule:** Every Intune remediation touching 64-bit registry keys or system binaries MUST enforce 64-bit native PowerShell execution via `SysNative`.

### 2026-08-10 | WinRM Multi-Node Orchestration | Kerberos Double-Hop
- **Mistake:** Remote PowerShell session via `Invoke-Command` succeeded, but subsequent access to a network share (`\\fileserver\share`) failed with "Access Denied".
- **Cause:** Kerberos double-hop issue: user credentials passed to the first remote machine are not delegated to the secondary target network share.
- **Fix:** Used explicit session credentials with JEA (Just Enough Administration) or delegated Kerberos via CredSSP / Resource-Based Constrained Delegation (RBCD).
- **Rule:** Never attempt secondary network hops inside WinRM sessions without CredSSP or Kerberos constrained delegation.

### 2026-08-05 | Azure Automation Runbooks | Sandbox Memory Limit
- **Mistake:** Large tenant device export runbook crashed halfway through with `OutOfMemoryException`.
- **Cause:** Azure Automation cloud sandboxes enforce a strict 400 MB RAM limit and a 3-hour "Fair Share" execution limit.
- **Fix:** Replaced in-memory array accumulation (`$allDevices += $item`) with streaming batch ingestion and chunked pagination (`Invoke-GraphBatchRequest`).
- **Rule:** In cloud runbooks, stream data directly to storage or use chunked $batch processing to never exceed 400 MB memory.

### 2026-07-28 | Microsoft Graph API | Query Parameter Stripping in Pagination
- **Mistake:** Script passed custom query parameters (`$select`, `$filter`) to the pagination loop, but subsequent pages ignored them.
- **Cause:** The `@odata.nextLink` URI returned by Graph API already contains the complete URL with all filter parameters encoded; re-appending params corrupts the query.
- **Fix:** Used the canonical `Get-MgGraphAllPages.ps1` helper which takes the raw `@odata.nextLink` verbatim without modifying query parameters.
- **Rule:** Always follow `@odata.nextLink` verbatim without modifying query parameters or headers.

### 2026-07-19 | macOS Intune Scripting | Plist Caching & cfprefsd
- **Mistake:** Modified a `.plist` file using `defaults write`, but the application did not read the new setting until system reboot.
- **Cause:** macOS caches preferences in the `cfprefsd` daemon; raw file writes or background changes are not instantly flushed to the active application.
- **Fix:** Followed `defaults write` with `killall cfprefsd` and used `PlistBuddy` for nested dictionary configurations.
- **Rule:** In macOS management scripts, always flush preference caches with `killall cfprefsd` after executing `defaults write`.
### 2026-08-22 | DeviceInfoViewer GUI | Canonical Name Drift Under Long Context
- **Mistake:** A model built a WPF GUI using Segoe MDL2 font glyphs, invented style keys (`PrimaryButtonStyle`), invented brush tokens (`ColorBg`), an `Add-LogLine` rewrite without the `$script:lastLogKey` guard, `StatusText` instead of `StatusBarText`, and a README without badges or Disclaimer.
- **Cause:** Critical identifiers live in reference files read early in the session; by the time the 1,400-line XAML was written, the model wrote styles/tokens/icons from memory instead of copying them verbatim. ICON LAW named only "Segoe Fluent Icons", so the model rationalized MDL2 as a different thing.
- **Fix:** Added the Identity Lock section to SKILL.md (canonical names table + never-invent rule), banned ALL Segoe symbol fonts explicitly, added a pre-flight gate (re-open references immediately before writing), embedded the mandatory README badge/disclaimer skeleton, and shipped scripts/Test-ToolCompliance.ps1 which FAILs every drift pattern (validated: gold-standard tool passes, drifted tool reports 10 FAIL).
- **Rule:** Canonical identifiers are copied from reference files verbatim at write time - never reconstructed from memory; every delivered tool must pass Test-ToolCompliance.ps1 with zero FAIL before handoff.

## 2026-09-14 | All scripts | logging console style

- **Mistake:** Embedded `Write-Log` functions in all scripts printed `[$timestamp] [$Level] $Message` to the console, making output noisy and hard to read during interactive troubleshooting.
- **Cause:** The original canonical pattern reused the same formatted string for both console and log file, prioritizing fleet log richness over interactive UX.
- **Fix:** Split the formatting: `$fileLine` keeps `[$timestamp] [$Level] $Message` for the log file; the console receives `$Message` only with color conveying severity. The banner title now includes a live timestamp.
- **Rule:** Console output = clean message with color only; log file = timestamped and leveled. Never mix formats; never print structured prefixes to the console.
