#!/bin/bash

# Local VPS Proxy - Automated Installation Script
# This script installs and configures 3x-ui proxy panel with monitoring tools

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/local-vps-proxy"
PROXY_PORT=10086
PANEL_PORT=2053

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
       print_error "This script must be run as root or with sudo"
       exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    print_info "Detected OS: $OS $VER"
}

check_network() {
    print_info "Checking network connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_info "Network connectivity: OK"
        return 0
    else
        print_error "No network connectivity"
        return 1
    fi
}

get_ip_info() {
    print_info "Retrieving IP information..."

    # Get local IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    print_info "Local IP: $LOCAL_IP"

    # Get public IP
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "Unable to detect")
    print_info "Public IP: $PUBLIC_IP"

    # Try to detect country
    COUNTRY=$(curl -s ipinfo.io/country || echo "Unknown")
    print_info "IP Country: $COUNTRY"
}

install_dependencies() {
    print_info "Installing system dependencies..."

    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt update
        apt install -y curl wget git unzip socat ufw net-tools
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum update -y
        yum install -y curl wget git unzip socat firewalld net-tools
    elif [[ "$OS" == *"Raspbian"* ]] || [[ "$OS" == *"Raspberry"* ]]; then
        apt update
        apt install -y curl wget git unzip socat ufw net-tools
    else
        print_warn "Unknown OS. Please install dependencies manually: curl wget git unzip socat"
    fi

    print_info "Dependencies installed successfully"
}

install_3x_ui() {
    print_info "Installing 3x-ui management panel..."

    if command -v x-ui &> /dev/null; then
        print_warn "3x-ui is already installed"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    # Install 3x-ui
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

    print_info "3x-ui installed successfully"
    print_info "Access panel at: http://$LOCAL_IP:$PANEL_PORT"
}

configure_firewall() {
    print_info "Configuring firewall..."

    if command -v ufw &> /dev/null; then
        # UFW (Ubuntu/Debian)
        ufw allow 22/tcp comment 'SSH'
        ufw allow $PANEL_PORT/tcp comment '3x-ui Panel'
        ufw allow $PROXY_PORT/tcp comment 'Proxy Port'
        ufw allow $PROXY_PORT/udp comment 'Proxy Port UDP'

        # Enable UFW if not already enabled
        if ! ufw status | grep -q "Status: active"; then
            print_warn "UFW is not active. Enabling..."
            echo "y" | ufw enable
        else
            ufw reload
        fi

        print_info "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        # FirewallD (CentOS/RHEL)
        firewall-cmd --permanent --add-port=22/tcp
        firewall-cmd --permanent --add-port=$PANEL_PORT/tcp
        firewall-cmd --permanent --add-port=$PROXY_PORT/tcp
        firewall-cmd --permanent --add-port=$PROXY_PORT/udp
        firewall-cmd --reload

        print_info "FirewallD configured"
    else
        print_warn "No firewall detected. Please configure manually."
    fi
}

optimize_system() {
    print_info "Optimizing system for proxy performance..."

    # Enable BBR congestion control
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        cat >> /etc/sysctl.conf << EOF

# TCP BBR Congestion Control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP Fast Open
net.ipv4.tcp_fastopen=3

# Increase file descriptors
fs.file-max=51200

# Network optimizations
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_mtu_probing=1
net.core.rmem_max=134217728
net.core.wmem_max=134217728
EOF
        sysctl -p
        print_info "System optimizations applied"
    else
        print_info "System already optimized"
    fi
}

