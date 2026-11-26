# ------------------------------------------------------------------
# MikroTik ISP MPLS VPN lab - P4
# Step: extend OSPF + MPLS/LDP to PE4
# Link: ether15 (10.10.10.37/30) <-> PE4 ether12 (10.10.10.38/30)
# RouterOS v7.x (tested on 7.23.8)
# ------------------------------------------------------------------

# OSPF: advertise and form an adjacency on the PE4 link
/routing ospf interface-template add area=BACKBONE networks=10.10.10.36/30

# LDP: enable label distribution towards PE4
/mpls ldp interface add interface=ether15

# ------------------------------------------------------------------
# Verification (run manually)
# ------------------------------------------------------------------
# /routing ospf neighbor print          (PE4 router-id 10.255.0.38 Full)
# /ip route print where dst-address=10.255.0.38/32
# /mpls ldp neighbor print              (10.255.0.38 with the O flag)
