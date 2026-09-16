# Verification Checklist (Before First Run)

> Single source of truth for the pre-launch gate.
> `SKILL.md` keeps only the 5-line summary; this file owns the full checklist.
> Automated enforcement: `scripts/Test-ToolCompliance.ps1` (identity lock),
> `scripts/Test-Delivery.ps1 -SmokeTest` (parser + compliance + 5.1 smoke),
> `scripts/Test-ReadmeFidelity.ps1` (README structure).

## XAML (Tier 1 + 2)

- [ ] Parses with BOTH `XamlReader.Parse()` AND `XmlNodeReader` + `XamlReader.Load()`
- [ ] All `{StaticResource X}` have matching `<Style x:Key="X">` in Window.Resources
- [ ] All `&` in XAML are `&amp;`
- [ ] `<Grid>` open/close tags balanced
- [ ] No custom ScrollBar template (Thumb.CornerRadius doesn't exist in PS 5.1)

## Controls

- [ ] Every `x:Name` in XAML has a matching `FindName()` binding
- [ ] Every interactive button has a handler
- [ ] All buttons have a `ToolTip`
- [ ] All action buttons have an SVG icon (never symbol fonts - see ICON LAW)

## Colors / Theme

- [ ] All bg/surface/border/text use `{DynamicResource}`
- [ ] Cards/Borders have NO `IsMouseOver` triggers (only Buttons do - sole exception: StatCard KPI tiles)
- [ ] InputBox has NO `IsMouseOver` trigger (keyboard focus only)

## Behavior

- [ ] STA check + auto-restart at top of file
- [ ] `$ErrorActionPreference = 'Stop'` at entry point
- [ ] `Guard-Action` wraps every interactive button handler
- [ ] `Release-Action` is in a `finally` block (not after `try`)
- [ ] Long operations use `Start-Job` or async runspace (never block UI thread)
- [ ] Background jobs cleaned up on window close
- [ ] Inline Documentation Standard applied to ALL script types (.ps1 and .sh): section purpose lines + one-liner above every function

## Identity Lock (automated)

- [ ] `scripts/Test-ToolCompliance.ps1 -ToolPath <file>` run -> **zero FAIL lines**
- [ ] Zero Segoe MDL2 / Fluent / UI Symbol references (ICON LAW)
- [ ] GUI: canonical style keys + brush tokens present, no invented aliases
- [ ] GUI: `$script:lastLogKey` guard present; StatusBar uses `StatusBarText`
- [ ] Smoke-tested with Windows PowerShell 5.1 (`powershell.exe -File tool.ps1 -WhatIf`) - pwsh-only success is NOT proof; standalone `[HelpMessage()]` parses on pwsh 7 but crashes 5.1 (`scripts/Test-Delivery.ps1 -SmokeTest` automates this)
- [ ] README has shields.io badges + Disclaimer section
- [ ] README carries ## License / ## Disclaimer sections (a short emoji prefix is allowed; the gate regex tolerates up to 4 symbol characters between ## and the keyword)
- [ ] README structurally matches its variant template (`scripts/Test-ReadmeFidelity.ps1 -ReadmePath README.md -Variant gui|cli|intune|basic` -> zero FAIL)

For the **full PS 5.1 pitfalls list** (Thumb.CornerRadius, Join-Path, Pester 3.4, ampersand crashes, etc.), see `references/pitfalls.md`.
