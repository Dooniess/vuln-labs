# vuln-labs

A collection of Docker labs for reproducing and analyzing CVEs in a local environment. Each lab deploys a vulnerable instance of a target application in a few commands — no VM required, Apple Silicon compatible.

> **⚠️ For security research and testing in isolated environments only.**  
> These labs must never be exposed on a public network.

---

## Global Prerequisites

- **Docker Desktop** — running, with at least **6 GB of RAM allocated** (required for GitLab, recommended for all)
- **macOS** with Command Line Tools (`make`, `curl`)
- **Apple Silicon**: all labs include `platform: linux/amd64` config + Rosetta compatibility for images without native ARM support

```bash
# Check RAM allocation in Docker Desktop
# Settings → Resources → Memory → 6 GB minimum
```

---

## Available Labs

| Lab | Application | Versions covered | Lab(s) |
|-----|-------------|-----------------|--------|
| [wordpress/](./wordpress/) | WordPress | All (via official tag + versioned plugins) | 1 |
| [glpi/](./glpi/) | GLPI | 9.4.x → 11.0.x | 2 (official + build) |
| [joomla/](./joomla/) | Joomla | 3.x → 6.x | 2 (official + build) |
| [gitlab/](./gitlab/) | GitLab CE | 11.x → 19.x | 1 |

---

## Repository Structure

```
vuln-labs/
├── wordpress/              # WordPress + WP-CLI + versioned plugin management
├── glpi/
│   ├── official/           # Official image (10.0.x, 11.0.x)
│   └── build/              # Build from GitHub archive (all versions)
├── joomla/
│   ├── official/           # Official image (5.x, 6.x)
│   └── build/              # Build from GitHub archive (3.x, 4.x)
├── gitlab/                 # GitLab CE — all versions via official tag
└── cves/                   # PoCs and CVE analyses
    ├── CVE-2026-78006/     # The Events Calendar — Unauthenticated RCE
    └── CVE-2026-85706/     # GitLab — Path traversal (CVSS 10)
```

---

## Quick Start

Every lab follows the same structure:

```bash
cd <lab>/
cp .env.example .env
# Set the target version in .env
make up
```

The instance is available at `http://localhost:8080` once provisioning completes.  
`make reset` restores the lab to its initial state.

---

## WordPress

**Path:** `wordpress/`  
**Image:** `wordpress:latest` (configurable tag)  
**Access:** `http://localhost:8080` — `admin / admin`

Automatic installation via WP-CLI, with versioned plugin management.

```bash
# Install a specific version of a plugin
make plugin SLUG=the-events-calendar VERSION=6.12.0

# Install the latest version
make plugin SLUG=contact-form-7

# Reset to a clean state
make reset
```

Plugins not found on WordPress.org are automatically retrieved via SVN fallback.

📄 [Full documentation](./wordpress/README.md)

---

## GLPI

**Path:** `glpi/`  
**Access:** `http://localhost:8080` — `glpi / glpi`

Two complementary labs:

| Lab | When to use |
|-----|-------------|
| `official/` | Maintained versions: recent 10.0.x, 11.0.x |
| `build/` | All other versions, including old ones (9.4, 9.5) |

```bash
# Official image
cd glpi/official/
# Set GLPI_TAG=10.0.18-ce.0 in .env
make up

# Custom build
cd glpi/build/
# Set GLPI_VERSION=9.5.12 in .env
make up
```

> Apple Silicon: versions < 10.x require `platform: linux/amd64` — already configured, Rosetta must be enabled in Docker Desktop.

📄 [Full documentation](./glpi/README.md)

---

## Joomla

**Path:** `joomla/`  
**Access:** `http://localhost:8080` — `admin / Admin@VulnLab1`

Two complementary labs:

| Lab | Versions |
|-----|----------|
| `official/` | 5.x, 6.x — official image, automatic install |
| `build/` | 3.x, 4.x — build from GitHub archive |

```bash
# Official image (5.x / 6.x)
cd joomla/official/
# Set JOOMLA_TAG=5.4.7-php8.2-apache in .env
make up

# Build (3.x / 4.x)
cd joomla/build/
# Set JOOMLA_VERSION=4.3.4 in .env
make up
```

> **Joomla 6.x**: admin password must be longer than 12 characters. The default (`Admin@VulnLab1`) meets this requirement.  
> **Versions 3.x / 4.0–4.2**: no CLI installer available, browser wizard required (DB host = `db`).

📄 [Full documentation](./joomla/README.md)

---

## GitLab CE

**Path:** `gitlab/`  
**RAM required:** 6 GB minimum  
**Access:** `http://localhost:8080` — `root / <generated password>`

```bash
# Set GITLAB_TAG=19.3.1-ce.0 in .env
make up

# Retrieve the root password (expires after 24h)
make root-password
```

First startup: 5 to 10 minutes (Omnibus initialization).

> **Old tags (11.x–13.x)**: amd64-only images, Rosetta required.  
> **Do not add** `grafana['enable'] = false` to the Omnibus config — option removed since GitLab 16.x.

📄 [Full documentation](./gitlab/README.md)

---

## CVEs

### CVE-2026-78006 — The Events Calendar ≤ 6.12.0

**Type:** Unauthenticated Remote Code Execution (two chains)  
**CVSS:** Critical  
**Path:** `cves/CVE-2026-78006/`

```bash
cd cves/CVE-2026-78006/
source .venv/bin/activate

python3 exploit-cve-2026-78006.py \
  --url http://localhost:8080 \
  --event "http://localhost:8080/?tribe_events=<slug>" \
  --chain 2
```

**Result:** admin password reset → full `wp-admin` access.

> **Note:** The Wordfence advisory lists versions ≤ 6.17.4 as affected. Our source code analysis shows that Chain 2 was silently patched since **6.12.2.1**, and that one exploitation condition is not documented in the official disclosure.

📄 [Full analysis + exploitation conditions](./cves/CVE-2026-78006/README.md)

---

### CVE-2026-85706 — GitLab Path Traversal

**Type:** Unauthenticated Path Traversal — arbitrary file read  
**CVSS:** 10.0  
**Vulnerable versions:** < 19.1.8 / < 19.2.6 / < 19.3.2  
**Tested on:** `19.3.1-ce.0`  
**Path:** `cves/CVE-2026-85706/`

```bash
# With GitLab lab running on 19.3.1
python3 exploit.py --url http://localhost:8080 --project-id <id>
```

**Result:** `gitlab.yml` and internal config files read via HTTP 400.  
**Patch verified:** `19.3.2-ce.0` → HTTP 401 before file is read.

📄 [Documentation + patch analysis](./gitlab/README.md#cve-2026-85706)

---

## Common Troubleshooting

| Issue | Solution |
|-------|----------|
| `no matching manifest for linux/arm64/v8` | `platform: linux/amd64` + Rosetta enabled in Docker Desktop |
| GitLab: random 500 errors | Insufficient RAM — allocate 6 GB in Docker Desktop |
| GitLab: nginx on wrong port | `nginx['listen_port'] = 80` in Omnibus config |
| Joomla 6.x: silent install failure | Password must be longer than 12 characters |
| WordPress plugin not found | Automatic SVN fallback retrieval |

---

## License

These labs are provided for security research purposes only.  
Included PoCs must not be used against systems without explicit authorization.
