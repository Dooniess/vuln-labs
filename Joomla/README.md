# Joomla Docker Labs

A set of Docker labs for testing Joomla extension vulnerabilities across specific versions. Two complementary labs are provided to cover the full version range.

* **Official image lab** — uses the official `joomla` Docker image. Fast, no build step, automatic installation. Use for **versions 5.x and 6.x**.
* **Build lab** — builds the image from the official GitHub release archive. Use for **versions 3.x and 4.x**, including point releases not available as official images.

**🚨 These Docker containers are intended for TEMPORARY USE ONLY 🚨**

---

## Prerequisites

* Docker Desktop running (`docker` and `docker compose` available)
* `make`, `curl` (provided by Command Line Tools on macOS)

---

## Which Lab to Use?

| Situation | Lab to use |
|-----------|------------|
| Joomla 5.x or 6.x | `official/` |
| Joomla 4.3.x or 4.4.x | `build/` — automatic install |
| Joomla 3.x, 4.0.x, 4.1.x, 4.2.x | `build/` — browser wizard required |
| Need to start quickly, no compilation | `official/` |

---

## Lab 1 — Official Image (5.x / 6.x)

### Getting Started

```bash
cd official/
cp .env.example .env
# edit .env as needed, then:
make up
```

Joomla installs **automatically** on first startup via environment variables. No browser interaction is required. Once installation completes, Joomla is accessible at http://localhost:8080.

> **Important:** Joomla 6.x requires the admin password to be longer than 12 characters. The default (`Admin@VulnLab1`) meets this requirement. If you change it, make sure to follow this rule — otherwise the auto-installation silently fails and the configuration wizard appears instead.

### Choosing the Version

The version corresponds to the **official image tag**, set via `JOOMLA_TAG` in `.env`. The tag also includes the PHP version.

```
JOOMLA_TAG=latest                  # latest stable (6.x + PHP 8.4)
JOOMLA_TAG=6.1.2                   # Joomla 6.1.2, default PHP
JOOMLA_TAG=6.1.2-php8.3-apache     # Joomla 6.1.2 + PHP 8.3
JOOMLA_TAG=5.4.7-php8.2-apache     # Joomla 5.4.7 + PHP 8.2
```

Full list of available tags: https://hub.docker.com/_/joomla/tags — look for `-apache` suffixed tags.

To change the version: update `JOOMLA_TAG` in `.env`, then run `make reset`.

### Installing an Extension

**Method 1 — Auto-install at startup (recommended)**

Place the zip in `./extensions/`, then set its path in `.env`:

```
JOOMLA_EXTENSIONS_PATHS=/opt/local-extensions/my-extension.zip
```

For multiple extensions, separate paths with `;`. You can also install from a URL:

```
JOOMLA_EXTENSIONS_URLS=https://example.com/my-extension.zip
```

**Method 2 — `make ext` after startup**

```bash
make ext EXT=./extensions/my-extension.zip
make ext EXT=https://example.com/my-extension.zip
```

**Method 3 — Admin interface**

**System → Install Extensions → Upload Package File**

---

## Lab 2 — Build from Archive (3.x / 4.x)

### Getting Started

```bash
cd build/
cp .env.example .env
# edit JOOMLA_VERSION and PHP_VERSION in .env, then:
make up
```

The first `make up` builds the image (downloads the official archive + compiles PHP extensions), starts the containers, then installs Joomla. Joomla is then accessible at http://localhost:8080.

> **Important:** when changing versions, use `make clean` then `make up` rather than `make reset`. This ensures no leftover volume data from the previous version masks the new image's files.

### Choosing the Version

Two variables in `.env`:

```
JOOMLA_VERSION=4.4.9
PHP_VERSION=8.1
```

`JOOMLA_VERSION` matches the exact GitHub release tag: https://github.com/joomla/joomla-cms/releases

### Available Versions and Installation Method

| Branch | Available versions | Installation |
|--------|-------------------|--------------|
| 4.4.x | 4.4.0 → 4.4.9 | ✅ Automatic (CLI) |
| 4.3.x | 4.3.0 → 4.3.4 | ✅ Automatic (CLI) |
| 4.2.x | 4.2.0 → 4.2.9 | ⚠️ Manual (browser wizard) |
| 4.1.x | 4.1.0, 4.1.2 → 4.1.5 | ⚠️ Manual (browser wizard) |
| 4.0.x | 4.0.0 → 4.0.6 | ⚠️ Manual (browser wizard) |
| 3.x | up to 3.10.12 | ⚠️ Manual (browser wizard) |

