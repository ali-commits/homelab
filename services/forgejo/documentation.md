# Forgejo - Self-hosted Git forge (the GitHub replacement)

## Purpose

Forgejo hosts the git repositories, issues, pull requests and CI that previously
lived on GitHub. It is here so that code, CI minutes and the repository history stay
on RedRipper: nothing important depends on a third party's free tier, and cloning
keeps working when the internet does not.

Community-governed fork of Gitea; chosen over GitLab CE (too heavy for one host) and
over running bare `git` + `cgit` (no issues, PRs, or CI). Forgejo Actions uses the
`act_runner` we already run in Docker, and its API is Gitea-compatible, so `fj`, `tea`
and existing tooling work unchanged.

## Configuration

### Environment Variables

All of it lives in `services/forgejo/.env` (gitignored - this repo is public).

| Variable | Description | Example / Default |
| -------- | ----------- | ----------------- |
| `FORGEJO_VERSION` | Pinned image tag. Bump deliberately: Forgejo majors have migration steps | `16.0.4` |
| `RUNNER_VERSION` | Runner image tag | `12` |
| `DB_PASSWORD` | Postgres password for the `forgejo` role | generated |
| `SECRET_KEY` | Instance secret (session/crypto) | `forgejo generate secret SECRET_KEY` |
| `INTERNAL_TOKEN` | Internal API token | `forgejo generate secret INTERNAL_TOKEN` |
| `JWT_SECRET` | OAuth2 JWT secret | `forgejo generate secret JWT_SECRET` |
| `LFS_JWT_SECRET` | Git LFS JWT secret | `forgejo generate secret LFS_JWT_SECRET` |

Non-secret configuration is passed inline in `compose.yml` as `FORGEJO__<section>__<KEY>`
variables, which Forgejo merges into `app.ini` at every boot. Two keys do **not** work
that way and are called out in Troubleshooting: `APP_NAME` and `DEFAULT_PRIVATE`.

### Ports

- **3000**: web UI and git over HTTPS (both proxied by Traefik)
- **2222**: git over SSH on the host, mapped to the container's sshd on 22
- **2222 is not exposed through the Cloudflare tunnel** (HTTP only) - see Usage

### Domains

- **External**: https://git.alimunee.com (Traefik router `forgejo` → `cloudflared` tunnel)
- **Internal**: http://forgejo:3000

## Dependencies

- **Networks**: `proxy` (Traefik + tunnel + postfix relay), `forgejo_internal` (Forgejo ↔ DB ↔ runner), `db_network`
- **Storage**:
  - `/storage/data/forgejo/data/git/repositories` - the bare repos (`ROOT = /data/git/repositories`)
  - `/storage/data/forgejo/data/gitea` - `conf/app.ini`, LFS, attachments, packages, logs
  - `/storage/data/forgejo/db` - Postgres data dir
  - `/storage/data/forgejo/runner` - runner secret, config, job workspaces
  - `/storage/data/forgejo/dumps` - nightly `forgejo dump` archives
- **External Services**: Zitadel (SSO), postfix relay (mail), Kopia (backup)

## Setup

### 1. Create Storage Directories

```bash
sudo mkdir -p /storage/data/forgejo/{data,db,runner,dumps}
sudo chown -R 1000:1000 /storage/data/forgejo/data /storage/data/forgejo/runner /storage/data/forgejo/dumps
# Postgres runs as uid 70 in the alpine image
sudo chown -R 70:70 /storage/data/forgejo/db
```

### 2. Generate Secrets And Deploy

```bash
cd /HOMELAB/services/forgejo
cp .env.template .env && chmod 600 .env   # then fill the four secrets + DB_PASSWORD
docker compose up -d
```

The instance boots without the web installer because `INSTALL_LOCK=true` and the
database is already configured through the environment.

### 3. Create The Admin Account

```bash
docker exec -u git forgejo forgejo admin user create \
  --admin --username ali --email <your-email> \
  --password '<generated>' --must-change-password=false
```

OIDC is wired up *after* this account exists: get the order wrong and there is no way
to log in to fix it. Change the password (or drop local login once SSO works) in
Settings → Account.

### 4. Fix `APP_NAME` In The Root Config Section

`APP_NAME` must be edited in the generated `app.ini`, not through an environment
variable:

```bash
# line 1 of the unnamed/root section - this is the value Forgejo actually displays
sudo sed -i '1s/.*/APP_NAME = RedRipper Forge/' \
  /storage/data/forgejo/data/gitea/conf/app.ini
docker compose restart forgejo
```

