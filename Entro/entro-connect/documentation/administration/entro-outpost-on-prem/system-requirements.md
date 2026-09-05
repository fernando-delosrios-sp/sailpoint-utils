System Requirements | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/entro-outpost-on-prem/system-requirements.md).
## Hardware requirements[#hardware-requirements](#hardware-requirements)

### Architecture[#architecture](#architecture)

Entro Outpost is only compatible with AMD64 architecture.
GitBook Assistant

### Docker Installation[#docker-installation](#docker-installation)

#### Docker Basic Instance Installation[#docker-basic-instance-installation](#docker-basic-instance-installation)
ComponentRequired Capacity

CPU
GitBook Assistant

8 Cores
GitBook Assistant

Memory
GitBook Assistant

32 GB
GitBook Assistant

Disk Space
GitBook Assistant

64 GB
GitBook Assistant
#### Docker Large Instance Installation[#docker-large-instance-installation](#docker-large-instance-installation)
ComponentRequired Capacty

CPU
GitBook Assistant

16 Cores
GitBook Assistant

Memory
GitBook Assistant

64 GB
GitBook Assistant

Disk Space
GitBook Assistant

250 GB (SSD) min
GitBook Assistant
#### Docker Volumes[#docker-volumes](#docker-volumes)

The following custom volume is required for all Docker installations:
GitBook Assistant

- 

var/nats : 10GB (Minimum storage)
GitBook Assistant

- 

stores message queues for data sent to the Entro cloud console
GitBook Assistant

When using the optional Git clone feature the following custom volume is required:
GitBook Assistant

- 

/clones: 20GB (Minimum storage)
GitBook Assistant

- 

repository storage while being scanned for secret exposures
GitBook Assistant

### Kubernetes Installation[#kubernetes-installation](#kubernetes-installation)

By default there will be 3 pods deployed (connector, scanner, nats) each with the following 
GitBook AssistantComponentRequired CapacityTotal across all Pods

CPU
GitBook Assistant

2 Cores
GitBook Assistant

6 cores
GitBook Assistant

Memory
GitBook Assistant

4 GB
GitBook Assistant

12 GB
GitBook Assistant

Disk Space
GitBook Assistant

10 GB (SSD) min
GitBook Assistant

30 GB (SSD) min
GitBook Assistant

Additional pods could also be used in addition to the 3 standard pods each with their own additional requirements.
GitBook Assistant

*OCR service pod:*
GitBook AssistantComponentRequired Capacity

CPU
GitBook Assistant

2 cores
GitBook Assistant

Memory
GitBook Assistant

4 GB
GitBook Assistant

Disk Space
GitBook Assistant

10 GB (SSD) min
GitBook Assistant

*Git clone server:*
GitBook AssistantComponentRequired Capacity

CPU
GitBook Assistant

2 cores
GitBook Assistant

Memory
GitBook Assistant

4 GB
GitBook Assistant

Disk Space
GitBook Assistant

60 GB (SSD) min
GitBook Assistant
## Software requirements[#software-requirements](#software-requirements)

#### Docker[#docker](#docker)

Minimum Docker version supported is 
GitBook Assistant
#### Kubernetes[#kubernetes](#kubernetes)

Minimum Kubernetes version supported is
GitBook Assistant

**Helm**
GitBook Assistant

Minimum Kubernetes version supported is
GitBook Assistant[PreviousEntro Outpost overview](/administration/entro-outpost-on-prem/entro-outpost-overview)[NextNetwork Requirements](/administration/entro-outpost-on-prem/network-requirements)

Last updated 11 months ago

- [Hardware requirements](#hardware-requirements)
- [Architecture](#architecture)
- [Docker Installation](#docker-installation)
- [Kubernetes Installation](#kubernetes-installation)
- [Software requirements](#software-requirements)
