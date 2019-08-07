# PowerShell-Lumos

[![Build status](https://ci.appveyor.com/api/projects/status/awhysa8j9ftgh3an?svg=true)](https://ci.appveyor.com/project/markwragg/powershell-influx) ![Test Coverage](https://img.shields.io/badge/coverage-0%25-red.svg?maxAge=60)

A PowerShell module for switching Windows 10 between light and dark themes depending on whether it is day or night.

![Invoke-Lumos](Invoke-Lumos.gif)

This module is published in the PowerShell Gallery, so can be installed via:

```PowerShell
Install-Module Lumos
```

## Usage

You can manually trigger Lumos as follows:

```PowerShell
Invoke-Lumos
```

This will get your geographical coordinates from your local system and then use these to query a web API for the sunrise and sunset times for your location.
If the sun is down, the theme will be set to dark.
If the sun is up, the theme will be set to light.

You can explicitly specify whether you want the Dark or Light modes with switches:

```PowerShell
Invoke-Lumos -Dark
Invoke-Lumos -Light
```

By default the cmdlet will change both the System and Application themes, but if you'd like to just change one of these you can exclude the other by using these switches:

```PowerShell
Invoke-Lumos -Dark -ExcludeSystem
Invoke-Lumos -Light -ExcludeApps
```

If you'd like your wallpaper to change with the theme, you can specify a path to these:

```PowerShell
Invoke-Lumos -Dark -DarkWallpaper c:\wallpaper\dark.png 
Invoke-Lomus -Light -LightWallpaper c:\wallpaper\light.png
```

If you'd like Windows to automatically switch from Light to Dark mode based on your local sunrise/sunset times, you can use the following cmdlet to add a Scheduled Task to do so:

```PowerShell
Register-LumosScheduledTask
```

Note you can specify all the above switches when doing this to customize the result. For example:

```PowerShell
Register-LumosScheduledTask -ExcludeApps -DarkWallpaper c:\wallpaper\dark.png -LightWallpaper c:\wallpaper\light.png
```

Note that each time the scheduled task runs it will invoke the `Update-LumosScheduledTask` cmdlet to change the timings of the triggers to reflect the latest sunrise/sunset times for your locale.