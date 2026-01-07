# Local VPS Proxy - Home-Based Proxy Node Setup

A comprehensive guide and toolkit for setting up a residential IP proxy node using home infrastructure (laptop/Raspberry Pi) for accessing geo-restricted content and services.

**Language / 语言**: English | [中文](README_CN.md)

## 🌟 Overview

This project helps you set up a proxy server at home (e.g., in Japan) that can be used to access services from that location. It's particularly useful for:

- Accessing geo-restricted content (TikTok, streaming services, etc.)
- E-commerce and live streaming from specific regions
- Stable, private proxy with residential IP
- Full control over your network traffic

### Why Residential IP > VPS Datacenter IP?

| Feature | Residential IP (Home) | VPS Datacenter IP |
|---------|----------------------|-------------------|
| Detection Risk | Very Low | Medium-High |
| Cost | ~$15-20/month (electricity) | $20-100/month |
| Latency | Optimal (local region) | Varies |
| IP Quality | Premium (real residential) | Often flagged |
| Control | Full | Limited |

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│          Client Device              │
│    (Phone/Computer in China)        │
│                                     │
│  ┌──────────────────────┐          │
│  │  Proxy Client App    │          │
│  │  (Shadowrocket/V2Ray)│          │
│  └──────────┬───────────┘          │
└─────────────┼─────────────────────────┘
              │ Encrypted Traffic
              │ (Through GFW)
              ▼
┌─────────────────────────────────────┐
│     Your Home Network (Japan)       │
│                                     │
│  ┌──────────────────────┐          │
│  │  Proxy Server        │          │
│  │  (Laptop/RasPi)      │          │
│  │  - 3x-ui Panel       │          │
│  │  - V2Ray/Xray        │          │
│  └──────────┬───────────┘          │
│             │                       │
│  ┌──────────▼───────────┐          │
│  │  Home Router         │          │
│  │  (Port Forwarding)   │          │
│  └──────────┬───────────┘          │
└─────────────┼─────────────────────────┘
              │ Japanese Residential IP
              ▼
         Internet / Target Services
```

## 📋 Prerequisites

### Hardware Options

#### Option A: Raspberry Pi (Recommended)
- **Model**: Raspberry Pi 4B or 5
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 32GB+ microSD or USB SSD
- **Power**: Official power adapter
- **Cost**: ~¥6,000-10,000 (~$60-100)
- **Power consumption**: ~5-15W (¥150-200/month electricity)

#### Option B: Laptop (Testing/Short-term)
- Any modern laptop with stable internet
- Must stay on 24/7
- **Power consumption**: ~50-100W (¥500-1,000/month)
- Not recommended for long-term use

#### Option C: Mini PC
- Intel NUC, ASUS PN series
- **Cost**: ¥30,000-50,000
- Best performance, moderate power consumption

### Network Requirements
- Stable home internet (fiber optic preferred)
- Upload speed: 10+ Mbps recommended
- Router admin access for port forwarding
- Static IP (preferred) or DDNS setup

### Software
- Linux-based system (Ubuntu, Raspberry Pi OS)
- Docker (optional, for containerized setup)
- SSH access for remote management

## 🚀 Quick Start

### 1. Automated Installation

```bash
# Download and run the installation script
curl -o install.sh https://raw.githubusercontent.com/kennyyen/local-vps-proxy/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

The script will:
- Install system dependencies
- Set up 3x-ui management panel
- Configure firewall rules
- Install monitoring tools
- Set up DDNS client

### 2. Manual Installation

See [docs/manual-installation.md](docs/manual-installation.md) for detailed step-by-step instructions.

## 📖 Setup Guide

### Step 1: Prepare Your Device

#### For Raspberry Pi:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git ufw

