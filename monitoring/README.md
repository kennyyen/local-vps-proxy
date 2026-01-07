# Monitoring Scripts

This directory contains monitoring and alerting scripts for your VPS proxy setup.

## Available Scripts

### 1. ip-monitor.sh
Monitors your public IP address and sends notifications when it changes.

**Usage:**
```bash
# Run once
./ip-monitor.sh

# Set up cron job (every hour)
crontab -e
# Add: 0 * * * * /opt/local-vps-proxy/monitoring/ip-monitor.sh
```

**Features:**
- Detects IP changes
- Sends notifications via Telegram/Email/Webhook
- Logs all changes
- Includes location and ISP information

---

### 2. traffic-monitor.sh
Monitors bandwidth usage and provides traffic statistics.

**Usage:**
```bash
# Real-time monitoring
./traffic-monitor.sh monitor

# Generate report
./traffic-monitor.sh report

# Check against threshold
./traffic-monitor.sh check

# Install vnstat for advanced monitoring
./traffic-monitor.sh install
```

**Features:**
- Real-time traffic display
- Monthly usage tracking
- Threshold alerts
- vnstat integration

---

### 3. health-check.sh
Comprehensive health monitoring for services and system resources.

**Usage:**
```bash
# Full health check
./health-check.sh

# Quick status
./health-check.sh quick

# Check specific components
./health-check.sh service    # Service status only
./health-check.sh resources  # CPU/Memory/Disk
./health-check.sh network    # Network connectivity
```

**Features:**
- Service status monitoring
- Port availability checks
- CPU, Memory, Disk usage
- Temperature monitoring (Raspberry Pi)
- Automatic service restart
- Error log analysis

---

## Setup Instructions

### 1. Make Scripts Executable

```bash
cd /opt/local-vps-proxy/monitoring
chmod +x *.sh
```

### 2. Configure Telegram Notifications

#### Create a Telegram Bot:

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Follow instructions to create your bot
4. Copy the **Bot Token** (looks like: `123456:ABC-DEF1234...`)

#### Get Your Chat ID:

