#!/bin/bash
# Stop, disable and remove the AlpacaTradeBot systemd units.
set -euo pipefail
sudo systemctl disable --now alpacatradebot-sml2.service alpacatradebot-daily-bars.timer || true
sudo rm -f /etc/systemd/system/alpacatradebot-sml2.service \
           /etc/systemd/system/alpacatradebot-daily-bars.service \
           /etc/systemd/system/alpacatradebot-daily-bars.timer
sudo systemctl daemon-reload
