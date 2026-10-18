#!/bin/bash
# Install/refresh the AlpacaTradeBot systemd units.
#   ./deploy/linux/install.sh            install + enable (does not start the bot)
#   ./deploy/linux/install.sh --start    install + enable + start now
#
# Units hard-code User=defectuous and /home/defectuous/AlpacaTradeBot with a
# .venv/ virtualenv. Edit them first if your user or path differs.
#
# Only ONE machine may run the SML2 screener against the paper account at a
# time. Stop the old StockTipsBot unit (screener-sml2) before starting this one.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

sudo cp "$HERE"/alpacatradebot-sml2.service \
        "$HERE"/alpacatradebot-daily-bars.service \
        "$HERE"/alpacatradebot-daily-bars.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable alpacatradebot-sml2.service alpacatradebot-daily-bars.timer

if [[ "${1:-}" == "--start" ]]; then
    if systemctl is-active --quiet screener-sml2.service; then
        echo "Old screener-sml2.service is still running — stop it first:" >&2
        echo "  sudo systemctl disable --now screener-sml2.service" >&2
        exit 1
    fi
    sudo systemctl start alpacatradebot-sml2.service alpacatradebot-daily-bars.timer
fi
systemctl --no-pager status alpacatradebot-sml2.service | head -5 || true
systemctl --no-pager list-timers alpacatradebot-daily-bars.timer || true
