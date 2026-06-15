# run-claude-on-deepseek

An idempotent, production-grade deployment engine to run Anthropic's Claude Code CLI powered entirely by the DeepSeek API with strict user-space isolation and zero-bloat runtime mapping.

This repository provides a streamlined, deterministic bootstrap script to bridge the Claude Code terminal agent with DeepSeek's high-reasoning API ecosystem. Built with security-first paradigms and zero external framework dependencies, it establishes a reliable infrastructure layer for developers and security engineers operating in standard or minimal Linux environments (Ubuntu, Debian, Kali).

---

## Architectural Highlights

* **True Idempotency:** Implements exact line matching (`grep -Fxq`) to safely manage search paths within shell profiles (`.bashrc` / `.zshrc`) across repeated runs without configuration bloat or line duplication.
* **Hardened Security Isolation:** Enforces absolute privilege containment using isolated user-space paths (`~/.npm-global` and `~/.local/bin`), granular file system permissions (`600`/`700`), and a strict execution `umask 077` directive.
* **Volatile Secret Ingestion:** Captures API keys strictly inside volatile process memory blocks during setup, fully preventing operational strings from spilling into execution logs or command-line histories.
* **Signal-Transparent Wrapper:** Deploys a thin, non-recursive execution wrapper using native `exec` commands to pass TTY signals, asynchronous terminal flags, and interactive keystrokes flawlessly down to the underlying Node runtime.
* **Modern Keyring Toolchain:** Provisions the verified Node.js v22 LTS compiler utilizing modern `gpg` signed-by repository structures, completely bypassing legacy or unauthenticated setup binaries.

---

## Deployment Blueprint


```

```
                  [ install.sh Executed ]
                             │
     ┌───────────────────────┴───────────────────────┐
     ▼                                               ▼

```

┌──────────────────┐                            ┌──────────────────┐
│  System Layer    │                            │ User-Space Setup │
├──────────────────┤                            ├──────────────────┤
│ • apt updates    │                            │ • mkdir global   │
│ • Keyring setups │                            │ • Inject PATH to │
│ • Node.js v22+   │                            │   .bashrc/.zshrc │
└────────┬─────────┘                            └────────┬─────────┘
│                                               │
└───────────────────────┬───────────────────────┘
▼
┌───────────────────────┐
│   npm CLI Toolchain   │
├───────────────────────┤
│ • npm install -g      │
│ • hash -r path cache  │
└───────────┬───────────┘
▼
┌───────────────────────┐
│   Secret Isolation    │
├───────────────────────┤
│ • In-Memory Key Read  │
│ • Write ~/.config/env │
└───────────┬───────────┘
▼
┌───────────────────────┐
│   Execution Mapping   │
├───────────────────────┤
│ • ~/.local/bin/claude │
│ • exec real binary    │
└───────────────────────┘

```

---

## Prerequisites

* **Operating System:** Ubuntu, Debian, or Kali Linux.
* **Privileges:** Standard non-root user account with `sudo` architectural access.
* **Core Utilities:** Internet access to reach the NodeSource and NPM package registries.

---

## Installation

### 1. Clone the Repository
Clone this repository directly to your local workspace and switch into the project root directory:
```bash
git clone [https://github.com/Tarik-Monwar/run-claude-on-deepseek.git](https://github.com/Tarik-Monwar/run-claude-on-deepseek.git)
cd run-claude-on-deepseek

```

### 2. Set Execution Permissions

Grant executable mapping flags to the localized deployment script:

```bash
chmod +x install.sh

```

### 3. Run the Installer

Execute the installation script as a standard user:

```bash
./install.sh

```

> ⚠️ **Important:** Do not execute using `sudo ./install.sh`. The engine isolates configurations strictly within user-space boundaries and will invoke your `sudo` elevation internally only when syncing core system package trees.

### 4. Initialize Your Shell Session

Reload your active environmental path configuration rules or open a clean terminal window:

**For Bash:**

```bash
source ~/.bashrc

```

**For Zsh (Default on Kali):**

```bash
source ~/.zshrc

```

Now you can invoke the agent globally from any path on your terminal session:

```bash
claude

```

---

## Operational Guide

### Binary Location Map

* **True Claude Execution Target:** `~/.npm-global/bin/claude`
* **Interception Wrapper Location:** `~/.local/bin/claude`
* **Isolated Environment Context Configuration:** `~/.config/claude/env`
* **Assigned Localized Development Workspace:** `~/claude_workspace`
