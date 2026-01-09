# Local VPS Proxy - 家庭网络代理节点搭建指南

一个全面的指南和工具包，用于使用家庭基础设施（笔记本电脑/树莓派）搭建住宅IP代理节点，访问地理限制的内容和服务。

**Language / 语言**: [English](README.md) | 中文

## 🌟 项目概述

本项目帮助您在家中（例如日本）搭建代理服务器，可用于从该地区访问服务。特别适用于：

- 访问地理限制内容（TikTok、流媒体服务等）
- 跨境电商和特定地区的直播带货
- 稳定、私密的住宅IP代理
- 完全掌控您的网络流量

### 为什么住宅IP优于VPS数据中心IP？

| 特性 | 住宅IP（家庭网络） | VPS数据中心IP |
|------|------------------|--------------|
| 被检测风险 | 非常低 | 中-高 |
| 成本 | ~¥150-200/月（电费） | ¥1,500-6,000/月 |
| 延迟 | 最优（本地区域） | 不确定 |
| IP质量 | 优质（真实住宅） | 经常被标记 |
| 控制权 | 完全 | 有限 |

## 🏗️ 系统架构

```
┌─────────────────────────────────────┐
│       客户端设备                     │
│    (中国的手机/电脑)                  │
│                                     │
│  ┌──────────────────────┐          │
│  │  代理客户端应用        │          │
│  │  (Shadowrocket/V2Ray)│          │
│  └──────────┬───────────┘          │
└─────────────┼─────────────────────────┘
              │ 加密流量
              │ (穿过GFW)
              ▼
┌─────────────────────────────────────┐
│     您的家庭网络（日本）              │
│                                     │
│  ┌──────────────────────┐          │
│  │  代理服务器            │          │
│  │  (笔记本/树莓派)        │          │
│  │  - 3x-ui 管理面板      │          │
│  │  - V2Ray/Xray         │          │
│  └──────────┬───────────┘          │
│             │                       │
│  ┌──────────▼───────────┐          │
│  │  家用路由器            │          │
│  │  (端口转发)            │          │
│  └──────────┬───────────┘          │
└─────────────┼─────────────────────────┘
              │ 日本住宅IP
              ▼
         互联网 / 目标服务
```

## 📋 系统要求

### 硬件选择

#### 方案A：树莓派（推荐）
- **型号**: 树莓派 4B 或 5
- **内存**: 4GB 起步，推荐 8GB
- **存储**: 32GB+ microSD卡 或 USB SSD
- **电源**: 官方电源适配器
- **成本**: 约 ¥6,000-10,000 (~$60-100)
- **功耗**: ~5-15W (每月电费约¥150-200)

#### 方案B：笔记本电脑（测试/短期）
- 任何现代笔记本，需保持稳定网络连接
- 必须24/7开机
- **功耗**: ~50-100W (每月电费约¥500-1,000)
- 不推荐长期使用

#### 方案C：迷你主机
- Intel NUC、华硕 PN 系列
- **成本**: ¥30,000-50,000
- 性能最佳，功耗适中

### 网络要求
- 稳定的家庭网络（建议光纤）
- 上传速度：推荐 10+ Mbps
- 路由器管理权限（用于端口转发）
- 固定IP（优选）或 DDNS 设置

### 软件要求
- 基于Linux的系统（Ubuntu、Raspberry Pi OS）
- Docker（可选，用于容器化部署）
- SSH远程管理访问权限

## ⚠️ 重要：日本ISP限制说明

**如果你在日本，请务必先看这里！**

大多数日本家庭宽带运营商（au Hikari、NTT、Softbank等）使用 **DS-Lite** 或 **MAP-E** 技术提供IPv4连接，这会**阻止外部连接**。

### 问题说明

| 技术类型 | 端口转发 | 说明 |
|---------|---------|------|
| **DS-Lite** | ❌ 完全不可能 | 多个用户共享一个IPv4地址，ISP层面阻止所有外部连接。 |
| **MAP-E** | ⚠️ 有限支持 | 你会得到特定的端口范围（240-1008个端口），但大多数家用路由器不支持。 |
| **传统IPv4** | ✅ 正常工作 | 完全支持端口转发。 |

