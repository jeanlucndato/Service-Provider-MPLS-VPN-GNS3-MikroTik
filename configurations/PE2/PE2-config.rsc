# =====================================================================
# PE2 - Provider Edge (RouterOS v7.25) - Lab MikroTik ISP MPLS VPN
# Loopback : 10.255.0.34/32      AS : 65000      Voisin cœur : P2
#
# Etat de validation :
#   [OK]  adressage + LDP PE2 <-> P2 (voisin OPERATIONAL, transport 10.255.0.34)
#   [?]   OSPF  : reconstitué, à comparer avec /routing/ospf export
#   [?]   BGP / filtres : syntaxe à valider, session iBGP pas encore ESTABLISHED
#   [-]   VRF client (RD / route-targets) : pas encore fait
# A importer sur un routeur vierge : /import file-name=PE2-config.rsc
# =====================================================================

/system identity set name=PE2

# --- 1. Interfaces et adressage -------------------------------------
/interface bridge add name=loopback
/ip address add address=10.255.0.34/32 interface=loopback network=10.255.0.34
/ip address add address=10.10.10.34/30 interface=ether11 network=10.10.10.32 comment=P2

# --- 2. OSPF (reconstitué : instance CORE-OSPF, aire BACKBONE) -------
/routing ospf instance add name=CORE-OSPF router-id=10.255.0.34
/routing ospf area add name=BACKBONE area-id=0.0.0.0 instance=CORE-OSPF
/routing ospf interface-template add area=BACKBONE interfaces=ether11 type=ptp
/routing ospf interface-template add area=BACKBONE interfaces=loopback passive

# --- 3. MPLS / LDP ---------------------------------------------------
# Le transport-address doit être égal au LSR-ID (la loopback de PE2).
/mpls ldp add lsr-id=10.255.0.34 transport-addresses=10.255.0.34
# Seule l'interface vers P2 : pas besoin de "interface=all".
/mpls ldp interface add interface=ether11

# --- 4. Filtres BGP VPNv4 (route-target 65000:100) -------------------
/routing filter community-ext-list
add list=VPN-RT-OK communities=rt:65000:100

/routing filter rule
add chain=VPNV4-IN  rule="if (afi vpnv4 && bgp-ext-communities any-list VPN-RT-OK) { accept; }"
add chain=VPNV4-IN  rule="reject;"
add chain=VPNV4-OUT rule="if (afi vpnv4) { accept; }"
add chain=VPNV4-OUT rule="reject;"

# --- 5. iBGP VPNv4 vers PE1 (loopback 10.255.0.26) -------------------
# En v7.25, le router-id se règle sur l'instance, pas sur le template.
/routing bgp instance add name=default as=65000 router-id=10.255.0.34

/routing bgp template add name=PE2-IBGP as=65000 afi=vpnv4 \
    input.filter=VPNV4-IN output.filter-chain=VPNV4-OUT

# Une seule connexion (attention aux doublons si la commande est relancée).
/routing bgp connection add name=PE2-to-PE1 instance=default \
    remote.address=10.255.0.26 local.address=10.255.0.34 \
    local.role=ibgp templates=PE2-IBGP

# --- 6. A FAIRE : VRF client ----------------------------------------
# /ip vrf, route-distinguisher et route-targets 65000:100 (import/export)
# a ajouter une fois la session iBGP ESTABLISHED.
