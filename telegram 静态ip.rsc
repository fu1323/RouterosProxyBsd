# 2026-07-29 10:32:39 by RouterOS 7.23.2

#

/ip route

add disabled=no distance=1 dst-address=91.108.4.0/22 gateway=172.20.20.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=91.108.8.0/22 gateway=172.20.20.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=91.108.12.0/22 gateway=172.20.20.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=91.108.16.0/22 gateway=172.20.20.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=91.108.56.0/22 gateway=172.20.20.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no dst-address=149.154.164.0/22 gateway=172.20.20.1 \
    routing-table=main
add disabled=no distance=1 dst-address=149.154.160.0/22 gateway=172.20.20.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no dst-address=149.154.168.0/22 gateway=172.20.20.1 \
    routing-table=main
add disabled=no dst-address=149.154.172.0/22 gateway=172.20.20.1 \
    routing-table=main
add disabled=no dst-address=95.161.64.0/20 gateway=172.20.20.1 routing-table=\
    main

#fd00:7878::1为bsd手动绑定的ip,因公网地址和fe80地址会变,故手动配了个fd开头的地址
/ipv6 route
add disabled=no dst-address=2a0a:f280::/32 gateway=fd00:7878::1@main \
    pref-src="" routing-table=main
add disabled=no distance=1 dst-address=2001:67c:4e8::/48 gateway=fd00:7878::1 \
    pref-src="" routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=2001:b28:f23f::/48 gateway=\
    fd00:7878::1 pref-src="" routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=2001:b28:f23d::/48 gateway=\
    fd00:7878::1 pref-src="" routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=2001:b28:f23c::/48 gateway=\
    fd00:7878::1 pref-src="" routing-table=main scope=30 target-scope=10