Why: the image's config template pins `APP_NAME` in the root section. An
`FORGEJO__DEFAULT__APP_NAME` variable is written by `environment-to-ini` into a
`[default]` section, which go-ini treats as *different* from the root section, and
`FORGEJO__server__APP_NAME` lands in `[server]`. Neither is what the renderer reads.
The edit survives restarts and is included in the Kopia backup; on a from-scratch
deploy it must be redone.

### 5. Actions Runner

```bash
bash setup-runner.sh          # idempotent: secret, registration, config.yaml
docker compose up -d forgejo-runner
```

The script writes `runner-secret` and `config.yaml` to `/storage/data/forgejo/runner/`
rather than into this repository, because the UUID is derived from the secret and the
repo is public.

### 6. Zitadel SSO (OIDC) - registered 2026-09-12

App `Forgejo` in the *Homelab* project, client ID `390385826216869895`. Zitadel
changed the console wording in v4: the method option that used to read **Basic** is
now labeled **Code**.

**New Application** → name `Forgejo` → type **Web** → authentication method **Code** →
redirect URI:

```
https://git.alimunee.com/user/oauth2/zitadel/callback
```

Then copy the client ID and secret into `.env` (`ZITADEL_CLIENT_ID` /
`ZITADEL_CLIENT_SECRET`) and register the source:

```bash
docker exec -u git forgejo forgejo admin auth add-oauth \
  --name zitadel --provider openidConnect \
  --key "$ZITADEL_CLIENT_ID" --secret "$ZITADEL_CLIENT_SECRET" \
  --auto-discover-url https://zitadel.alimunee.com/.well-known/openid-configuration \
  --scopes openid --scopes email --scopes profile
```

`[oauth2_client] ENABLE_AUTO_REGISTRATION=true` then provisions a Forgejo account for
any homelab user who signs in through Zitadel. Outside collaborators do **not** get
Zitadel accounts - create them locally and hand out access tokens.

The app registration cannot be scripted: the `login-client` machine PAT that ships in
`/storage/data/zitadel/config/login-client.pat` has read-only project access
(`AUTH-5mWD2` on create). It is a four-click job in the console.

**Pick `Code`, never `PKCE`.** Zitadel issues no client secret for a PKCE app, and
Forgejo's auth-source form requires one; separately, Forgejo sends no `code_challenge`
in its authorize request (verified against the live redirect), so a PKCE-enforcing app
would reject the login. `Code` maps to `client_secret_basic` on Zitadel's token
endpoint; if that exchange ever 401s, switch the app to `Post` rather than rebuilding.

The auth source lives in the Forgejo **database**, not in `app.ini` - restoring it means
restoring `forgejo-db.sql` from the nightly dump, then re-running `add-oauth` if the
source was added after the dump. `forgejo admin auth list` should show
`1  zitadel  OAuth2  true`.

<!--lint disable double-link-->

The login button renders as **Sign in with zitadel** (lowercase) because the auth source
name is also the callback path segment `/user/oauth2/zitadel/`. Renaming it for cosmetics
silently breaks the redirect URI registered in Zitadel - leave it lowercase.

### 7. Publish The Hostname

```bash
bash /HOMELAB/scripts/flared add git      # tunnel route + DNS CNAME
```

## Usage

### Cloning And Pushing (HTTPS - the default path)

Zitadel SSO gates the *browser* only. Git over HTTPS authenticates with a Forgejo
access token, which is why CI, scripts and outside collaborators keep working:

1. Settings → Applications → **Generate New Token** (scope `write:repository`)
2. `git clone https://git.alimunee.com/ali/<repo>.git` and use the token as the password

Public repositories clone anonymously with no credentials at all.

### Cloning And Pushing (SSH)

SSH cannot travel through the Cloudflare tunnel, so port 2222 is reachable from the
LAN and from Tailscale only:

```bash
git clone ssh://git@100.102.64.99:2222/ali/<repo>.git
```

`SSH_DOMAIN=git.alimunee.com` keeps the URLs in the UI coherent; on the LAN (and over
Tailscale, where the name resolves) the same hostname works because AdGuard points
`*.alimunee.com` at `192.168.1.2`. From the public internet it does not - that is
intentional, not a bug.

### Actions

`forgejo-runner` serves labels `ubuntu-latest` and `ubuntu-22.04`, both mapped to
`docker://node:22-bookworm`. Workflows live in `.forgejo/workflows/`.

