# Stop and remove the AlpacaTradeBot scheduled tasks.
$ErrorActionPreference = 'Stop'
foreach ($name in 'AlpacaTradeBot SML2', 'AlpacaTradeBot Daily Bars') {
    if (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue) {
        Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $name -Confirm:$false
        Write-Host "Removed '$name'"
    }
}