**典型症状：**
- 路由器端口转发已正确配置，但从外网仍然无法连接
- 端口检测工具显示端口"关闭"或"超时"
- 本地可以正常工作，但朋友从外网连不上

### 日本用户的解决方案

#### 方案1：联系运营商（推荐家庭搭建）
致电运营商并申请：
- **"固定IPアドレス"**（固定IP地址）服务
- 或从DS-Lite改为 **IPv4 PPPoE** 连接方式
- 费用：通常每月额外¥1,000-2,000

完成后，家庭搭建方案就能按文档正常工作了。

#### 方案2：使用VPS替代（更简单）
由于家庭宽带有限制，使用VPS通常更简单：

**推荐的日本VPS提供商：**

| 提供商 | 起步价格 | 位置 | 备注 |
|--------|---------|------|------|
| [Vultr Tokyo](https://www.vultr.com/) | $6/月 | 东京 | 到中国速度快，按小时计费 |
| [Linode Tokyo](https://www.linode.com/) | $5/月 | 东京 | 稳定可靠，网络质量好 |
| [ConoHa VPS](https://www.conoha.jp/) | ¥678/月 | 东京 | 日本公司，有CN2线路 |
| [Sakura VPS](https://vps.sakura.ad.jp/) | ¥590/月 | 东京/大阪 | 价格便宜，纯日本IP |

**设置方法相同：** 只需SSH登录VPS并运行安装脚本：
```bash
ssh root@你的VPS_IP
curl -o install.sh https://raw.githubusercontent.com/kennyyen/local-vps-proxy/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

#### 方案3：使用IPv6（高级）
如果你家有IPv6，且用户也有IPv6连接，可以使用IPv6地址。但是这个方案比较复杂，而且支持度不高。

### 如何检查你的连接类型

```bash
# 检查是否使用DS-Lite或MAP-E
curl -4 ifconfig.me
# 如果你的公网IP和路由器WAN IP不匹配，很可能是DS-Lite/MAP-E
```

或者查看运营商合同，寻找这些关键词：
- "IPv4 over IPv6"
- "DS-Lite"
- "MAP-E"
- "v6プラス" (v6 plus)
- "transix"

**参考资料：**
- [Asahi Net: DS-Lite端口转发说明](https://faq.asahi-net.jp/en/faq_detail.html?id=5309)
- [日本ISP IPv4 over IPv6技术说明](https://kuropixel.com/japanese-internet-guide/)

## 🚀 快速开始

### 1. 自动化安装

```bash
# 下载并运行安装脚本
curl -o install.sh https://raw.githubusercontent.com/kennyyen/local-vps-proxy/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

安装脚本将自动：
- 安装系统依赖
- 设置 3x-ui 管理面板
- 配置防火墙规则
- 安装监控工具
- 设置 DDNS 客户端

### 2. 手动安装

详细的分步说明请参见 [docs/manual-installation.md](docs/manual-installation.md)

## 📖 详细设置指南

### 第一步：准备设备

#### 树莓派：
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必需的包
sudo apt install -y curl wget git ufw

# 启用SSH（如果尚未启用）
sudo systemctl enable ssh
sudo systemctl start ssh
```

#### Mac/Windows 笔记本：
- **Mac**: 直接使用终端
- **Windows**: 安装 WSL2 和 Ubuntu

### 第二步：安装 3x-ui 面板

```bash
# 运行 3x-ui 安装脚本
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# 安装过程中设置：
# - 用户名: 您的管理员用户名
# - 密码: 设置强密码
# - 端口: 2053（或自定义端口）
```

### 第三步：配置 3x-ui

1. 查找设备的本地IP：
```bash
# Linux/Mac
hostname -I
# 或
ip addr show
```

2. 在浏览器中访问 3x-ui 面板：
```
http://192.168.1.XXX:2053
```

3. 创建入站连接：
   - 协议：VMess 或 VLESS
   - 端口：10086（避免使用常见端口）
   - UUID：随机生成
   - 传输：TCP 或 WebSocket
   - 加密：auto 或 aes-128-gcm

### 第四步：路由器端口转发

1. 查找您的公网IP：
```bash
curl ifconfig.me
```

2. 登录路由器（通常是 `192.168.1.1` 或 `192.168.0.1`）

3. 导航至：**高级设置** → **端口转发** / **虚拟服务器**

4. 添加规则：
   - **服务名称**: proxy-server
   - **外部端口**: 10086
   - **内部IP**: 192.168.1.XXX（您的设备IP）
   - **内部端口**: 10086
   - **协议**: TCP+UDP

5. 保存并测试端口：
```bash
# 从外部网络测试或使用：
# https://www.yougetsignal.com/tools/open-ports/
```

### 第五步：配置客户端设备

#### iOS（iPhone/iPad）
1. 下载客户端（需要非中国区 Apple ID）：
   - Shadowrocket（小火箭，$2.99）
   - Quantumult X

2. 添加服务器：
   - 类型：VMess/VLESS
   - 地址：YOUR_PUBLIC_IP（您的公网IP）
   - 端口：10086
   - UUID：（从3x-ui获取）
   - 加密方式：auto/aes-128-gcm

3. 连接并验证IP

#### Android
1. 下载客户端：
   - v2rayNG（推荐）
   - Clash for Android

2. 导入配置（通过二维码或手动输入）

3. 启用VPN连接

#### 桌面电脑
1. 下载 V2Ray 客户端：
   - Windows: v2rayN
   - Mac: V2RayX
   - Linux: v2ray-core

2. 导入服务器配置

3. 设置系统代理

## 🔧 高级配置

### DDNS 设置（动态IP）

如果您的ISP提供动态IP地址，需要设置DDNS：

#### 使用 Cloudflare：
```bash
# 安装 ddns-go
cd /opt
wget https://github.com/jeessy2/ddns-go/releases/latest/download/ddns-go_linux_arm64.tar.gz
tar -zxvf ddns-go_linux_arm64.tar.gz
sudo ./ddns-go -s install

# 访问配置页面 http://localhost:9876
```

#### 使用 No-IP：
1. 在 https://www.noip.com/ 注册
2. 创建免费主机名
3. 安装 DUC（动态更新客户端）

#### 简单的IP变化通知：
使用 `monitoring/ip-monitor.sh` 脚本：
```bash
# 设置定时任务，每小时检查一次IP
crontab -e
# 添加：0 * * * * /path/to/monitoring/ip-monitor.sh
```

### 性能优化

```bash
# 启用 BBR 拥塞控制
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 增加文件描述符
echo "fs.file-max = 51200" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 防火墙配置

```bash
# 允许必要的端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 2053/tcp  # 3x-ui 面板
sudo ufw allow 10086/tcp # 代理端口
sudo ufw enable
```

## 📊 监控与维护

### 内置 3x-ui 监控
- 访问面板：http://YOUR_IP:2053
- 查看实时流量、连接数、带宽使用情况

### 自定义监控脚本

位于 `monitoring/` 目录：

1. **ip-monitor.sh**: 跟踪IP变化并发送通知
2. **traffic-monitor.sh**: 监控带宽使用
3. **health-check.sh**: 检查服务状态
4. **alert-telegram.sh**: 通过 Telegram 机器人发送警报

### 自动化维护

```bash
# 设置自动更新（每周）
crontab -e
# 添加：0 3 * * 0 /path/to/scripts/auto-update.sh
```

## 🛡️ 安全最佳实践

1. **更改默认端口**: 不要使用 443、80 或其他常见端口
2. **强密码**: 为 3x-ui 面板使用复杂密码
3. **定期更新**: 保持系统和 3x-ui 更新
4. **防火墙规则**: 只允许必要的端口
5. **Fail2ban**: 安装以防止暴力破解
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```
6. **SSH密钥认证**: 禁用 SSH 密码认证

## 🔍 故障排除

### 无法连接到代理

**检查1**: 服务是否运行？
```bash
sudo systemctl status x-ui
# 如果未运行：
sudo systemctl start x-ui
```

**检查2**: 端口是否开放？
```bash
sudo netstat -tulpn | grep 10086
```

**检查3**: 端口转发是否正确？
- 验证路由器设置
- 检查外部端口是否与内部端口匹配
- 确保防火墙允许该端口

**检查4**: 客户端配置
- 验证使用的是公网IP（不是 192.168.x.x 这样的本地IP）
- 检查端口号
- 验证 UUID 是否匹配

### 连接速度慢

**问题**: 带宽限制
```bash
# 测试上传速度
speedtest-cli --upload-only

# 如果速度低，检查：
# 1. ISP 带宽限制
# 2. 路由器 QoS 设置
# 3. 其他设备占用带宽
```

**问题**: 高延迟
```bash
# 检查服务器负载
top
htop

# 使用更轻的加密方式优化
# 在 3x-ui 中：使用 chacha20-poly1305 或 none（仅测试）
```

### TikTok 仍然检测到位置

**检查清单**:
- [ ] 手机GPS已关闭
- [ ] 系统语言设置为目标国家（日语）
- [ ] 时区设置为目标国家（亚洲/东京）
- [ ] SIM卡已取出或使用目标国家SIM卡
- [ ] 清除 TikTok 缓存
- [ ] 使用住宅IP（不是数据中心IP）
- [ ] IP未被共享/标记

### IP变化导致连接丢失

**解决方案1**: 使用新IP更新客户端配置
```bash
# 查看当前公网IP
curl ifconfig.me
```

**解决方案2**: 使用 DDNS
- 设置自动更新的域名
- 在客户端配置中使用域名而不是IP

**解决方案3**: 启用 IP 变化通知
- 设置 monitoring/ip-monitor.sh 脚本
- IP变化时自动接收警报

## 📚 其他资源

### 文档
- [手动安装指南](docs/manual-installation.md)
- [高级配置](docs/advanced-config.md)
- [TikTok 优化指南](docs/tiktok-setup.md)
- [安全加固](docs/security.md)

### 有用链接
- [3x-ui GitHub](https://github.com/mhsanaei/3x-ui)
- [V2Ray 官方](https://www.v2ray.com/)
- [Xray 文档](https://xtls.github.io/)

## 💰 成本分析

### 一次性成本
| 项目 | 成本（日元） | 成本（美元） |
|------|------------|-------------|
| 树莓派 4B 4GB | ¥6,000 | $60 |
| 电源适配器 | ¥1,000 | $10 |
| 外壳 + 散热 | ¥1,000 | $10 |
| microSD 32GB | ¥1,000 | $10 |
| **总计** | **¥9,000** | **$90** |

### 每月成本
| 项目 | 成本（日元） | 成本（美元） |
|------|------------|-------------|
| 电费（树莓派） | ¥150-200 | $1.50-2 |
| 网络 | ¥0* | $0* |
| 域名（可选） | ¥100-1000/年 | $1-10/年 |
| **总计** | **¥150-200/月** | **$1.50-2/月** |

*假设使用现有的家庭网络

### 与VPS的成本对比
| 解决方案 | 初始成本 | 每月成本 | IP质量 |
|---------|---------|---------|--------|
| 家庭搭建（树莓派） | $90 | $2 | 优秀（住宅） |
| 日本VPS基础版 | $0 | $6-12 | 良好 |
| 日本VPS高级版（CN2） | $0 | $30-50 | 良好 |
| 商业代理服务 | $0 | $10-100 | 差-良好 |

**回本周期**: 与高级VPS相比，家庭搭建方案在7-8个月内回本。

## ⚖️ 法律声明

本工具仅供教育目的和合法使用场景，例如：
- 远程访问您自己的服务
- 测试您有权访问的地理限制内容
- 个人隐私保护
- 开发和测试

**重要提示**:
- 确保遵守您所在国家/地区的法律法规
- 不要用于非法活动
- 未经适当许可，不要提供商业代理服务
- 了解您访问的平台的服务条款

## 🤝 贡献

欢迎贡献！请随时提交拉取请求或提出问题。

## 📝 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [3x-ui](https://github.com/mhsanaei/3x-ui) 提供优秀的管理面板
- V2Ray 和 Xray 社区提供强大的代理协议
- 开源社区提供的各种工具和脚本

## 📞 支持

- 在 GitHub 上提出问题
- 查看[故障排除](#故障排除)部分
- 查阅 [docs/](docs/) 目录获取详细指南

---

**注意**: 本项目专为树莓派 4/5 和现代 Linux 系统设计。性能可能因硬件和网络条件而异。