> Non-existent versions — do not use: `4.1.1`, `4.2.10` and beyond in 4.2.x, `4.3.5`, `4.3.6`.

The Joomla CLI installer (`installation/joomla.php`) was introduced in **4.3.0**. All earlier versions (3.x, 4.0.x, 4.1.x, 4.2.x) require the browser wizard.

### Matching PHP to the Joomla Version

| Joomla version | Recommended PHP_VERSION |
|----------------|------------------------|
| 3.x | `7.4` |
| 4.0.x – 4.2.x | `8.1` |
| 4.3.x – 4.4.x | `8.1` or `8.2` |

### Automatic Installation (4.3.x and 4.4.x)

`provision.sh` detects the version and runs the CLI installer without any interaction. At the end of startup:

```
======================================================
 Joomla 4.4.9 ready: http://localhost:8080
 Admin : http://localhost:8080/administrator
 Login : admin / Admin@VulnLab1
======================================================
```

### Manual Installation — Browser Wizard (3.x, 4.0.x, 4.1.x, 4.2.x)

For these versions, `provision.sh` prints the parameters to enter in the wizard:

```
======================================================
 Joomla 4.2.8 starting: http://localhost:8080

 This version has no CLI installer.
 Complete the wizard in your browser:
   http://localhost:8080/installation/

 Database parameters to enter in the wizard:
   DB Type     : MySQLi
   DB Host     : db   ← important, not localhost
   DB User     : joomla
   DB Password : joomla
   DB Name     : joomla
======================================================
```

> **Critical:** in the database host field, enter `db` and not `localhost`. Under Docker, `localhost` attempts a Unix socket connection that does not exist in the Joomla container — this causes a *"No such file or directory"* error.

### Installing an Extension (Build Lab)

Place the extension zip in `./extensions/`, then install via the admin interface:

**System → Install Extensions → Upload Package File**

> Unlike the official image lab, the build lab does not support automatic extension installation at startup. The admin interface is the most reliable method for all 3.x and 4.x versions.

---

## Default Admin Account

| Field | Value |
|-------|-------|
| Admin URL | http://localhost:8080/administrator |
| Username | `admin` |
| Password | `Admin@VulnLab1` |

---

## Typical Test Loop

**Official image lab (5.x / 6.x):**

```bash
# .env: set JOOMLA_TAG=5.4.7-php8.2-apache
make up
# ... run your PoC against http://localhost:8080 ...
make reset   # wipes and reinstalls in seconds
```

**Build lab (3.x / 4.x):**

```bash
# .env: set JOOMLA_VERSION=4.4.3 / PHP_VERSION=8.1
make up
# ... run your PoC ...

# Minor version change (same branch) → reset
make reset

# Major version or branch change → clean rebuild
# .env: JOOMLA_VERSION=4.2.8
make clean
make up
```

> Use `make reset` to stay on the same branch (minor version change), and `make clean` + `make up` when changing major version or branch. This avoids file conflicts between structurally different versions.

---

## Running Multiple Labs in Parallel

```bash
make up NAME=joomla-A HTTP_PORT=8081
make up NAME=joomla-B HTTP_PORT=8082
```

> Pass the same `NAME` to subsequent commands: `make reset NAME=joomla-A`, `make down NAME=joomla-A`, etc.

---

## macOS / Apple Silicon

The official Joomla image (5.x / 6.x) is published for `arm64v8` — no additional configuration needed. All versions run natively.

For the build lab (3.x / 4.x), PHP base images (`php:x.x-apache`) are multi-arch. If you encounter a `no matching manifest for linux/arm64/v8` error, uncomment `platform: linux/amd64` under the `joomla` service in `docker-compose.yml`, then restart.

---

## Available Commands

Shared by both labs:

| Command | Effect |
|---------|--------|
| `make up` | Start the lab and install Joomla automatically. |
| `make shell` | Open a shell in the Joomla container. |
| `make logs` | Stream logs (useful during a PoC). |
| `make reset` | Reset to a clean state (same version, DB wiped). |
| `make down` | Stop containers while keeping data. |
| `make clean` | Remove containers and volumes (use before a version change). |

Official image only:

| Command | Effect |
|---------|--------|
| `make ext EXT=<zip or URL>` | Install an extension on the running lab. |

---

## Security Reminder

These labs are intentionally isolated locally. Never expose them on a network accessible from outside, and only test code you are authorized to evaluate (public extensions, your own targets, or bug bounty programs within defined scope).