# Enable SSH (if not already)
sudo systemctl enable ssh
sudo systemctl start ssh
```

#### For Mac/Windows Laptop:
- **Mac**: Use Terminal directly
- **Windows**: Install WSL2 with Ubuntu

### Step 2: Install 3x-ui Panel

```bash
# Run 3x-ui installation script
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# During installation, set:
# - Username: your_admin_username
# - Password: strong_password_here
# - Port: 2053 (or custom port)
```

### Step 3: Configure 3x-ui

1. Find your device's local IP:
```bash
# Linux/Mac
hostname -I
# or
ip addr show
```

2. Access 3x-ui panel in browser:
```
http://192.168.1.XXX:2053
```

3. Create an inbound connection:
   - Protocol: VMess or VLESS
   - Port: 10086 (avoid common ports)
   - UUID: Generate random
   - Transport: TCP or WebSocket
   - Encryption: auto or aes-128-gcm

### Step 4: Router Port Forwarding

1. Find your public IP:
```bash
curl ifconfig.me
```

2. Log into your router (usually `192.168.1.1` or `192.168.0.1`)

3. Navigate to: **Advanced Settings** → **Port Forwarding** / **Virtual Server**

4. Add rule:
   - **Service Name**: proxy-server
   - **External Port**: 10086
   - **Internal IP**: 192.168.1.XXX (your device)
   - **Internal Port**: 10086
   - **Protocol**: TCP+UDP

5. Save and test port:
```bash
# Test from outside network or use:
# https://www.yougetsignal.com/tools/open-ports/
```

### Step 5: Configure Client Devices

#### iOS (iPhone/iPad)
1. Download Shadowrocket or Quantumult X (requires non-CN Apple ID)
2. Add server:
   - Type: VMess/VLESS
   - Address: YOUR_PUBLIC_IP
   - Port: 10086
   - UUID: (from 3x-ui)
   - Method: auto/aes-128-gcm
3. Connect and verify IP

#### Android
1. Download v2rayNG or Clash for Android
2. Import config via QR code or manual entry
3. Enable VPN connection

#### Desktop
1. Download V2Ray client (v2rayN for Windows, V2RayX for Mac)
2. Import server configuration
3. Set system proxy

## 🔧 Configuration

### DDNS Setup (For Dynamic IPs)

If your ISP provides dynamic IP addresses, set up DDNS:

#### Using Cloudflare:
```bash
# Install ddns-go
cd /opt
wget https://github.com/jeessy2/ddns-go/releases/latest/download/ddns-go_linux_arm64.tar.gz
tar -zxvf ddns-go_linux_arm64.tar.gz
sudo ./ddns-go -s install

# Access configuration at http://localhost:9876
```

#### Using No-IP:
1. Register at https://www.noip.com/
2. Create free hostname
3. Install DUC (Dynamic Update Client)

#### Simple IP Change Notification:
Use the included script at `monitoring/ip-monitor.sh`:
```bash
# Set up cron job to check IP every hour
crontab -e
# Add: 0 * * * * /path/to/monitoring/ip-monitor.sh
```

### Performance Optimization

```bash
# Enable BBR congestion control
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Increase file descriptors
echo "fs.file-max = 51200" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Firewall Configuration

```bash
# Allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 2053/tcp  # 3x-ui panel
sudo ufw allow 10086/tcp # Proxy port
sudo ufw enable
```

## 📊 Monitoring & Maintenance

### Built-in 3x-ui Monitoring
- Access panel: http://YOUR_IP:2053
- View real-time traffic, connections, bandwidth usage

### Custom Monitoring Scripts

Located in `monitoring/` directory:

1. **ip-monitor.sh**: Tracks IP changes and sends notifications
2. **traffic-monitor.sh**: Monitors bandwidth usage
3. **health-check.sh**: Checks service status
4. **alert-telegram.sh**: Sends alerts via Telegram bot

### Automated Maintenance

```bash
# Set up auto-updates (weekly)
crontab -e
# Add: 0 3 * * 0 /path/to/scripts/auto-update.sh
```

## 🛡️ Security Best Practices

1. **Change default ports**: Don't use 443, 80, or other common ports
2. **Strong passwords**: Use complex passwords for 3x-ui panel
3. **Regular updates**: Keep system and 3x-ui updated
4. **Firewall rules**: Only allow necessary ports
5. **Fail2ban**: Install to prevent brute force attacks
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```
6. **SSH key authentication**: Disable password auth for SSH

## 🔍 Troubleshooting

### Cannot Connect to Proxy

**Check 1**: Is the service running?
```bash
sudo systemctl status x-ui
# If not running:
sudo systemctl start x-ui
```

**Check 2**: Is the port open?
```bash
sudo netstat -tulpn | grep 10086
```

**Check 3**: Is port forwarding correct?
- Verify router settings
- Check if external port matches internal port
- Ensure firewall allows the port

**Check 4**: Client configuration
- Verify public IP (not local IP like 192.168.x.x)
- Check port number
- Verify UUID matches

### Slow Connection Speed

**Issue**: Bandwidth throttling
```bash
# Test upload speed
speedtest-cli --upload-only

