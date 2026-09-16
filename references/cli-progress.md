# CLI Progress - `Write-Progress` for Long-Running Operations

> Single source of truth for console progress in CLI scripts.
> `SKILL.md` keeps only the 5-line summary; this file owns the full pattern.

Every CLI script that loops over more than ~25 items, paginates Graph results, or performs batched remote operations MUST emit `Write-Progress` so the operator sees real status in the console. The audit found roughly half the reporting scripts do this; the rest need it.

## When to Use

| Operation | Use Write-Progress? |
|-----------|---------------------|
| Single Graph call returning one page | No (too brief) |
| `Get-MgGraphAllPages` over >50 items | **Yes** - one update per page |
| `foreach ($device in $devices)` with per-item Graph calls | **Yes** - one update per device |
| Batched remediation / wipe / sync actions | **Yes** - one update per target |
| Proactive Remediation detect/remediate (returns in <5s) | No |
| Quick CSV export of in-memory data | No |

## Canonical Pattern (Copy VERBATIM)

```powershell
$processedCount = 0
$total = @($items).Count

foreach ($item in $items) {
    $processedCount++
    # Activity = persistent label; Status = current item; PercentComplete = 0..100
    Write-Progress -Activity 'Collecting managed devices' `
        -Status "Device $processedCount of $total : $($item.deviceName)" `
        -PercentComplete (($processedCount / [Math]::Max($total, 1)) * 100)

    # ... per-item work ...
}

# Always close the progress bar when the loop exits (success OR failure)
try { } finally { Write-Progress -Activity 'Collecting managed devices' -Completed }
```

## Three Rules (Identity Lock)

1. **One `Activity` label per logical phase.** Do not change the activity string mid-loop - that resets the bar. New phase -> new activity string.
2. **Always call `-Completed` in a `finally` block.** Skipping it leaves the progress bar hanging in the console for 30+ seconds after the script ends.
3. **`[Math]::Max($total, 1)` guards the divide-by-zero** when the collection is empty (otherwise the bar shows `NaN%`).

## Pair With `Write-Log`

`Write-Progress` is for the console bar; `Write-Log` is for the file log. They are complementary, not interchangeable:

```powershell
Write-Progress -Activity 'Auditing policies' -Status "Policy $i of $total" -PercentComplete (...)
Write-Log -Message "Auditing policy '$($p.displayName)' ($i/$total)" -Level 'DEBUG'
```

Progress is high-frequency (once per item) and verbose; logging is summary-grade. Mixing them floods the log file.
