# Component Map

## Upstream areas to track

1. Qubes builder
- build orchestration
- source fetching
- artifact generation

2. Qubes core admin
- qube lifecycle management
- policy handling
- system management interfaces

3. qrexec
- inter-domain RPC and policy enforcement

4. GUI stack
- secure GUI composition and agent/daemon interfaces

5. Templates and service domains
- network domain
- USB domain
- template VM model

## Adaptation categories

### Category A: likely reusable with packaging changes
- userland tools not tightly bound to distro-specific init

### Category B: requires service management adaptation
- daemons currently assuming another init/service model

### Category C: likely builder-specific work
- package generation
- image generation
- installer outputs

### Category D: security-sensitive integration
- qrexec policy paths
- GUI virtualization
- update/trust chain behavior