1. Search for [@userinfobot](https://t.me/userinfobot) in Telegram
2. Send `/start`
3. Copy your **Chat ID** (looks like: `123456789`)

Or use this method:
```bash
# Replace YOUR_BOT_TOKEN with your actual token
curl https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates

# Send a message to your bot first, then run the command
# Look for "chat":{"id":XXXXXXX} in the response
```

#### Update Scripts:

Edit each monitoring script and replace:
```bash
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"
```

With your actual values:
```bash
TELEGRAM_BOT_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
TELEGRAM_CHAT_ID="123456789"
```

### 3. Test Telegram Notifications

```bash
# Quick test
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage" \
  -d chat_id="<YOUR_CHAT_ID>" \
  -d text="Test message from VPS Proxy"
```

If successful, you should receive a message on Telegram!

### 4. Set Up Cron Jobs

```bash
# Edit crontab
crontab -e

# Add these lines:
# IP Monitor - every hour
0 * * * * /opt/local-vps-proxy/monitoring/ip-monitor.sh >> /var/log/ip-monitor-cron.log 2>&1

# Health Check - every 30 minutes
*/30 * * * * /opt/local-vps-proxy/monitoring/health-check.sh quick >> /var/log/health-check-cron.log 2>&1

# Traffic Check - daily at midnight
0 0 * * * /opt/local-vps-proxy/monitoring/traffic-monitor.sh check >> /var/log/traffic-check-cron.log 2>&1

# Weekly health report - Sundays at 9 AM
0 9 * * 0 /opt/local-vps-proxy/monitoring/health-check.sh full >> /var/log/health-report.log 2>&1
```

Save and exit (Ctrl+X, then Y, then Enter in nano).

### 5. Verify Cron Jobs

```bash
# List your cron jobs
crontab -l

# Check cron logs
grep CRON /var/log/syslog
```

---

## Configuration Options

### IP Monitor Configuration

Edit `ip-monitor.sh`:

```bash
# Notification method
NOTIFY_METHOD="telegram"  # Options: telegram, email, webhook, log

# Email settings (if using email)
EMAIL_TO="your-email@example.com"
EMAIL_SUBJECT="[VPS Proxy] IP Address Changed"

# Webhook settings (if using webhook)
WEBHOOK_URL="https://your-webhook-url.com/notify"
```

### Traffic Monitor Configuration

Edit `traffic-monitor.sh`:

```bash
# Alert threshold (in GB)
ALERT_THRESHOLD_GB=50

# Network interface (auto-detected, but can override)
INTERFACE="eth0"  # or wlan0, ens33, etc.
```

### Health Check Configuration

Edit `health-check.sh`:

```bash
# Proxy ports
PROXY_PORT=10086
PANEL_PORT=2053

# Resource thresholds
CPU_THRESHOLD=80       # Percentage
MEMORY_THRESHOLD=80    # Percentage
DISK_THRESHOLD=85      # Percentage
TEMP_THRESHOLD=70      # Celsius

# Alert cooldown (to avoid spam)
ALERT_COOLDOWN=3600    # Seconds (1 hour)
```

---

## Notification Examples

### IP Change Notification
```
⚠️ IP Address Changed!

🔴 Old IP: 123.45.67.89
🟢 New IP: 98.76.54.32

📍 Location: Tokyo, Japan
🌐 ISP: NTT Communications
🕐 Time: 2026-01-06 15:30:00

⚙️ Action Required:
Update your client configuration with the new IP address.
```

### Health Alert
```
🚨 Service Down Alert

Service: x-ui
Status: ❌ Not Running
Time: 2026-01-06 16:45:00

Attempting to restart...
```

### Traffic Alert
```
⚠️ Traffic Alert

📊 Monthly usage: 55GB
🚨 Threshold: 50GB

Your VPS proxy has exceeded the traffic threshold.
```

---

## Troubleshooting

### Scripts Not Running

**Check permissions:**
```bash
ls -la /opt/local-vps-proxy/monitoring/
# Should show -rwxr-xr-x (executable)

# Fix if needed:
chmod +x /opt/local-vps-proxy/monitoring/*.sh
```

**Check cron service:**
```bash
sudo systemctl status cron
# Should show "active (running)"

# Start if not running:
sudo systemctl start cron
```

### Telegram Notifications Not Working

**Test bot token:**
```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
# Should return bot information
```

**Verify chat ID:**
```bash
# Send test message
curl -X POST "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage" \
  -d chat_id="<YOUR_CHAT_ID>" \
  -d text="Test"
```

**Common issues:**
- Wrong token or chat ID
- Bot not started (send `/start` to your bot first)
- Token/ID has spaces or special characters

### IP Monitor Not Detecting Changes

**Test IP retrieval:**
```bash
curl ifconfig.me
# Should return your public IP
```

**Check IP file:**
```bash
cat /tmp/vps_proxy_ip.txt
# Should show your current IP
```

**Force IP change detection:**
```bash
# Delete IP file and run again
rm /tmp/vps_proxy_ip.txt
./ip-monitor.sh
```

### Health Check False Alarms

**Adjust thresholds:**
```bash
# Edit health-check.sh
nano health-check.sh

# Modify thresholds to suit your system:
CPU_THRESHOLD=90        # Increase if needed
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
```

---

## Advanced Usage

### Create Custom Alerts

Example: Alert when specific service restarts:

```bash
#!/bin/bash
# watch-service.sh

SERVICE="x-ui"

while true; do
    if ! systemctl is-active --quiet $SERVICE; then
        # Send alert
        curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
            -d chat_id="<CHAT_ID>" \
            -d text="⚠️ Service $SERVICE stopped!"

        # Wait before checking again
        sleep 300
    fi
    sleep 60
done
```

### Email Notifications

Install mail utilities:
```bash
sudo apt install mailutils

# Configure postfix when prompted
# Choose "Internet Site"
```

Test email:
```bash
echo "Test message" | mail -s "Test Subject" your-email@example.com
```

### Webhook Integration

For Discord webhook:
```bash
curl -H "Content-Type: application/json" \
  -X POST \
  -d '{"content": "Your message here"}' \
  YOUR_DISCORD_WEBHOOK_URL
```

For Slack webhook:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Your message here"}' \
  YOUR_SLACK_WEBHOOK_URL
```

---

## Dashboard Setup (Optional)

### Using Netdata

Install real-time monitoring dashboard:

```bash
# Install Netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Access at: http://your-ip:19999
```

### Using vnStat PHP Frontend

```bash
# Install vnstat and web interface
sudo apt install vnstat apache2 php libapache2-mod-php

# Clone vnstat-dashboard
cd /var/www/html
sudo git clone https://github.com/alexandermarston/vnstat-dashboard.git

# Access at: http://your-ip/vnstat-dashboard
```

---

## Log Management

### View Logs

```bash
# IP monitor logs
tail -f /var/log/vps-proxy-ip-monitor.log

# Traffic logs
tail -f /var/log/vps-proxy-traffic.log

# Health check logs
tail -f /var/log/vps-proxy-health.log

# All logs
tail -f /var/log/vps-proxy-*.log
```

### Log Rotation

Create `/etc/logrotate.d/vps-proxy`:

```bash
/var/log/vps-proxy-*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Performance Tips

1. **Adjust monitoring frequency** based on your needs:
   - Critical systems: Every 5-15 minutes
   - Normal use: Every 30-60 minutes
   - Low priority: Once daily

2. **Use quick checks** for frequent monitoring:
   ```bash
   */15 * * * * /opt/local-vps-proxy/monitoring/health-check.sh quick
   ```

3. **Limit log size**:
   ```bash
   # In your scripts, add log rotation
   if [ $(wc -l < $LOG_FILE) -gt 10000 ]; then
       tail -5000 $LOG_FILE > $LOG_FILE.tmp
       mv $LOG_FILE.tmp $LOG_FILE
   fi
   ```

---

## Getting Help

If you encounter issues:

1. Check script permissions: `ls -la`
2. Test scripts manually: `./script.sh`
3. Check cron logs: `grep CRON /var/log/syslog`
4. Verify Telegram bot: Test with curl commands above
5. Check system logs: `journalctl -xe`

For more help, open an issue on GitHub.

---

**Last Updated:** 2026-01-06
