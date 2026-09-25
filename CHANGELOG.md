# Change Log

## !Deploy

* [Breaking] `Invoke-Lumos` with no switches now toggles to whichever theme isn't currently active on Windows, instead of automatically picking Dark/Light based on your location and time of day. This matches the existing macOS behavior. Added a new `-Auto` switch to `Invoke-Lumos` to get the previous automatic, location/time-based behavior back on either platform.
* [Feature] `Register-LumosScheduledTask` now always includes `-Auto` when scheduling `Invoke-Lumos`, since the task relies on independent location/time-based detection at each of its sunrise/sunset triggers rather than toggling. If you previously registered the scheduled task, re-run `Register-LumosScheduledTask` to pick up this change.
* [BugFix] `Register-LumosScheduledTask` no longer points a PowerShell 7 scheduled task at a path that breaks on the next update, if PowerShell was installed from the Microsoft Store. Store installs live in a version-specific folder that gets removed on update; the task now points at Windows' own stable app-execution-alias for `pwsh.exe` in that case instead, which Windows keeps current across updates. Traditionally installed PowerShell 7 and Windows PowerShell are unaffected, since both already have a stable path.

## [3.0.0] - 2026-09-24

* [BugFix] `Register-LumosScheduledTask` now runs the scheduled task using whichever PowerShell edition (Core or Windows PowerShell) is currently running the cmdlet, instead of always hardcoding `powershell.exe`. Previously, if Lumos was only installed under PowerShell Core, the scheduled task would fail since Windows PowerShell can't see modules installed to the Core-only module path.
* [Feature] `Register-LumosScheduledTask` now runs `Invoke-Lumos` at two fixed daily triggers (sunrise and sunset) instead of every 15 minutes. Re-adds `Update-LumosScheduledTask`, which keeps those trigger times aligned with sunrise/sunset as they drift through the year - this time registered as its own separate "Lumos-Maintenance" task (run once weekly, at solar noon) rather than as a second action of the "Lumos" task itself.
* [Feature] `Invoke-Lumos` (and `Register-LumosScheduledTask`) now apply a System theme change to the taskbar by broadcasting a WM_SETTINGCHANGE message by default, instead of restarting Explorer. Added a `-RestartExplorer` switch to both cmdlets to restore the previous Explorer-restart behavior, for cases where the broadcast alone doesn't refresh the taskbar.
* [Feature] `Register-LumosScheduledTask` now accepts `-Sunrise` and `-Sunset` to register the "Lumos" task with fixed daily trigger times of your choosing, instead of automatically looking up your location's sunrise/sunset. Since fixed times don't need to be kept current with the season, the "Lumos-Maintenance" task is not registered when they're specified.
* [Feature] `Register-LumosScheduledTask -FromNightLight` registers the "Lumos" task using whichever schedule Windows' own Night Light feature is currently configured with, instead of looking up sunrise/sunset. Adds the private `Get-NightLightSchedule`, which reads this directly from the registry - reverse-engineered, since Night Light doesn't expose its schedule through any documented API. As with `-Sunrise`/`-Sunset`, the "Lumos-Maintenance" task is not registered, since the schedule is only read once, at registration time.
* [Breaking] `Register-LumosScheduledTask` now returns the registered scheduled task(s) instead of `$null`, so it's always visible what was registered (and, for `-FromNightLight` or the automatic sunrise/sunset lookup, what times were actually picked up) without needing `-Verbose`.
* [BugFix] `Register-LumosScheduledTask -Sunrise`/`-Sunset`/`-FromNightLight` now removes any "Lumos-Maintenance" task left over from a previous registration with the automatic lookup, instead of leaving it in place to silently overwrite the fixed schedule a week later.

## [2.0.1] - 2026-09-24

* [BugFix] `Invoke-Lumos -IncludeOfficeProPlus` no longer throws a `ParameterBindingException` when a signed-in Office identity is found, caused by a `Write-Verbose` call passing it two positional arguments instead of one interpolated string.

## [2.0.0] - 2026-09-24

