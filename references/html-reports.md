# HTML Reports — IBM Carbon Dark (Canonical for All HTML Output)

> Single source of truth for every HTML report this skill produces.
> `SKILL.md` keeps only the 6-line summary; this file owns the full system.

**Every HTML report produced by any tool in this skill MUST use the IBM Carbon
Design System (Dark theme).** WPF GUI tools use Tailwind Slate
(`references/design-tokens.md`); HTML output uses Carbon Dark. Two surfaces,
two design systems, no overlap.

## Why Carbon Dark for HTML

- **Operator-deliverable reports** are emailed, archived, and printed; Carbon is the IBM enterprise standard for executive dashboards and reads identically on every browser and printed page.
- The reference design (`Intune-Reporting-Tools/Export-IntuneDashboard/IntuneDashboard_*.html`) is the production-proven shape — KPI tiles, donut/bar charts, structured tables, footer with run metadata, disclaimer modal.
- It is self-contained: a `<style>` block with IBM Plex Sans/Mono + Carbon tokens, plus optional inline SVG and vanilla JS. No CDN runtime dependency that can fail offline.

## Canonical Tokens (Copy, Never Invent)

| Token | Value | Use |
|-------|-------|-----|
| `--cds-background` | `#161616` | Page background |
| `--cds-layer-01` | `#262626` | Card / row background |
| `--cds-layer-02` | `#353535` | Hover / inner panel |
| `--cds-border-strong-01` | `#4d4d4d` | Header divider |
| `--cds-border-subtle-01` | `#393939` | Row divider, KPI grid separator |
| `--cds-text-primary` | `#f4f4f4` | Headings, values |
| `--cds-text-secondary` | `#c6c6c6` | Body text, table cells |
| `--cds-text-helper` | `#8d8d8d` | Captions, footer |
| `--cds-blue` | `#0f62fe` | Primary accent (links, card borders) |
| `--cds-support-success` | `#24a148` | Compliant / healthy |
| `--cds-support-warning` | `#f1c21b` | At risk / degraded |
| `--cds-support-error` | `#da1e28` | Critical / failed |
| `--cds-support-info` | `#0043ce` | Informational |
| `--cds-purple` | `#8a3ffc` | Secondary accent |
| `--cds-magenta` | `#d02670` | Tertiary accent |

**Never write hex codes inline** when a token exists. Print styles are part of the template — `@media print` inverts to white background automatically.

## Canonical Helpers (Five Functions, One Source of Truth)

The complete HTML rendering toolkit lives at **`templates/EnterpriseHtmlReport.template.ps1`** (canonical, copy VERBATIM into every script that emits HTML — or dot-source it). The five reserved function names:

| Function | Returns | Purpose |
|----------|---------|---------|
| `Get-StandardHtmlHead` | `<!DOCTYPE html>...<style>...</style></head>` | Head + Carbon stylesheet. Parameters: `-Title`, `-Subtitle`. |
| `Get-StandardHtmlOpen` | `<body><header> + KPI row` | Page header + KPI tiles. Parameters: `-Title`, `-Subtitle`, `-GeneratedAt`, `-Operator`, `-Kpis` (`@(@{value=…; label=…; color=…})`). |
| `Get-StandardHtmlFooter` | `</body>-end footer (3-col) + disclaimer modal` | Run metadata (tenant, operator, UTC, run-id, version, grade). Parameters: `-Tenant`, `-Operator`, `-Grade`, `-GradeRate`, `-GradeColor`, `-GradeTip`, `-ReportName`, `-Version`. |
| `Get-StandardHtmlClose` | `</body></html>` + JS helpers | Closes document; adds instant-search + dark-print support. |
| `Get-StandardHtmlChartScripts` | Optional `<script>` block | Canvas donut + flat bar charts (use only when emitting chart data). |

A sixth convenience helper, **`Export-StandardHtmlReport`**, wraps the four above into a single call:

```powershell
Export-StandardHtmlReport -OutputPath $path -Title "Compliance" -Subtitle "Tenant: contoso" `
    -Tenant $tenant -Operator $upn -Kpis $kpis -Body $bodyHtml `
    -Grade 'A' -GradeRate '97%' -GradeColor '#24a148' -GradeTip 'A >= 95% (Excellent)' `
    -Version '1.0.0' -ReportName 'Compliance Report' -ChartScripts $chartJs
```

## Body Layout (between Open and Footer)

Build the body with these sanctioned HTML patterns — never invent ad-hoc CSS:

```html
<div class="section-title">Compliance Breakdown</div>
<div class="grid-2">
    <div class="card">
        <h2>By State</h2>
        <table><thead><tr><th>State</th><th>Count</th></tr></thead><tbody>
            <tr><td>Compliant</td><td>123</td></tr>
        </tbody></table>
    </div>
    <div class="card">
        <h2>By Platform</h2>
        <canvas id="chart-platform"></canvas>
    </div>
</div>
```

Sanctioned classes: `.section-title`, `.grid-2`, `.card`, `.kpi-row`, `.kpi-card`, `.bar-chart`, `.legend`, `.badge.critical|high|medium|low`, `.progress-bar`, `.footer`, `.disclaimer-box`. Need a new pattern? Extend by copying the closest existing class — never invent a new one.

## Migration Rule (Identity Lock)

If a script already emits HTML and uses a different design, **migrate it to Carbon** using the canonical helpers — do not maintain parallel design systems. The audit found 10 HTML-emitting scripts; 9 already use Carbon via `Get-StandardHtml*`, one outlier (`Export-IntuneDashboard.ps1`) still has bespoke HTML and is the canonical migration target.

## HTML Fidelity Audit Protocol

When auditing N HTML-emitting scripts:

1. **Classify before fixing** — run a full triage pass and output a sorted `| # | Script | Verdict | Issue |` table (FAIL → WEAK → PASS) before any edits.
2. **Scoring rubric (4 metrics):** KPI tiles bound to real data (+1), body built from `$rows | ForEach-Object` dynamically (+1), ≥5 rows of script-specific detail (+1), charts derived from same data (+1). PASS=3–4, WEAK=1–2, FAIL=0.
3. **N > 3 files → task agent** with a precise output spec; N ≤ 3 → inline read+edit.
4. **Audit scope discipline:** fix only the audited concern (HTML fidelity). Log pre-existing console/logic bugs as separate follow-ups.
5. **Three-gate verification after fix** (see Hardcoded Rule 28 in `SKILL.md`).
