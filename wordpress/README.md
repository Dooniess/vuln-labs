# WordPress Docker Lab

A local Docker lab for testing WordPress plugin vulnerabilities. It provides a WordPress instance with WP-CLI, allowing you to validate PoCs against specific plugin versions.

**🚨 This Docker container is intended for TEMPORARY USE ONLY 🚨**

---

## Prerequisites

* Docker Desktop running (`docker` and `docker compose` available)
* `make`, `curl` (provided by Command Line Tools on macOS)
* `svn` (`brew install svn`) — only needed to rebuild a pulled version
* `zip` — same

---

## Getting Started

```bash
cp .env.example .env
# edit the .env file as needed, then:
make up
```

Adjust the `.env` file **before** starting the lab.

Configurable parameters include:

* the exposed HTTP port;
* the WordPress image used (the tag includes the PHP version, e.g. `6.4-php8.1-apache`).

Once `make up` completes, WordPress is accessible at [http://localhost:8080](http://localhost:8080) (`admin` / `admin` by default). Installation is automatic.

---

## Installing a Plugin

### Latest version

```bash
make plugin SLUG=contact-form-7
```

### Specific version

```bash
make plugin SLUG=wp-fastest-cache VERSION=1.2.2
```

### Finding the plugin SLUG

The `SLUG` is the plugin's exact identifier, as it appears in its WordPress.org URL. Go to [https://wordpress.org/plugins](https://wordpress.org/plugins), find the plugin, and extract the name from the URL.

> Example: for the plugin `LC Lightbox Lite`, the URL is  
> `https://wordpress.org/plugins/`**`lc-lightbox-lite`**`/`  
> → the SLUG is `lc-lightbox-lite`.

This is not the plugin's display name, but its technical URL identifier.

---

## How a Version is Resolved

When you request a specific version, the script tries multiple sources in order:

1. **Local zip** — `./plugins/<slug>.<version>.zip`, if you placed it there yourself.
2. **WordPress.org via WP-CLI** — fetches the version if it is still published in the official directory.
3. **Direct download** — from `https://downloads.wordpress.org/plugin/<slug>.<version>.zip`.
4. **SVN fallback** — if all previous steps fail, the script prints the rebuild procedure (see next section).

For free plugins, every published version is archived by WordPress.org via two mechanisms:

* the **ready-to-use zip**: `https://downloads.wordpress.org/plugin/<slug>.<version>.zip` (targeted by steps 2 and 3);
* the **SVN source repository**: `https://plugins.svn.wordpress.org/<slug>/`, with a `tags/` folder containing a copy of the code for each published version.

> **Important:** when a version is pulled for security reasons (status "closed"), the ready-to-use zip typically disappears — steps 2 and 3 will fail. This is precisely the most common case for vulnerable versions you want to test. The SVN source code, however, usually remains accessible.

---

## Rebuilding a Pulled Version (SVN)

SVN provides **raw source files**, whereas WordPress only installs plugins from a **zip**. You therefore need to fetch the sources for the desired version and repackage them.

Example for `wp-fastest-cache` version `1.2.2`:

```bash
# 1. Fetch the sources for this exact version
svn export https://plugins.svn.wordpress.org/wp-fastest-cache/tags/1.2.2/ wp-fastest-cache

# 2. Repackage (the zip folder MUST be named after the slug)
zip -r wp-fastest-cache.1.2.2.zip wp-fastest-cache

# 3. Place the archive in the lab
cp wp-fastest-cache.1.2.2.zip ./plugins/

# 4. Re-run: step 1 (local zip) now succeeds
make plugin SLUG=wp-fastest-cache VERSION=1.2.2
```

To list **all available versions** of a plugin, open in a browser:  
`https://plugins.svn.wordpress.org/<slug>/tags/` — this page lists all tags, i.e. all published versions.

---

## Premium / Paid Plugins

Only **free plugins from the official directory** are listed on wordpress.org.

**Premium / paid plugins** (purchased from a vendor, CodeCanyon, etc.) are not listed there: none of the automatic steps will work. You will need to manually place the zip in `./plugins/`, named `<slug>.<version>.zip`, before running `make plugin`.

---

## Typical Test Loop

```bash
make plugin SLUG=xxx VERSION=y.y.y   # set up the target
# ... run your PoC against http://localhost:8080 ...
make reset                           # 100% clean state in seconds
make plugin SLUG=xxx VERSION=z.z.z   # next version
```

`make reset` destroys the database and files, then reinstalls a clean WordPress — ideal to avoid previous test state leaking into the next one.

---

## Running Multiple Labs in Parallel

Each lab uses a distinct project name and port:

```bash
make up NAME=lab-cve-A HTTP_PORT=8081
make up NAME=lab-cve-B HTTP_PORT=8082
```

> Pass the same `NAME` (and `HTTP_PORT` if needed) to subsequent commands for that lab, e.g.:  
> `make plugin NAME=lab-cve-A SLUG=... VERSION=...` or `make down NAME=lab-cve-A`.

---

## Available Commands

| Command | Effect |
|---------|--------|
| `make up` | Start the environment and install WordPress. |
| `make plugin SLUG=<plugin> VERSION=<version>` | Install a plugin (`VERSION` is optional). |
| `make wp CMD="plugin list"` | Run an arbitrary WP-CLI command. |
| `make shell` | Open a shell in the WordPress container. |
| `make logs` | Stream logs (useful during a PoC). |
| `make reset` | Reset the environment to a clean state. |
| `make down` | Stop containers while keeping data. |
| `make clean` | Remove the entire environment (containers and volumes). |

---

## Security Reminder

This lab is intentionally isolated locally. Never expose it on a network accessible from outside, and only use it on code you are authorized to test (public plugins, your own targets, or bug bounty programs within defined scope).