* [BugFix] `Get-UserLocation` now determines location via IP-address geolocation instead of the Windows Location Service, which routinely denies permission when Lumos is run from a Scheduled Task - causing sunrise/sunset auto-detection to fail silently.
* [BugFix] `Invoke-Lumos` now restarts Explorer after changing the System theme, fixing the Windows 11 taskbar (including on secondary monitors) not updating to match the new Dark/Light mode.
* [BugFix] `Invoke-Lumos -IncludeOfficeProPlus` no longer throws when Office isn't installed or has no signed-in identity, since it looked up the Office identities registry key without checking it exists first.
* [BugFix] `Register-LumosScheduledTask` no longer requires administrator privileges. The scheduled task now runs as the current user at standard (non-elevated) privilege instead of the built-in Administrators group at the highest run level, which nothing Lumos does actually needs.
* `Register-LumosScheduledTask` now exits gracefully with a warning when run on a non-Windows OS, instead of failing on the Windows-only `ScheduledTasks` module cmdlets.
* [Breaking] Removed `Update-LumosScheduledTask`. It previously ran as a second action of the Lumos scheduled task to keep its sunrise/sunset triggers up to date through the year, but repeatedly re-registering the task this way proved unreliable - in testing it started throwing `Access is denied`, leaving the task without any triggers at all. `Register-LumosScheduledTask` now instead schedules `Invoke-Lumos` to run every 15 minutes; `Invoke-Lumos` already looks up the current sunrise/sunset on every run, so the theme still switches promptly without the task ever needing to be modified after creation.
* [BugFix] `Register-LumosScheduledTask` no longer adds an "at logon" trigger to the scheduled task. Some endpoint security software denies non-admin users permission to register a task with this trigger type - likely because running automatically at every logon is a common persistence technique - which was causing `Access is denied` even on a brand new task name. The 15 minute repeating trigger already fires immediately on registration and again shortly after any logon, so this has little practical effect.
* [BugFix] `Invoke-Lumos` now only sets the System/Apps theme (and restarts Explorer) when the theme actually needs to change, instead of doing so unconditionally on every call. This matters now that `Register-LumosScheduledTask` runs `Invoke-Lumos` every 15 minutes - previously that meant Explorer was restarted every 15 minutes as well, even when the theme hadn't changed since the last run.

## [1.0.33] - 2021-12-07

* Added `Lumos` as an alias of `Invoke-Lumos` because its nice to just be able to type `Lumos` at the console and change the theme to night/day when required.

## [1.0.32] - 2019-09-09

* Testing new deployment pipeline.

## [1.0.25] - 2019-08-24

* [Feature] Added support to change theme and Wallpaper on MacOS. Thanks [@TylerLeonhardt](https://github.com/TylerLeonhardt) for the suggestion!

## [1.0.20] - 2019-08-16

* [Feature] Added `-IncludeOfficeProPlus` switch to `Invoke-Lumos` to allow switching of Office applications between Dark and Light themes. [#7](https://github.com/markwragg/PowerShell-Lumos/pull/7) - Thanks [@appieschot](https://github.com/appieschot)

## [1.0.13] - 2019-08-12

* [BugFix] Added `-StartWhenAvailable` setting to the scheduled task so that it will execute the next time it can if the schedule is missed, and added a restart of explorer.exe to the scheduled task to ensure the change applies. [#4](https://github.com/markwragg/PowerShell-Lumos/pull/4) - Thanks [@voioo](https://github.com/voioo)

## [1.0.9] - 2019-08-08

* [BugFix] Added code to localize the local administrator group name so that `Register-LumosScheduledTask` would work on non-English systems. [#2](https://github.com/markwragg/PowerShell-Lumos/pull/2)  - Thanks [@manualbashing](https://github.com/AspenForester)

## [1.0.4] - 2019-08-07

Initial public release.

* Added `Invoke-Lumos` cmdlet to control switching of light/dark mode on Windows 10 and (optionally) desktop wallpaper.
* Added `Register-LumosScheduledTask` to configure Lumos to switch between light/dark mode based on the users current sunrise/sunset times.
* Added `Update-LumosScheduledTask` which is executed each time the scheduled task runs and updates the timings with the current sunrise/sunset times.
