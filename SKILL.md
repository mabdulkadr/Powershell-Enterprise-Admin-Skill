---
name: powershell-enterprise-admin
description: 'Build production-grade PowerShell tools with Tailwind Slate WPF GUI, Intune Proactive Remediation pairs, and Graph/Entra ID automation. Handles AD bulk ops, WinRM, CIM inventory, event logs, printer management, and macOS bash. Use for helpdesk tools, dashboards, DataGrid UIs, dark/light theme, compliance scripts, notification runbooks, CSV-driven AD, or professional READMEs - even when phrased casually like "make me a tool". Also use for auditing, refactoring, reviewing, or final compliance passes on an existing Intune/Intune-Scripts-style PowerShell library (re-run gates, fix broken headings, normalize emojis, validate templates). Skip for one-liners, non-PowerShell languages, or conceptual explanations. CRITICAL: when writing/editing files from this skill, ALL emoji and multi-byte content MUST be written via [System.IO.File]::WriteAllText(...,[System.Text.UTF8Encoding]::new($false)) and emoji MUST be constructed with [string][char]::ConvertFromUtf32(0xHHHH) - never pipe here-strings through Set-Content (the bash tool mangles multi-byte bytes and strips emojis).'
---

# PowerShell Enterprise Admin

Build production-grade PowerShell tools with modular architecture, Tailwind Slate design system, dark/light theme, async UI patterns, structured logging, and consistent patterns across every tool.

---

## Table of Contents

