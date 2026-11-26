# ------------------------------------------------------------------
# MikroTik ISP MPLS VPN lab - PE2
# Step: customer isolation test with a second VRF (CUST-B)
# RouterOS v7.x (tested on 7.23.8)
# ------------------------------------------------------------------

# 1. Accept the CUST-B route-target in the VPNv4 filters
#    (add only if rt:65000:200 is not already in the list;
#     the list must end up with exactly two entries: 65000:100 and 65000:200)
/routing filter community-ext-list add list=VPN-RT-OK communities=rt:65000:200

# 2. CUST-B customer-facing bridge and addressing
/interface bridge add name=br-custB
/ip address add address=192.168.40.1/24 interface=br-custB comment="CUST-B site (PE2)"

# 3. VRF CUST-B
/ip vrf add name=CUST-B interfaces=br-custB

# 4. BGP VPNv4 import/export for CUST-B (RD and RT 65000:200)
/routing bgp vpn add vrf=CUST-B route-distinguisher=65000:200 \
    import.route-targets=65000:200 export.route-targets=65000:200 \
    export.redistribute=connected label-allocation-policy=per-vrf

# ------------------------------------------------------------------
# Verification (run manually)
# ------------------------------------------------------------------
# /ip route print where routing-table=CUST-B
# /ping 192.168.30.1 vrf=CUST-B src-address=192.168.40.1 count=3
# Isolation (must fail, no route):
# /ping 192.168.10.1 vrf=CUST-B src-address=192.168.40.1 count=3
# /ping 192.168.30.1 vrf=CUST-A src-address=192.168.20.1 count=3
