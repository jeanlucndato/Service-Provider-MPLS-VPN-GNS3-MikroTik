# MikroTik ISP MPLS VPN Infrastructure

![RouterOS](https://img.shields.io/badge/RouterOS-v7-blue)
![GNS3](https://img.shields.io/badge/Lab-GNS3-orange)
![MPLS](https://img.shields.io/badge/MPLS-L3VPN-green)
![Status](https://img.shields.io/badge/Status-In%20progress-yellow)

An ISP-style backbone built on **MikroTik CHR (RouterOS v7)** in **GNS3**. It delivers isolated Layer 3 VPN services to enterprise customers over a shared MPLS core, using OSPF, LDP, MP-BGP VPNv4, VRFs and eBGP.

> **Lab project.** This is a staged lab, not a production configuration. Every step is verified with command output and documented.

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
| PE1–PE4 | _to be assigned_ |

### Planned customer design

| Customer | AS | Sites | RD / RT |
|---|---|---|---|
| Customer A | 65101 | 192.168.10.0/24, 192.168.20.0/24 | 65000:101 |
| Customer B | 65102 | 192.168.30.0/24, 192.168.40.0/24 | 65000:102 |

ISP AS: **65000**. PE–CE links use dedicated /30 subnets from 172.16.0.0/16.

---

## Technologies

| Technology | Where | Purpose |
|---|---|---|
| OSPFv2 (area 0) | Provider core | Advertise loopbacks and core links |
| Loopback interfaces | All ISP routers | Stable router IDs and LDP/BGP endpoints |
| MPLS + LDP | Core-facing interfaces | Label-switched transport |
| MP-BGP VPNv4 (iBGP) | PE routers | Exchange customer VPN routes and VPN labels |
| VRF | PE routers | Separate routing table per customer |
| eBGP | PE–CE links | Exchange customer routes |
| IPsec IKEv2 | VPN endpoints | Encrypted site-to-site tunnel |
| VPLS, QoS, firewall | Edge and core | Layer 2 VPN, traffic policy, control-plane protection |

---

## Design notes

- **OSPF** advertises the /30 links and each loopback (passive). LDP and BGP use loopbacks so sessions survive a single link failure.
- **LDP** uses the loopback as LSR-ID and transport address, and runs only on core-facing interfaces.
- **MP-BGP VPNv4** runs between PE routers (AS 65000), sourced from loopbacks.
- **MPLS L3VPN separates customers but does not encrypt traffic.** IPsec is added as a separate, complementary service for confidentiality and integrity.

---

## Roadmap

- [x] Topology and addressing plan
- [x] OSPF area 0 across the P core (adjacencies Full)
- [ ] MPLS/LDP across the core and PE uplinks _(in progress)_
- [ ] MP-BGP VPNv4 between PE routers
- [ ] Customer VRFs, RD/RT and isolation tests
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
/mpls forwarding-table print
/routing bgp session print
/ip ipsec active-peers print
/ip ipsec installed-sa print
```

Verification outputs and screenshots are stored in `testing/` and `docs/images/`.

---

## Troubleshooting log

| Symptom | Cause | Fix |
|---|---|---|
| `failure: one active instance per VRF allowed` when adding LDP | An LDP instance already existed in the main VRF | Edited it with `/mpls ldp set [find] lsr-id=... transport-addresses=...` instead of adding a second one |

---

## Repository structure

```
.
├── README.md
├── docs/
│   └── images/            # topology and verification screenshots
├── configurations/        # sanitized RouterOS exports (P1–P4, PE1–PE4, CE-*)
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
[LinkedIn](https://www.linkedin.com/in/your-profile) · [Portfolio](https://your-portfolio-link)

## License

MIT