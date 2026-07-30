# RouterOS + FreeBSD 全透明代理方案

> 基于 **RouterOS + FreeBSD + Xray-core + tun2socks** 的家庭网络透明代理方案，支持 **IPv4 / IPv6 原生双栈**，客户端零配置，不使用 FakeIP。

**作者：fu1323**

---
## 分流域名列表(rsc脚本) 持续维护中(参考了社区公开gfw屏蔽列表并完善)
已完整支持:
google全家桶 github openai claude Meta全家桶(threads fb ig等)
      X(推，grok) 维基百科 Tiktok(针对美区) reddit discord twitch
      Pinterest Quora telegram(需用静态ip进行分流)
-邮箱服务
GMX protonmail naver aol yahoo 等等
-网盘服务
mega.nz  terabox pikpak dropbox 等等
-主流媒体
彭博社 路透社 法新社 cna voa bbc 和台湾媒体 电视台 等等
-(针对外服游戏平台欠缺优化，因本人不玩游戏 欢迎补充)
## ✨ 特点

- ✅ 内网设备零配置
- ✅ IPv4 / IPv6 原生支持
- ✅ RouterOS DNS 分流
- ✅ FreeBSD 独立代理节点
- ✅ Xray-core + tun2socks
- ✅ Reality / VLESS 等协议
- ✅ 不使用 FakeIP
- ✅ 路由与代理解耦
- ✅ 支持虚拟化部署（ESXi、Proxmox、Hyper-V 等）

---
# 拓补图

