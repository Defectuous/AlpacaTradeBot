# AlpacaTradeBot

SML2: an RSI / MACD / VWAP momentum screener that trades $0.50–$5.00 stocks on an Alpaca **paper** account, plus the data capture, review and backtesting tools around it.

Split out of `StockTipsBot` on 2026-10-18. The retired screeners (SML, MID, SUPER, RUNNER, LIVE) and the old email/Sheets code stayed behind there. Their trade **history** came along in the data files.

> **Only one machine may run the screener at a time.** Two copies would trade the same paper account against each other.

## Layout

```
run_sml2_screener.py   the bot (entry point)
bot/                   Alpaca trader, price stream, indicators, universe, SQLite, Discord, logging
tools/                 data capture, review, account maintenance and backtests (below)
daily_report.py        HTML dashboard for one trading day → logs/report_<date>.html
deploy/linux/          systemd units + install/uninstall scripts (Raspberry Pi)
deploy/windows/        Task Scheduler install/uninstall scripts
docs/                  config history (tradeconfig.md), todo.md, strategy notes
pi_data/               (gitignored) synced copy of the Pi's logs and DBs — SML + SML2 history
reports/               (gitignored) backtest outputs and the 1-min bar caches they reuse
```

## Setup

```bash
python -m venv venv             # the systemd units and Windows scripts expect venv/
venv/bin/pip install -r requirements.txt      # Windows: venv\Scripts\pip
cp .env.example .env            # fill in SML2_ALPACA_API_KEY / SECRET and DISCORD_WEBHOOK_URL
python run_sml2_screener.py
```

The startup banner prints every active setting. Check it after any `.env` change.

The bot writes `stockbot.db` (positions, wallet, cooldowns) and the daily logs `sml2.log.MMDDYYYY` to the repo root.

## Running as a service

**Linux / Pi (systemd)**

```bash
./deploy/linux/install.sh           # install + enable alpacatradebot-sml2 and the daily-bars timer
./deploy/linux/install.sh --start   # ...and start now (refuses if the old screener-sml2 is still running)
./deploy/linux/uninstall.sh
journalctl -u alpacatradebot-sml2 -f
```

The units assume user `defectuous`, `/home/defectuous/AlpacaTradeBot` and a `venv/` virtualenv. Edit them if any of those differ.

**Windows (Task Scheduler)**

```powershell
.\deploy\windows\install-tasks.ps1          # register "AlpacaTradeBot SML2" (at logon, auto-restart) + "AlpacaTradeBot Daily Bars"
.\deploy\windows\install-tasks.ps1 -Start   # ...and start the bot now
.\deploy\windows\uninstall-tasks.ps1
```

Both set up a weekday 20:15 job that saves full-day 1-minute bars for that day's traded and candidate symbols into `market_data.db`.

## Tools

| Purpose | Script |
|---|---|
| Why did/didn't SML2 trade today | `tools/explain_trading_day.py --date YYYY-MM-DD` |
| One-day HTML dashboard | `daily_report.py --date YYYY-MM-DD` |
| Multi-day P&L report / Discord summary | `tools/report_range.py` |
| Save the day's 1-min bars | `tools/store_daily_bars.py` (runs nightly via the service) |
| Reconcile DB vs Alpaca positions and cash | `tools/sync_db.py`, `tools/reconcile_wallets.py` |
| Cancel open orders / reset the paper account | `tools/cancel_orders.py`, `tools/reset_paper.py` |
| Rebuild DB rows from Alpaca order history | `tools/backfill_orders.py`, `tools/backfill_entry_stats.py` |
| Backtests | `tools/backtest_sml2.py` (main replay), `backtest_symbols.py`, `backtest_filter_sweep.py`, `backtest_optimize.py`, `backtest_stop_floor.py`, `backtest_equity_sim.py`, `backtest_strategies.py`, `backtest_today_wide.py` |
| Shadow / candidate studies | `tools/vwap_reclaim_shadow.py`, `tools/pull_day_candidates.py` |

The account tools only target SML2. Review and backtest tools default to reading `pi_data/` and accept `--providers sml sml2` so the SML history stays usable.