# If low, check:
# 1. ISP bandwidth limits
# 2. Router QoS settings
# 3. Other devices using bandwidth
```

**Issue**: High latency
```bash
# Check server load
top
htop

# Optimize with lighter encryption
# In 3x-ui: Use chacha20-poly1305 or none (for testing)
```

### TikTok Still Detects Location

**Checklist**:
- [ ] GPS disabled on phone
- [ ] System language set to target country (Japanese)
- [ ] Timezone set to target country (Asia/Tokyo)
- [ ] SIM card removed or use target country SIM
- [ ] TikTok cache cleared
- [ ] Using residential IP (not datacenter)
- [ ] IP not shared/flagged

### IP Changed and Connection Lost

**Solution 1**: Update client config with new IP
```bash
# Check current public IP
curl ifconfig.me
```

**Solution 2**: Use DDNS
- Set up domain name that auto-updates
- Use domain in client config instead of IP

**Solution 3**: Enable IP change notifications
- Set up monitoring/ip-monitor.sh script
- Receive automatic alerts when IP changes

## 📚 Additional Resources

### Documentation
- [Manual Installation Guide](docs/manual-installation.md)
- [Advanced Configuration](docs/advanced-config.md)
- [TikTok Optimization Guide](docs/tiktok-setup.md)
- [Security Hardening](docs/security.md)

### Useful Links
- [3x-ui GitHub](https://github.com/mhsanaei/3x-ui)
- [V2Ray Official](https://www.v2ray.com/)
- [Xray Documentation](https://xtls.github.io/)

## 💰 Cost Analysis

### One-time Costs
| Item | Cost (JPY) | Cost (USD) |
|------|------------|------------|
| Raspberry Pi 4B 4GB | ¥6,000 | $60 |
| Power Adapter | ¥1,000 | $10 |
| Case + Cooling | ¥1,000 | $10 |
| microSD 32GB | ¥1,000 | $10 |
| **Total** | **¥9,000** | **$90** |

### Monthly Costs
| Item | Cost (JPY) | Cost (USD) |
|------|------------|------------|
| Electricity (RasPi) | ¥150-200 | $1.50-2 |
| Internet | ¥0* | $0* |
| Domain (optional) | ¥100-1000/year | $1-10/year |
| **Total** | **¥150-200/month** | **$1.50-2/month** |

*Assuming existing home internet

### Comparison with VPS
| Solution | Setup Cost | Monthly Cost | IP Quality |
|----------|------------|--------------|------------|
| Home Setup (RasPi) | $90 | $2 | Excellent (Residential) |
| Japan VPS Basic | $0 | $6-12 | Good |
| Japan VPS Premium (CN2) | $0 | $30-50 | Good |
| Commercial Proxy Service | $0 | $10-100 | Poor-Good |

**Break-even point**: Home setup pays for itself in 7-8 months compared to premium VPS.

## ⚖️ Legal Disclaimer

This tool is provided for educational purposes and legitimate use cases such as:
- Accessing your own services remotely
- Testing geo-restricted content you have rights to access
- Personal privacy protection
- Development and testing

**Important**:
- Ensure compliance with your country's laws and regulations
- Do not use for illegal activities
- Do not provide commercial proxy services without proper licensing
- Be aware of the terms of service of platforms you access

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- [3x-ui](https://github.com/mhsanaei/3x-ui) for the excellent management panel
- V2Ray and Xray communities for the robust proxy protocols
- The open-source community for various tools and scripts

## 📞 Support

- Open an issue on GitHub
- Check the [Troubleshooting](#troubleshooting) section
- Review [docs/](docs/) for detailed guides

---

**Note**: This project is designed for Raspberry Pi 4/5 and modern Linux systems. Performance may vary based on hardware and network conditions.
