# 回家后待办事项

## ✅ 已完成
- [x] Git配置：本地项目已设置为使用kennyyen credential
- [x] 文档更新：README中英文版已添加日本ISP限制警告

---

## 🏠 回家后要做的事情

### 第一步：检查网络连接类型 (5分钟)

```bash
# 1. 检查公网IP
curl -4 ifconfig.me
# 记录结果：_________________

# 2. 登录路由器
# 浏览器打开：http://192.168.0.1 或 http://192.168.1.1

# 3. 查找并记录：
#    - WAN IP地址：_________________
#    - 连接方式：PPPoE / IPv4 over IPv6 / その他
```

**判断：**
- [ ] 公网IP = 路由器WAN IP + PPPoE → ✅ 可以直接搭建
- [ ] 公网IP ≠ 路由器WAN IP → ⚠️ 需要改设置

---

### 第二步：简单测试（推荐！先确认端口转发是否工作）

**你朋友的建议：先测试简单服务，确认可以从外网连接，再架设复杂的VPS代理** ✅

#### 测试方案1：简单Web服务器（最简单）

```bash
# 1. 在Mac上启动一个简单的Web服务器
cd ~
echo "Hello from Japan! 端口转发成功！" > test.html
python3 -m http.server 8080
```

**路由器设置：**
- [ ] 添加端口转发：外部8080 → 你的Mac IP:8080

**测试：**
```bash
# 用手机4G网络访问（不要用WiFi）
http://你的公网IP:8080/test.html

# 如果看到 "Hello from Japan! 端口转发成功！"
# 🎉 恭喜！端口转发工作了！
```

---

#### 测试方案2：SSH连接（更安全）

```bash
# 1. Mac上确保SSH已启动
sudo systemsetup -setremotelogin on

# 2. 查看Mac的本地IP
ipconfig getifaddr en0
# 记录：192.168.0.___
```

**路由器设置：**
- [ ] 添加端口转发：外部2222 → 你的Mac IP:22

**测试：**
```bash
# 从外网测试（用手机4G或朋友从中国测试）
ssh -p 2222 你的用户名@你的公网IP

# 如果能登录
# 🎉 端口转发工作！可以继续搭建VPS代理
```

---

#### 测试结果判断

- [ ] ✅ **测试成功** → 端口转发正常工作，可以继续搭建代理服务器
- [ ] ❌ **测试失败** → 端口转发不工作，需要：
  - 检查是不是v6プラス（需要改PPPoE）
  - 或者直接用VPS方案

---

### 第三步：选择方案（测试成功后）

#### 方案A：如果是PPPoE（最理想）✅

**操作清单：**
- [ ] 确认路由器端口10086已转发到Mac IP
- [ ] 测试端口开放（用手机4G）：`nc -zv 你的公网IP 10086`
- [ ] 配置DDNS（推荐No-IP或DuckDNS）
- [ ] 给朋友配置连接（使用DDNS域名，不是IP）

**TikTok业务推荐配置：**
- 协议：VMess
- 传输：WebSocket
- 加密：TLS
- 端口：443

---

#### 方案B：如果是v6プラス（需要改设置）⚠️

**改成PPPoE（推荐）：**
- [ ] 登录路由器
- [ ] 找到「基本設定」→「接続設定」
- [ ] 从「IPv4 over IPv6」改成「PPPoE」
- [ ] 输入PPPoE账号密码（查合同或打客服：0077-777）
- [ ] 重启路由器
- [ ] 验证：再次检查公网IP和WAN IP是否相同

**或者查询v6プラス可用端口：**
- [ ] 访问：https://ipv4.web.fc2.com/map-e.html
- [ ] 输入公网IP查询可用端口范围
- [ ] 使用查到的端口替代10086

---

#### 方案C：如果必须用VPS ⚠️

**推荐VPS（TikTok业务考虑日本本土）：**
- [ ] Sakura VPS (¥590/月) - 最便宜，纯日本IP
- [ ] ConoHa VPS (¥678/月) - 日本公司，CN2可选

**VPS设置：**
```bash
ssh root@你的VPS_IP
curl -o install.sh https://raw.githubusercontent.com/kennyyen/local-vps-proxy/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

**TikTok业务必须配置：**
- [ ] 使用TLS加密（443端口）
- [ ] VMess + WebSocket + TLS
- [ ] 固定使用一个VPS，不频繁换IP

---

### 第三步：提交代码到GitHub

```bash
cd /Users/ts-chungchih.a.yen/Development/local-vps-proxy

git status
git add README.md README_CN.md
git commit -m "Add Japanese ISP limitations warning and solutions

- Add DS-Lite/MAP-E/PPPoE explanation
- Add VPS provider recommendations
- Add troubleshooting guide for Japanese users
- Add references to Japanese tech community articles

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

git push -u origin main
```

如果需要输入密码，使用kennyyen的GitHub Personal Access Token。

---

## 📞 重要联系方式

**au光客服：** 0077-777（免费）

**要说的话：**
- 查询PPPoE账号密码：「PPPoE接続のIDとパスワードを教えてください」
- 改成PPPoE连接：「IPv4 over IPv6からPPPoE接続に変更したいです」
- 申请固定IP：「固定IPアドレスサービスを申し込みたいです」

---

## 🎯 最终目标

### 成功标准：
- [ ] 你朋友从中国可以连接到你的代理
- [ ] 她的设备显示IP为日本
- [ ] 可以正常使用TikTok（观看/发布/直播）

### 风险提醒（TikTok业务）：
- ✅ 家庭住宅IP：风险最低，账号安全
- ⚠️ VPS数据中心IP：有一定检测风险，需谨慎

---

## 📚 参考资料

**日本技术社区实际案例：**
- [au光VPN端口映射设置](https://synrock-tech.com/network/internet/au_portmapping/)
- [自宅端口开放的运营商选择](https://zenn.dev/atsushi570/articles/3ac7fb8d49fc76)
- [Raspberry Pi + WireGuard VPN](https://zenn.dev/ledmirage/articles/f2696f07529f78)
- [au光端口开放教程](https://www.hikari-au.net/settings/port_forwarding/setup_portforwarding)

**技术说明：**
- [Asahi Net: DS-Lite端口转发](https://faq.asahi-net.jp/en/faq_detail.html?id=5309)
- [日本ISP IPv4 over IPv6技术](https://kuropixel.com/japanese-internet-guide/)

---

## ✏️ 执行记录

**日期：________**

第一步检查结果：
- 公网IP：_________________
- 路由器WAN IP：_________________
- 连接方式：_________________
- 判断：_________________

选择的方案：
- [ ] 方案A: PPPoE直接搭建
- [ ] 方案B: 改成PPPoE
- [ ] 方案C: 使用VPS

遇到的问题：
_________________________________
_________________________________

解决方案：
_________________________________
_________________________________

最终状态：
- [ ] 成功 ✅
- [ ] 失败 ❌（原因：___________）
