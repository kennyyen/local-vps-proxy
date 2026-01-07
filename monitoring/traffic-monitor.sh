#!/bin/bash

# Traffic Monitor Script
# Monitors bandwidth usage and sends alerts when thresholds are exceeded

set -e

# Configuration
LOG_FILE="/var/log/vps-proxy-traffic.log"
DATA_DIR="/var/lib/vps-proxy"
ALERT_THRESHOLD_GB=50  # Alert when monthly usage exceeds this
INTERFACE="eth0"  # Change to your network interface (eth0, wlan0, etc.)

# Notification settings
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_telegram() {
    local message="$1"

    if [ "$TELEGRAM_BOT_TOKEN" != "YOUR_BOT_TOKEN_HERE" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="${message}" \
            -d parse_mode="Markdown" > /dev/null
    fi
}

detect_interface() {
    # Auto-detect primary network interface
    local iface=$(ip route | grep default | awk '{print $5}' | head -n1)

    if [ -n "$iface" ]; then
        INTERFACE="$iface"
        log_message "Detected network interface: $INTERFACE"
    else
        log_message "WARNING: Could not auto-detect interface, using default: $INTERFACE"
    fi
}

get_traffic_stats() {
    # Get current RX and TX bytes
    if [ -f "/sys/class/net/$INTERFACE/statistics/rx_bytes" ]; then
        RX_BYTES=$(cat "/sys/class/net/$INTERFACE/statistics/rx_bytes")
        TX_BYTES=$(cat "/sys/class/net/$INTERFACE/statistics/tx_bytes")
    else
        log_message "ERROR: Interface $INTERFACE not found"
        return 1
    fi

    # Convert to human readable
    RX_GB=$(echo "scale=2; $RX_BYTES / 1073741824" | bc)
    TX_GB=$(echo "scale=2; $TX_BYTES / 1073741824" | bc)
    TOTAL_GB=$(echo "scale=2; $RX_GB + $TX_GB" | bc)

    echo "RX:$RX_GB TX:$TX_GB TOTAL:$TOTAL_GB"
}

format_bytes() {
    local bytes=$1

    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc)KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc)MB"
    else
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)GB"
    fi
}

calculate_speed() {
    local current_bytes=$1
    local previous_bytes=$2
    local time_diff=$3  # in seconds

    if [ -z "$previous_bytes" ] || [ "$previous_bytes" == "0" ]; then
        echo "0"
        return
    fi

    local bytes_diff=$((current_bytes - previous_bytes))
    local speed=$((bytes_diff / time_diff))

    echo "$speed"
}

get_monthly_usage() {
    # Get usage for current month from vnstat if available
    if command -v vnstat &> /dev/null; then
        vnstat --oneline -i "$INTERFACE" | awk -F';' '{print $11}' | sed 's/ //g'
    else
        echo "vnstat not installed"
    fi
}

monitor_realtime() {
    echo -e "${GREEN}Real-time Traffic Monitor${NC}"
    echo -e "Interface: ${YELLOW}$INTERFACE${NC}"
    echo -e "Press Ctrl+C to stop\n"

    local prev_rx=0
    local prev_tx=0
    local interval=2  # seconds

    while true; do
        # Get current stats
        local rx_bytes=$(cat "/sys/class/net/$INTERFACE/statistics/rx_bytes")
        local tx_bytes=$(cat "/sys/class/net/$INTERFACE/statistics/tx_bytes")

        if [ $prev_rx -ne 0 ]; then
            # Calculate speeds
            local rx_speed=$(calculate_speed $rx_bytes $prev_rx $interval)
            local tx_speed=$(calculate_speed $tx_bytes $prev_tx $interval)

            # Format output
            local rx_formatted=$(format_bytes $rx_speed)
            local tx_formatted=$(format_bytes $tx_speed)

            echo -e "\r⬇️  ${GREEN}$rx_formatted/s${NC} | ⬆️  ${YELLOW}$tx_formatted/s${NC}     " | tr -d '\n'
        fi

        prev_rx=$rx_bytes
        prev_tx=$tx_bytes

        sleep $interval
    done
}

check_threshold() {
    local current_usage=$1  # in GB

    if (( $(echo "$current_usage > $ALERT_THRESHOLD_GB" | bc -l) )); then
        log_message "WARNING: Traffic exceeded threshold! Current: ${current_usage}GB, Threshold: ${ALERT_THRESHOLD_GB}GB"

        send_telegram "⚠️ *Traffic Alert*

📊 Monthly usage: \`${current_usage}GB\`
🚨 Threshold: \`${ALERT_THRESHOLD_GB}GB\`

Your VPS proxy has exceeded the traffic threshold."

        return 1
    fi

    return 0
}

generate_report() {
    echo -e "\n${GREEN}=== Traffic Report ===${NC}"
    echo -e "Interface: ${YELLOW}$INTERFACE${NC}"
    echo -e "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')\n"

    # Current session stats
    local stats=$(get_traffic_stats)
    local rx=$(echo $stats | cut -d: -f2 | cut -d' ' -f1)
    local tx=$(echo $stats | cut -d: -f3 | cut -d' ' -f1)
    local total=$(echo $stats | cut -d: -f4)

    echo -e "📥 Downloaded: ${GREEN}${rx}GB${NC}"
    echo -e "📤 Uploaded:   ${YELLOW}${tx}GB${NC}"
    echo -e "📊 Total:      ${total}GB"

    # Monthly stats (if vnstat available)
    if command -v vnstat &> /dev/null; then
        echo -e "\n${GREEN}Monthly Statistics:${NC}"
        vnstat -m -i "$INTERFACE"
    else
        echo -e "\n${YELLOW}Install vnstat for detailed monthly statistics:${NC}"
        echo -e "  sudo apt install vnstat"
    fi
}

install_vnstat() {
    echo "Installing vnstat for traffic monitoring..."

    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y vnstat
    elif command -v yum &> /dev/null; then
        sudo yum install -y vnstat
    else
        echo "Please install vnstat manually"
        return 1
    fi

    # Start vnstat
    sudo systemctl enable vnstat
    sudo systemctl start vnstat

    # Add interface if needed
    sudo vnstat -i "$INTERFACE"

    echo "vnstat installed and configured for interface: $INTERFACE"
}

# Main
main() {
    mkdir -p "$DATA_DIR"

    # Detect network interface
    detect_interface

    case "${1:-report}" in
        monitor|realtime|-m)
            monitor_realtime
            ;;
        report|-r)
            generate_report
            ;;
        check|-c)
            stats=$(get_traffic_stats)
            total=$(echo $stats | cut -d: -f4)
            check_threshold "$total"
            ;;
        install)
            install_vnstat
            ;;
        *)
            echo "Usage: $0 {monitor|report|check|install}"
            echo ""
            echo "Commands:"
            echo "  monitor   - Real-time traffic monitoring"
            echo "  report    - Generate traffic report"
            echo "  check     - Check against threshold"
            echo "  install   - Install vnstat for advanced monitoring"
            exit 1
            ;;
    esac
}

# Run
main "$@"
