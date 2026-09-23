if (-not (Test-Path alias:lumos)) {
    New-Alias -Name 'lumos' -Value 'Invoke-Lumos'
    Export-ModuleMember -Alias 'lumos'
}
