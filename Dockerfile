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

# The Ubuntu agent image runs as root (there is no `buildkite` user), which is
# also required for the Nix daemon to manage the store.
