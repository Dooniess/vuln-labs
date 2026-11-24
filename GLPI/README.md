# GLPI Docker Labs

A set of Docker labs for testing GLPI vulnerabilities across specific versions. Two complementary labs are provided to cover the full version range.

* **Official image lab** — uses the official `glpi/glpi` Docker image. Fast, no build step, automatic installation. Use for **currently maintained branches** (10.0.x, 11.0.x).
* **Build lab** — builds the image from the official version archive. Use for **all other versions**, especially **older ones** not available as official images (9.4, 9.5, old 10.0.x point releases).

**🚨 These Docker containers are intended for TEMPORARY USE ONLY 🚨**

---

## Prerequisites

* Docker Desktop running (`docker` and `docker compose` available)
* `make`, `curl` (provided by Command Line Tools on macOS)

---

## Which Lab to Use?

| Situation | Lab to use |
|-----------|------------|
| Maintained version (recent 10.0.x, 11.0.x) | Official image |
| Old version / point release not in official images | Build |
| Need to start quickly, no compilation | Official image |
| Version not available on Docker Hub | Build |

When in doubt: try the official image first; if the tag doesn't exist, switch to the build lab.

---

## Lab 1 — Official Image

### Getting Started

```bash
cp .env.example .env
# edit GLPI_TAG in .env to select the version, then:
make up
```

GLPI installs **automatically** on first startup: the official image creates its schema as soon as it receives the database credentials (provided by `docker-compose.yml`). No manual installation step is required. GLPI is then accessible at http://localhost:8080.

### Choosing the Version

The version corresponds to the **official image tag**, set via `GLPI_TAG` in `.env`:

```
GLPI_TAG=11.0.8      # specific version
GLPI_TAG=10.0.25     # LTS branch
GLPI_TAG=latest      # latest stable
```

Available tags: https://hub.docker.com/r/glpi/glpi/tags

To change the version: update `GLPI_TAG`, then run `make reset`.

> **Important limitation:** official images only publish maintained branches. For older versions, no tag exists — use the build lab instead.

### Timezones (optional)

GLPI displays a warning until timezone support is enabled. No impact on testing, but to dismiss it:

```bash
make timezones
```

---

## Lab 2 — Build from Archive

### Getting Started

```bash
cp .env.example .env
# edit GLPI_VERSION and PHP_VERSION in .env, then:
make up
```

The first `make up` builds the image (downloads the official archive + compiles PHP extensions), starts the containers, then installs GLPI via CLI (`bin/console db:install`). GLPI is then accessible at http://localhost:8080.

### Choosing the Version

Two variables in `.env`:

```
GLPI_VERSION=9.5.11   # any version from GitHub releases
PHP_VERSION=7.4       # base PHP version, must match GLPI requirements
```

Full version list: https://github.com/glpi-project/glpi/releases

To change the version: update `GLPI_VERSION` (and `PHP_VERSION` if needed), then run `make reset`. One-off test without editing `.env`:

```bash
GLPI_VERSION=10.0.6 PHP_VERSION=8.1 make reset
```

### Matching PHP to the GLPI Version

The PHP version must be compatible with the GLPI version, otherwise installation fails:

| GLPI version | Recommended PHP_VERSION |
|--------------|------------------------|
| 9.5.x | `7.4` |
| 10.0.0 – 10.0.5 | `7.4` or `8.1` |
| 10.0.6+ | `7.4`, `8.1`, or `8.2` |

> For GLPI ≤ 9.4 (PHP ≤ 7.3), the `gd` extension option syntax differs: a comment in the `Dockerfile` indicates the variant to use.

---

## Default Accounts

Shared by both labs, created automatically at installation:

| Username | Password | Profile |
|----------|----------|---------|
| `glpi` | `glpi` | Super-administrator |
| `tech` | `tech` | Technician |
| `normal` | `normal` | Standard user |
| `post-only` | `postonly` | Self-service |

A fresh install will also warn that the `install/` directory should be removed. In a lab context, this warning can be safely ignored.

---

## Testing a Plugin

The `./plugins/` folder is mounted into the GLPI container. Place the plugin to test there (one subfolder per plugin, e.g. `./plugins/myplugin/`), then activate it:

* via the interface: **Configuration > Plugins**;
* via CLI — the exact command names may vary by version; list them with `make console CMD="list"`:

```bash
make console CMD="plugin:install myplugin"
make console CMD="plugin:activate myplugin"
```

---

## Typical Test Loop

Applies to both labs (only the version variable name differs):

```bash
# .env: set the target version
make up
# ... run your PoC against http://localhost:8080 ...
make reset          # clean state in seconds
# .env: set the patched version to verify the fix
make reset
```

`make reset` wipes the volumes and reinstalls GLPI from scratch — ideal to avoid state leaking between tests.

---

## Running Multiple Labs in Parallel

Each lab uses a distinct project name and port:

```bash
make up NAME=glpi-A HTTP_PORT=8081
make up NAME=glpi-B HTTP_PORT=8082
```

> Pass the same `NAME` (and `HTTP_PORT` if needed) to subsequent commands, e.g. `make reset NAME=glpi-A` or `make down NAME=glpi-A`.

---

## macOS / Apple Silicon

Images are pulled automatically for your architecture. Some versions — especially **older ones** — are only published for **amd64**, with no `arm64` variant. In that case, Docker refuses to run them with:

```
no matching manifest for linux/arm64/v8 in the manifest list entries
```

Fix: uncomment the `platform: linux/amd64` line under the `glpi` service in `docker-compose.yml`, then run `make reset`. A warning about platform mismatch will appear — this is expected and harmless.

Two useful tips:

* Enable **Rosetta** in Docker Desktop (**Settings → General → "Use Rosetta for x86/amd64 emulation"**): emulation becomes significantly faster than QEMU, which is noticeable with PHP applications.
* You can leave `platform: linux/amd64` permanently enabled: even on a multi-arch image, forcing amd64 works (it will just run emulated instead of native).

---

## Available Commands

Shared by both labs:

| Command | Effect |
|---------|--------|
| `make up` | Start the lab and install GLPI (build lab also compiles the image). |
| `make console CMD="list"` | Run a GLPI console command. |
| `make shell` | Open a shell in the GLPI container. |
| `make logs` | Stream logs (useful during a PoC). |
| `make reset` | Reset the environment to a clean state. |
| `make down` | Stop containers while keeping data. |
| `make clean` | Remove the entire environment (containers and volumes). |

Official image only: `make timezones` (enables timezone support).

---

## Security Reminder

These labs are intentionally isolated locally. Never expose them on a network accessible from outside — the default accounts and deliberately vulnerable versions make them trivially compromisable — and only test code you are authorized to evaluate.
