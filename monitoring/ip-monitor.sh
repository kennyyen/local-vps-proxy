#!/bin/bash

# IP Monitor Script
# Monitors public IP changes and sends notifications

set -e

# Configuration
IP_FILE="/tmp/vps_proxy_ip.txt"
LOG_FILE="/var/log/vps-proxy-ip-monitor.log"
NOTIFY_METHOD="telegram"  # Options: telegram, email, webhook, log

# Telegram Configuration (if using)
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"

# Email Configuration (if using)
EMAIL_TO="your-email@example.com"
EMAIL_SUBJECT="[VPS Proxy] IP Address Changed"

# Webhook Configuration (if using)
WEBHOOK_URL="https://your-webhook-url.com/notify"

# Functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_public_ip() {
    # Try multiple services for reliability
    local ip=""

    ip=$(curl -s --max-time 5 ifconfig.me) || \
    ip=$(curl -s --max-time 5 ipinfo.io/ip) || \
    ip=$(curl -s --max-time 5 icanhazip.com) || \
    ip=$(curl -s --max-time 5 api.ipify.org)

    echo "$ip"
}

send_telegram_notification() {
    local message="$1"

    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" == "YOUR_BOT_TOKEN_HERE" ]; then
        log_message "Telegram not configured"
        return 1
    fi

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="Markdown" > /dev/null

    if [ $? -eq 0 ]; then
        log_message "Telegram notification sent successfully"
    else
        log_message "Failed to send Telegram notification"
    fi
}

send_email_notification() {
    local message="$1"

    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$EMAIL_SUBJECT" "$EMAIL_TO"
        log_message "Email notification sent"
    else
        log_message "mail command not found. Install mailutils: sudo apt install mailutils"
    fi
}

send_webhook_notification() {
    local message="$1"

    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"$message\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

    log_message "Webhook notification sent"
}

notify() {
    local message="$1"

    case "$NOTIFY_METHOD" in
        telegram)
            send_telegram_notification "$message"
            ;;
        email)
            send_email_notification "$message"
            ;;
        webhook)
            send_webhook_notification "$message"
            ;;
        log)
            log_message "$message"
            ;;
        *)
            log_message "Unknown notification method: $NOTIFY_METHOD"
            ;;
    esac
}

# Main logic
main() {
    log_message "Starting IP monitor check..."

    # Get current public IP
    CURRENT_IP=$(get_public_ip)

    if [ -z "$CURRENT_IP" ]; then
        log_message "ERROR: Failed to retrieve public IP"
        exit 1
    fi

    log_message "Current IP: $CURRENT_IP"

    # Check if IP file exists
    if [ ! -f "$IP_FILE" ]; then
        log_message "First run detected. Saving IP: $CURRENT_IP"
        echo "$CURRENT_IP" > "$IP_FILE"

        notify "🚀 *VPS Proxy Monitor Started*

📍 Initial IP: \`$CURRENT_IP\`
🕐 Time: $(date '+%Y-%m-%d %H:%M:%S')

Monitor is now active and will alert you of IP changes."
        exit 0
    fi

    # Read previous IP
    PREVIOUS_IP=$(cat "$IP_FILE")

    # Compare IPs
    if [ "$CURRENT_IP" != "$PREVIOUS_IP" ]; then
        log_message "IP CHANGED: $PREVIOUS_IP → $CURRENT_IP"

        # Save new IP
        echo "$CURRENT_IP" > "$IP_FILE"

        # Get additional info
        COUNTRY=$(curl -s "ipinfo.io/$CURRENT_IP/country" || echo "Unknown")
        CITY=$(curl -s "ipinfo.io/$CURRENT_IP/city" || echo "Unknown")
        ISP=$(curl -s "ipinfo.io/$CURRENT_IP/org" || echo "Unknown")

        # Send notification
        notify "⚠️ *IP Address Changed!*

🔴 Old IP: \`$PREVIOUS_IP\`
🟢 New IP: \`$CURRENT_IP\`

📍 Location: $CITY, $COUNTRY
🌐 ISP: $ISP
🕐 Time: $(date '+%Y-%m-%d %H:%M:%S')

⚙️ *Action Required:*
Update your client configuration with the new IP address.

If using DDNS, the domain should auto-update within a few minutes."

        # Optional: Auto-update config (if you have a script for that)
        # /opt/local-vps-proxy/scripts/update-client-config.sh "$CURRENT_IP"

    else
        log_message "IP unchanged: $CURRENT_IP"
    fi
}

# Run main function
main "$@"
