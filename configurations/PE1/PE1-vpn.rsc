# ======================================================================
# PE1 - L3VPN / MP-BGP VPNv4 configuration (delta)
# Lab    : MikroTik ISP MPLS VPN (GNS3)
# Router : PE1 | RouterOS 7.23.8 | Loopback 10.255.0.26/32 | AS 65000
# Peer   : PE2 (10.255.0.34) over iBGP, address family VPNv4
# Apply  : /import file-name=PE1-vpn.rsc
# Every block checks first, so the file can be imported more than once.
# ======================================================================


# ----------------------------------------------------------------------
# 1. Loopback address
# The connected route must be 10.255.0.26/32 (NETWORK = the address itself).
# A wrong NETWORK value meant LDP created no local label for this loopback,
# so P1 had no forwarding entry and dropped labelled packets from P2.
# ----------------------------------------------------------------------
:if ([:len [/ip address find where address="10.255.0.26/32" and network=10.255.0.26]] = 0) do={
    :do { /ip address remove [find where address="10.255.0.26/32"] } on-error={}
    /ip address add address=10.255.0.26/32 interface=loopback comment="PE1 loopback"
}


# ----------------------------------------------------------------------
# 2. LDP on the loopback interface
# PE1 loopback interface is named "loopback" (the P routers use lo0).
# Required so PE1 advertises a label for its own /32.
# ----------------------------------------------------------------------
:if ([:len [/mpls ldp interface find where interface=loopback]] = 0) do={
    /mpls ldp interface add interface=loopback
}


# ----------------------------------------------------------------------
# 3. iBGP session to PE2 carries VPNv4
# Without afi=vpnv4 the session was Established but only IPv4 was
# negotiated, so no VPN route could be exchanged.
# ----------------------------------------------------------------------
/routing bgp connection set [find where name="PE1-to-PE2"] afi=vpnv4


# ----------------------------------------------------------------------
# 4. VRF CUST-A (RD 65000:100, RT 65000:100)
# br-custA is an empty bridge that acts as the customer LAN, so the
# connected route stays active without a physical CE.
# ----------------------------------------------------------------------
:if ([:len [/interface bridge find where name="br-custA"]] = 0) do={
    /interface bridge add name=br-custA comment="CUST-A virtual LAN (lab)"
}

:if ([:len [/ip address find where address="192.168.10.1/24"]] = 0) do={
    /ip address add address=192.168.10.1/24 interface=br-custA
}

:if ([:len [/ip vrf find where name="CUST-A"]] = 0) do={
    /ip vrf add name=CUST-A interfaces=br-custA
}

:if ([:len [/routing bgp vpn find where vrf="CUST-A"]] = 0) do={
    /routing bgp vpn add vrf=CUST-A route-distinguisher=65000:100 import.route-targets=65000:100 export.route-targets=65000:100 label-allocation-policy=per-vrf export.redistribute=connected
}


# ----------------------------------------------------------------------
# 5. Verification (run by hand, not part of the import)
# ----------------------------------------------------------------------
# /routing bgp session print                  -> E, local and remote .afi=vpnv4
# /ip route print where routing-table=CUST-A  -> 192.168.20.0/24 with flag y
# /ping 192.168.20.1 vrf=CUST-A src-address=192.168.10.1 count=3


# ----------------------------------------------------------------------
# 6. OPTIONAL - second customer VRF CUST-B (isolation test)
# Not applied yet. Uncomment the lines to use it.
# The existing VPNV4-IN filter only accepts 65000:100 through the
# extended community list VPN-RT-OK, so 65000:200 must be allowed first.
# Check the syntax with: /routing filter community-ext-list print
# ----------------------------------------------------------------------
# /routing filter community-ext-list add list=VPN-RT-OK communities=rt:65000:200
# /interface bridge add name=br-custB comment="CUST-B virtual LAN (lab)"
# /ip address add address=192.168.30.1/24 interface=br-custB
# /ip vrf add name=CUST-B interfaces=br-custB
# /routing bgp vpn add vrf=CUST-B route-distinguisher=65000:200 import.route-targets=65000:200 export.route-targets=65000:200 label-allocation-policy=per-vrf export.redistribute=connected
#
# Expected: ping to 192.168.40.1 works inside CUST-B, ping to 192.168.20.1
# from CUST-B fails (no route), and the CUST-A / CUST-B tables stay separate.
