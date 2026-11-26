# MikroTik ISP MPLS VPN Infrastructure
 
![RouterOS](https://img.shields.io/badge/RouterOS-v7-blue)
![GNS3](https://img.shields.io/badge/Lab-GNS3-orange)
![MPLS](https://img.shields.io/badge/MPLS-L3VPN-green)
![Status](https://img.shields.io/badge/Status-In%20progress-yellow)
 
An ISP-style backbone built on **MikroTik CHR (RouterOS v7)** in **GNS3**. It delivers isolated Layer 3 VPN services to enterprise customers over a shared MPLS core, using OSPF, LDP, MP-BGP VPNv4, VRFs and eBGP.
 
> **Lab project.** This is a staged lab, not a production configuration. Every step is verified with command output and documented.
 
**Current status (updated 2026-11-26):** the OSPF underlay, the MPLS/LDP transport and two L3VPN customer VRFs (`CUST-A` and `CUST-B` between PE1 and PE2, carried over MP-BGP VPNv4) are working and verified end to end, including isolation between the two customers. PE4 has joined the underlay (OSPF and LDP). Next steps are bringing PE3 into the underlay, completing the iBGP VPNv4 full mesh, adding VRFs on PE3 and PE4, and PE–CE eBGP.
 
---
 
## What this project demonstrates
 
| Capability | Evidence |
|---|---|
| Network design | Topology, addressing plan and design rationale |
| Underlay routing | OSPF adjacencies, loopback reachability, failover |
| MPLS transport | LDP neighbors, label mappings, forwarding table |
| L3VPN | VRFs, route distinguishers, route targets, VPNv4 route exchange |
| Customer routing | PE–CE eBGP and prefix filtering |
| Security | IPsec IKEv2 tunnel, firewall policy, customer isolation tests |
| Operations | Failure simulations and a troubleshooting log |
 
**Target outcome:** Customer A sites reach each other, Customer B sites reach each other, and A and B stay isolated by default.
 
---
 
## Topology
 
![GNS3 topology](docs/images/topology.png)
 
- **4 provider core routers (P1–P4)** connected in a full mesh
- **4 provider edge routers (PE1–PE4)**, each attached to one P router
- **1 NAT node** attached to P1 for external access
### Core and PE links
 
| Link | Subnet |
|---|---|
| P1 – P2 | 10.10.10.0/30 |
| P1 – P3 | 10.10.10.4/30 |
| P3 – P4 | 10.10.10.8/30 |
| P1 – P4 | 10.10.10.12/30 |
| P2 – P4 | 10.10.10.16/30 |
| P2 – P3 | 10.10.10.20/30 |
| PE1 – P1 | 10.10.10.24/30 |
| PE3 – P3 | 10.10.10.28/30 |
| PE2 – P2 | 10.10.10.32/30 |
| PE4 – P4 | 10.10.10.36/30 |
 
### Loopbacks (router ID, LSR-ID, BGP endpoint)
 
| Router | Loopback |
|---|---|
| P1 | 10.255.0.1/32 |
| P2 | 10.255.0.2/32 |
| P3 | 10.255.0.6/32 |
| P4 | 10.255.0.10/32 |
| PE1 | 10.255.0.26/32 |
| PE2 | 10.255.0.34/32 |
| PE3 | 10.255.0.30/32 _(planned, not configured yet)_ |
| PE4 | 10.255.0.38/32 |
 
### Planned customer design
 
| Customer | CE AS (planned) | Sites | RD / RT |
|---|---|---|---|
| Customer A | 65101 | 192.168.10.0/24, 192.168.20.0/24 | 65000:100 |
| Customer B | 65102 | 192.168.30.0/24, 192.168.40.0/24 | 65000:200 |
 
ISP AS: **65000**. PE–CE links use dedicated /30 subnets from 172.16.0.0/16. The RD and RT values are the ones configured in the lab.
 
### Implemented so far
 
#### Validation VRFs (`CUST-A` and `CUST-B`)
 
The first VRF, `CUST-A`, validates the L3VPN control plane and data plane between PE1 and PE2 before real CE routers are added. The customer LAN is simulated with an empty bridge (`br-custA`) inside the VRF, so the connected route stays active without a physical CE. The second VRF, `CUST-B`, repeats the same pattern with its own RD, RT and LAN (`br-custB`) to prove that two customers can share the same PE routers and core without seeing each other.
 
| Item | PE1 | PE2 |
|---|---|---|
| Loopback / iBGP endpoint | 10.255.0.26/32 | 10.255.0.34/32 |
| VRF `CUST-A`, RD / RT | 65000:100 | 65000:100 |
| `CUST-A` LAN (`br-custA`) | 192.168.10.1/24 | 192.168.20.1/24 |
| VRF `CUST-B`, RD / RT | 65000:200 | 65000:200 |
| `CUST-B` LAN (`br-custB`) | 192.168.30.1/24 | 192.168.40.1/24 |
 
#### PE4 joins the underlay
 
PE4 is attached to P4 and runs OSPF area 0 and LDP, using the same conventions as the other routers. VPNv4 sessions and VRFs on PE4 come next.
 
| Item | PE4 | P4 |
|---|---|---|
| Link | `ether12`, 10.10.10.38/30 | `ether15`, 10.10.10.37/30 |
| Loopback | 10.255.0.38/32 (`loopback`) | 10.255.0.10/32 (`lo0`) |
| OSPF | area 0, loopback passive | template added for 10.10.10.36/30 |
| LDP | LSR-ID 10.255.0.38, on `ether12` and `loopback` | `ether15` added to the LDP interfaces |
 
---
 
## Technologies
 
| Technology | Where | Purpose |
|---|---|---|
| OSPFv2 (area 0) | Provider core | Advertise loopbacks and core links |
| Loopback interfaces | All ISP routers | Stable router IDs and LDP/BGP endpoints |
| MPLS + LDP | Core-facing interfaces and loopbacks | Label-switched transport |
| MP-BGP VPNv4 (iBGP) | PE routers | Exchange customer VPN routes and VPN labels |
| VRF | PE routers | Separate routing table per customer |
| eBGP | PE–CE links | Exchange customer routes |
| IPsec IKEv2 | VPN endpoints | Encrypted site-to-site tunnel |
| VPLS, QoS, firewall | Edge and core | Layer 2 VPN, traffic policy, control-plane protection |
 
---
 
## Design notes
 
- **OSPF** advertises the /30 links and each loopback (passive). All templates use the default broadcast network type, so every new router must use the same type to form an adjacency. LDP and BGP use loopbacks so sessions survive a single link failure.
- **LDP** uses the loopback as LSR-ID and transport address. It runs on the core-facing interfaces and on the loopback itself, so every router advertises a label for its own /32. The loopback interface is named `lo0` on the P routers and `loopback` on the PE routers.
- **MP-BGP VPNv4** runs between PE routers (AS 65000), sourced from loopbacks, with the VPNv4 address family enabled explicitly on the connection (`afi=vpnv4`).
- **Route-target filtering:** the filter chains `VPNV4-IN` and `VPNV4-OUT` only accept route targets listed in the extended community list `VPN-RT-OK`. A new route target must be added to that list before a new VRF can exchange routes. The list currently holds `rt:65000:100` (CUST-A) and `rt:65000:200` (CUST-B), once each.
- **Customer isolation:** each customer has its own RD and RT. A VRF imports only the routes that carry its own route target, so `CUST-A` and `CUST-B` never see each other's prefixes, even though they share the same PE routers, the same OSPF/LDP core and the same iBGP session.
- **VPN data plane:** traffic between PEs carries two labels, the VPN label (per-VRF allocation) and the LDP transport label to the remote PE loopback.
- **MPLS L3VPN separates customers but does not encrypt traffic.** IPsec is added as a separate, complementary service for confidentiality and integrity.
---
 
## Roadmap
 
- [x] Topology and addressing plan
- [x] OSPF area 0 across the P core (adjacencies Full)
- [x] MPLS/LDP across the core and the PE1 and PE2 uplinks
- [x] MP-BGP VPNv4 iBGP session between PE1 and PE2
- [x] First customer VRF (`CUST-A`): VPNv4 route exchange and bidirectional ping across the MPLS core
- [x] Customer isolation test with a second VRF (`CUST-B`)
- [ ] Extend MPLS/LDP and VPNv4 to PE3 and PE4
  - [x] PE4: OSPF and LDP underlay
  - [ ] PE3: loopback, OSPF and LDP
  - [ ] iBGP VPNv4 full mesh between PE1, PE2, PE3 and PE4
  - [ ] Customer VRFs on PE3 and PE4
- [ ] PE–CE eBGP and end-to-end site reachability
- [ ] IPsec IKEv2 site-to-site tunnel
- [ ] VPLS, QoS and firewall policy
- [ ] Failure simulations, monitoring and final documentation
---
 
## Verification commands
 
```
/routing ospf neighbor print
/ip route print where dst-address~"10.255.0"
/mpls ldp neighbor print
/mpls ldp interface print
/mpls forwarding-table print
/routing bgp session print
/routing filter community-ext-list print
/ip vrf print
/routing bgp vpn print
/ip route print where routing-table=CUST-A
/ip route print where routing-table=CUST-B
/ping 192.168.20.1 vrf=CUST-A src-address=192.168.10.1 count=3
/ping 192.168.40.1 vrf=CUST-B src-address=192.168.30.1 count=3
/ip ipsec active-peers print
/ip ipsec installed-sa print
```
 
Verification outputs and screenshots are stored in `testing/` and `docs/images/`.
 
---
 
## Verified results
 
### VPNv4 session and VRF routes (PE1)
 
`/routing bgp session print` shows the session to PE2 (10.255.0.34) as Established, with the `vpnv4` address family on both the local and the remote side.
 
The VRF table on PE1 holds its own connected LAN and the remote LAN learned over BGP-MPLS-VPN (flag `y`, iBGP distance 200, next hop = PE2 loopback):
 
```
[admin@PE1] > /ip route print where routing-table=CUST-A
Flags: D - DYNAMIC; A - ACTIVE; c - CONNECT, y - BGP-MPLS-VPN
    DST-ADDRESS      GATEWAY          ROUTING-TABLE  DISTANCE
DAc 192.168.10.0/24  br-custA@CUST-A  CUST-A                0
DAy 192.168.20.0/24  10.255.0.34      CUST-A              200
```
 
### End-to-end connectivity through the MPLS core
 
```
[admin@PE1] > /ping 192.168.20.1 vrf=CUST-A src-address=192.168.10.1 count=3
  SEQ HOST          SIZE TTL TIME
    0 192.168.20.1    56  63 7ms471us
    1 192.168.20.1    56  63 7ms99us
    2 192.168.20.1    56  63 7ms721us
    sent=3 received=3 packet-loss=0% min-rtt=7ms99us avg-rtt=7ms430us max-rtt=7ms721us
```
 
The reverse test from PE2 (`192.168.20.1` to `192.168.10.1` inside `CUST-A`) also succeeds, 3 of 3 replies.
 
### Customer isolation (`CUST-A` and `CUST-B`)
 
Both VRFs are configured on PE2 with their own RD and RT, and both are exported into the same iBGP session:
 
```
[admin@PE2] > /routing bgp vpn print
Flags: X - DISABLED, I - INACTIVE 
 0   name="bgp-mpls-vpn-1" instance=default route-distinguisher="65000:100" 
     vrf=CUST-A label-allocation-policy=per-vrf 
     import.route-targets=65000:100 
     export.route-targets=65000:100 .redistribute=connected 

 1   name="bgp-mpls-vpn-2" instance=default route-distinguisher="65000:200" 
     vrf=CUST-B label-allocation-policy=per-vrf 
     import.route-targets=65000:200 
     export.route-targets=65000:200 .redistribute=connected 
```
 
Results of the isolation tests:
 
- Inside `CUST-B`, the two sites reach each other across the MPLS core (`192.168.30.1` and `192.168.40.1`).
- Between the two customers, pings fail with `no route` in both directions (a `CUST-B` source towards `CUST-A` addresses, and a `CUST-A` source towards `CUST-B` addresses).
- Each VRF table holds only its own customer's prefixes.
 
Isolation test run from PE1:
 
```
/ping 192.168.20.1 vrf=CUST-B src-address=192.168.30.1 count=3    # CUST-B towards CUST-A: must fail
/ping 192.168.40.1 vrf=CUST-A src-address=192.168.10.1 count=3    # CUST-A towards CUST-B: must fail
```
 
### PE4 in the underlay
 
- OSPF: PE4 forms a Full adjacency with P4 and learns the loopbacks of the core routers.
- LDP: PE4 runs a session with P4, sourced from its loopback (10.255.0.38).
- Loopback-to-loopback pings between PE4 and the other PE routers succeed, for example `/ping 10.255.0.26 src-address=10.255.0.38 count=3`.
 
---
 
## Troubleshooting log
 
| Symptom | Cause | Fix |
|---|---|---|
| `failure: one active instance per VRF allowed` when adding LDP | An LDP instance already existed in the main VRF | Edited it with `/mpls ldp set [find] lsr-id=... transport-addresses=...` instead of adding a second one |
| Ping between loopbacks failed (PE1 to the P2 loopback and back) while pings without a source address worked | Two faults on PE1: the loopback address had a wrong NETWORK value (10.255.0.24 instead of 10.255.0.26), and the `loopback` interface was not in `/mpls ldp interface`. PE1 advertised no label for its own /32, so P1 had no forwarding entry for the labelled packets sent by P2 | Added `loopback` to `/mpls ldp interface` and re-created the address so the connected route is 10.255.0.26/32. Found by disabling LDP on one link (the plain IP ping then worked) and comparing `/mpls forwarding-table` on P1 and P2 |
| iBGP session Established but no VPN routes could be exchanged | The PE1 connection had no `afi=vpnv4`; `/routing bgp session print` showed `ip` as its local address family | `/routing bgp connection set [find name="PE1-to-PE2"] afi=vpnv4` |
| `bad parameter redistribute` on `/routing bgp vpn add` | In RouterOS v7.23.8 the parameter is named differently in this menu | Used `export.redistribute=connected` |
| `input does not match any value of vrf` on `/routing bgp vpn add` | The VRF did not exist yet on that router | Created the VRF with `/ip vrf add` first, then added the BGP VPN entry |
| `CUST-B` routes never reached PE2: its `CUST-B` table held only the connected LAN | The extended community list `VPN-RT-OK` contained `rt:65000:100` three times and never `rt:65000:200`, so the VPNv4 filters rejected the CUST-B route target | Fixed the list so it holds exactly `rt:65000:100` and `rt:65000:200`, and checked it with `/routing filter community-ext-list print` |
| Isolation ping returned `could not...` instead of `no route` | The `src-address` belonged to the remote PE, so RouterOS refused a source that is not local before any route lookup. The test proved nothing | Run each test from the router that owns the source address. The expected result of an isolation test is `no route` |
| PE4 had no OSPF neighbor (it elected itself DR on its uplink) and no LDP neighbor | P4 had neither an OSPF interface template nor an LDP interface for the PE4 link (10.10.10.36/30, `ether15`), so the two routers never exchanged hellos | Added `networks=10.10.10.36/30` to the OSPF templates of P4 and `ether15` to its `/mpls ldp interface` list |
| PE4 loopback unreachable from P4: LDP neighbor stuck in `DT` (throttled) and loopback pings timed out | Applying the OSPF commands twice created a duplicate instance, area and templates on PE4. Removing the duplicate area left the loopback template pointing at a deleted area (flagged `I`, `ospf area not active`), so 10.255.0.38/32 was never advertised, P4 had no route to it, and the LDP session, which runs between loopbacks, could not come up | Re-attached the template with `/routing ospf interface-template set [find networks=10.255.0.38/32] area=BACKBONE`. All pings then succeeded. Lesson: run `print` before `add` to avoid duplicates |
 
---
 
## Repository structure
 
```
.
├── README.md
├── docs/
│   └── images/            # topology and verification screenshots
├── configurations/        # sanitized RouterOS scripts, one folder per router (P1–P4, PE1–PE4, CE-*), e.g. PE1/PE1-cust-b.rsc, PE4/PE4-underlay.rsc
├── services/              # ospf, mpls-ldp, mp-bgp, vrf, ipsec, vpls, qos
├── security/              # firewall policy and security tests
└── testing/               # connectivity tests, failure simulations
```
 
---
 
## Security
 
All configurations are sanitized. No passwords, pre-shared keys, private keys or certificates are published in this repository.
 
---
 
## Author
 
**NDATO Jeanluck** · Network and Security
[LinkedIn](www.linkedin.com/in/jeanluck-ndato) · [Portfolio](https://jeanlucndato.github.io/cyberinsights/)
 
## License
 
MIT