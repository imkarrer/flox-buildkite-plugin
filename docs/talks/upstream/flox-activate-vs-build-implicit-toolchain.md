# Draft: Flox issue — activate vs `flox build` implicit toolchain

Status: **draft — not filed.** Refine here, then open on
[flox/flox](https://github.com/flox/flox/issues). Suggested labels:
`new-feature`, `user-reported` (same as [#2447](https://github.com/flox/flox/issues/2447)).

This is adjacent to [#2447](https://github.com/flox/flox/issues/2447) (isolated
activate) but not a duplicate: that issue is “host PATH leaks into activate.”
This one is that **activate and `flox build` (pure) have two different implicit
bases**, so the manifest is not a complete description of either environment.

---

## Suggested title

Activate and `flox build` (pure) don't share an implicit toolchain (host PATH vs Nix stdenv)

## Suggested type

Design / docs gap, with a real portability failure. Not a regression, and not
a request to put a compiler toolchain on every `flox activate`.

---

## Body (paste from here)

### Summary

`flox activate` and `flox build` with `sandbox = "pure"` are both described as
“this project's toolchain,” but they do not start from the same implicit
packages.

- **Activate** layers `[install]` onto the **host `PATH`**. Tools the manifest
  never declares still work if the OS ships them.
- **Pure builds** run in a Nix derivation and get **stdenv** (GNU Make, bash,
  coreutils, …) whether or not those packages appear in `[install]`. Host
  `PATH` is gone.

The result: `flox activate -- make` is not portable across machines, and
`sandbox = "warn"` does not catch the miss. That surprised us, and we suspect
it surprises others who treat `manifest.toml` as the whole toolchain.

We don't think this is accidental — activate-as-a-layer and Nix stdenv in the
builder both look like deliberate, good defaults. The gap is that they don't
match, and the docs don't say so.

### What we observed

Flox **1.14.0**, manifest `schema-version = "1.14.0"`. Project:
[imkarrer/flox-buildkite-plugin](https://github.com/imkarrer/flox-buildkite-plugin)
`docs/talks` — a small Marp deck whose `[build.project]` command is essentially
`make`.

The environment `[install]`s `marp-cli`, `geist-font`, `chromium` (Linux), and
(after we learned this) `gnumake`.

| Context | `gnumake` in `[install]`? | Does `make` work? | Why |
|---|---|---|---|
| `flox activate -- make` on Ubuntu / Debian | no | yes | host `/usr/bin/make` |
| `flox activate -- make` on NixOS | no | **no** | NixOS does not put Make on the login `PATH` |
| `flox build` with `sandbox = "pure"` | no | yes | Nix **stdenv** in the builder |

Commenting `gnumake` out of `[install]` and running `flox build project` with
`sandbox = "warn"` still succeeded on Ubuntu, **with no warning about `make`**.
Switching to `sandbox = "pure"` still had `make` (stdenv), so it still did not
fail for a missing pin.

That combination — warn is silent, pure still has Make, activate on NixOS does
not — is what made us think this was worth writing up.

### Why `sandbox = "warn"` did not help

We had read `sandbox = "warn"` as “tell me if this build uses anything I didn't
declare.” The [manifest.toml](https://flox.dev/docs/man/manifest.toml) wording
is that a warning is printed for each **file** the build accesses outside the
package closure.

From `package-builder/sandbox.c` in 1.14.0, the virtual sandbox interposes
`open` / `openat` / `fopen` / `readlink`, not `execve`. GNU Make is started with
`exec`; it then only opens files under the project (`FLOX_SRC_DIR`, always
allowed) and execs `marp` from the env (in the closure). There is no
out-of-closure *read*, so there is nothing to warn about.

That seems consistent with the implementation. It does mean `sandbox = "warn"`
cannot answer “did this `command =` use a host binary?” which is the question
we were asking.

(`sandbox-allow` is documented as local-mode only, so it also doesn't apply
under `"pure"`. Fine; we only mention it to show we checked.)

### Why installing catalog `stdenv` is not a workaround

Our first instinct was “install stdenv instead of pinning `gnumake`.” That does
not work, and we don't think Flox should make it work:

- Catalog `stdenv` is the Nixpkgs **build driver** (`$stdenv/setup`), not a
  metapackage of `bin/make`. Installing it as a NixOS system package has the
  same outcome: still no `make` on `PATH`
  ([nixpkgs#17293](https://github.com/NixOS/nixpkgs/issues/17293)).
- The catalog splits it by platform (`stdenv@darwin` vs Linux variants;
  `stdenvNoCC` likewise). `gnumake` is one package on all four systems.
- `flox activate` does not source `$stdenv/setup` the way `nix-shell` does
  (this matches how the team has described activate vs develop elsewhere).

Pinning `gnumake` is the honest `[install]` for `flox activate -- make`. It
does not make the pure builder and activate identical; it only makes activate
self-contained.

### What we are not asking for

We are not asking Flox to:

- Put gcc / a full stdenv on every `flox activate` `PATH`.
- Make catalog `stdenv` grow a `bin/make`.
- Break the “dotfiles and host tools still work” activate default. Maintainers
  have been clear that some of activate is *intentionally* not hermetic
  ([#2447](https://github.com/flox/flox/issues/2447) comment from @mkenigs,
  and the `env -i` workaround rather than a native isolated mode).

### Related work (so this isn't a cold start)

- **[#2447](https://github.com/flox/flox/issues/2447) — isolated activate.**
  Open, labeled `new-feature`. @ysndr: activate layers on the current
  environment; the gap is known. Workaround: `env -i` (later
  `PATH="" HOME=…`). @sschuberth later asked whether builds could grow
  `sandbox = "isolated"` (host binaries gone, network still allowed, only
  `[install]`). That would close the *host* side. It would **not** by itself
  make activate match `sandbox = "pure"`, because pure still injects stdenv.
- **[floxdocs#90](https://github.com/flox/floxdocs/issues/90)** — document the
  isolated-activate workaround.
- Discourse: [Creating a clean environment](https://discourse.flox.dev/t/creating-a-clean-environment/1140),
  [env vs shell/develop](https://discourse.flox.dev/t/why-we-have-to-keep-separation-on-env-and-shell-develop/700).

The new piece we want to add: the **builder** has an implicit toolchain too,
and it is a *different* implicit toolchain than the host. Isolated activate
and pure builds can both be “correct” and still disagree about `make`.

### Options (no preference, happy to take docs-only)

Any one of these would have unblocked us faster than discovering it by
commenting packages out:

1. **Docs.** One short section: activate = host `PATH` + `[install]`; pure
   build = Nix stdenv + `[install]`, no host `PATH`; `sandbox = "warn"` traces
   file opens, not `PATH` lookups. Pin every command the Makefile / `command =`
   invokes if `flox activate -- …` must work on NixOS.
2. **Isolated activate** as a first-class mode ([#2447](https://github.com/flox/flox/issues/2447)),
   so a missing `[install]` pin fails on Ubuntu the same way it fails on
   NixOS. Does not by itself align with pure-build stdenv.
3. **Make `sandbox = "warn"` (or a sibling) notice undeclared `PATH` executables**,
   not only out-of-closure `open`s. We realize `execve` interposition is a
   different design than today's libsandbox; raising it only because warn is
   the knob that *looks* like it would have caught this.
4. **Align the two implicits** — either don't inject stdenv into manifest
   builds unless asked, or offer a develop/activate view that includes the
   same stdenv tools the builder gets. We assume this is the expensive /
   controversial one.

(1) alone would have been enough for our project. (2)+(1) is what we'd reach
for if we were designing a “the manifest is the toolchain” tutorial.

### Reproduction (optional, for the table above)

On Ubuntu, with `gnumake` **not** in `[install]`:

```bash
flox activate -- command -v make   # /usr/bin/make
flox build <name>                  # sandbox = "warn": make runs, no warning
                                   # sandbox = "pure": make still runs (stdenv)
```

On NixOS, same manifest:

```bash
flox activate -- make              # make: command not found
flox build <name>                  # sandbox = "pure": make still runs
```

### Environment

- Flox 1.14.0
- Manifest schema 1.14.0
- Observed on Ubuntu (WSL) and reasoned against NixOS (NixOS login shells do
  not ship `make` unless `environment.systemPackages` says so)

Happy to turn any of the options above into a docs PR if that's the preferred
first step.

---

## Notes for us (do not paste)

- File against **flox/flox**, not floxdocs, unless they redirect. Mention
  floxdocs#90 so docs folks see it.
- Tone check before submit: we are guests in a design they already explained
  (#2447). Lead with the table and the warn miss; don't lead with “structural
  hole.”
- Do not propose `stdenv` as an `[install]`. They will correctly say no.
- Do not paste Marp/Chromium/CHROME_PATH in this issue — that's a separate
  (our) problem (`flox build` skips `on-activate` hooks). If we file that,
  it's a different ticket.
- After filing, link the issue from `docs/talks/.flox/env/manifest.toml`
  comments if we keep the gnumake pin rationale.
