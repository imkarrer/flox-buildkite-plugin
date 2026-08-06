# Pre-baked Buildkite agent with flox installed, so jobs skip the install step.
#
# Uses the Ubuntu (glibc) agent image — flox ships glibc .deb/.rpm packages and
# does not run on the default Alpine (musl) `buildkite/agent:3` image.
FROM buildkite/agent:3-ubuntu

ARG FLOX_VERSION=1.14.0

USER root

# Install flox from its Debian package (the old flox.dev/install script is gone).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils \
    && arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
         amd64) flox_arch="x86_64-linux" ;; \
         arm64) flox_arch="aarch64-linux" ;; \
         *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://downloads.flox.dev/by-env/stable/deb/flox-${FLOX_VERSION}.${flox_arch}.deb" -o /tmp/flox.deb \
    && apt-get install -y /tmp/flox.deb \
    && rm -f /tmp/flox.deb \
    && rm -rf /var/lib/apt/lists/*

# flox needs the Nix daemon running. The agent entrypoint runs everything in
# /docker-entrypoint.d via run-parts before starting, so launch the daemon there.
RUN mkdir -p /docker-entrypoint.d \
    && printf '%s\n' \
      '#!/usr/bin/env bash' \
      'set -euo pipefail' \
      'for f in /etc/profile.d/nix*.sh; do [ -e "$f" ] && . "$f"; done' \
      'daemon="$(command -v nix-daemon || true)"' \
      '[ -z "$daemon" ] && for p in /nix/var/nix/profiles/default/bin/nix-daemon /usr/bin/nix-daemon; do [ -x "$p" ] && daemon="$p" && break; done' \
      'if [ -n "$daemon" ] && ! pgrep -x nix-daemon >/dev/null 2>&1; then "$daemon" >/var/log/nix-daemon.log 2>&1 & fi' \
      > /docker-entrypoint.d/10-nix-daemon \
    && chmod +x /docker-entrypoint.d/10-nix-daemon

# Single-user Nix fallback: when the daemon isn't running (e.g. no systemd in
# containers) NIX_REMOTE=auto makes the bundled Nix operate on /nix/store
# directly, so flox still works. Adapted from jbayer/flox-buildkite.
ENV NIX_REMOTE=auto

# Make the store usable by whatever user the agent runs jobs as. Buildkite
# forbids changing USER/UID/GID, so we can't chown to a user we create.
RUN chmod -R a+rwX /nix

# --- Optional: bake an S3 binary-cache READ path into the image ---------------
# Same idea as jbayer/flox-buildkite's agent image: the substituter pointer is
# NON-SECRET (bucket, endpoint, region, public key), so it can live in the image
# as reliable phase-1 config — every build has it with no runtime step. When
# S3_CACHE_BUCKET is set, write the substituter + trusted key into
# /etc/nix/nix.conf (the file flox's bundled Nix reads). Empty = skip.
ARG S3_CACHE_BUCKET=""
ARG S3_CACHE_ENDPOINT=""
ARG S3_CACHE_REGION="auto"
ARG S3_CACHE_PUBLIC_KEY=""
RUN set -eux; \
    if [ -n "$S3_CACHE_BUCKET" ]; then \
        { \
          echo ""; \
          echo "# --- flox S3 binary cache ---"; \
          echo "extra-substituters = s3://${S3_CACHE_BUCKET}?endpoint=${S3_CACHE_ENDPOINT}&region=${S3_CACHE_REGION}"; \
          echo "extra-trusted-public-keys = ${S3_CACHE_PUBLIC_KEY}"; \
        } >>/etc/nix/nix.conf; \
        echo "baked S3 cache substituter into /etc/nix/nix.conf"; \
    fi

# --- Optional: seed common packages into the store -----------------------------
# Packages baked into the Nix store at build time so cold builds don't re-download
# them. Edit the SEED_PACKAGES default below — a space-separated list of Flox
# pkg-paths, e.g. "nodejs python3 go". Set to "" to bake nothing beyond flox.
# `hello` mirrors the CI smoke-test sentinel in examples/hello/.flox.
# A baked package only yields a runtime cache hit when a project env resolves to
# the SAME store path (same version, same catalog) — bake the versions your
# projects actually use.
ARG SEED_PACKAGES="hello"
RUN set -eux; \
    if [ -n "$SEED_PACKAGES" ]; then \
        mkdir -p /opt/seed-env; \
        cd /opt/seed-env; \
        flox init; \
        flox install $SEED_PACKAGES; \
        flox list; \
    fi

# Stash the baked Nix store outside /nix so a /nix cache volume (empty on the
# first build) can be seeded from it at runtime — the plugin's environment hook
# restores it when the volume mounts cold. Hardlink the copy (-l) so it costs
# ~no extra image space; fall back to a real copy if hardlinks aren't possible.
RUN cp -al /nix /opt/nix-seed || cp -a /nix /opt/nix-seed

# The Ubuntu agent image runs as root (there is no `buildkite` user), which is
# also required for the Nix daemon to manage the store.
