## The target system
*For this document we define a target. The target for this document is a rocky server with a webserver installed and an example webpage served.*

```mermaid
flowchart TB
    subgraph server["<span style='font-size:26px'><b>target server</b></span>"]
        direction TB

        subgraph disk["<b>/dev/vda — GPT</b>"]
            direction TB

            boot["<b>Partition 1 — /boot</b><br/>ext4 · 1023 MiB"]
            efi["<b>Partition 2 — /boot/efi</b><br/>VFAT · 1 GiB"]

            subgraph partition3["<b>Partition 3 — LVM physical volume</b>"]
                direction TB

                subgraph vg["<b>Volume group: vg.rh</b>"]
                    direction TB
                    swap["<b>swap</b><br/>512 MiB"]
                    root["<b>root — /</b><br/>ext4 · all remaining VG space"]
                end
            end

            boot ~~~ efi
            efi ~~~ partition3
        end

        subgraph distribution["<span style='font-size:22px'><b>target distribution</b> (rocky9)</span>"]
            configuration["<b>target configuration</b><br/><div style='text-align:left'>• Apache<br/>&nbsp;&nbsp;&nbsp;&nbsp;◦ simple webpage</div>"]
        end

        disk ~~~ distribution
    end
    style disk fill:#E3F2FD,stroke:#1976D2,color:#1A1A1A
    style partition3 fill:#D1E7FA,stroke:#1976D2,color:#1A1A1A
    style vg fill:#BBDEFB,stroke:#1976D2,color:#1A1A1A

    style boot fill:#FFFFFF,stroke:#1976D2,color:#1A1A1A
    style efi fill:#FFFFFF,stroke:#1976D2,color:#1A1A1A
    style swap fill:#FFFFFF,stroke:#1976D2,color:#1A1A1A
    style root fill:#FFFFFF,stroke:#1976D2,color:#1A1A1A

    style distribution fill:#E8F5E9,stroke:#388E3C,color:#1A1A1A
    style configuration fill:#C8E6C9,stroke:#388E3C,color:#1A1A1A
```
_Examples how these definitions can look for a server can be found in [host_vars/](../inventory/host_vars/)_.

# The problem

For realizing the target installation on a server, there are typically two steps involved.

1. Install a server with a minimal OS

2. install and configure the server to its final state

After **step 1**, we have a bare installed system with which we effectively cannot do anything. We can boot the system, we can log-in to the system but that pretty much is it. It’s intended purpose still needs to be realized.

There are however some crucial, partly irreversible, decisions already made:

- (costly or disruptive to change) The partition layout of the system

- (partly modifiable) The OS release installed


In **step 2** we can install additional software and configure the system to a final target state.


For **step 1** the following parameters have to be defined:

1. partition layout

2. OS Release

For **step 2** the parameters are:

1. webserver

2. webpage


For **step 1** we can choose different solutions. For example:

- kickstart file with a partitioning and installation

- clone of an existing image (only works for a virtual server)


For **step 2** we can as well choose different solutions:

- manual installation/configuration

- scripted installation/configuration

- ansible

- teraform

Independent of which solution we choose, the two steps remain independent.

Tuxifier combines these two steps into one.

That means we can define all the parameters in one place, use one tool, and simply say: Make it so!

# How does Tuxifier work

Tuxifier is made up of different parts. These parts are:

- Tuxifier tasks collection

- Tuxifier runtime

- Tuxifier boot

## Tuxifier tasks collection

At the heart of Tuxifier is the Tuxifier tasks collection. The Tuxifier tasks collection consists of the tasks to partition a disk and install an OS on it.

## Tuxifier-runtime

Tuxifier runtime is a runtime environment that is completely independant and portable.<br>
For the Tuxifier-runtime a [conda python environment](https://docs.conda.io/projects/conda/en/stable/) is build. The Tuxifier-runtime consists of:

- python
- basic linux tools
- partitioning tools

## Tuxifier boot

Tuxifier boot creates a boot time environment with the Tuxifier-runtime included. This makes it possible for the Tuxifier tasks collection to be executed at boot time.

# Tuxifier execution

Tuxifier boot basically pauses execution just before the root filesystem with the installation gets accessed. This happens really early,within the first seconds, when you boot your server.
At that point tuxifier tasks collection, executed on a different control server, partitions the disk and installs an OS onto it. Finally it triggers continuation of the boot process.

# Conclusion
This makes it possible to:
- Define all parameter for the final state of a server
- boot a server, where possibly an OS was never installed.
- End up with a server identical to the requirements specified in the parameters file.