![拓扑图](https://github.com/fu1323/ikuaiSoftroutergfw/blob/main/拓补图.png?raw=true)

---

# 网络拓扑

```text
                 Internet
                     │
                WAN1（公网）
                     │
              ┌────────────┐
              │ RouterOS   │
              │            │
LAN──────────▶│            │
              │            │
              └─────┬──────┘
                    │WAN2
                    │
          ┌─────────────────┐
          │    FreeBSD       │
          │                  │
          │ xray-core        │
          │ tun2socks        │
          │ PF + FIB         │
          └────────┬─────────┘
                   │
              返回 RouterOS LAN
```

RouterOS 负责：

- PPPoE
- DHCP
- DNS
- 域名分流
- 策略路由

FreeBSD 负责：

- Xray-core
- tun2socks
- FIB
- PF 防火墙
- 数据封装与解封装

两者职责分离，互不影响。

---

# 工作原理

客户端访问 Google 为例：

```
终端
↓

RouterOS

↓

DNS 查询

↓

命中代理域名

↓

Address List

↓

Mangle 打 Routing Mark

↓

WAN2

↓

FreeBSD

↓

tun2socks

↓

Xray-core

↓

VPS

↓

Internet
```

整个过程中：

- RouterOS 不负责代理
- FreeBSD 不负责 DNS
- 各司其职

---
# 补充一下底层原理
```
Google TCP4️⃣

↓

Xray Server

↓

VLESS 3️⃣

↓

Xray Client

↓

SOCKS2️⃣(CONNECT Google的真实ip:443)

↓

tun2socks

↓

重新生成

↓

TCP1️⃣

↓

客户端
```
可见 其实一共有四个独立的tcp连接，所以客户端认为自己在和google握手，其实这个tcp连接在tun2socks就已经终止了(tun2socks内部自己维护了独立于操作系统的tcp状态机)
 这也是路径不对称  ,连接跟踪 都不会乱套的根本原因 
(这也是代理工具去Xray sniff根据sni探测分流的原理，因为客户端tcp实际终止在xray，xray自然就可以先让客户端tcp握手完成，回个syn+ack之后根据tls握手的sni来决定是否代理，一旦需要，服务端和google建立的tcp连接是全新独立的一个
也因此，sniff功能并不强制要求fakeip，fakeip只是方便 简化配置的手段之一)

# 部署环境

推荐部署：

```
ESXi

├── RouterOS VM
└── FreeBSD VM
```

二者通过虚拟交换机连接即可。

当然也可以：

- RouterOS 物理机
- FreeBSD 物理机

原理一致。

---

# RouterOS 配置

## 1. 基础网络

正常配置：

- PPPoE 拨号
- LAN
- DHCP
- NAT

**注意：**

只有 WAN1 做 ipv4 Masquerade。

WAN2 不做 NAT，仅作为透明转发出口。

---

## 2. DNS

开启 RouterOS DNS Server。

DHCP 下发：

```
DNS = RouterOS
```

这是整个方案最核心的一步。

所有终端 DNS 必须交给 RouterOS。

---

## 3. Static DNS

对于需要代理的域名：

```
Type：FWD
```

转发：

```
1.1.1.1
```

同时：

加入自定义 Address List。

建议：

仅维护一级域名，并勾选：

```
Match Subdomain
```

目前约两千多个域名即可覆盖绝大部分访问需求。(不定期维护中)

域名列表就是整个方案的核心。

---

## 4. Mangle

IPv4

```
Address List
↓

Routing Mark
```

IPv6

同样配置。

---

## 5. Route

建立新的 Routing Table：

IPv4：

```
Routing Mark

↓

Next Hop

↓

WAN2
```

IPv6 同理。

---

## 6. 静态路由

需要保证：

```
1.1.1.1

↓

WAN2
```

否则 DNS Forward 将无法工作。

另外：

RouterOS 自己的上游 DNS 不建议与 FWD 使用同一个服务器。

否则：

所有 DNS 查询都会走代理。

---

# FreeBSD 配置

建议两块网卡：

```
NIC1

↓

连接 RouterOS WAN2

NIC2

↓

连接 RouterOS LAN
```

其中：

LAN 网卡作为默认路由。

---

## 安装

需要：

- xray-core
- tun2socks

---

## 网络

tun 接口与 WAN2：

均建议配置：

- IPv4
- IPv6

静态地址。

---

## FIB

开启多个 FIB。

例如：

```
fib1
```

默认路由：

```
fib1

↓

tun0
```

---

## PF

PF 负责：

来自 WAN2 的流量：

```
↓

setfib 1

↓

进入 tun
```

随后：

tun2socks

↓

Xray

↓

VPS

完成封装。

---

# IPv6 配置

本方案支持 IPv6 原生代理。

## 光猫

推荐：

关闭 RA

开启 DHCPv6。

这样 RouterOS 可以直接获取公网前缀。

---

## Prefix

配置：

```
Pool

Prefix Length = 64
```

随后：

Address

使用 Pool。

开启：

RA。

---

## MTU

这是 IPv6 最容易踩坑的地方。

由于：

tun2socks

本质上：

```
IP

↓

TCP / UDP

↓

SOCKS
```

不会转发 ICMP Packet Too Big。

因此：

PMTU 无法正常工作。

最终表现：

- 微信转圈
- 抖音转圈
- 部分网站打不开

---

## 推荐解决方案

两种方式：

### 方法一

降低 IPv6 MTU。

例如：

```
1420
```

根据实际链路调整。

---

### 方法二（推荐）

RouterOS：

Firewall

↓

Mangle

↓

TCP SYN

↓

Change MSS

限制 MSS。

这样可以彻底避免 PMTU 黑洞。

---

# TikTok 无法加载

TikTok 超时机制较激进。

跨洋访问：

DNS 查询往返时间可能达到：

700ms 左右。

如果不使用 FakeIP：

容易因为 DNS 超时导致：

无法加载。

解决方案：

- 开启 RouterOS DNS Cache
- 开启 Address List Cache

即可恢复正常。

---

# 数据流向

## 去程

```
客户端

↓

RouterOS

↓

命中代理

↓

WAN2

↓

FreeBSD

↓

tun2socks

↓

Xray

↓

VPS

↓

Internet
```

---

## 回程

```
Internet

↓

VPS

↓

WAN1

↓

RouterOS

↓

FreeBSD

↓

解封装

↓

客户端
```

注意：

这是**非对称路由**。

客户端抓包时：

去程和回程：

MAC 地址不同属于正常现象。

因为：

客户端与 FreeBSD LAN 处于同一广播域。

回程不会再次经过 RouterOS 转发。

---

# 为什么不用 FakeIP？

本方案完全不使用 FakeIP。

优点：

- 终端获得真实 IP
- 排查网络问题简单
- DNS 行为更符合真实网络
- IPv6 支持更自然

缺点：

- 不支持 DoH 分流
- 必须使用 UDP 53
- Telegram 等 IP 直连软件需要额外配置静态路由
- 需要维护域名列表

---

# 为什么选择 RouterOS + FreeBSD？

传统透明代理：

```
OpenWrt

↓

路由

↓

代理

↓

DNS
```

全部集中在一个系统。

本方案：

RouterOS：

- 路由
- DHCP
- DNS
- 策略路由

FreeBSD：

- Xray
- tun2socks
- PF
- FIB

系统职责分离。

优点：

- 更稳定
- 更容易维护
- 更容易排查故障
- 升级互不影响

---

# 优缺点

## 优点

- 客户端零配置
- IPv4 / IPv6 原生支持
- RouterOS 性能优秀
- FreeBSD 稳定
- 不依赖 FakeIP
- 网络结构清晰
- 完全透明

## 缺点

- 需要维护域名列表
- 不支持 DoH 分流
- Telegram 等 IP 直连软件需额外处理
- 首次部署配置较复杂

---

# 测试
- 域名清单添加了test-ipv6.com,配置成功之后内网设备用浏览器打开test-ipv6.com

观察到返回的ipv6 ipv4地址均为vps的，非本机地址，即配置成功

---
此方案要求vps需要具备ipv6访问能力，若服务端只有ipv4，可用tunnelbroke配置6in4（免费）来实现

提示: tunnelbroke注册比较麻烦，常用邮箱会被拒绝，推荐自己域名邮箱（嫌麻烦就注册域名之后托管给腾讯企业邮）

# License

MIT License  <br>
(p.s. 关于那个非对称的路径，并非设计之处本意，是去掉初版使用的nat66之后  
由于直连路由优先级最高而自然形成的，经过判断没有副作用，故留了下来，顺便将ipv4  
改成统一，若有复杂需求，比如涉及防火墙 连接跟踪，无法接受路径不对称，可用pf防火墙reply-to规则掰成对称)  
欢迎交流与改进。  <br>
方案原创，底层部分，配置文件和部分深入分析有chatgpt功劳  
感谢Chatgpt帮忙整理Readme.md