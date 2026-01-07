#!/bin/bash

# Health Check Script
# Monitors the health of VPS proxy services and system resources

set -e

# Configuration
LOG_FILE="/var/log/vps-proxy-health.log"
PROXY_PORT=10086
PANEL_PORT=2053

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
TEMP_THRESHOLD=70  # Celsius (for Raspberry Pi)

# Notification
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"
ALERT_COOLDOWN=3600  # Seconds between duplicate alerts
LAST_ALERT_FILE="/tmp/vps-proxy-last-alert"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    local alert_type="$2"

    # Check cooldown
    if [ -f "$LAST_ALERT_FILE" ]; then
        local last_alert=$(cat "$LAST_ALERT_FILE")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_alert))

        if [ $time_diff -lt $ALERT_COOLDOWN ]; then
            log_message "Alert cooldown active. Skipping notification."
            return
        fi
    fi

    # Send Telegram notification
    if [ "$TELEGRAM_BOT_TOKEN" != "YOUR_BOT_TOKEN_HERE" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="${message}" \
            -d parse_mode="Markdown" > /dev/null

        log_message "Alert sent: $alert_type"
        date +%s > "$LAST_ALERT_FILE"
    fi
}

check_service() {
    local service_name="$1"

    if systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}✓${NC} $service_name is running"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name is not running"
        log_message "ERROR: $service_name is not running"

        send_alert "🚨 *Service Down Alert*

