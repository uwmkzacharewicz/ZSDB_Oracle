#!/bin/bash

TIMESTAMP=$(date +"%d%m%Y_%H%M")

LOG_DIR="/home/oracle/stock_oracle/logs"
LOG_FILE="${LOG_DIR}/cron_stock_update_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

cd /home/oracle/stock_oracle

/usr/bin/python3.8 scripts/update_stock_prices.py > "$LOG_FILE" 2>&1
