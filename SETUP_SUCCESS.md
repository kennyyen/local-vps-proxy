# 成功配置记录 - au 光 + BL1500HM

## 配置日期
2026-01-09

## 最终工作配置

### 网络环境
- **ISP**: au 光（KDDI）
- **ONU**: Nokia HI4CP
- **路由器**: KDDI BL1500HM
- **公网 IP**: 113.148.4.138
- **连接类型**: PPPoE（非 v6プラス/MAP-E）

### 关键配置步骤

#### 1. 固定 Mac IP 地址
- **MAC 地址**: 26:2B:D0:87:C1:F2
- **固定 IP**: 192.168.0.2
- **配置位置**: 路由器 → 詳細設定 → DHCP固定/除外割当設定

#### 2. 端口映射配置
**路由器配置**（ポートマッピング設定）：
- **优先度 1**: LAN側ホスト 192.168.0.2, TCP, 10086-10086（代理端口）
- **优先度 2**: LAN側ホスト 192.168.0.2, TCP, 8080-8080（测试端口，可删除）

#### 3. DMZ 配置（可选但推荐用于测试）
- **DMZ ホスト IP**: 192.168.0.2
- **状态**: 启用

#### 4. Docker 配置
**docker-compose.yml**:
```yaml
services:
  vps-proxy:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: vps-proxy
    restart: unless-stopped
    volumes:
      - ./data/x-ui:/etc/x-ui
      - ./data/certs:/root/cert
    environment:
      - TZ=Asia/Tokyo
      - XRAY_VMESS_AEAD_FORCED=false
    ports:
      - "2053:2053"   # 3x-ui 管理面板
      - "10086:10086" # VMess 代理端口
```

#### 5. VMess Inbound 配置
**3x-ui 面板配置**（http://localhost:2053）:
- **Protocol**: VMess
- **Listen IP**: 0.0.0.0（监听所有接口）
- **Port**: 10086
- **UUID**: d45a8ff0-7ede-4023-90d9-b5ec3cf0781b
- **Alter ID**: 0
- **Security**: auto
- **Network**: tcp
- **TLS**: none

#### 6. 客户端连接信息
**VMess 连接字符串**:
```
vmess://eyJ2IjoiMiIsInBzIjoiSmFwYW4tSG9tZS1Qcm94eSIsImFkZCI6IjExMy4xNDguNC4xMzgiLCJwb3J0IjoxMDA4NiwiaWQiOiJkNDVhOGZmMC03ZWRlLTQwMjMtOTBkOS1iNWVjM2NmMDc4MWIiLCJhaWQiOjAsInNjeSI6ImF1dG8iLCJuZXQiOiJ0Y3AiLCJ0eXBlIjoibm9uZSIsImhvc3QiOiIiLCJwYXRoIjoiIiwidGxzIjoiIiwic25pIjoiIiwiYWxwbiI6IiJ9
```

**手动配置参数**:
- Server: 113.148.4.138
- Port: 10086
- UUID: d45a8ff0-7ede-4023-90d9-b5ec3cf0781b
- Alter ID: 0
- Security: auto
- Network: tcp
- TLS: disabled

## 常见问题解决

### 问题 1: 端口转发不工作
**原因**: Mac IP 地址改变导致端口映射失效

**解决方案**:
1. 在路由器设置 DHCP 固定分配
2. 更新端口映射和 DMZ 配置指向正确的 IP

### 问题 2: Xray 启动失败 "bind: cannot assign requested address"
**原因**: Listen IP 设置为公网 IP

**解决方案**:
- 将 Listen IP 设置为 `0.0.0.0` 或留空
- 客户端配置使用公网 IP (113.148.4.138)

### 问题 3: 客户端连接后无网络
**原因**: 3x-ui 默认地址为 localhost

**解决方案**:
- 编辑 inbound 配置，确保客户端看到的地址是公网 IP
- 或者手动生成 VMess 连接字符串

## 端口开放验证

验证端口是否开放：https://www.yougetsignal.com/tools/open-ports/

测试结果：
- ✅ Port 10086: Open
- ✅ Port 8080: Open (测试端口)

## 维护命令

### Docker 管理
```bash
# 查看状态
docker ps

# 查看日志
docker logs vps-proxy -f

# 重启容器
docker-compose restart

# 停止服务
docker-compose stop

# 启动服务
docker-compose start
```

### 访问管理面板
```bash
# 本地访问
http://localhost:2053

# 默认账号
用户名: admin
密码: admin（首次登录后修改）
```

### 检查 Mac IP
```bash
# 查看当前 IP
ifconfig en0 | grep "inet "

# 查看 MAC 地址
ifconfig en0 | grep ether
```

## 注意事项

1. **保持 Mac 运行**: 服务需要 Mac 24/7 运行
2. **防止休眠**:
   - 系统设置 → 电池 → 防止自动休眠
   - 或运行: `caffeinate -d -i -s &`

3. **IP 变化监控**:
   - 公网 IP 可能会变化
   - 建议设置 DDNS 或使用 IP 监控脚本

4. **安全建议**:
   - 修改 3x-ui 默认密码
   - 定期更换 UUID
   - 监控流量使用
   - 考虑启用 TLS（生产环境推荐）

## 性能优化

### 对于 TikTok 使用（如需）
客户端设备设置：
- 禁用 GPS/位置服务
- 系统语言设置为日语
- 时区设置为 Asia/Tokyo
- 移除中国 SIM 卡或使用飞行模式
- 清除 TikTok 应用数据后首次使用

### 升级到 WebSocket + TLS（可选）
如需更强的隐蔽性：
1. 注册域名指向 113.148.4.138
2. 申请 Let's Encrypt 证书
3. 修改 inbound 配置使用 ws + tls
4. 使用端口 443

## 故障排查清单

- [ ] Docker 容器是否运行: `docker ps`
- [ ] 端口是否监听: `lsof -iTCP:10086 -sTCP:LISTEN`
- [ ] Mac IP 是否正确: `ifconfig en0 | grep "inet "`
- [ ] 路由器端口映射是否指向正确 IP
- [ ] 公网 IP 是否变化: `curl ifconfig.me`
- [ ] 防火墙是否关闭: macOS 防火墙应关闭
- [ ] 从外网测试端口: https://www.yougetsignal.com/tools/open-ports/

## 成功标准

✅ 端口 10086 从外网可访问
✅ 客户端能成功连接
✅ 连接后 IP 显示为 113.148.4.138
✅ 可以正常访问被墙网站

---

**配置完成时间**: 2026-01-09 23:30
**配置者**: Claude Sonnet 4.5 + Kenny Yen
