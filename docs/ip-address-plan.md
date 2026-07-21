# IP address plan

Azure reserves the first four and last address in every subnet. A `/24` therefore has 251 assignable addresses. Small lab subnets intentionally leave room for endpoint NICs and service delegation.

| Allocation | Range | Example subnets / purpose |
|---|---|---|
| Stage 01 minimal | `10.20.0.0/20` | management `10.20.0.0/24`; application `10.20.1.0/24` |
| Stage 02 three-tier | `10.20.16.0/20` | management `.16/24`; web `.17/24`; application `.18/24`; data `.19/24` |
| Hub | `10.20.32.0/20` | shared services `.32/24`; management `.33/24`; DNS `.34/24` |
| Spoke 1 | `10.20.48.0/20` | workload `.48/24` |
| Spoke 2 | `10.20.64.0/20` | workload `.64/24` |
| Stage 04 peer A | `10.20.80.0/24` | workload `10.20.80.0/25` |
| Stage 04 peer B | `10.20.81.0/24` | workload `10.20.81.0/25` |
| Stage 06 private service | `10.20.82.0/23` | workload `.82/24`; private endpoints `.83/24` |
| Stage 03 route diagnostics | `10.20.84.0/23` | source `.84/24`; target `.85/24` |
| Stage 07 monitoring | `10.20.86.0/23` | monitored workload `.86/24`; diagnostics `.87/24` |
| Stage 08 troubleshooting | `10.20.88.0/21` | source `.88/24`; target `.89/24`; DNS `.90/24` |
| Near-term growth | `10.20.96.0/19` | reserved, do not allocate |
| Long-term growth | `10.20.128.0/17` | reserved, do not allocate |

The remaining unused prefixes inside each stage block allow additional tiers without renumbering. Terraform validates syntax, containment, and pairwise overlap by checking whether either network address falls inside the other prefix. Repository tests assert the exact approved allocations.
