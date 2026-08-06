# Flox Buildkite Plugin

[![CI](https://github.com/imkarrer/flox-buildkite-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/imkarrer/flox-buildkite-plugin/actions/workflows/ci.yml)

Run your Buildkite steps inside a reproducible [Flox](https://flox.dev) environment that lives in your repo. No Dockerfile, no container registry, no image tags to keep in sync — the environment travels with your code, so a dependency change and the code that needs it land in a single commit.

The plugin wraps each step in `flox activate`, materializing the environment on any Linux/macOS runner: if `flox` is on `PATH` it uses it, otherwise it downloads and installs the platform package from `downloads.flox.dev` (same URL scheme as [`install-flox-action`](https://github.com/flox/install-flox-action)). The lockfile pins every dependency to a content hash, so builds are reproducible without pre-baked runner images or a Docker supply chain to maintain.

Flox ships first-class CI integrations for GitHub Actions, CircleCI, and GitLab — Buildkite is the gap this plugin fills. You *floxify* a repo once (`flox init` writes `.flox/manifest.toml`, committed alongside your code); this plugin is the Buildkite-native way to run against that environment — the counterpart to [`install-flox-action`](https://github.com/flox/install-flox-action) for GitHub Actions and the [Flox orb](https://github.com/flox/flox-orb) for CircleCI. It turns the bare `flox activate -c` you'd otherwise hand-roll in every command step into declarative plugin config: flox auto-install on ephemeral agents, FloxHub token and `trust` handling, per-directory environments for monorepos, and matrix builds.

## Why not just bake a Docker image?

You can, and plenty of teams do. The usual path to a reproducible CI environment is a Dockerfile: install your toolchain, build the image, push it to a registry, and point your agents at the tag. It works — but it leaves you owning a second artifact that lives outside your repo, versions on its own schedule, and has to be rebuilt and re-pushed every time a dependency moves.

Flox collapses that. The environment is a single file in your repo (`.flox/manifest.toml`) with a lockfile pinning every package to a content hash. Nothing to build, nothing to publish — the plugin realizes the environment on the runner at job time, and changing a dependency lands in the same commit as the code that needs it.

Here's the same Node build environment defined both ways.

**Docker** — write a Dockerfile:

```dockerfile
FROM buildkite/agent:3

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates git \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm@9 \
    && rm -rf /var/lib/apt/lists/*
USER buildkite
```

Build it, push it, then reference the tag in your pipeline:

```bash
docker build -t your-registry/ci-node:22 .
docker push your-registry/ci-node:22
```

```yml
steps:
  - command: pnpm install && pnpm build
    agents:
      queue: docker
    plugins:
      - docker#v5.11.0:
          image: your-registry/ci-node:22
```

**Flox** — declare the same tools and commit the result:

```bash
flox init
flox install nodejs_22 pnpm
```

That writes `.flox/manifest.toml`:

```toml
schema-version = "1.14.0"

[install]
nodejs_22.pkg-path = "nodejs_22"
pnpm.pkg-path = "pnpm"
```

Commit `.flox/`, then run against it — no registry, no image tag to track:

```yml
steps:
  - command: pnpm install && pnpm build
    plugins:
      - imkarrer/flox#v1.0.0:
          command: pnpm install && pnpm build
```

The gap shows up on day two. Bumping Node from 22 to 24 with Docker means editing the Dockerfile, rebuilding, pushing, and usually bumping a tag in a separate PR before CI ever sees the change. With Flox it's `flox install nodejs_24` on the same branch as the code that needs it — one commit, and the identical environment activates on your laptop with `flox activate`. No more "green in CI, broken locally."

Reach for Flox when you already use it locally, run a monorepo with many environments, or just want to stop maintaining a separate CI image pipeline. Docker still earns its keep when you need kernel-level isolation for untrusted build steps, or when the image *is* the thing you ship — and the two aren't mutually exclusive: bake `flox` into a slim agent image to skip cold-start install time and let the plugin realize each repo's `.flox/` on top (see [Docker](#docker) below). But for the everyday case — "make CI use the same tools as my project" — a committed Flox environment is a file and a commit, not a pipeline you have to babysit.

## Usage

### Local environment

```yml
steps:
  - command: npm run build
    plugins:
      - imkarrer/flox#v1.0.0:
          command: npm run build
```

The `.flox/` directory lives in your repo — no auth needed.

### Remote environment from FloxHub

```yml
steps:
  - command: netlify deploy
    plugins:
      - imkarrer/flox#v1.0.0:
          command: netlify deploy
          environment: my-org/netlify-deploy
          floxhub-token: BKvR...
```

Better: set the token once on the agent as an environment variable.

```yml
steps:
  - command: netlify deploy
    plugins:
      - imkarrer/flox#v1.0.0:
          command: netlify deploy
          environment: my-org/netlify-deploy
```

```bash
# Agent environment or Buildkite pipeline env:
FLOX_TOKEN=BKvR...
```

### Remote environment from another org (requires trust)

```yml
steps:
  - command: deploy
    plugins:
      - imkarrer/flox#v1.0.0:
          command: deploy
          environment: another-org/tools
          floxhub-token: BKvR...
          trust: true
```

### Multi-step pipeline

```yml
steps:
  - label: ":flox: Lint"
    command: eslint .
    plugins:
      - imkarrer/flox#v1.0.0:
          command: eslint .
  - label: ":flox: Test"
    command: vitest run
    plugins:
      - imkarrer/flox#v1.0.0:
          command: vitest run
```

### Monorepo subdirectory

```yml
steps:
  - label: ":rust: Build backend"
    plugins:
      - imkarrer/flox#v1.0.0:
          dir: backend
          command: cargo build --release
  - label: ":react: Build frontend"
    plugins:
      - imkarrer/flox#v1.0.0:
          dir: frontend
          command: vite build
```

### Matrix build

```yml
steps:
  - label: ":flox: Test python {{ matrix.env }}"
    plugins:
      - imkarrer/flox#v1.0.0:
          environment: my-org/python-{{ matrix.env }}
          command: pytest
    matrix:
      - env: "3.11"
      - env: "3.12"
      - env: "3.13"
```

### Containerize and push

```yml
steps:
  - label: ":docker: Build image"
    plugins:
      - imkarrer/flox#v1.0.0:
          command: flox containerize --runtime docker
  - label: ":docker: Push"
    commands:
      - docker tag myapp-container:latest registry.example.com/myapp:${BUILDKITE_COMMIT}
      - docker push registry.example.com/myapp:${BUILDKITE_COMMIT}
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `command` | string | — | Command to run inside the Flox environment |
| `channel` | string | `stable` | Flox release channel (`stable`, `qa`, `nightly`, or commit hash) |
| `version` | string | _(empty = channel latest)_ | Pin a specific flox version (e.g. `1.14.0`) |
| `environment` | string | — | Remote FloxHub environment in `owner/name` format |
| `dir` | string | — | Path to directory containing a `.flox/` environment |
| `floxhub-token` | string | — | FloxHub token for remote environment auth (falls back to `FLOX_TOKEN` env var) |
| `activation-mode` | string | _(empty = manifest default)_ | Activate in `dev` or `run` mode (equivalent to `flox activate -m`, overrides `options.activate.mode` in the manifest) |
| `trust` | boolean | `false` | Trust remote environment hook (equivalent to `flox activate --trust`) |
| `s3-cache-bucket` | string | — | S3-compatible Nix binary cache bucket (e.g. `flox-binary-cache`). Empty disables the cache |
| `s3-cache-endpoint` | string | — | Full S3 endpoint URL (R2: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` · AWS: `https://s3.<region>.amazonaws.com` · MinIO: `https://minio.example.com:9000`) |
| `s3-cache-region` | string | `auto` | S3 region for the cache (`auto` for R2) |
| `s3-cache-public-key` | string | — | Trusted Nix cache public key (`cache-name-1:base64=`) |
| `s3-cache-push` | boolean | `false` | Write back (push) the activated environment's closure to the cache after the step (needs `S3_CACHE_SIGNING_KEY`) |
| `disable-metrics` | boolean | `true` | Disable anonymous usage telemetry |

### Auth precedence

1. `floxhub-token` plugin config
2. `FLOX_TOKEN` environment variable (set on the agent or pipeline)
3. If neither is set and a remote environment is requested, activation fails

Local environments (`.flox/` in the repo via `dir`) need no auth.

## Caching

Cold agents pay a one-time flox install (~85 MB) plus the cost of realizing your
environment's packages from upstream on first use. The plugin can layer a
**Nix binary cache** on top so every build pulls prebuilt store paths from
nearby durable storage instead of upstream — the approach and scripts are
adapted from [jbayer/flox-buildkite](https://github.com/jbayer/flox-buildkite).

### S3-compatible binary cache (read)

Configuring the plugin with a bucket, endpoint, and trusted public key writes
an `extra-substituters` + `extra-trusted-public-keys` block into
`/etc/nix/nix.conf` (the file flox's bundled Nix reads), so a cold `flox
activate` substitutes already-built paths from the cache:

```yml
steps:
  - command: pnpm install && pnpm build
    plugins:
      - imkarrer/flox#v1.0.0:
          command: pnpm install && pnpm build
          s3-cache-bucket: flox-binary-cache
          s3-cache-endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com
          s3-cache-region: auto
          s3-cache-public-key: flox-binary-cache-1:base64=
```

Works with any S3-compatible object store (AWS S3, CloudFlare R2, MinIO, Ceph
RGW, Backblaze B2, …). Reads of a **private** bucket need the access key in the
job environment (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) or as
`S3_CACHE_ACCESS_KEY_ID` / `S3_CACHE_SECRET_ACCESS_KEY` cluster secrets; a
public-read bucket works without credentials. The substituter pointer is
non-secret, so you can also bake it into the [agent image](#docker) instead.

### Write-back (opt-in)

Set `s3-cache-push: true` to push the activated environment's closure back to
the cache after each step — signed, so the *next* cold build trusts it. Needs
the Nix signing key as `S3_CACHE_SIGNING_KEY` (or `S3_CACHE_SIGNING_KEY_FILE`)
in the job environment or as a `S3_CACHE_SIGNING_KEY` cluster secret:

```yml
steps:
  - command: pnpm install && pnpm build
    plugins:
      - imkarrer/flox#v1.0.0:
          command: pnpm install && pnpm build
          s3-cache-bucket: flox-binary-cache
          s3-cache-endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com
          s3-cache-public-key: flox-binary-cache-1:base64=
          s3-cache-push: true
```

> **Guard the signing key.** Anyone holding it can place *trusted* paths in
> your cache. Keep it only in Buildkite secrets, never in the image or repo;
> the plugin writes it to a `0600` temp file and deletes it on exit.

Generate a keypair once with:

```bash
nix --extra-experimental-features nix-command key generate-secret \
    --key-name flox-binary-cache-1 > secret.key
nix --extra-experimental-features nix-command key convert-secret-to-public \
    < secret.key > public.key
```

`public.key` is the non-secret `s3-cache-public-key`; `secret.key`'s text is
`S3_CACHE_SIGNING_KEY`.

### `/nix` cache volume (custom agent image)

With the [pre-baked image](#docker) you can attach a Buildkite `/nix` cache
volume to your queue to keep the packages your env pulls warm across builds.
The volume shadows the image's `/nix`, so when it mounts cold the plugin's
environment hook restores the store from `/opt/nix-seed` (the copy the
Dockerfile stashes outside `/nix`) before running anything. This is
best-effort — a binary cache is the reliable complement.

## Auto-install

When `flox` is missing, the plugin installs it at job start:

| Platform | Package | Notes |
|----------|---------|-------|
| Debian/Ubuntu (glibc) | `.deb` via `apt-get` | Resolves deps (e.g. `sudo`) |
| RHEL/Fedora/etc. | `.rpm` | Requires `rpm` on `PATH` |
| macOS | `.pkg` | Requires `installer` + sudo |
| Alpine / musl | — | **Not supported** — use `buildkite/agent:3-ubuntu` |

Pin with `channel` (`stable` / `qa` / `nightly` / commit hash) and optional `version`. An empty `version` pulls the channel's latest build (`flox.x86_64-linux.deb`, etc.). After install the hook starts `nix-daemon` when possible, or configures single-user Nix ownership on non-systemd hosts (matching Flox's GitHub Action). The hook also exports `FLOX_SHELL=bash` (silences CI's no-tty shell-detection warning) and `NIX_REMOTE=auto` (single-user Nix fallback) when unset.

## Docker

Use a pre-baked agent image to skip the install step — no downloads at job time, pinned flox version. See the [`Dockerfile`](Dockerfile) in this repo, which:

- bases on `buildkite/agent:3-ubuntu` (flox ships glibc packages and does not run on the default Alpine `buildkite/agent:3` image),
- installs flox from its `.deb` package (arch-aware, pinned via the `FLOX_VERSION` build arg),
- starts the Nix daemon on boot via a `/docker-entrypoint.d` hook, which flox requires (with `NIX_REMOTE=auto` as a single-user fallback),
- optionally bakes an S3 cache substituter into `/etc/nix/nix.conf` (via the `S3_CACHE_BUCKET` / `S3_CACHE_ENDPOINT` / `S3_CACHE_REGION` / `S3_CACHE_PUBLIC_KEY` build args),
- optionally bakes common packages into the store via the `SEED_PACKAGES` build arg (e.g. `--build-arg SEED_PACKAGES="nodejs python3 go"`), and
- stashes the baked store at `/opt/nix-seed` so a cold `/nix` cache volume can be restored by the plugin at job start.

Build, push, and configure your agents:

```bash
docker build -t your-registry/buildkite-agent-flox:latest .
docker push your-registry/buildkite-agent-flox:latest
```

## Developing

The repo root carries a Flox environment (`.flox/`) providing the dev toolchain, so `flox activate` is the only setup you need:

```shell
flox activate -c "docker compose run --rm tests"
```

Run the bats unit tests (they stub `flox`, so no account or network needed):

```shell
flox activate -c "docker compose run --rm tests"
```

No Docker? Run the identical suite locally, rootless — the same bats stack CI uses (bats-core 1.10.0, Buildkite's `bats-mock` fork, bats-assert/file/support) is downloaded once into the gitignored `.bats-libs/`:

```shell
scripts/test-local.sh
```

Lint the plugin definition:

```shell
flox activate -c "docker compose run --rm lint"
```

These run on every push and pull request via [GitHub Actions](.github/workflows/ci.yml), alongside a real `flox activate` smoke test using [`flox/install-flox-action`](https://github.com/flox/install-flox-action):

- **Blocking** — `Unit tests & lint` and `Real flox activation (local env)`. No account or token needed. Mark these as required status checks in branch protection.
- **Non-blocking** — `Real flox activation (remote env)` exercises the FloxHub path. A missing or expired `FLOX_TOKEN` produces a warning, never a merge-blocking failure, so token expiry never gates a merge. Add a `FLOX_TOKEN` repository secret to enable it; leave it as an *optional* check (not required) in branch protection.

### End-to-end

The plugin dogfoods itself via [`.buildkite/pipeline.yml`](.buildkite/pipeline.yml) against the environment in `examples/hello` — no separate consumer repo required. Point a Buildkite pipeline at this repo to run it. Generate the example environment once with:

```shell
flox init -d examples/hello
flox install -d examples/hello hello
```

Commit the resulting `examples/hello/.flox/` so the lockfile is pinned. For the remote-environment step, `flox push -d examples/hello` and set `FLOX_TOKEN` on the agent.

## Credits

This plugin's caching layer is adapted from
[jbayer/flox-buildkite](https://github.com/jbayer/flox-buildkite) by
[James Bayer](https://github.com/jbayer).

### What each repo offers

| | [jbayer/flox-buildkite](https://github.com/jbayer/flox-buildkite) | [imkarrer/flox-buildkite-plugin](https://github.com/imkarrer/flox-buildkite-plugin) (this plugin) |
| --- | --- | --- |
| **Form** | Copy-paste template — standalone shell scripts + pipeline snippets you paste into each build | Declarative Buildkite plugin — set config keys under `plugins:` and the hooks handle the rest |
| **S3 binary cache — read** | `s3-cache-configure.sh` appends the substituter + trusted key to `/etc/nix/nix.conf` | `s3-cache-bucket` / `-endpoint` / `-region` / `-public-key` → `hooks/environment:configure_s3_cache()` |
| **S3 binary cache — write** | `s3-cache-push.sh` signs and pushes the step's closure after the job | `s3-cache-push: true` → `hooks/post-command` |
| **Cold `/nix` volume** | `ensure-nix.sh` restores the store from `/opt/nix-seed` on cold mounts | same logic in `hooks/environment:ensure_nix_seeded()` |
| **Agent image** | Dockerfile bakes `NIX_REMOTE=auto`, the S3 substituter, `SEED_PACKAGES`, and the `/opt/nix-seed` stash | the same ENV/ARGs in this repo's `Dockerfile` |
| **Remote (FloxHub) envs** | not covered | `environment` / `floxhub-token` / `trust` config |
| **flox auto-install** | separate `linux-install-flox.sh` / `macos-install-flox.sh` scripts to copy into the image | `channel` / `version` config → install step in `hooks/environment` |
| **Per-build wiring** | paste `S3_CACHE_*` env vars and `source …` lines into every pipeline step | one `plugins:` block per step — nothing to copy |

### Why these ideas were adopted

jbayer's scripts solve real cold-build problems — S3 substituters, signed
write-back, `/nix` seeding, single-user Nix — but each fix ships as a script to
copy into an agent image and `source` in every pipeline. That works, yet it is
easy to get subtly wrong and to let drift: one pipeline misses the `source`
line, another uses a stale copy, and the cache stops helping. This plugin
already owned the pieces jbayer's repo doesn't cover (auto-install, remote
FloxHub environments, per-step configuration), so the natural move was to adopt
those caching ideas as declarative config: one plugin, versioned and tested in
one place, wired into every step by a single `plugins:` block. The specific
pieces and their sources:

| Plugin component | Adapted from |
| --- | --- |
| `hooks/environment` — `configure_s3_cache()`: S3 **read** path, appends `extra-substituters` / `extra-trusted-public-keys` to `/etc/nix/nix.conf` | [`s3-cache-configure.sh`](https://github.com/jbayer/flox-buildkite/blob/main/.buildkite/lib/s3-cache-configure.sh) |
| `hooks/environment` — `ensure_nix_seeded()`: cold `/nix` cache-volume restore from `/opt/nix-seed` | [`ensure-nix.sh`](https://github.com/jbayer/flox-buildkite/blob/main/.buildkite/lib/ensure-nix.sh) |
| `hooks/post-command` — S3 **write-back**: signed push of the activated environment's closure | [`s3-cache-push.sh`](https://github.com/jbayer/flox-buildkite/blob/main/.buildkite/lib/s3-cache-push.sh) |
| `Dockerfile` — `NIX_REMOTE=auto` single-user fallback, S3 cache baked into `/etc/nix/nix.conf`, `SEED_PACKAGES` baked into the store, `/opt/nix-seed` stash for cold `/nix` volumes | [`agent-image/Dockerfile`](https://github.com/jbayer/flox-buildkite/blob/main/.buildkite/agent-image/Dockerfile) |

jbayer's repo carries no license file, so attribution lives here in the README
and in per-file headers on `hooks/environment`, `hooks/post-command`, and the
`Dockerfile`. If the caching features are useful to you, a star on
[jbayer/flox-buildkite](https://github.com/jbayer/flox-buildkite) is the
original work a thank-you goes to.

## License

MIT
