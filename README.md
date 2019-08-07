# PowerShell-Lumos

[![Build status](https://ci.appveyor.com/api/projects/status/awhysa8j9ftgh3an?svg=true)](https://ci.appveyor.com/project/markwragg/powershell-influx) ![Test Coverage](https://img.shields.io/badge/coverage-0%grey.svg?maxAge=60)

A PowerShell module for switching Windows 10 between light and dark themes depending on whether it is day or night.

## Installation

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
