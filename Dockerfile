FROM buildkite/agent:3

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sudo \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN bash <(curl -fsSL https://flox.dev/install) --channel stable --yes \
    && chmod a+rx /usr/local/bin/flox

USER buildkite
