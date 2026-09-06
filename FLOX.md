# This checkout

Root [`.flox/`](.flox/) is the plugin's own toolchain (`docker-compose` for tests and lint). The talks deck has a separate env at [`docs/talks/.flox/`](docs/talks/.flox/). Example CI env: [`examples/hello/.flox/`](examples/hello/.flox/).

```bash
scripts/test-local.sh
flox activate -c "docker compose run --rm tests"
flox activate -c "docker compose run --rm lint"
flox activate -- make -C docs/talks serve
```

CI is Buildkite (`.buildkite/pipeline.yml`). Cache identity is `S3_CACHE_*`; steps only set `command` / `dir` / `environment` / `trust`.
