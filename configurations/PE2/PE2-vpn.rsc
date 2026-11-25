# ======================================================================
# PE2 - L3VPN / MP-BGP VPNv4 configuration (delta)
# Lab    : MikroTik ISP MPLS VPN (GNS3)
# Router : PE2 | RouterOS 7.23.8 | Loopback 10.255.0.34/32 | AS 65000
# Peer   : PE1 (10.255.0.26) over iBGP, address family VPNv4
# Apply  : /import file-name=PE2-vpn.rsc
# Every block checks first, so the file can be imported more than once.
# ======================================================================


# ----------------------------------------------------------------------
# 1. iBGP session to PE1 (already in place, shown for reference)
# Connection PE2-to-PE1 uses template PE2-IBGP with afi=vpnv4 and the
# filter chains VPNV4-OUT (output) and VPNV4-IN (input).
# A duplicate PE2-to-PE1 entry existed during testing; keep only one.
# ----------------------------------------------------------------------
# /routing bgp connection print


# ----------------------------------------------------------------------
# 2. VRF CUST-A (RD 65000:100, RT 65000:100)
# br-custA is an empty bridge that acts as the customer LAN, so the
# connected route stays active without a physical CE.
# ----------------------------------------------------------------------
:if ([:len [/interface bridge find where name="br-custA"]] = 0) do={
    /interface bridge add name=br-custA comment="CUST-A virtual LAN (lab)"
}

:if ([:len [/ip address find where address="192.168.20.1/24"]] = 0) do={
    /ip address add address=192.168.20.1/24 interface=br-custA
}

:if ([:len [/ip vrf find where name="CUST-A"]] = 0) do={
    /ip vrf add name=CUST-A interfaces=br-custA
}

:if ([:len [/routing bgp vpn find where vrf="CUST-A"]] = 0) do={
    /routing bgp vpn add vrf=CUST-A route-distinguisher=65000:100 import.route-targets=65000:100 export.route-targets=65000:100 label-allocation-policy=per-vrf export.redistribute=connected
}


# ----------------------------------------------------------------------
# 3. Verification (run by hand, not part of the import)
# ----------------------------------------------------------------------
# /routing bgp session print                  -> E, local and remote .afi=vpnv4
# /ip route print where routing-table=CUST-A  -> 192.168.10.0/24 with flag y
# /ping 192.168.10.1 vrf=CUST-A src-address=192.168.20.1 count=3


# ----------------------------------------------------------------------
# 4. OPTIONAL - second customer VRF CUST-B (isolation test)
# Not applied yet. Uncomment the lines to use it.
# The existing VPNV4-IN filter only accepts 65000:100 through the
# extended community list VPN-RT-OK, so 65000:200 must be allowed first.
# Check the syntax with: /routing filter community-ext-list print
# ----------------------------------------------------------------------
# /routing filter community-ext-list add list=VPN-RT-OK communities=rt:65000:200
# /interface bridge add name=br-custB comment="CUST-B virtual LAN (lab)"
# /ip address add address=192.168.40.1/24 interface=br-custB
# /ip vrf add name=CUST-B interfaces=br-custB
# /routing bgp vpn add vrf=CUST-B route-distinguisher=65000:200 import.route-targets=65000:200 export.route-targets=65000:200 label-allocation-policy=per-vrf export.redistribute=connected
#
# Expected: ping to 192.168.30.1 works inside CUST-B, ping to 192.168.10.1
# from CUST-B fails (no route), and the CUST-A / CUST-B tables stay separate.
