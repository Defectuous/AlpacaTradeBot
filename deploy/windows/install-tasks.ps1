<#
Register AlpacaTradeBot as Windows scheduled tasks (no admin or extra software needed).

  .\deploy\windows\install-tasks.ps1          register both tasks (does not start the bot)
  .\deploy\windows\install-tasks.ps1 -Start   register, then start the bot now

Tasks (run as the current user, only while that user is logged on):
  AlpacaTradeBot SML2        starts at logon, restarts on failure, no time limit
  AlpacaTradeBot Daily Bars  Mon-Fri 20:15 local time, runs late if the PC was off

Expects the virtualenv at <repo>\venv (python -m venv venv).
Only ONE machine may run the SML2 screener against the paper account at a time;
don't start it here while the Pi is running it.
#>
param([switch]$Start)
$ErrorActionPreference = 'Stop'

$Root   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Python = Join-Path $Root 'venv\Scripts\python.exe'
if (-not (Test-Path $Python)) { throw "Python venv not found at $Python - run: python -m venv venv; venv\Scripts\pip install -r requirements.txt" }

$User      = "$env:USERDOMAIN\$env:USERNAME"
$Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Limited

# Bot: long-running, restarted by Task Scheduler if it exits with an error.
$botAction   = New-ScheduledTaskAction -Execute $Python -Argument 'run_sml2_screener.py' -WorkingDirectory $Root
$botTrigger  = New-ScheduledTaskTrigger -AtLogOn -User $User
$botSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
                 -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
                 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
                 -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'AlpacaTradeBot SML2' -Force -Principal $Principal `
    -Action $botAction -Trigger $botTrigger -Settings $botSettings `
    -Description 'AlpacaTradeBot SML2 screener (paper).' | Out-Null

# Daily bars: once per weekday after the post-market close.
$barsAction   = New-ScheduledTaskAction -Execute $Python `
                  -Argument 'tools\store_daily_bars.py --dir . --db market_data.db' -WorkingDirectory $Root
$barsTrigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At '20:15'
$barsSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
                  -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'AlpacaTradeBot Daily Bars' -Force -Principal $Principal `
    -Action $barsAction -Trigger $barsTrigger -Settings $barsSettings `
    -Description 'Save full-day 1-min bars for the day''s SML2 symbols into market_data.db.' | Out-Null

Write-Host "Registered 'AlpacaTradeBot SML2' and 'AlpacaTradeBot Daily Bars' for $User (root: $Root)"
if ($Start) {
    Start-ScheduledTask -TaskName 'AlpacaTradeBot SML2'
    Write-Host 'Started AlpacaTradeBot SML2.'
}
Get-ScheduledTask -TaskName 'AlpacaTradeBot*' | Select-Object TaskName, State | Format-Table -AutoSize
