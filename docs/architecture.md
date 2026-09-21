<!-- LTeX: dictionary+=tuxifier dictionary+=Tuxifier dictionary+=libblockdev dictionary+=dracut -->
# Architecture

Tuxifier is made up of different projects. These projects are:

- [Tuxifier playbook](https://github.com/tuxifier-playbook)

- [Tuxifier tasks collection](https://github.com/Geertsky/tuxifier)

- [Tuxifier-runtime](https://github.com/Geertsky/tuxifier-python)

- [Tuxifier boot](https://github.com/Geertsky/dracut-tuxifier)

## Tuxifier playbook

The tuxifier playbook is just a simple playbook that imports the `ansible_tuxifier` role of the Tuxifier tasks collection.

## Tuxifier tasks collection

At the heart of Tuxifier is the Tuxifier tasks collection. The Tuxifier tasks collection consists of the tasks to partition a disk and install an OS on it.

## Tuxifier-runtime

Tuxifier-runtime is a runtime environment that is completely independent and portable.<br>
The Tuxifier-runtime environment is an additional layer on top of the OS that enables the execution of the tasks specified in the Tuxifier tasks collection.
For the Tuxifier-runtime, a [conda Python environment](https://docs.conda.io/projects/conda/en/stable/) is built. The Tuxifier-runtime consists of:

- Python
- Basic Linux tools
- Partitioning tools

## Tuxifier boot

Tuxifier boot creates a boot environment with an ssh server and with the Tuxifier-runtime environment included.
This makes it possible for the Tuxifier tasks collection to be executed at boot time.

# Tuxifier execution flow

Tuxifier boot basically pauses execution just before the root file system with the installation gets accessed.
This happens really early, within the first seconds, when you boot your server.

At that point, the Tuxifier tasks collection, executed on a different control server, partitions the disk and installs an OS onto it.
Finally, it triggers continuation of the boot process which either boots the target machine to the just installed operating system, or powers off the target machine.
# Components and Relationships

## Preparation
```mermaid
---
title:
config:
  look: classic
  theme: base
  themeVariables:
    background: "#ffffff"
    primaryColor: "#f5f7f8"
    primaryTextColor: "#173238"
    primaryBorderColor: "#71878c"
    lineColor: "#587078"
---
flowchart TB
  %% ==================== PREPARATION ====================
  subgraph PREP["PREPARATION — prerequisite builds before installation"]
    direction TB

    subgraph PYBUILD["Build tuxifier-python"]
      direction LR
      CF["conda-forge channel"]:::support
      GC["geertsky channel"]:::support
      CONDA["Conda"]:::support
      TPBUILD["tuxifier-python<br/>Conda environment"]:::tuxpy
      PACK["conda-pack"]:::support
      SQ["tuxifier-python.squashfs"]:::artifact

      CF -->|"supplies packages"| CONDA
      GC -->|"supplies packages"| CONDA
      CONDA -->|"creates environment"| TPBUILD
      TPBUILD --> PACK
      PACK -->|"packages as SquashFS"| SQ
    end

    subgraph BOOTBUILD["Build boot environment"]
      direction LR
      DTBUILD["dracut-tuxifier"]:::dracutTux
      SSHDBUILD["dracut-sshd"]:::support
      DRACUT["dracut"]:::support
      INIT["Customized initramfs"]:::custinitramfs

      DTBUILD -->|"module used by"| DRACUT
      SSHDBUILD -->|"sshd module used by"| DRACUT
      DRACUT -->|"generates"| INIT
    end

    SQ -->|"embeds runtime"| DTBUILD

  end

  %% ==================== LINKS ====================
  click DTBUILD "https://github.com/Geertsky/dracut-tuxifier/blob/HEAD/94tuxifier/module-setup.sh" "dracut-tuxifier build integration" _blank
  click TPBUILD "https://github.com/Geertsky/tuxifier-python/blob/HEAD/README.md" "tuxifier-python build and runtime documentation" _blank

  %% ==================== STYLING ====================
  classDef tuxifier fill:#0F6F73,stroke:#084B4E,color:#FFFFFF,stroke-width:2px
  classDef dracutTux fill:#2B8C87,stroke:#17615E,color:#FFFFFF,stroke-width:2px
  classDef tuxpy fill:#63B7AE,stroke:#2C7771,color:#102F31,stroke-width:2px
  classDef support fill:#F3F5F6,stroke:#819297,color:#173238
  classDef artifact fill:#E8ECEE,stroke:#687C82,color:#173238
  classDef note fill:#FFFFFF,stroke:#87999E,color:#173238,stroke-dasharray:4 3
  classDef prepKey fill:#EEF5F4,stroke:#6B918D,color:#173238
  classDef installKey fill:#F4F5F6,stroke:#7A858A,color:#173238
  classDef custinitramfs fill:#E8ECEE,stroke:#FFFD00,stroke-width:5pt

  style PREP fill:#F8FCFB,stroke:#6B918D,stroke-width:2px
  style PYBUILD fill:#FFFFFF,stroke:#A6B8B6
  style BOOTBUILD fill:#FFFFFF,stroke:#A6B8B6
```

## Installation


```mermaid
---
title:
config:
  look: classic
  theme: base
  themeVariables:
    background: "#ffffff"
    primaryColor: "#f5f7f8"
    primaryTextColor: "#173238"
    primaryBorderColor: "#71878c"
    lineColor: "#587078"
---
flowchart TB
  %% ==================== INSTALLATION: CONTROLLER ====================
  subgraph INSTALL["INSTALLATION"]
    direction TB

    INIT["Customized initramfs"]:::custinitramfs --> BOOTREQ
    KERNEL["Linux kernel"]:::artifact
    BOOTREQ["Target installation-environment boot prerequisites"]:::note
    KERNEL --> BOOTREQ
    BOOTREQ--> IR
  %% ==================== SHARED DISTRIBUTION REPOSITORY ====================
  RPMREPO["Distribution RPM repository<br/><br/><i>provides package metadata to resolver</i>"]:::repo
  RPMREPO --> RES
  RPMREPO -->|"supplies OS packages"| EXEC
  RES -->|"resolved RPM URLs"| EXEC
  ORCH -->|"SSH"| SSHD


    subgraph CTRL["Ansible controller"]
      direction TB
      HV["Host variables<br/>• Disk layout<br/>• Target distribution<br/>• continue_install"]:::support
      PLAY["Ansible playbook"]:::support
      ORCH["geertsky.tuxifier<br/>Task orchestration"]:::tuxifier
      RES["RPM dependency resolver<br/>geertsky.tuxifier · Python DNF API"]:::tuxifierSmall

      HV --> PLAY
      PLAY -->|"invokes"| ORCH
      ORCH -->|"delegated to localhost"| RES
    end

    %% ==================== INSTALLATION: TARGET ====================
    subgraph TARGET["Target machine"]
      direction TB

      subgraph IR["initramfs — Boot environment"]
        direction TB
        DT["<b>dracut-tuxifier</b><br/><ul><li><b>Initialization</b><ul><li>mounts tuxifier-python runtime</li></ul></li><li><b>Boot control</b><ul><li>pauses boot</li></ul></li></ul>"]:::dracutTux
        SSHD["dracut-sshd"]:::support
        EXEC["geertsky.tuxifier<br/>Installation task execution"]:::tuxifier

        subgraph TPENV["tuxifier-python — Conda environment"]
          direction TB
          TPTITLE["tuxifier-python"]:::tuxpy
          PY["Python runtime"]:::runtime
          DISK["Disk and filesystem tools"]:::runtime
          PKG["Package installation and download tools"]:::runtime
        end

        DT -->|"mounts"| TPTITLE
        SSHD -->|"enables remote task execution"| EXEC
        EXEC -->|"uses Python and installation tools"| TPTITLE
        TPTITLE --- PY
        PY --- DISK
        DISK --- PKG
      end

      OS["Installed operating system"]:::artifact
      DEC{"continue_install + kernel check"}:::decision
      CONT["Continue boot into installed OS<br/>continue_install = true AND<br/>installed kernel = running kernel"]:::outcome
      OFF["Power off<br/>continue_install = false OR kernel mismatch<br/>installed kernel may differ when false"]:::outcome

      EXEC -->|"installs"| OS
      EXEC --> DT
      DT -->|"boot remains paused until installation is finished"| DEC
      DEC -->|"continue"| CONT
      DEC -->|"power off"| OFF
      CONT --> OS
    end
  end


  %% ==================== INVISIBLE POSITIONING ONLY ====================
  %% Shared upstream anchor encourages initramfs and kernel onto the same row.
  %% No invisible edge between them: that would impose a vertical ordering.
  HV ~~~ INIT
  HV ~~~ KERNEL
  %% Encourage the repository to sit one row below the boot inputs.
  PLAY ~~~ RPMREPO

  %% ==================== LINKS ====================
  click ORCH "https://github.com/Geertsky/tuxifier" "geertsky.tuxifier overview and orchestration" _blank
  click RES "https://github.com/Geertsky/tuxifier/blob/main/plugins/modules/generate_minimal_install_urls_info.py" "RPM dependency resolver source" _blank
  click EXEC "https://github.com/Geertsky/tuxifier/blob/main/roles/ansible_tuxifier/tasks/main.yml" "Installation task execution" _blank
  click DEC "https://github.com/Geertsky/tuxifier/blob/main/roles/ansible_tuxifier/tasks/continue_install.yml" "Continuation decision source" _blank
  click DT "https://github.com/Geertsky/dracut-tuxifier/blob/HEAD/README.md" "dracut-tuxifier runtime overview" _blank
  click TPTITLE "https://github.com/Geertsky/tuxifier-python/blob/HEAD/README.md" "tuxifier-python build and runtime documentation" _blank

  %% ==================== STYLING ====================
  classDef tuxifier fill:#0F6F73,stroke:#084B4E,color:#FFFFFF,stroke-width:2px
  classDef tuxifierSmall fill:#0F6F73,stroke:#084B4E,color:#FFFFFF,stroke-width:1.5px,font-size:12px
  classDef dracutTux fill:#2B8C87,stroke:#17615E,color:#FFFFFF,stroke-width:2px
  classDef tuxpy fill:#63B7AE,stroke:#2C7771,color:#102F31,stroke-width:2px
  classDef runtime fill:#DDF1EE,stroke:#78AAA5,color:#173238
  classDef support fill:#F3F5F6,stroke:#819297,color:#173238
  classDef artifact fill:#E8ECEE,stroke:#687C82,color:#173238
  classDef repo fill:#ECEFF1,stroke:#71858A,color:#173238
  classDef decision fill:#FFF8E8,stroke:#A3843E,color:#3C331D,stroke-width:2px
  classDef outcome fill:#FFFFFF,stroke:#87999E,color:#173238
  classDef prepKey fill:#EEF5F4,stroke:#6B918D,color:#173238
  classDef installKey fill:#F4F5F6,stroke:#7A858A,color:#173238
  classDef custinitramfs fill:#E8ECEE,stroke:#FFFD00,stroke-width:5pt

  style INSTALL fill:#FAFBFB,stroke:#7A858A,stroke-width:2px
  style CTRL fill:#FFFFFF,stroke:#8B9A9E,stroke-width:2px
  style TARGET fill:#FFFFFF,stroke:#8B9A9E,stroke-width:2px
  style IR fill:#F5F8F8,stroke:#91A6AA,stroke-width:2px
  style TPENV fill:#F0FAF8,stroke:#63A39D,stroke-width:2px
```