Service: \`$service_name\`
Status: ❌ Not Running
Time: $(date '+%Y-%m-%d %H:%M:%S')

Attempting to restart..." "service_down"

        # Attempt to restart
        sudo systemctl restart "$service_name"
        sleep 3

        if systemctl is-active --quiet "$service_name"; then
            send_alert "✅ Service \`$service_name\` restarted successfully" "service_recovered"
            return 0
        else
            send_alert "❌ Failed to restart \`$service_name\`. Manual intervention required." "service_failed"
            return 1
        fi
    fi
}

check_port() {
    local port="$1"
    local service_name="$2"

    if nc -z localhost "$port" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Port $port ($service_name) is open"
        return 0
    else
        echo -e "${RED}✗${NC} Port $port ($service_name) is closed"
        log_message "ERROR: Port $port is not accessible"

        send_alert "🚨 *Port Check Failed*

Port: \`$port\` ($service_name)
Status: ❌ Closed
Time: $(date '+%Y-%m-%d %H:%M:%S')" "port_closed"

        return 1
    fi
}

check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=${cpu_usage%.*}  # Remove decimal

    echo -ne "CPU Usage: "
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        echo -e "${RED}${cpu_usage}%${NC} (⚠️  High)"
        send_alert "⚠️ *High CPU Usage*

Usage: \`${cpu_usage}%\`
Threshold: \`${CPU_THRESHOLD}%\`
Time: $(date '+%Y-%m-%d %H:%M:%S')" "high_cpu"
    elif [ "$cpu_usage" -gt 50 ]; then
        echo -e "${YELLOW}${cpu_usage}%${NC}"
    else
        echo -e "${GREEN}${cpu_usage}%${NC}"
    fi
}

check_memory() {
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local mem_percent=$((used * 100 / total))

    echo -ne "Memory Usage: "
    if [ "$mem_percent" -gt "$MEMORY_THRESHOLD" ]; then
        echo -e "${RED}${mem_percent}%${NC} (⚠️  High)"
        send_alert "⚠️ *High Memory Usage*

Usage: \`${mem_percent}%\`
Threshold: \`${MEMORY_THRESHOLD}%\`
Time: $(date '+%Y-%m-%d %H:%M:%S')" "high_memory"
    elif [ "$mem_percent" -gt 50 ]; then
        echo -e "${YELLOW}${mem_percent}%${NC}"
    else
        echo -e "${GREEN}${mem_percent}%${NC}"
    fi
}

check_disk() {
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

    echo -ne "Disk Usage: "
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        echo -e "${RED}${disk_usage}%${NC} (⚠️  High)"
        send_alert "⚠️ *High Disk Usage*

Usage: \`${disk_usage}%\`
Threshold: \`${DISK_THRESHOLD}%\`
Time: $(date '+%Y-%m-%d %H:%M:%S')

Consider cleaning up logs and temporary files." "high_disk"
    elif [ "$disk_usage" -gt 70 ]; then
        echo -e "${YELLOW}${disk_usage}%${NC}"
    else
        echo -e "${GREEN}${disk_usage}%${NC}"
    fi
}

check_temperature() {
    # For Raspberry Pi
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))

        echo -ne "Temperature: "
        if [ "$temp" -gt "$TEMP_THRESHOLD" ]; then
            echo -e "${RED}${temp}°C${NC} (⚠️  High)"
            send_alert "🔥 *High Temperature Warning*

Temperature: \`${temp}°C\`
Threshold: \`${TEMP_THRESHOLD}°C\`
Time: $(date '+%Y-%m-%d %H:%M:%S')

Check cooling and ventilation." "high_temp"
        elif [ "$temp" -gt 60 ]; then
            echo -e "${YELLOW}${temp}°C${NC}"
        else
            echo -e "${GREEN}${temp}°C${NC}"
        fi
    fi
}

check_network() {
    echo -ne "Internet Connectivity: "

    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✓${NC} Connected"
    else
        echo -e "${RED}✗${NC} No internet connection"
        send_alert "🚨 *Network Down*

Internet connectivity lost!
Time: $(date '+%Y-%m-%d %H:%M:%S')" "network_down"
        return 1
    fi

    # Check public IP accessibility
    echo -ne "Public IP: "
    local public_ip=$(curl -s --max-time 5 ifconfig.me)
    if [ -n "$public_ip" ]; then
        echo -e "${GREEN}$public_ip${NC}"
    else
        echo -e "${YELLOW}Unable to detect${NC}"
    fi
}

check_logs_for_errors() {
    echo -e "\n${YELLOW}Recent Errors:${NC}"

    if command -v journalctl &> /dev/null; then
        local errors=$(journalctl -u x-ui --since "1 hour ago" -p err --no-pager | tail -5)

        if [ -z "$errors" ]; then
            echo -e "${GREEN}No recent errors${NC}"
        else
            echo "$errors"
        fi
    fi
}

full_health_check() {
    echo -e "${GREEN}=== VPS Proxy Health Check ===${NC}"
    echo -e "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')\n"

    # Service checks
    echo -e "${YELLOW}Service Status:${NC}"
    check_service "x-ui"

    # Port checks
    echo -e "\n${YELLOW}Port Status:${NC}"
    if command -v nc &> /dev/null; then
        check_port "$PROXY_PORT" "Proxy"
        check_port "$PANEL_PORT" "3x-ui Panel"
    else
        echo -e "${YELLOW}netcat not installed. Skipping port checks.${NC}"
    fi

    # System resources
    echo -e "\n${YELLOW}System Resources:${NC}"
    check_cpu
    check_memory
    check_disk
    check_temperature

    # Network
    echo -e "\n${YELLOW}Network Status:${NC}"
    check_network

    # Logs
    check_logs_for_errors

    echo -e "\n${GREEN}Health check complete${NC}"
}

quick_check() {
    local all_good=true

    # Quick service check
    if ! systemctl is-active --quiet x-ui; then
        echo "❌ x-ui service down"
        all_good=false
    fi

    # Quick CPU check
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=${cpu_usage%.*}
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        echo "⚠️  High CPU: ${cpu_usage}%"
        all_good=false
    fi

    if $all_good; then
        echo "✅ All systems operational"
    fi
}

# Main
main() {
    case "${1:-full}" in
        full|-f)
            full_health_check
            ;;
        quick|-q)
            quick_check
            ;;
        service|-s)
            check_service "x-ui"
            ;;
        resources|-r)
            check_cpu
            check_memory
            check_disk
            check_temperature
            ;;
        network|-n)
            check_network
            ;;
        *)
            echo "Usage: $0 {full|quick|service|resources|network}"
            echo ""
            echo "Commands:"
            echo "  full       - Complete health check (default)"
            echo "  quick      - Quick status check"
            echo "  service    - Check service status only"
            echo "  resources  - Check system resources only"
            echo "  network    - Check network connectivity only"
            exit 1
            ;;
    esac
}

# Dependencies check
if ! command -v nc &> /dev/null; then
    echo "Note: Install netcat for port checks: sudo apt install netcat"
fi

# Run
main "$@"
