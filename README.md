Routeros路由器，wan1连接公网出口，wan2连接freebsd，lan负责局域网。  ros和bsd可以使用esxi放在一个机器，使用虚拟交换机连接。
Freebsd连接:两个网线，一个连接ros wan2，一个连接到ros lan侧（是bsd的默认路由）
Freebsd配置: 开启代理软件xray-core，监听socks代理端口(可以只用v4/v6连接服务器，服务器只要支持v6，他就可以处理v6，与连接方式无关)，使用tun2socks创建tun接口，开启fib路由表，fib1路由表设置默认路由指向tun接口(tun接口和wan2口都需要手动配置静态ipv4 ipv6地址)pf防火墙配置规则，wan2进来的流量有fib1路由表。流量封装完成，会通过lan再次来到ros，从wan1出去。
Routeros配置:  
正常上网:拨号，配置内网ip，配置dhcp地址池，只有wab1 nat配置masauerade规则。（wan2不动，ros做三层透明转发）
代理部分:
ip dns static 配置外网域名（收集了两千多个，只需要配置一级域名并勾选匹配subdomain，能覆盖百分之九十五的访问需求这个域名清单是分流核心，需要自己维护），配置FWD类型，转发到1.1.1.1，配置加入一个自己命名的addresslist，ipv4 ipv6分别配置防火墙mangle规则，在自己命名的那个addresslist里的地址，打上routingmark。ipv4 ipv6路由表分别配置  带那个routingmark的流量走下一跳wan2出口。然后配置静态路由，1.1.1.1要走wan2。开启dns服务器，允许内网设备连接，上游设置成和fwd转发不一样的公共dns地址（设置成一样会导致所有dns查询都走代理）。 dhcp要设置所有设备dns服务器是routeros(这是核心)

Ipv6需要特殊处理，如果光猫非桥接模式，可以关闭光猫ra,开启dhcpv6(方便ros拿前缀，根据规范，只有路由器之间才可以不经过ra直接通过dhcp拿公网前缀) 配置pool,前缀长度64，Address下用pool的地址前缀开ra 如果遇到微信 抖音 转圈问题，大概率是mtu问题，可以适当改小ipv6 mtu。

tiktok由于超时机制比较激进，跨洋往返光dns查询就要700ms，因此在不使用fakeip的方案经常超时造成无法加载，必须使用ros的dns缓存同时打开addresslist缓存，方可解决问题。

去程路径:终端发起请求（如google ig）->ros命中代理->交给wan2-> xray加密隧道封装->lan给ros,wan1出网
回程:vps返回数据经过wan1 ros给bsd->bsd解封装->交给原始设备（重点 路径不对称，原始发起请求的设备ip(v4 v6)和bsd lan在同一个广播域，所以会通过lan直接返回数据，不再次经过ros，终端抓包可以抓到去程回程的mac地址不是一个设备，正常现象）

此方法没有使用fakeip，终端获取到的是真实ip，但无法支持doh，必须使用明文udp53，telegram等ip直连软件需要额外配置静态路由分流，此方案优势在于彻底 透明，弊端在于需要手动维护域名列表，ipv6原生支持，绝对稳定 透明 客户端零配置
