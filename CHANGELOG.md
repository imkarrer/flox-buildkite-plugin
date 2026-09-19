# Changelog

All notable changes to this plugin are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.2] - 2026-09-06

Same commit as 1.0.1, re-tagged. Pin `imkarrer/flox#v1.0.2`.

### Fixed

- `hooks/environment` never ran in a real job: Buildkite sources hooks into
  its bootstrap shell, so the `BASH_SOURCE[0] == $0` guard around `main()`
  never held. The guard is gone; the hook does its work when sourced.

## [1.0.1] - 2026-09-06

Superseded by 1.0.2 (identical content).

## [1.0.0] - 2026-09-06

First tagged release. Pin `imkarrer/flox#v1.0.0` instead of `#main`.

### Fixed

- `floxhub-token` was read from the wrong environment variable
  (`BUILDKITE_PLUGIN_FLOXHUB_TOKEN` instead of `BUILDKITE_PLUGIN_FLOX_FLOXHUB_TOKEN`),
  so the plugin config key never worked — only the `FLOX_TOKEN` fallback did.
- `trust: true` was only forwarded to `flox activate` when `environment` was
  also set, so a borrowed `dir` environment silently lost `--trust`.

### Added

- `ferahgo/flox-buildkite-agent` published to Docker Hub from tag builds
  (`.buildkite/pipeline.yml`'s `publish` step).
- Unit tests for `resolve_download_url` (channel/version/OS/arch matrix) and
  for the FloxHub auth path in `hooks/environment`.

[1.0.2]: https://github.com/imkarrer/flox-buildkite-plugin/releases/tag/v1.0.2
[1.0.1]: https://github.com/imkarrer/flox-buildkite-plugin/releases/tag/v1.0.1
[1.0.0]: https://github.com/imkarrer/flox-buildkite-plugin/releases/tag/v1.0.0