## Integration

- **Zitadel** - OIDC login, auto-provisioning for homelab users (see Setup 6)
- **Postfix** - outbound mail via the `postfix` relay alias on port 25, from
  `forgejo@alimunee.com`. `alimunee.com` SPF includes `spf.brevo.com` and DKIM is
  published (`brevo1._domainkey`), so notification mail authenticates
- **Kopia** - `/storage/data/forgejo` is inside the nightly B2 backup scope
- **Webhooks** - `ALLOWED_HOST_LIST=external,private`, so repos can call internal
  services (n8n, ntfy) as well as public ones
- **Traefik** - router `forgejo`, no Sablier: `git push`, webhooks and job polling
  cannot tolerate a cold start

## Troubleshooting

### Runner container exits with `exec: "daemon": executable file not found in $PATH`

The runner image declares **no ENTRYPOINT**, so a bare `command: ["daemon", ...]`
replaces the binary path with the subcommand. Use the full path:

```yaml
command: ["/bin/forgejo-runner", "daemon", "--config", "/storage/data/forgejo/runner/config.yaml"]
```

### Runner logs `permission denied while trying to connect to the Docker daemon socket`

The image runs as uid 1000, which is not in the host's `docker` group (gid 987).
Mounting the socket is not enough:

```yaml
group_add:
- "987"
```

Verify with `stat -c '%g' /var/run/docker.sock` - the gid changes if the daemon is
reinstalled.

### New repositories are not private by default

`DEFAULT_PRIVATE` is documented in the example config's `[service]` block, but the v16
web form only honours it in `[repository]`:

```yaml
- FORGEJO__repository__DEFAULT_PRIVATE=private
```

Prove it by loading `/repo/create` while logged in and checking that the *Make
repository private* box is pre-ticked. Note the API does **not** apply this default -
API clients must send `"private": true`.

### The instance still shows "Forgejo: Beyond coding. We forge."

See Setup 4 - `APP_NAME` is a root-section key.

### Job steps fail with "not a git repository", or an empty workspace

Job containers are siblings created by the host daemon, so the runner's workspace
path must be identical on both sides. That is why the runner mounts
`/storage/data/forgejo/runner` at the *same* path, and why `host.workdir_parent` in
`config.yaml` points at `/storage/data/forgejo/runner/act`. Mounting it at `/data`
instead breaks every job in a way that looks like a checkout bug.

### Invites to outside collaborators land in spam

Check `alimunee.com` SPF before blaming Forgejo - it must include `spf.brevo.com`
alongside `zohomail.com`. Forgejo itself is only relaying through postfix.

### Health Check

```bash
docker compose ps                                   # forgejo, forgejo-db, forgejo-runner
curl -fsS http://localhost:3000/api/healthz
curl -fsSI https://git.alimunee.com/api/v1/version
docker logs --tail 20 forgejo-runner                # "declared successfully" = registered
```

## Backup

### Data to Backup

- **Repositories and config**: `/storage/data/forgejo/data` (includes `app.ini`)
- **Database**: `/storage/data/forgejo/db` - but prefer the logical dump below
- **Runner state**: `/storage/data/forgejo/runner` (secret + config; losing it means re-running `setup-runner.sh`)

Kopia covers `/storage/data` nightly to Backblaze B2, so repositories are off-site
protected without extra plumbing. Copying a live Postgres data directory is *not* a
consistent backup, hence the dump job:

```bash
sudo install -m 755 configs/scripts/forgejo-dump.sh /usr/local/bin/forgejo-dump.sh
sudo install -m 644 configs/systemd/forgejo-dump.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now forgejo-dump.timer
systemctl list-timers forgejo-dump.timer    # daily 03:30
```

The script must land as an executable: systemd reports `status=203/EXEC` / "Permission
denied" if the target is mode 644, which reads like a missing file rather than a
permission problem.

`configs/scripts/forgejo-dump.sh` (installed to `/usr/local/bin/forgejo-dump.sh`, like the
Kopia and btrfs jobs) runs `forgejo dump` into `/storage/data/forgejo/dumps` and keeps
7 days.

### Restore Process

1. Stop the stack: `cd /HOMELAB/services/forgejo && docker compose down`
2. Restore `/storage/data/forgejo/` from Kopia, or unzip a dump for a logical restore
3. `docker compose up -d`
4. Verify: `curl -fsS http://localhost:3000/api/healthz`, then check a few repository
   pages and that `forgejo-runner` logs `declared successfully`
