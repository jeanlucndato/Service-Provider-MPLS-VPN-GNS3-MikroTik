# =====================================================================
# PE1 - Provider Edge (RouterOS v7.25) - Lab MikroTik ISP MPLS VPN
# Loopback : 10.255.0.26/32      AS : 65000      Voisin cœur : P1
#
# Etat de validation :
#   [?]   adressage : repris de la description du lab, à comparer avec /ip address print
#   [?]   OSPF  : reconstitué, à comparer avec /routing/ospf export
#   [?]   LDP PE1 <-> P1 : pas encore vérifié (suspect dans le test PE2 -> PE1)
#   [?]   BGP / filtres : syntaxe à valider, session iBGP pas encore ESTABLISHED
#   [-]   VRF client (RD / route-targets) : pas encore fait
# A importer sur un routeur vierge : /import file-name=PE1-config.rsc
# =====================================================================

/system identity set name=PE1

# --- 1. Interfaces et adressage -------------------------------------
# La loopback de PE1 est 10.255.0.26 (10.255.0.1 est déjà prise par P1).
/interface bridge add name=loopback
/ip address add address=10.255.0.26/32 interface=loopback network=10.255.0.26
/ip address add address=10.10.10.26/30 interface=ether11 network=10.10.10.24 comment=P1

# --- 2. OSPF (reconstitué : instance CORE-OSPF, aire BACKBONE) -------
/routing ospf instance add name=CORE-OSPF router-id=10.255.0.26
/routing ospf area add name=BACKBONE area-id=0.0.0.0 instance=CORE-OSPF
/routing ospf interface-template add area=BACKBONE interfaces=ether11 type=ptp
/routing ospf interface-template add area=BACKBONE interfaces=loopback passive

# --- 3. MPLS / LDP ---------------------------------------------------
# Le transport-address doit être égal au LSR-ID (la loopback de PE1),
# et non 10.255.0.1 qui est la loopback de P1.
/mpls ldp add lsr-id=10.255.0.26 transport-addresses=10.255.0.26
/mpls ldp interface add interface=ether11

# --- 4. Filtres BGP VPNv4 (route-target 65000:100) -------------------
/routing filter community-ext-list
add list=VPN-RT-OK communities=rt:65000:100

/routing filter rule
add chain=VPNV4-IN  rule="if (afi vpnv4 && bgp-ext-communities any-list VPN-RT-OK) { accept; }"
add chain=VPNV4-IN  rule="reject;"
add chain=VPNV4-OUT rule="if (afi vpnv4) { accept; }"
add chain=VPNV4-OUT rule="reject;"

# --- 5. iBGP VPNv4 vers PE2 (loopback 10.255.0.34) -------------------
# En v7.25, le router-id se règle sur l'instance, pas sur le template.
/routing bgp instance add name=default as=65000 router-id=10.255.0.26

/routing bgp template add name=PE-IBGP as=65000 afi=vpnv4 \
    input.filter=VPNV4-IN output.filter-chain=VPNV4-OUT

# Une seule connexion (attention aux doublons si la commande est relancée).
/routing bgp connection add name=PE1-to-PE2 instance=default \
    remote.address=10.255.0.34 local.address=10.255.0.26 \
    local.role=ibgp templates=PE-IBGP

# --- 6. A FAIRE : VRF client ----------------------------------------
# /ip vrf, route-distinguisher et route-targets 65000:100 (import/export)
# a ajouter une fois la session iBGP ESTABLISHED.
