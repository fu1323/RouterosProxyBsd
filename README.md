拓补如图，Routeros路由器，Lan1连接公网出口，Lan2连接freebsd，lan负责局域网。 ros和bsd可以使用ESxi
虚拟化放在一个机器，使用虚拟交换机连接。freebsd连接两个网线，一个连接Ros wan2，一个连接到Ros lan侧（是bsd的默认路由）

BSD部分： 使用Tun2socks创建Tun接口，开启Fib路由表，Fib1路由表设置默认路由指向Tun接口,tun接口和Lan2口都需要手动配置静态Ipv4 ipv6地址pf防火墙配置规则，lan2进来的流量走fib1路由表。流量封装完成，会通过lan再次来到ros，从Wan1出去。
xray客户端连接美国vps，并把socks映射成tun0接口，pf配置规则
pass in quick on $ext_if from any to any rtable $fibid keep state
表里默认路由走tun0。
pf还要阻止icmp进入tun0,否则会影响邻居发现，造成ros wan2 ipv6找不到下一跳bsd的mac地址,从而wan2 ipv6瘫痪(重要!重要!重要!)
（到vps的请求走lan1，因为会走默认的fibO的默认路由），（以上配置启动脚本，开机按顺序启动，托管给rc）

ROS代理部分：
正常上网拨号，配置内网Ip，配置Dhcp地址池，Nat配置Masauerade规则。
ip dns static 配置外网域名（收集了两千多个，只需要配置一级域名并勾选匹配Subdomain，能覆盖百分之九十五的访问需求这个域名清单是分流核心，需要自己维护），配置WD类型，转发到1.1.1.1，配置加入一个自己命名的addresslist，
iPv4 ipv6分别配置防火墙Mangle规则，在自己命名的那个Addresslist
里的地址，打上Routingmark。Ipv4 ipv6路由表分别配置 带那个Routingmark的流量走下一跳Wan2出口。然后配置静态路由，1.1.1.1要走Wan2。开启dns服务器，允许内网设备连接，上游设置成不一样的公共dns地址（如223.5.5.5 设置成一样会导致所有dns查询都走代理）。dhcp要设置所有设备dns服务器是Routeros(这是核心Ipv6需要特殊处理，如果光猫非桥接模式，可以关闭光猫Ra,开启Dhcpv6(方便ros拿地址，根据规范，只有路由器之间才可以不经过ra直接通过dhcpv6拿地址 前缀配置Nat66，Ra通告分配Fd00地址

（方法不唯一，根据拓补灵活调整，总之必须让ipv6流量出口经过ros）如果遇到微信抖音转圈问题，大概率是mtu问题，可以适当改小ipv6 mtu。Tiktok由于超时机制比较激进，跨洋往返光ns查询就要700ms，因此在不使用fakeip的方案经常超时造成无法加载，必须使用ros的dns缓存同时打开Addresslist缓存，方可解决问题。

此方法没有使用fakeip，将分流借助dns从应用层下放到三层策略路由,终端获取到的是真实Ip，但无法支持Doh，必须使用明文Udp53，Telegram等ip直连软件需要额外配置静态路由分流，此方案优势在于彻底透明,ipv6代理支持，弊端在于需要手动维护域名列表，复杂环境还会Nat破坏pv6 一对一特性，但是绝对稳定透明客户端零配置。若想去掉nat66，需要运营商分配大于/64的ipv6前缀，一个给wan1，一个给wan2，而且还要考虑前缀变动，或用dhcpv6拿前缀）
直连下 路径: lan-ros wan1 出去，当命中分流逻辑，ikuai判定需要代理时，路径变成lan-wan2-freebsd-lan-wan1 (bsd内部见图)

(freebsd可换成Linux,思路不变)
原创 by fu1323
![pdf.png](https://raw.githubusercontent.com/fu1323/ikuaiSoftroutergfw/main/989.png)