1. [Script Type Routing (Classify Before You Build)](#script-type-routing-classify-before-you-build)
2. [Canonical Conventions (One Table, No Exceptions)](#canonical-conventions-one-table-no-exceptions)
3. [Identity Lock](#identity-lock-names-you-copy-never-invent)
4. [The 12 Non-Negotiable Laws](#the-12-non-negotiable-laws)
5. [Enterprise Platform & Compatibility Matrix](#enterprise-platform-compatibility-matrix)
6. [The Right-Sized Architecture](#the-right-sized-architecture-choose-by-tool-size)
7. [The 21 Canonical Patterns](#the-21-canonical-patterns-memorize-these)
8. [The Design System — Tailwind Slate](#the-design-system-tailwind-slate)
9. [The 19 Required XAML Styles](#the-19-required-xaml-styles)
10. [The Log Levels (Exact Colors)](#the-log-levels-exact-colors)
11. [The HTML Design System — IBM Carbon Dark](#the-html-design-system-ibm-carbon-dark-canonical-for-all-html-output)
12. [The Required XAML Structure](#the-required-xaml-structure)
13. [CLI Progress](#cli-progress-write-progress-for-long-running-operations)
14. [Output Placement](#output-placement-reports-beside-the-script)
15. [Workflow: Building a New Tool](#workflow-building-a-new-tool)
16. [Verification Checklist](#verification-checklist-before-first-run)
17. [Writing Professional README.md Files](#writing-professional-readmemd-files)
18. [Hardcoded Rules From Lessons Learned](#hardcoded-rules-from-the-lessons-learned-register-read-before-writing)
19. [Lessons Learned Register](#lessons-learned-register)
20. [Reference Files](#reference-files-read-in-this-order)

---

## Script Type Routing — Classify Before You Build

Before writing any code, classify the user's request into one of three types. This determines which patterns, headers, and reference files to use.

### Decision Tree

```
What is the user asking for?
│
├── "Build me a GUI tool / dashboard / WPF app / helpdesk tool"
│   └── TYPE 1: WPF GUI Tool (Tier 1/2/3)
│       → Follow the 12 Laws, use XAML styles, Add-LogLine, Guard-Action
│       → Read: references/file-architecture.md, references/patterns.md
│
├── "Create a script for Intune / detection / remediation / compliance / Graph API / Entra ID"
│   │   OR mentions: Intune, detection script, remediation script, compliance,
│   │   Azure Automation, runbook, Managed Identity, Graph API, proactive remediation
│   └── TYPE 2: Intune/Graph Script (CLI)
│       → Use Intune header fields (.REMEDIATIONTYPE, .PAIRSCRIPT, .PLATFORM, .PERMISSIONS)
│       → Read: references/intune-patterns.md, references/notification-patterns.md
│       → Follow: Intune Best Practices section below
│
├── "Write a script for AD / event logs / remote management / bulk operations / printer"
│   │   OR mentions: Active Directory, WinRM, event log, CSV bulk, CIM query,
│   │   printer management, remote server, multi-machine
│   └── TYPE 3: General Enterprise CLI Script
│       → Use standard PowerShell header (references/script-template.md)
│       → Read the domain-specific reference:
│         AD → references/ad-patterns.md
│         Remote → references/winrm-patterns.md
│         Event logs → references/event-log-patterns.md
│         macOS → references/macos-patterns.md
│
└── "Write a README" / "Create documentation"
    └── TYPE 4: Documentation
        → Use the README template in Writing Professional README.md Files section
        → Read: references/readme-template.md
```

### How to Tell Type 2 (Intune) from Type 3 (General CLI)

| Signal | Type 2 (Intune) | Type 3 (General CLI) |
|--------|-----------------|---------------------|
| Mentions Intune, Entra ID, Azure AD | ✅ | ❌ |
| Mentions "detection" or "remediation" | ✅ | ❌ |
| Mentions "compliance" in device context | ✅ | ❌ |
| Mentions "Graph API", "Microsoft.Graph" | ✅ | ❌ (unless Graph is just a data source) |
| Mentions "Azure Automation", "runbook" | ✅ | ❌ |
| Mentions "Managed Identity" | ✅ | ❌ |
| Mentions Active Directory, WinRM | ❌ | ✅ |
| Mentions event logs, CIM/WMI | ❌ | ✅ |
| Mentions CSV bulk operations | ❌ | ✅ |
| Mentions macOS, bash | ❌ | ✅ |
| Mentions WPF, GUI, XAML, dashboard | ❌ | ❌ (Type 1) |
| Just says "PowerShell script" with no context | ❌ | ✅ (default to general) |

**When ambiguous, ask the user.** A script that uses Graph API to query Entra ID for a WPF dashboard is Type 1 (WPF tool) that happens to call Graph — not Type 2.

---

## Canonical Conventions (One Table, No Exceptions)

These conventions are unified across every reference file. When a reference contradicts this table, this table wins. If you find a contradiction, fix the reference, not the convention.

| Convention | Type 1 (WPF GUI) | Type 2 (Intune/Graph CLI) | Type 3 (General CLI) |
|------------|------------------|---------------------------|----------------------|
| **Header format** | Canonical rich header, ALL types identical (Enterprise standard): `.TITLE .SYNOPSIS .DESCRIPTION .TAGS` `[.REMEDIATIONTYPE .PAIRSCRIPT for pairs]` `.PLATFORM [.MINROLE] .PERMISSIONS .AUTHOR .VERSION .CHANGELOG .LASTUPDATE .EXAMPLE(s) .NOTES` with one blank line between fields — see `references/_header-canonical.md` | Same canonical rich header | Same canonical rich header |
| **File naming** | `[ToolName].ps1` | `detect-<name>.ps1` / `remediate-<name>.ps1` / `notify-<name>.ps1` | `[ToolName].ps1` |
| **Logging function** | `Add-LogLine` (`scripts/Add-LogLine.ps1`) | `Write-Log` + `Initialize-Log` + `Finish-Script` + `Write-Banner` + `Write-Summary` (`scripts/Write-Log.ps1`, `references/intune-patterns.md`) | `Write-Log` + `Write-Banner` + `Write-Summary` (`scripts/Write-Log.ps1`) |
| **Log path** | `%LOCALAPPDATA%\<ToolName>\Logs\` | `<SystemDrive>\IntuneLogs\<SolutionName>\` | `C:\ProgramData\<ToolName>\Logs\` |
| **Exit codes** | n/a (GUI) | Detection: 0=compliant / 1=non-compliant / 2=error. Remediation: 0=success / 1=failure / 2=error | 0=success / 1=failure |
| **`.PERMISSIONS` field** | n/a | Only real Graph scopes; `None (local SYSTEM context)` when the script doesn't call Graph | Only if the script calls Graph |
| **Busy guard** | `Guard-Action` / `Release-Action` (`scripts/Guard-Action.ps1`) | n/a | n/a |
| **Graph pagination** | In background jobs (Pattern B) | `Get-MgGraphAllPages` (`scripts/Get-MgGraphAllPages.ps1`) | Same, if Graph is used |
| **Graph auth** | Interactive (user context) | Per context — `scripts/Connect-GraphAuth.ps1` | Per context |

**Why this table exists:** five reference files previously shipped different log paths and function names for the same concept. Operators troubleshooting a fleet found logs in three different locations depending on which file the model had read. One table, one convention, one place to look. **Log-folder exclusivity:** `IntuneLogs` is reserved for Type 2 Intune scripts ONLY — Type 1 uses `%LOCALAPPDATA%`, Type 3 uses `C:\ProgramData`. A non-Intune script referencing `IntuneLogs` fails the compliance gate.

---

## Identity Lock — Names You Copy, Never Invent

Long-context models drift: they write a 1,400-line GUI and quietly mint `PrimaryButtonStyle`, `ColorBg`, or `StatusText` instead of the canonical identifiers. Those tools *run*, so the drift ships silently — until theme switching breaks, shared theming tooling misses, or a reviewer rejects the tool. Treat these names as a fixed API. If a name you are about to type is not in this table, stop and re-open the canonical reference instead of inventing an alias.

| Category | Canonical identifiers (exact spelling) |
|----------|----------------------------------------|
| **Brush tokens** | `BackgroundBrush` `SurfaceBrush` `SurfaceAltBrush`(see design-tokens) `BorderBrush` `TextPrimaryBrush` `TextSecondaryBrush` `TextMutedBrush` `TextBodyBrush` `AccentBrush` `AccentHoverBrush` `SuccessBrush` `WarningBrush` `DangerBrush` `SidebarBrush` — full set with light/dark values in `references/design-tokens.md`. Never write `ColorBg`, `ColorSurface`, `CardBg`, or any invented alias |
| **Style keys (GUI)** | The 19 keys under *The 19 Required XAML Styles* below: `BtnBase` `BtnPrimary` `BtnBlue` `BtnGreen` `BtnRed` `BtnPurple` `BtnGhost` `BtnOutline` `BottomActionBtn` `NavBtnBase` `Card` `StatCard` `FieldLabel` `InputBox` `InputBoxNoHover` `StyledCheckBox` `StyledComboBox` `LiveMessageCenterBox` `SessionCard`. Need a variant? Extend with `BasedOn="{StaticResource BtnPrimary}"` — never mint new key names like `PrimaryButtonStyle`, `SecondaryButtonStyle`, `IconButtonStyle`, `CardBorderStyle` |
| **StatusBar controls** | `StatusDot` \| `StatusLabel` \| `StatusBarText` \| `StatusTime` — never `StatusText`, `StatusMessage`, `ClockText` |
| **Header controls** | `ConnectionDot` + `ConnectionLabel` + `ThemeToggleBtn` on every tool; add `TryModeBtn` / `SignInBtn` only when that feature actually exists (omit otherwise — no placeholders) |
| **GUI logging internals** | Copy `scripts/Add-LogLine.ps1` VERBATIM into the tool — including `$script:lastLogKey` duplicate guard, status-bar update, UTF8 file write, and console colors. Rewriting it from memory drops the duplicate guard and floods logs |
| **CLI logging internals** | Copy `scripts/Write-Log.ps1` verbatim (`Initialize-Log` / `Write-Banner` / `Write-Log` / `Write-Summary` / `Finish-Script`) |

**Enforcement:** before delivering ANY tool, run `scripts/Test-ToolCompliance.ps1 -ToolPath <file.ps1>` and fix every FAIL it reports. The script greps for exactly the drift patterns above (symbol fonts, invented style keys, missing token names, missing guards). A tool that passes manual review but fails this script is not done.

---

## The 12 Non-Negotiable Laws

**Violating any law = the tool is rejected. No exceptions.**

| # | Law | Why it matters |
|---|-----|----------------|
| 1 | **HEADER LAW** — Every `.ps1` opens with the canonical rich header FIRST, identical field order for all types: `.TITLE .SYNOPSIS .DESCRIPTION .TAGS [.REMEDIATIONTYPE .PAIRSCRIPT] .PLATFORM [.MINROLE] .PERMISSIONS .AUTHOR .VERSION .CHANGELOG .LASTUPDATE .EXAMPLE(s) .NOTES`, one blank line between field blocks (template: `references/_header-canonical.md`), followed by `#Requires -Version 5.1`. Never write `#Requires -RunAsAdministrator` — detect elevation at runtime with `Test-IsElevated` and degrade gracefully | The header is the API contract. Without it, `Get-Help` returns nothing and reviewers cannot understand the tool. A hard elevation requirement kills partial-work runs and blocks unelevated logging. |
| 2 | **NAMING LAW** — Functions = `Verb-Noun` PascalCase. Local variables = `camelCase` (`$computerName`, `$logDir`). Script-shared variables = `$script:PascalCase` (`$script:IsBusy`, `$script:LogFile`) — prefix + PascalCase. UI controls = prefix (`$btnSubmit`, `$txtInput`, `$dgvResults`) | Consistent naming means every tool reads the same. The next person can find what they need without searching. |
| 3 | **NO ALIASES LAW** — Never use `gci`, `?`, `%`, `select`, `ft`, `where` in saved scripts. Full cmdlet names only | Aliases hide intent and confuse grep. A junior reading `gci | ?` has to translate to `Get-ChildItem | Where-Object` mentally. |
| 4 | **ERROR LAW** — `$ErrorActionPreference = 'Stop'` at entry point. Specific `catch` types. Never empty `catch {}`. Use `try/catch/finally` for cleanup | Production errors must surface with the actual exception type, not get swallowed silently. The user (helpdesk) must see *why* it failed. |
| 5 | **COLOR LAW** — All bg/surface/text/border colors use `{DynamicResource TokenName}`. Semantic colors (`#3B82F6`, `#10B981`, `#EF4444`, `#F59E0B`) may be hardcoded in XAML. Background tints MUST use `DynamicResource` | The only way dark/light theme toggle works without rebuilding the UI. If a color is hardcoded, dark mode breaks that control. |
| 6 | **ICON LAW** — Every icon is an SVG `<Path Data="..."/>` element with `Stretch="Uniform"`. ZERO icon/symbol fonts of any kind: Segoe Fluent Icons, **Segoe MDL2 Assets** (`FontFamily="Segoe MDL2 Assets"`), and Segoe UI Symbol are ALL forbidden. Copy path data verbatim from `references/icons.md`; never synthesize glyph escapes like `&#xE7F4;` or `[char]0xE701` | Symbol fonts look like a shortcut but fail on Windows Server (Fluent is not installed), render as empty boxes on locked-down builds, and cannot recolor with theme brushes the way `Path.Fill="{DynamicResource AccentBrush}"` does. Models rationalize "MDL2 is not Fluent" — this law bans both. Compliance grep: `Segoe\s*(MDL2|Fluent|UI Symbol)` must return 0 hits in every delivered tool. |
| 7 | **SIDEBAR LAW** — Sidebar = Logo + Nav buttons + Version footer ONLY. System controls (Sign In, Theme toggle, Try Mode) belong in the **Header toolbar** top-right | The sidebar is for navigation. Mixing system controls with nav breaks the user's mental model and creates inconsistent layouts across tools. |
| 8 | **THREAD LAW** — NEVER block the WPF dispatcher. Long ops use `[powershell]::BeginInvoke()` + `DispatcherTimer` (350ms poll). Data load uses `Start-Job` + `DispatcherTimer` (300ms poll) | A blocked UI thread = frozen window. The user thinks the tool crashed. They click again. Now you have a second operation racing the first. |
| 9 | **AMPERSAND LAW** — Every `&` in XAML text/attributes MUST be `&amp;`. Unescaped `&` causes `XamlParseException` | This is a silent crash at ShowDialog. The XAML parses but the renderer fails. Test with `XamlReader.Parse()` to catch it before runtime. |
| 10 | **STATICRESOURCE LAW** — Every `{StaticResource X}` MUST have a matching `<Style x:Key="X">` in `Window.Resources`. Missing key = crash at `ShowDialog()` | Same silent crash as Law 9. The parse succeeds, the runtime fails. Use `DynamicResource` when the key may not exist at compile time. |
| 11 | **LANGUAGE & BRANDING LAW** — All generated scripts, comments, headers, log messages, and README.md must be **English only**. Never emit Arabic, mixed-language, or external branding (e.g., `Enterprise patterns.com`) in code or docs. `.AUTHOR` resolves at build time: `git config user.name` when discoverable, otherwise the literal `AI Generated`; use internal references (`references/_header-canonical.md`) | Enterprise scripts run on English OS locales, Intune, and Git; non-ASCII breaks parsers, grep, and CI. External branding leaks training examples and confuses ownership. |
| 12 | **REPORT PATH LAW** — Default `OutputPath`/`Reports` must be **beside the original script**, never `".\Reports"` or `Get-Location` alone. Use `$PSScriptRoot` with dot-source fallback: `$scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }; Join-Path $scriptBase "Reports"` and normalize with `if (-not $PSBoundParameters.ContainsKey('OutputPath')) { $OutputPath = Join-Path $scriptBase "Reports" }` | `. 'path\to\script.ps1'` leaves `$PSScriptRoot=''` → `Join-Path '' 'Reports'` crashes with `ParameterBindingValidationException`. Beside-script guarantees the report is found where the operator expects it, regardless of caller's `cd`. |

---

## Enterprise Platform & Compatibility Matrix

Every script and tool built with this skill is tested against the following enterprise compatibility matrix:

| Operating System | PowerShell Version | WPF GUI (Type 1) | Intune Remediation (Type 2) | Enterprise CLI (Type 3) | Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Windows 11 (22H2–24H2)** | 5.1 / 7.4+ | ✅ Full Support | ✅ Full Support | ✅ Full Support | Modern WinRT toasts & native STA WPF. |
| **Windows 10 (21H2–22H2)** | 5.1 / 7.4+ | ✅ Full Support | ✅ Full Support | ✅ Full Support | Standard enterprise client base. |
| **Windows Server 2025/2022** | 5.1 / 7.4+ | ✅ Full Support | ⚠️ Hybrid Azure Arc | ✅ Full Support | Server Desktop Experience required for WPF. |
| **Windows Server 2019/2016** | 5.1 | ✅ Full Support | ⚠️ Hybrid Azure Arc | ✅ Full Support | Uses SVG paths; no Segoe Fluent dependency. |
| **macOS (Sonoma / Sequoia)** | Bash 3.2+ / zsh | ❌ n/a | ✅ Via Intune macOS | ✅ macOS Shell | Follows `references/macos-patterns.md`. |
| **Azure Automation Cloud** | 5.1 / 7.2 | ❌ Headless | ✅ Runbooks | ✅ Hybrid Worker | Strict 400MB RAM / 3hr runtime limits. |

---

## The Right-Sized Architecture (Choose by Tool Size)

Pick the smallest structure that fits. Most admin tools are **single-file** — the modular layout is for the framework itself, not for the tools it produces.

| Tier | When | Files |
|------|------|-------|
| **1. Single-file** | Default — most admin tools | 4-5 files, everything in 1 `.ps1` |
| **2. Split XAML** | Long XAML (>500 lines) or repeated dialogs | 6-7 files, XAML in `.xaml` |
| **3. Modular** | Complex GUI (5+ features, settings, drag-drop) OR frameworks | 15-25 files, embedded XAML + `src/` + `config/` |

**Hybrid rule:** Tier 1 for simple single-workflow tools, **Tier 3 Enterprise patterns-style for complex GUI** even with one audience. Enterprise patterns () is the canonical GUI reference — embedded GZip+Base64 XAML, P/Invoke console-hide, `src/` modular, `%APPDATA%` settings. See `references/file-architecture.md` (Tier 3 Enterprise patterns).

**The 80% rule:** Use Tier 1 for 80% of simple tools. Complex GUI → Tier 3.

**Anti-patterns:** Modular structure for a 500-line tool (overhead). Single-file for a 5000-line tool (editor pain). Splitting "for future-proofing" (YAGNI). Empty `tests/`, `scripts/`, `docs/` folders.

For the folder trees, the full decision guide, and the complete Tier 1 bootstrap (single-file structure with all required pieces), see `references/file-architecture.md`.

---

## The 21 Canonical Patterns (Memorize These)

Every tool needs the same primitives. Read the pattern reference for the exact implementation; Pattern H's code is canonical in `scripts/Guard-Action.ps1`:

| Pattern | When | File |
|---------|------|------|
| **A. Theme Toggle** | Always — sun/moon icon swap | `references/patterns.md` |
| **B. Background Data Load** | CIM/WMI queries, Graph API calls | `references/patterns.md` |
| **C. Async Runspace** | Long .NET ops, in-process assemblies | `references/patterns.md` |
| **D. Inline XAML Dialog** | Modal forms that don't need their own XAML file | `references/patterns.md` |
| **E. LogViewer Theme Copy** | Always — child windows must inherit theme | `references/patterns.md` |
| **F. Window-Level Drag & Drop** | File path inputs | `references/patterns.md` |
| **G. Select All / Deselect All DataGrid** | Bulk operations on row-checked grids | `references/patterns.md` |
| **H. Guard-Action / Release-Action** | **EVERY interactive button** | `scripts/Guard-Action.ps1` (canonical) |
| **I. Set-UIState Busy/Idle** | Disable buttons + show progress bar | `references/patterns.md` |
| **J. Update-UIState Central Refresh** | TextChanged events, post-action state | `references/patterns.md` |
| **K. Clock Timer** | StatusBar always shows current time | `references/patterns.md` |
| **L. Show-ToastMessage** | Replace MessageBox for non-blocking notifications (In-App) | `references/patterns.md` |
| **M. About Dialog Markdown Rendering** | `docs/*.md` → WPF elements | `references/patterns.md` |
| **N. Live Column Filtering** | Filter boxes over DataGrid columns | `references/patterns.md` |
| **O. Shift-Click Range Selection** | Fast multi-row checkbox selection | `references/patterns.md` |
| **P. Multi-Input Query Parsing** | Comma/newline search box parsing | `references/patterns.md` |
| **Q. Settings Persistence** | Safe `%LocalAppData%` JSON config | `references/patterns.md` |
| **R. Async External Process Wrapper** | Non-blocking CLI tool wrapper with polling | `references/patterns.md` |
| **S. Live Message Center Console** | Color-coded in-app RichTextBox log terminal | `references/patterns.md` |
| **T. Native Windows Toast** | Action Center notifications via WinRT XML without extra modules | `references/patterns.md` |
| **U. Responsive HTML Executive Report (Carbon Dark)** | Self-contained executive HTML dashboard with instant search; IBM Carbon Design System dark theme is the **only** approved design system for HTML output | `templates/EnterpriseHtmlReport.template.ps1` (canonical helpers: `Get-StandardHtmlHead/Open/Footer/Close/ChartScripts` + `Export-StandardHtmlReport`) |

---

## The Design System — Tailwind Slate

Every color, every spacing value, every font size is defined as a **token**. The design system lives in `Window.Resources` and gets overridden by `Set-Theme`.

Core tokens (11 shown) + full set in `references/design-tokens.md`:

| Token | Light → Dark | Use |
|-------|--------------|-----|
| `BackgroundBrush` | `#F1F5F9` → `#1E293B` | Window background |
| `SurfaceBrush` | `#FFFFFF` → `#334155` | Cards, inputs |
| `AccentBrush` | `#3B82F6` → `#60A5FA` | Primary accent |
| `TextPrimaryBrush` | `#0F172A` → `#FFFFFF` | Headings |
| `BorderBrush` | `#E2E8F0` → `#475569` | Borders |

Spacing: `Card Padding=18`, `Card CornerRadius=14`, `Button CornerRadius=8`, `Button Height=38/34`. Typography: Segoe UI Variable, 11–28pt. Full dark-mode overrides, spacing, and typography in `references/design-tokens.md` (canonical). Also see `references/_header-canonical.md` for file structure.

---

## The 19 Required XAML Styles

Every `MainWindow.xaml` MUST define these styles in `Window.Resources`. They are the visual identity of every tool — change them and you've broken the design language.

| Style | Target | Purpose |
|-------|--------|---------|
| `BtnBase` | Button | Root button: 38px, 8px corner, hover opacity |
| `BtnPrimary` | Button | Primary CTA — `BtnPrimaryBg` fill, White text |
| `BtnBlue` | Button | Subtle blue — `BtnBlueBg` |
| `BtnGreen` | Button | Success — `BtnGreenBg` |
| `BtnRed` | Button | Danger — `BtnRedBg` |
| `BtnPurple` | Button | About tab selector — `BtnPurpleBg` |
| `BtnGhost` | Button | Transparent, hover tint only |
| `BtnOutline` | Button | Transparent fill, 1px border, hover surface |
| `BottomActionBtn` | Button | 34px, sidebar footer (About/Logs) |
| `NavBtnBase` | Button | 46px, 10px corner, left-aligned nav |
| `Card` | Border | Surface bg, 12px corner, drop shadow |
| `StatCard` | Border | Like Card but with hover-border highlight |
| `FieldLabel` | TextBlock | 12-14px SemiBold, secondary text |
| `InputBox` | TextBox | 34px, focus border AccentBrush, NO IsMouseOver |
| `InputBoxNoHover` | TextBox | Like InputBox but no border change on hover |
| `StyledCheckBox` | CheckBox | Modern CheckBox with SemiBold text and hand cursor |
| `StyledComboBox` | ComboBox | 34px height, surface background, theme border |
| `LiveMessageCenterBox` | RichTextBox | 140px, dark terminal background (`#1E293B`) for streaming logs |
| `SessionCard` | Border | Sidebar session details card with elevation pill |

**Critical:** Cards are STATIC. No `IsMouseOver` triggers — only `<Button>` elements get hover via their ControlTemplate, plus ONE sanctioned exception: `StatCard` KPI tiles use a border-highlight hover trigger. Read `references/xaml-styles.md` for the complete XAML for every style.

---

## The Log Levels (Exact Colors)

| Level | Color | Console (clean) | File |
|-------|-------|---------------|------|
| `DEBUG` | `#94A3B8` | `Message` in DarkGray | `[yyyy-MM-dd HH:mm:ss] [DEBUG] Message` |
| `INFO` | `#3B82F6` | `Message` in Cyan | `[yyyy-MM-dd HH:mm:ss] [INFO] Message` |
| `SUCCESS` | `#10B981` | `Message` in Green | `[yyyy-MM-dd HH:mm:ss] [SUCCESS] Message` |
| `WARNING` | `#F59E0B` | `Message` in Yellow | `[yyyy-MM-dd HH:mm:ss] [WARNING] Message` |
| `ERROR` | `#EF4444` | `Message` in Red | `[yyyy-MM-dd HH:mm:ss] [ERROR] Message` |

Console = **clean**: `Write-Log` / `Add-LogLine` print only `Message` in level color (no `[timestamp] [LEVEL]` prefix). File = detailed `[$timestamp] [$Level] $Message`. GUI uses `Add-LogLine` (duplicate guard + status bar); CLI uses `Write-Log`. Levels, `Write-Summary`, and the empty-message spacer rule live in `references/_logging-canonical.md` (canonical) - read it before writing any logging call.

---

## The HTML Design System — IBM Carbon Dark (Canonical for All HTML Output)

**Every HTML report produced by any tool in this skill MUST use the IBM Carbon Design System (Dark theme).** WPF GUI tools use Tailwind Slate (see above); HTML output uses Carbon Dark. Two surfaces, two design systems, no overlap.

Canonical toolkit: **`templates/EnterpriseHtmlReport.template.ps1`** - five reserved helpers (`Get-StandardHtmlHead/Open/Footer/Close/ChartScripts`) plus the `Export-StandardHtmlReport` convenience wrapper; copy VERBATIM, never invent a parallel helper. Tokens (`--cds-*`), sanctioned body classes, migration rule, and the fidelity audit protocol (triage table, PASS=3-4 / WEAK=1-2 / FAIL=0, three-gate verification per Hardcoded Rule 28) all live in `references/html-reports.md` - read it before emitting any HTML.

---

## The Required XAML Structure

Every MainWindow follows this layout exactly:

```
Window (WindowStyle="SingleBorderWindow", ResizeMode="CanResizeWithGrip")
└── Grid (3 rows: Auto / * / Auto)
    ├── Row 0: Header (DockPanel)
    │   └── Right side: ConnectionDot + ConnectionLabel + ThemeToggle + TryModeBtn + SignInBtn
    ├── Row 1: Grid (2 cols: Auto Sidebar | * Content)
    │   ├── Col 0: Sidebar (DockPanel)
    │   │   ├── Top: Logo + AppName + Tagline
    │   │   ├── Mid: Nav buttons (NavBtnBase style)
    │   │   └── Bottom: AboutBtn + LogsBtn (BottomActionBtn) + version
    │   └── Col 1: Content area
    │       └── Pages (Visibility toggled by Set-ActivePage)
    └── Row 2: StatusBar
        └── Grid (4 cols): StatusDot | StatusLabel | StatusBarText | StatusTime
```

**Why this exact structure:**

- Header toolbar top-right = consistent "system controls" location across all tools
- Sidebar bottom = consistent "About + Logs" footer
- StatusBar bottom = always-visible status, time, and progress
- Pages pattern = multi-feature tools without navigation tabs cluttering the chrome

---

## CLI Progress — `Write-Progress` for Long-Running Operations

Every CLI script that loops over more than ~25 items, paginates Graph results, or performs batched remote operations MUST emit `Write-Progress` so the operator sees real status in the console.

One `Activity` label per logical phase; always close with `-Completed` in a `finally` block; guard divide-by-zero with `[Math]::Max($total, 1)`. `Write-Progress` is the console bar, `Write-Log -Level DEBUG` is the file record - pair them, never replace one with the other. Full when-to-use table and the verbatim pattern live in `references/cli-progress.md`.

---

## Output Placement — Reports Beside the Script

Every script that produces output files (HTML, CSV, JSON, MD, ZIP) MUST place them in a folder beside the script:

- **Reports** (HTML/CSV/JSON/MD): `<script-folder>\Reports\`
- **Logs**: `<script-folder>\Logs\` **only** when the script actually emits logs (most CLI scripts do — WPF GUI scripts use `%LOCALAPPDATA%\<Tool>\Logs\` instead)

The reason: dot-sourcing a script (`'. .\script.ps1'`) leaves `$PSScriptRoot=''` and `Join-Path '' 'Reports'` crashes with `ParameterBindingValidationException`. Anchoring beside the script guarantees the report lands where the operator expects it, regardless of the caller's working directory.

### Canonical Pattern (Law 12)

```powershell
$scriptDirectory = if ($PSScriptRoot) { $PSScriptRoot }
elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath }
elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path }
else { (Get-Location).Path }

# If user passed a relative OutputPath, anchor it beside the script
if ($PSBoundParameters.ContainsKey('OutputPath') -and $OutputPath -and
    -not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $scriptDirectory $OutputPath
}

# If user passed no OutputPath, default to <script>\Reports\
if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
    $OutputPath = Join-Path $scriptDirectory 'Reports'
}

# Always create the folder if missing (never let Export-Csv fail on a missing dir)
if (-not (Test-Path -LiteralPath $OutputPath)) {
    $null = [System.IO.Directory]::CreateDirectory($OutputPath)
}
```

### Don't Create `Logs\` Unless You Log

If the script uses `Initialize-Log`, that helper creates its own folder (currently `%ProgramData%\<Tool>\Logs\` for the General type and `<SystemDrive>\IntuneLogs\<Tool>\` for the Intune type). Do **not** add an extra `Logs\` folder beside the script just for symmetry — let the logging helper own that decision. Only add a beside-script `Logs\` when the script writes plain-text log files outside of `Initialize-Log`.

Reporting/inventory scripts (TAGS `Reporting`/`Inventory`/`Compliance`/`Health`/`Audit`, or `Export-*`/`Get-*` names) MUST export BOTH `Reports\<ScriptName>_yyyyMMdd_HHmmss.csv` (raw) and `.html` (Carbon dashboard, shared timestamp) plus print both paths in the tailored display. Full dual-export pattern, display snippet, and single-format WARN rule live in `references/file-architecture.md` (Output Placement).

---

## Workflow: Building a New Tool

### Template Library — Copy First, Customize Second (TEMPLATE LOCK)

Every deliverable starts from a copy-paste-ready scaffold in `templates/` — never from an empty file:

| Deliverable | Copy |
|-------------|------|
| Type 2 detection / remediation | `templates/intune-detect.template.ps1` / `templates/intune-remediate.template.ps1` |
| Type 2 notification runbook | `templates/intune-notification.template.ps1` |
| Type 3 general CLI tool | `templates/cli-tool.template.ps1` |
| Type 1 WPF GUI tool (Tier 1) | `templates/wpf-gui-tool.template.ps1` (all 19 styles included) |
| macOS bash script | `templates/macos-script.template.sh` |
| READMEs (4 variants) | `templates/readme-*.template.md` |

**LOCK rules:** keep the skeleton (header order, logging block, exit paths, guards,
lifecycle) intact — extend it, never rewrite it; customize only `[Placeholders]` and
`TODO:` regions; every generated `.ps1` must pass `scripts/Test-ToolCompliance.ps1`
(the templates themselves pass it — staying close to the template IS compliance).
Full guide: `templates/README.md`.

### Tier 1 (Single-File - Most Tools)

0. **Pre-flight:** re-open `references/xaml-styles.md`, `references/design-tokens.md`, `references/icons.md` (GUI) or the domain CLI reference *immediately before writing code* - copy verbatim, never from memory.
0b. **Copy the template:** `templates/wpf-gui-tool.template.ps1` (19 styles, Add-LogLine, guards, lifecycle included) - fill `[Placeholders]` and `TODO:` only.
1. Header (canonical order) + `#Requires -Version 5.1` + `[CmdletBinding()]` + `$ErrorActionPreference = 'Stop'` + STA check.
2. Blocks in order: `Add-LogLine`, WPF assemblies, XAML (tokens + 19 styles), loader, `Guard-Action`/`Release-Action`, control bindings, guarded handlers, `ShowDialog()`.
3. `XamlReader.Parse()` test, then the verification checklist (`references/verification.md`).

### Tier 2 (Split XAML)

Same as Tier 1, but replace the XAML here-string with `$xaml = Get-Content 'MainWindow.xaml' -Raw`.

### Tier 3 (Modular)

See `references/file-architecture.md` for the full structure.

### CLI Scripts (No GUI)

Before writing, classify the script using the **Script Type Routing** decision tree above.

> **⚡ Fast Track:** Read `<skill>/lessons-learned.md` + matching template in `templates/`. Self-contained templates embed headers, logging, and elevation guards. Resolve `.AUTHOR` via `git config user.name` (or `AI Generated`). Verify with `scripts/Test-Delivery.ps1 -ScriptPath <tool.ps1> -ReadmePath <README.md> -SmokeTest`.

**Inline Documentation Standard:** One short line under each `# ====` section banner; one imperative one-liner above every function (`# Sets/removes DisabledComponents under ShouldProcess; idempotent result object.`); `# why` comments for non-obvious registry/WhatIf mechanics; English only (Law 11). macOS/bash `.sh` follows identical rules.

1. **Scaffold first:** `templates/cli-tool.template.ps1` (Type 3 CLI), `templates/intune-detect.template.ps1` + `templates/intune-remediate.template.ps1` (Type 2 pair), or `templates/intune-notification.template.ps1` (runbook). Header standard: `references/script-template.md`.
2. **Domain references:** AD → `references/ad-patterns.md` | WinRM → `references/winrm-patterns.md` | Event Logs → `references/event-log-patterns.md` | macOS → `references/macos-patterns.md`.
3. Use `Write-Log` (in `scripts/Write-Log.ps1`) for console output.
4. Intune headers (`.REMEDIATIONTYPE`, `.PAIRSCRIPT`) are strictly for Intune scripts. Standard CLI scripts use the canonical rich header without pair fields.

### Intune Best Practices

**Only apply these patterns when the script is Type 2 (Intune/Graph).** General CLI scripts (Type 3) do NOT use these patterns — they use standard PowerShell headers and logging.

The complete production-tested pattern set lives in `references/intune-patterns.md` (headers, module checks, Graph pagination/retry, remediation pairs, always-run detection, config-driven execution, remote diagnostics) and `references/notification-patterns.md` (scheduled email alerts). Read the relevant file before writing a Type 2 script — this section only lists the rules that must never be violated:

- **Exit codes are canonical:** Detection = `0` compliant / `1` non-compliant / `2` script error. Remediation = `0` success / `1` failure / `2` script error. Never use `1` for a script error — Intune would treat a crashed detection as non-compliant and run remediation needlessly.
- **Module checks first:** Validate `Microsoft.Graph.Authentication` (and any other modules) exist before importing — never fail halfway through execution.
- **Pagination is never manual:** Use the canonical `Get-MgGraphAllPages` (in `scripts/Get-MgGraphAllPages.ps1`) for any Graph API call that can return more than one page. Wrap retryable calls in `Invoke-MgGraphRequestWithRetry` for 429/503.
- **Auth matches context:** Managed Identity in Azure Automation, interactive (or MgGraphCommunity for RDP/CI-CD) locally, Client Credentials (App Registration) for unattended service contexts. See `scripts/Connect-GraphAuth.ps1`.
- **Remediation scripts are paired** (detection + action), idempotent, and verify the fix after applying it (pre-check → action → post-verify with JSON output).
- **Log to `<SystemDrive>\IntuneLogs\<SolutionName>\`** with `Initialize-Log` + `Write-Log` (canonical in `scripts/Write-Log.ps1`); use `Finish-Script` for every exit point.
- **`.PERMISSIONS` reflects what the script actually calls.** A script that runs locally in SYSTEM context (`ipconfig /flushdns`, service restarts, disk cleanup) needs **no Graph permission** — declare `None (local SYSTEM context)` instead of inventing Graph scopes. Only scripts that call Graph API list real permissions.
- **Notification scripts** (`.EXECUTION RunbookOnly`, `.OUTPUT Email`) run as Azure Automation runbooks with Managed Identity, send HTML email via Graph Mail API with `saveToSentItems = $false` — see `references/notification-patterns.md`.

---

## Verification Checklist (Before First Run)

Full checklist lives in `references/verification.md` - run it before the first launch:

- XAML parses (`XamlReader.Parse()` + `XmlNodeReader`/`Load`); every `{StaticResource}` has a key; every `&` is `&amp;`; no custom ScrollBar template.
- Every `x:Name` is bound; every button has handler + `ToolTip` + SVG icon (never symbol fonts).
- Theme: `{DynamicResource}` everywhere; no `IsMouseOver` on cards/inputs (buttons only, plus `StatCard`).
- Behavior: STA restart, `$ErrorActionPreference = 'Stop'`, `Guard-Action` + `finally Release-Action`, async long ops, job cleanup, inline-docs standard.
- Automated: `Test-ToolCompliance.ps1` zero FAIL, 5.1 smoke test (`Test-Delivery.ps1 -SmokeTest`), README fidelity FAITHFUL.

For the **full PS 5.1 pitfalls list** (Thumb.CornerRadius, Join-Path, Pester 3.4, ampersand crashes, etc.), see `references/pitfalls.md`.

---

## Writing Professional README.md Files

Pick the variant matching script type from `references/readme-template.md` (Basic, Intune Remediation, WPF GUI, CLI Script), paste it as the skeleton, replace `[Placeholders]` - never write from scratch. Mandatory order: Badges, Overview, Features, Structure, Scripts, Requirements, Intune Deployment (pairs only), Typical Workflow (pairs only), Operational Notes, Disclaimer, License, Author. Non-negotiables: 5+ `for-the-badge` badges in a centered hero, quick-nav row, verbatim Disclaimer, signature footer. Section matrix and examples live in the template file.

```markdown
## Disclaimer

This skill and every script it generates are provided as-is with no warranty of any kind. Test generated tools in a staging environment before deploying to production. The authors assume no liability for any damage or data loss resulting from their use.
```

Full templates and section examples → `references/readme-template.md` (canonical).

---

## Hardcoded Rules From The Lessons Learned Register (READ BEFORE WRITING)

These 28 non-negotiable rules are extracted from `lessons-learned.md` because they represent recurring real-world failure modes.

### A. File I/O & Character Encoding
1. **Never pipe here-strings with emojis to `Set-Content` in `bash` / `pwsh`** — Use `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))` for UTF-8 without BOM.
2. **Construct emojis via `[string][char]::ConvertFromUtf32(0xHHHH)`** (e.g. `✨=0x2728`, `📂=0x1F4C2`, `🛡=0x1F6E1`, `📜=0x1F4DC`, `⚠=0x26A0`, `🚀=0x1F680`). Never use raw multiline emoji regex in CLI.
3. **Decode file bytes via `[System.Text.Encoding]::UTF8.GetString($bytes)`** when non-ASCII contents are inspected.

### B. Module Placement & Self-Containment
4. **Individually deployed scripts MUST be self-contained** — Inline canonical logging helpers (`Initialize-Log`, `Write-Banner`, `Write-Log`, `Write-Summary`, `Finish-Script`) verbatim after the header; do not rely on relative dot-sourcing across machines.
5. **Auditing sequence:** (1) AST Parser → (2) `Test-ToolCompliance.ps1` → (3) `Test-ReadmeFidelity.ps1` → (4) AST Re-verify. The canonical gate is the single source of truth.

### C. Template & README Structure
6. **Intune pair README heading levels are hierarchical:** Top-level sections (Overview, Core Features, Project Structure, Scripts Included, Requirements, Intune Deployment, Typical Workflow, Operational Notes) = H1; Subsections (Detection Script, Remediation Script, Author, License, Disclaimer) = H2.
7. **Discovery & macOS scripts still require `## Remediation Script` (marked N/A with prose explanation)** and exit codes `0 = Discovery completed` + `2 = Script error`.
8. **Canonical Header sequence is non-negotiable:** `TITLE → SYNOPSIS → DESCRIPTION → TAGS → [REMEDIATIONTYPE → PAIRSCRIPT] → PLATFORM → [MINROLE] → PERMISSIONS → AUTHOR → VERSION → CHANGELOG → LASTUPDATE → [PARAMETER] → EXAMPLE → NOTES`.

### D. Logging, Safety & Error Handling (Log Law & Law 4)
9. **`Write-Log` / `Add-LogLine` Message parameter MUST declare `[AllowEmptyString()]` and default `""`** with `if ([string]::IsNullOrEmpty($Message)) { return }` spacer guard.
10. **Zero-tolerance for empty `catch {}`** — Log errors at DEBUG or handle explicitly; never swallow unexpected exceptions silently.
11. **Header fields must start with `.` followed by uppercase letters without `$` prefix** — Avoid silent `Get-Help` dropping.

### E. Design System & Report Paths (Laws 6, 11, 12)
12. **Icon Law:** SVG `<Path Data="..."/>` only (`Stretch="Uniform"`). Zero Segoe MDL2 Assets, Fluent Icons, or symbol fonts anywhere in code or comments.
13. **Report Path Law (Law 12):** Default `OutputPath` parameter MUST be empty string `""` (never `"."`), resolving beside the script via `$scriptDirectory` fallback with `Join-Path $scriptDirectory 'Reports'`.
14. **Output capture from child scripts:** Use `*>&1` (not `2>&1`) to capture Information stream 6 (`Write-Host`) and check `$LASTEXITCODE` before piping.
15. **Author & Branding:** Author block = `**Mohammad Abdelkader Omar**`, GitHub `@mabdulkadr`, `momar.tech`. No external fictitious brands.

### F. Build & Session Discipline
16. **Canonical gate authority:** `Test-ToolCompliance.ps1` PASS = 0 FAIL. WARN lines are advisory.
17. **Commit after each fix pass:** (1) `feat:`, (2) `fix:`, (3) `chore: 100% COMPLIANT`.
18. **No external helper scripts (No Python):** Analyze and edit code directly in conversation using native tools (`read`, `edit`, `pwsh`, `grep`).
19. **Rich deliverables:** Every script needs comprehensive `.DESCRIPTION`, `.EXAMPLE`, and `.NOTES`. Every README needs 5+ badges and standard hero.
20. **Honor tool bans for entire task:** When the user bans Python/helpers, the ban is absolute for all subsequent turns.
21. **No summary loops:** When user sends "Stop/Continue/ok", respond with 1 action or question — never re-summarize entire conversation context.
22. **Confirm scope mismatches upfront:** Verify script inventories before bulk modifications.
23. **Template function name alignment:** Verify helper names in prose match canonical templates (e.g. Export-StandardHtmlReport is correct, the CarbonHtml variant does not exist).

### G. HTML Report Fidelity
24. **HtmlEncode every dynamic cell:** All dynamic values in HTML tables MUST go through `[System.Net.WebUtility]::HtmlEncode`. Wrap paths/identifiers in `<code>` after encoding. No exceptions.
25. **KPI tiles must be domain-specific:** If a KPI label could appear identically in 5 unrelated scripts, it is too generic. `OK/Failed` counters only fit pass/fail scripts (Test-SecureBoot, STIG).
26. **Try-scope data survival:** When HTML export consumes `$rows` from a prior try-block, always add defensive re-collection: `if (-not $rows) { $rows = <fresh-query> }`. Never trust cross-try variable survival.
27. **Nested `$_` capture:** Before any nested `ForEach-Object` or `Where-Object` inside an outer `ForEach-Object`, capture `$rowRef = $_` and use `$rowRef.Property` inside the inner block.
28. **Three-gate HTML verification:** After any HTML fix: (1) `[Parser]::ParseFile` = 0 errors, (2) script runs and produces HTML file, (3) count rows/cells/badges before vs after. Parser alone is not proof of data fidelity.

---

## Lessons Learned Register

This skill learns from its own mistakes. The **Lessons Learned Register** lives INSIDE the skill at `<skill-dir>/lessons-learned.md` — it is global and applies to every script, tool, and project the skill touches. Do not create project-local copies; one shared register means a lesson learned in one project protects every future build.

**Before building:** read the register from the skill directory. If a listed lesson applies to the current task, follow its rule.

**Append an entry immediately** when: the user corrected your output; a script crashed at runtime; you hit a pitfall missing from `references/pitfalls.md`; you found a new environment constraint. Format + worked example: `references/lessons-learned.md`. Rules: dedupe first; evidence-based; one line per field. To promote a twice-proven rule into `references/pitfalls.md`, ask the user - never edit references unilaterally.

---

## Reference Files (Read in This Order)

**Canonical single sources (edit ONLY these for cross-cutting changes):**

1. **`references/_header-canonical.md`** — Header field order + file order (all types) — single source for `script-template.md`, `intune-patterns.md`, `file-architecture.md`
2. **`references/_logging-canonical.md`** — Logging per context (GUI vs CLI) + levels/colors + paths — single source for `script-template.md`, `intune-patterns.md`
3. **`references/_graph-canonical.md`** — Graph pagination/retry/batch/auth/403 unified (7-service ValidateSet, Retry-After) — single source for `intune-patterns.md`, `notification-patterns.md`, `scripts/*`

Then:

4. **`scripts/`** — Canonical implementations, copy verbatim: `Add-LogLine.ps1` (GUI), `Write-Log.ps1` (CLI + `Initialize-Log`/`Write-Banner`/`Write-Log`/`Write-Summary`/`Finish-Script`), `Guard-Action.ps1` (Pattern H), `Get-MgGraphAllPages.ps1`, `Invoke-GraphRequestWithRetry.ps1`, `Invoke-GraphBatchRequest.ps1`, `Get-Graph403Message.ps1`, `ConvertTo-SafeDateTime.ps1`, `Connect-GraphAuth.ps1`, `Test-XamlFile.ps1`, `Test-Skill.ps1` (skill self-test), `Test-Delivery.ps1` (one-shot delivery verifier: parser + compliance + README fidelity + PS 5.1 smoke test), `Test-ReadmeFidelity.ps1` (README vs variant-template structural gate: heading order, hero badges, placeholders, leaked instructions, Disclaimer, footer), plus Enterprise patterns-style `Embed-Xaml.ps1` for embedded XAML build step
5. **`references/file-architecture.md`** — Tier 1/2/3 folder structures + complete Tier 1 bootstrap code + **Enterprise patterns Tier 3 reference (embedded XAML, console-hide, AppConstants)**
6. **`references/design-tokens.md`** — Complete Tailwind Slate color tokens + light/dark overrides + spacing + typography (canonical for `SKILL.md` Design System)
7. **`references/xaml-styles.md`** — Full XAML for every required style (BtnBase hierarchy, Card, StatCard, InputBox, NavBtnBase, StyledCheckBox, StyledComboBox, LiveMessageCenterBox, SessionCard)
8. **`references/patterns.md`** — The 21 canonical patterns (A–U)
9. **`references/pitfalls.md`** — Documented PS 5.1 crash causes and fixes
10. **`references/icons.md`** — SVG path data for the standard icon set
11. **`references/script-template.md`** — CLI header + Description quality bar + examples (extends `_header-canonical.md`)
12. **`references/intune-patterns.md`** — Intune/Graph remediation pairs, Azure Automation auth, Graph pointers (extends `_header/_logging/_graph` canonicals)
13. **`references/notification-patterns.md`** — Intune notification runbooks (extends `_graph-canonical.md`)
14. **`references/ad-patterns.md`** — Active Directory patterns
15. **`references/winrm-patterns.md`** — Multi-machine WinRM patterns
16. **`references/event-log-patterns.md`** — Windows Event Log patterns
17. **`references/macos-patterns.md`** — macOS bash script patterns
18. **`references/readme-template.md`** — Professional README.md template (4 variants, canonical for `SKILL.md` README section)
19. **`references/lessons-learned.md`** — Lessons Learned Register format, triggers, and worked example
20. **`references/advanced-capabilities.md`** — Communication Style + advanced scenarios (multi-window tools, REST API backends, self-updating tools, bulk operations, plugin architecture)
21. **`references/exe-packaging.md`** — Ship as .exe: Enterprise patterns CodeDOM compilation, Authenticode signing, icon embedding, companion bundling, PSGallery publishing
22. **`templates/`** - Copy-paste-ready scaffolds for every deliverable (Intune detect/remediate/notification, CLI, WPF GUI with all 19 styles, macOS, 4 README variants) + guide. TEMPLATE LOCK: copy first, customize placeholders only
23. **`references/html-reports.md`** — IBM Carbon Dark for all HTML output (tokens, helpers, body classes, migration, fidelity audit)
24. **`references/cli-progress.md`** — `Write-Progress` when-to-use table + verbatim pattern + Write-Log pairing
25. **`references/verification.md`** — Pre-launch verification checklist (XAML, controls, theme, behavior, automated gates)

---

## Related Skills

This skill encodes the **canonical enterprise design standard** for production-grade tools. It pairs with:

- **`powershell-expert`** — Use for general PowerShell best practices NOT covered here: deep `CmdletBinding` parameter sets, `ShouldProcess` (`-WhatIf`/`-Confirm`), `PSResourceGet`, Windows Forms for simple dialogs, Pester testing, live verification against PowerShell Gallery. The two skills are complementary: `powershell-expert` covers *how to write PowerShell well*, this skill covers *what every tool must look and behave like*.

---

## Success Metrics & Verification

| Metric | Target | How to Verify |
|--------|--------|---------------|
| **XAML parse** | Zero errors on PS 5.1 | `XamlReader.Parse()` + `XmlNodeReader` + `XamlReader.Load()` |
| **Theme toggle** | 100% of controls respond | Visual inspection / dynamic token verification |
| **Compliance Gate** | 0 FAIL lines | `scripts/Test-ToolCompliance.ps1 -ToolPath <file.ps1>` |
| **README Fidelity** | FAITHFUL (0 FAIL) | `scripts/Test-ReadmeFidelity.ps1 -ReadmePath README.md -Variant <type>` |
| **Delivery Verifier**| 100% PASS | `scripts/Test-Delivery.ps1 -ScriptPath <tool.ps1> -ReadmePath README.md -SmokeTest` |

---

## Quick Recap

1. **Scaffold first from `templates/`** — never write from scratch; customize placeholders only.
2. **Obey the 12 Laws** — Header sequence, zero symbol fonts (Law 6), no empty catch (Law 4), beside-script report paths (Law 12).
3. **Use canonical patterns (A–U)** and tokens (Tailwind Slate for GUI, IBM Carbon Dark for HTML).
4. **Define all 19 required XAML styles** with dynamic resources.
5. **Verify with automated gates** before delivery.

