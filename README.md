# PowerShell-Lumos

[![Build status](https://ci.appveyor.com/api/projects/status/awhysa8j9ftgh3an?svg=true)](https://ci.appveyor.com/project/markwragg/powershell-lumos) ![Test Coverage](https://img.shields.io/badge/coverage-35%25-red.svg?maxAge=60)

A PowerShell module for switching Windows 10 and MacOS Mojave between light and dark themes depending on whether it is day or night.

__Windows:__

![Invoke-Lumos](assets/Invoke-Lumos-Windows.gif | width=600)

__macOS:__

![Invoke-Lumos](assets/Invoke-Lumos-macOS.gif | width=600)

This module is published in the PowerShell Gallery, so can be installed via:

```PowerShell
Install-Module Lumos
```

## Usage

You can manually trigger Lumos as follows:

```PowerShell
Invoke-Lumos
```

On Windows, this will get your geographical coordinates from your local system and then use these to query a web API for the sunrise and sunset times for your location.
If the sun is down, the theme will be set to dark.
If the sun is up, the theme will be set to light.

On MacOS Mojave, using `Invoke-Lumos` with no switches will switch the theme to its alternate, i.e if it's Light it will switch to Dark and if Dark switch to Light.

You can explicitly specify whether you want the Dark or Light modes on both Windows 10 and MacOS Mojave with the following switches:

```PowerShell
Invoke-Lumos -Dark

Invoke-Lumos -Light
```

By default the cmdlet will change both the System and Application themes, but on Windows 10 if you'd like to just change one of these you can exclude the other by using these switches:

```PowerShell
Invoke-Lumos -Dark -ExcludeSystem

Invoke-Lumos -Light -ExcludeApps
```
These switches are not available on MacOS Mojave.

If you'd like your wallpaper to change with the theme (on Windows 10 or MacOS Mojave), you can specify a path to these:

```PowerShell
Invoke-Lumos -Dark -DarkWallpaper c:\wallpaper\dark.png

Invoke-Lumos -Light -LightWallpaper /Users/markwragg/Pictures/light.jpg
```

If you'd like change the theme of your Office ProPlus installation on Windows 10, you can pass the `-IncludeOfficeProPlus` flag. It will update your Office Clients to switch to either the Dark or Light mode. Note that it requires a restart of your Office Applications before it takes effect.

```PowerShell
Invoke-Lumos -Dark -IncludeOfficeProPlus
```

If you'd like Windows 10 to automatically switch from Light to Dark mode based on your local sunrise/sunset times, you can use the following cmdlet to add a Scheduled Task to do so (this cmdlet does not currently support MacOS Mojave):

> Note this may require your PowerShell terminal to be running as Administrator.

```PowerShell
Register-LumosScheduledTask
```

Note you can specify all the above switches when doing this to customize the result. For example:

```PowerShell
Register-LumosScheduledTask -ExcludeApps -DarkWallpaper c:\wallpaper\dark.png -LightWallpaper c:\wallpaper\light.png
```

Note that each time the scheduled task runs it will invoke the `Update-LumosScheduledTask` cmdlet to change the timings of the triggers to reflect the latest sunrise/sunset times for your locale.