install_ddns() {
    print_info "Would you like to install DDNS client for dynamic IP? (Recommended)"
    read -p "Install DDNS? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing ddns-go..."

        # Detect architecture
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            DDNS_ARCH="amd64"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            DDNS_ARCH="arm64"
        elif [[ "$ARCH" == "armv7l" ]]; then
            DDNS_ARCH="arm"
        else
            print_warn "Unknown architecture: $ARCH. Skipping DDNS installation."
            return 1
        fi

        # Download and install ddns-go
        mkdir -p /opt/ddns-go
        cd /opt/ddns-go

        DDNS_VERSION=$(curl -s https://api.github.com/repos/jeessy2/ddns-go/releases/latest | grep tag_name | cut -d '"' -f 4)
        wget -O ddns-go.tar.gz "https://github.com/jeessy2/ddns-go/releases/download/${DDNS_VERSION}/ddns-go_${DDNS_VERSION#v}_linux_${DDNS_ARCH}.tar.gz"
        tar -zxf ddns-go.tar.gz
        chmod +x ddns-go

        # Install as service
        ./ddns-go -s install

        print_info "DDNS-go installed successfully"
        print_info "Access DDNS configuration at: http://$LOCAL_IP:9876"
    fi
}

install_monitoring() {
    print_info "Setting up monitoring scripts..."

    mkdir -p $INSTALL_DIR/monitoring
    mkdir -p $INSTALL_DIR/logs

    # Copy monitoring scripts (will be created separately)
    if [ -d "$(dirname $0)/../monitoring" ]; then
        cp -r $(dirname $0)/../monitoring/* $INSTALL_DIR/monitoring/
        chmod +x $INSTALL_DIR/monitoring/*.sh
        print_info "Monitoring scripts installed"
    else
        print_warn "Monitoring scripts not found. Please install them manually."
    fi
}

create_management_script() {
    print_info "Creating management script..."

    cat > /usr/local/bin/vps-proxy << 'EOF'
#!/bin/bash
# Local VPS Proxy Management Script

case "$1" in
    start)
        systemctl start x-ui
        echo "Proxy service started"
        ;;
    stop)
        systemctl stop x-ui
        echo "Proxy service stopped"
        ;;
    restart)
        systemctl restart x-ui
        echo "Proxy service restarted"
        ;;
    status)
        systemctl status x-ui
        ;;
    info)
        echo "=== System Information ==="
        echo "Local IP: $(hostname -I | awk '{print $1}')"
        echo "Public IP: $(curl -s ifconfig.me)"
        echo "3x-ui Status: $(systemctl is-active x-ui)"
        echo "Panel URL: http://$(hostname -I | awk '{print $1}'):2053"
        ;;
    logs)
        journalctl -u x-ui -f
        ;;
    update)
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        ;;
    *)
        echo "Usage: vps-proxy {start|stop|restart|status|info|logs|update}"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/vps-proxy
    print_info "Management script created. Use 'vps-proxy' command to manage."
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""
    echo -e "${GREEN}System Information:${NC}"
    echo "  Local IP:  $LOCAL_IP"
    echo "  Public IP: $PUBLIC_IP"
    echo "  Country:   $COUNTRY"
    echo ""
    echo -e "${GREEN}Access Points:${NC}"
    echo "  3x-ui Panel: http://$LOCAL_IP:$PANEL_PORT"
    if [ -d "/opt/ddns-go" ]; then
        echo "  DDNS Panel:  http://$LOCAL_IP:9876"
    fi
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Access 3x-ui panel and create your first inbound connection"
    echo "  2. Configure router port forwarding for port $PROXY_PORT"
    echo "  3. Set up DDNS if you have dynamic IP"
    echo "  4. Configure client devices with the connection details"
    echo ""
    echo -e "${GREEN}Quick Commands:${NC}"
    echo "  vps-proxy status  - Check service status"
    echo "  vps-proxy info    - Show system information"
    echo "  vps-proxy logs    - View service logs"
    echo "  vps-proxy restart - Restart proxy service"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "  - Default proxy port: $PROXY_PORT"
    echo "  - Remember to set up port forwarding on your router"
    echo "  - Use a strong password for the 3x-ui panel"
    echo "  - Consider setting up DDNS for dynamic IP"
    echo ""
    echo "=========================================="
}

# Main installation flow
main() {
    clear
    echo "=========================================="
    echo "  Local VPS Proxy - Installation Script"
    echo "=========================================="
    echo ""

    check_root
    detect_os
    check_network || exit 1
    get_ip_info

    echo ""
    read -p "Continue with installation? (y/n): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi

    install_dependencies
    install_3x_ui
    configure_firewall
    optimize_system
    install_ddns
    install_monitoring
    create_management_script

    print_summary
}

# Run main function
main
