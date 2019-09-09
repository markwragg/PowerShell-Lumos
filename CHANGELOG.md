# Change Log

## [1.0.31] - 2019-09-09

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
