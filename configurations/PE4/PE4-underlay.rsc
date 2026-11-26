# ------------------------------------------------------------------
# MikroTik ISP MPLS VPN lab - PE4
# Step: extend OSPF + MPLS/LDP to PE4
# Uplink: ether12 (10.10.10.38/30) <-> P4 ether15 (10.10.10.37/30)
# RouterOS v7.x (tested on 7.23.8)
# ------------------------------------------------------------------

# 1. Loopback (router-id and LDP LSR-ID) and uplink addressing
/interface bridge add name=loopback
/ip address add address=10.10.10.38/30 interface=ether12 comment=P4
/ip address add address=10.255.0.38/32 interface=loopback network=10.255.0.38 comment="PE4 loopback / LSR-ID"

# 2. OSPF (same instance, area and broadcast network type as the rest of the core)
/routing ospf instance add name=CORE-OSPF version=2 router-id=10.255.0.38
/routing ospf area add name=BACKBONE area-id=0.0.0.0 instance=CORE-OSPF
/routing ospf interface-template add area=BACKBONE networks=10.10.10.36/30
/routing ospf interface-template add area=BACKBONE networks=10.255.0.38/32 passive

# 3. MPLS LDP (session between loopbacks)
/mpls ldp add lsr-id=10.255.0.38 transport-addresses=10.255.0.38
/mpls ldp interface add interface=ether12
/mpls ldp interface add interface=loopback

# ------------------------------------------------------------------
# Verification (run manually)
# ------------------------------------------------------------------
# /routing ospf interface print         (loopback must be state=passive)
# /routing ospf neighbor print          (10.10.10.37 Full)
# /mpls ldp neighbor print              (P4 with the O flag)
# /ping 10.255.0.26 src-address=10.255.0.38 count=3
# /ping 10.255.0.34 src-address=10.255.0.38 count=3
