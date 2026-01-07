# Configuration Templates

This directory contains various configuration templates for different proxy setups.

## Available Configurations

### 1. VMess + TCP (vmess-tcp.json)
**Best for:** Simple setup, low overhead
**Security:** Medium
**Speed:** Fast
**Stealth:** Low

```json
{
  "protocol": "vmess",
  "transport": "tcp",
  "port": 10086
}
```

**Use case:** Testing, low-risk scenarios, maximum speed

---

### 2. VMess + WebSocket + TLS (vmess-ws-tls.json)
**Best for:** Maximum stealth, bypassing deep packet inspection
**Security:** High
**Speed:** Medium
**Stealth:** High

```json
{
  "protocol": "vmess",
  "transport": "ws",
  "security": "tls",
  "port": 443
}
```

**Use case:** Production use, high censorship areas, TikTok streaming

**Requirements:**
- Domain name
- TLS certificate (Let's Encrypt recommended)
- Optional: Cloudflare CDN

---

### 3. VLESS + XTLS (vless-xtls.json)
**Best for:** Low latency, high performance
**Security:** Very High
**Speed:** Very Fast
**Stealth:** High

**Use case:** Gaming, video streaming, real-time applications

---

## Configuration Guide

### Step 1: Choose Your Configuration

| Scenario | Recommended Config | Why |
|----------|-------------------|-----|
| Quick test | VMess + TCP | Fast setup, no domain needed |
| TikTok streaming | VMess + WS + TLS | Best detection avoidance |
| Gaming | VLESS + XTLS | Lowest latency |
| Max security | VMess + WS + TLS + CDN | Multiple layers of protection |

### Step 2: Generate UUID

```bash
# Method 1: Using uuidgen (Linux/Mac)
uuidgen

# Method 2: Using Python
python3 -c "import uuid; print(uuid.uuid4())"

# Method 3: Online
# Visit: https://www.uuidgenerator.net/
```

### Step 3: Update Configuration

Replace `YOUR-UUID-HERE` in the config file with your generated UUID.

### Step 4: Apply Configuration

#### Using 3x-ui Panel (Recommended)
1. Log into 3x-ui panel: `http://YOUR_IP:2053`
2. Go to **Inbounds** → **Add Inbound**
3. Fill in details based on your chosen configuration
4. Save and enable

#### Using V2Ray directly
```bash
# Copy config to V2Ray directory
sudo cp vmess-tcp.json /usr/local/etc/v2ray/config.json

# Restart V2Ray
sudo systemctl restart v2ray
```

---

## Router Port Forwarding Examples

### Common Router Brands

#### 1. TP-Link Router

1. Navigate to: **Advanced** → **NAT Forwarding** → **Virtual Servers**
2. Click **Add**
3. Enter:
   ```
   Service Port: 10086
   Internal Port: 10086
   IP Address: 192.168.1.XXX (your device)
   Protocol: TCP
   Status: Enabled
   ```
4. Click **Save**

#### 2. ASUS Router

1. Navigate to: **WAN** → **Virtual Server / Port Forwarding**
2. Enable Port Forwarding
3. Add:
   ```
   Service Name: Proxy
   Port Range: 10086
   Local IP: 192.168.1.XXX
   Local Port: 10086
   Protocol: TCP
   ```
4. Click **Add** → **Apply**

#### 3. Netgear Router

1. Navigate to: **Advanced** → **Advanced Setup** → **Port Forwarding**
2. Click **Add Custom Service**
3. Configure:
   ```
   Service Name: VPS_Proxy
   Service Type: TCP
   External Starting Port: 10086
   External Ending Port: 10086
   Internal Starting Port: 10086
   Internal Ending Port: 10086
   Internal IP Address: 192.168.1.XXX
   ```
4. Click **Apply**

#### 4. Buffalo Router

1. Go to: **Security** → **Port Forwarding**
2. Add new rule:
   ```
   Name: Proxy Server
   Protocol: TCP
   Port (from): 10086
   Port (to): 10086
   To IP Address: 192.168.1.XXX
   ```
3. Save settings

---

## Client Configuration Examples

### iOS (Shadowrocket)

```
Type: VMess
Address: YOUR_PUBLIC_IP_OR_DOMAIN
Port: 10086
UUID: YOUR-UUID-HERE
Alter ID: 0
Security: auto
Network: tcp (or ws for WebSocket)
```

**For WebSocket + TLS:**
```
Type: VMess
Address: your-domain.com
Port: 443
UUID: YOUR-UUID-HERE
Alter ID: 0
Security: auto
Network: ws
Path: /your-websocket-path
TLS: On
```

### Android (v2rayNG)

```
{
  "v": "2",
  "ps": "Japan Home Proxy",
  "add": "YOUR_PUBLIC_IP",
  "port": "10086",
  "id": "YOUR-UUID-HERE",
  "aid": "0",
  "net": "tcp",
  "type": "none",
  "host": "",
  "path": "",
  "tls": ""
}
```

### Desktop (V2RayN / V2RayX)

Import the configuration via:
1. QR Code (generated from 3x-ui)
2. VMess URL
3. Manual configuration (same as above)

---

## Security Recommendations

### 1. Port Selection
- **Avoid**: 8080, 8443, 1080, 8388 (commonly scanned)
- **Good**: 10086, 28967, 33891 (random high ports)
- **Best**: 443, 80 (with TLS, looks like normal HTTPS)

### 2. UUID Best Practices
- ✅ Generate unique UUID for each client
- ✅ Rotate UUIDs periodically
- ❌ Don't use example UUIDs from tutorials
- ❌ Don't share UUIDs publicly

### 3. Additional Security Layers

```bash
# Enable UFW logging
sudo ufw logging on

# Limit SSH attempts
sudo ufw limit 22/tcp

# Install fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

---

## Testing Your Configuration

### 1. Test from Local Network

```bash
# Using curl with proxy
curl -x socks5://localhost:10086 https://ifconfig.me

# Should return your home public IP
```

### 2. Test from Client Device

```bash
# After connecting to proxy
curl https://ifconfig.me

# Should return your proxy server's IP
```

### 3. Test Latency

```bash
# Ping your proxy server
ping YOUR_PUBLIC_IP

# Typical latency:
# Japan to China: 50-100ms
# USA to China: 150-250ms
# Europe to China: 200-350ms
```

### 4. Test for DNS Leaks

Visit: https://dnsleaktest.com/

Should show DNS servers in the proxy location (Japan), not your actual location.

---

## Troubleshooting

### Configuration Issues

**Problem:** "Configuration file error"
```bash
# Validate JSON syntax
python3 -m json.tool < vmess-tcp.json

# Or use online validator: https://jsonlint.com/
```

**Problem:** "Port already in use"
```bash
# Check what's using the port
sudo lsof -i :10086

# Kill the process if needed
sudo kill -9 <PID>
```

**Problem:** "Permission denied"
```bash
# Run with sudo
sudo v2ray -config /path/to/config.json

# Or fix permissions
sudo chmod 644 /path/to/config.json
```

---

## Advanced Topics

### 1. Multiple Users

Create multiple clients in the same inbound:

```json
{
  "clients": [
    {
      "id": "UUID-USER-1",
      "email": "user1@example.com"
    },
    {
      "id": "UUID-USER-2",
      "email": "user2@example.com"
    }
  ]
}
```

### 2. Traffic Routing

Route different traffic to different outbounds:

```json
{
  "routing": {
    "rules": [
      {
        "type": "field",
        "domain": ["geosite:cn"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": ["geosite:geolocation-!cn"],
        "outboundTag": "proxy"
      }
    ]
  }
}
```

### 3. Cloudflare CDN Integration

For WebSocket + TLS configurations:

1. Add your domain to Cloudflare
2. Enable proxy (orange cloud)
3. Use Cloudflare IP in client config
4. Traffic flow: Client → Cloudflare → Your Server

Benefits:
- Hides your real IP
- DDoS protection
- May improve speed in some regions

---

## Additional Resources

- [V2Ray Configuration Reference](https://www.v2ray.com/en/configuration/)
- [3x-ui Documentation](https://github.com/mhsanaei/3x-ui)
- [Port Forwarding Guides](https://portforward.com/)

---

**Last Updated:** 2026-01-06
