# Reproducible CI Without Docker — The Hard Way, Then The Easy Way

Lightning talk plan for Chippewa Valley Developers Group. **20 minutes total.**

**Audience:** software-minded folks, mixed experience. Assume familiarity with Docker and the *idea* of installing packages. Do **not** assume fluency in git internals or assembly. Assume *zero* prior Nix, Flox, or Buildkite.

**Jargon rule:** because experience is mixed, every acronym gets expanded once, out loud, on first use — **CI** (continuous integration), **CLI** (command-line interface), **TOML** (a plain config format, like INI), **OCI** (the standard container image format), **PATH** (the list of directories your shell searches for commands). Cheap insurance; costs you about eight seconds total.

**Structure:** three live demos. The first is the cold open: the room clones this repo, `make` fails, `flox activate` doesn't. Everyone is a Flox user before the argument starts. The hard-way and easy-way demos are the spine after that. Slides are scaffolding between them.

**The one thing they remember:** *your build environment can be a file in your repo, versioned in the same commit as the code that needs it.*

**The deck:** [`slides.md`](slides.md) — 26 slides, Flox-branded, with every speaker note below embedded as presenter notes. Build it with `flox activate -- make` in this directory; see [`README.md`](README.md). This file stays the long-form script and rationale: the *why* behind each slide, the pre-flight checklists, the Q&A prep, and the accuracy notes on claims that are easy to overstate. You will present Act 0 *from this file* (or the PDF) — Marp presenter view isn't up yet.

---

## The device

The cold open *is* the thesis, performed before you name it. The room clones the repo this talk lives in, runs `make`, and watches it fail because Marp isn't on their machine. Then `flox activate -- make serve` and they're looking at the same deck you are. You didn't install a toolchain. You activated one that lives in the repo. *Then* you explain why that just worked.

After that, show the hard way first, so the easy way means something.

Raw Nix first: do it once, by hand, so they see the machinery and trust it. Flox second: same engine, same guarantees, what you actually use. The demos *are* the argument — don't spend a slide teaching a metaphor from another discipline so you can teach the thing you're about to show.

Frame the hard-way demo in one sentence, on the demo slide itself:

> "Not because you should ever work this way, but because in five minutes you'll see exactly what the easy way is doing for you."

That's the whole device. Then type.

### The flake-vs-TOML slide

Act 5's money moment is a two-column shape: cramped flake on the left, four lines of TOML on the right, matching results highlighted. The contrast argues itself — 20 lines of a functional language versus a list. Let the columns sit for a beat, then:

> "Same engine. Same mechanism. Same guarantees. The line count isn't even the story — the story is that one of these requires learning a lazy functional language and the other is a list."

---

## Timing budget

Clone, shirts, and the swag bit happen **before the clock** — that's settling, ~5–8 minutes for ~20 people. Don't start the fail/activate until repos are out and shirts are in hands. If install is the long pole, don't wait; people still downloading can watch and catch up.

| Act | Content | Time | Running |
|---|---|---|---|
| 0 | **DEMO: boot the deck** (fail, then activate) | 1:30 | 1:30 |
| 1 | The problem | 2:00 | 3:30 |
| 2 | Docker's sleight of hand | 2:00 | 5:30 |
| 3 | Nix — one idea | 2:00 | 7:30 |
| 4 | **DEMO: the hard way (raw Nix)** | 5:00 | 12:30 |
| 5 | **DEMO: the easy way (Flox)** | 3:00 | 15:30 |
| 6 | Buildkite + the plugin | 3:30 | 19:00 |
| 7 | Tradeoffs + close | 1:30 | 20:30 |

The extra 90 seconds is Act 0 on the clock; the 1:00 buffer is gone. If you're tight at the start, the landing slide ("you're a Flox user") is the cut — the fail still plays. Act 3 and the later demos are still where you'll overrun.

---

## Act 0 — DEMO: boot the deck (1:30, plus settling)

This is the talk's thesis, performed before you name it. You will present it from the **PDF** (title + follow-along) with this script on your laptop — Marp presenter view isn't up yet. That's the point of the reveal.

### Settling (before the clock)

Title slide on the projector, from `build/slides.pdf`. Point at the repo URL:

> "If you want to follow along, clone that. I'll give you a minute."

Advance to **Follow along** so they have the commands. Then pass shirts and sharpies. ~20 people; don't rush it. Install is the long pole — `brew install flox` / a `.deb` while they clone is the whole reason you have dead air to fill.

Once repos are out and shirts are in hands, the swag bit. Spoken, not a slide:

> "I'm soon joining Flox, but I have no swag to hand out, so if you like it we're going to make our own. During this talk, if I've convinced you, write I ♥ Flox on the shirt and we'll take a picture at the end. If I haven't, find me after and I'll try to answer whatever I didn't."

### The reveal

> "What you're looking at is a PDF. I can keep my notes open next to it — that's why I baked speaker notes into the file. Fine as a backup. But these slides are markdown, and the toolchain that presents them is in the repo you just cloned. Watch."

### The fail (45s)

Clean terminal. No `flox activate`. Confirm `command -v marp` is empty and `echo $FLOX_ENV` is empty. Terminal ≥18pt.

```console
$ make
```

`make` and `make serve` both hit `check-marp` first, so leftover `build/` artifacts cannot hide the miss. The slide shows `make`; `make serve` is the same fail with a shorter path to the URL.

Let it fail. Read the error out loud:

```
  marp is not on PATH.

  The toolchain for this deck lives in .flox/ — a file in this repo.
  Activate it, then retry:

    flox activate -- make serve
```

**Say:** "Marp isn't installed on this machine. It isn't installed on yours either. The toolchain is a file in the repo."

### The activate (45s)

```console
$ flox activate -- make serve
```

Open http://localhost:8080/slides.md. Press <kbd>P</kbd> for presenter view — notes, next slide, timer. That's the thing the PDF couldn't do in one window.

**Say:** "If you cloned the repo, do the same. `make`, then `flox activate -- make serve`. You just became a Flox user."

Don't wait for every laptop. Native Windows can't; WSL can — say so once. If `make` succeeded for someone, they already had marp; skip them ahead to serve.

### Landing slide

> You didn't install a toolchain.
> You activated one that lives in the repo.
>
> You're a Flox user. The rest of this talk is why that just worked.

Let it sit for a beat. Don't explain Nix. Don't explain Flox. Then into Act 1.

### Pre-flight

- **PDF already built** on the presenter laptop (`flox activate -- make pdf`), ready to open before anyone sits down. Second copy on a backup laptop.
- **A clean terminal** that has never been activated in this session. The activated one is for after the fail.
- **No global `marp`.** `npm install -g @marp-team/marp-cli` would make `make` succeed and kill the bit. Check with `command -v marp` the morning of.
- **20 shirts, 20 sharpies.** The swag bit dies if either is missing.
- **Flox already installed on the presenter machine** — you're showing activate, not install. The room may be installing during settling; you are not.

---

## Act 1 — The problem (2 min, 3 slides)

Title, follow-along, and the landing line are Act 0. The argument starts here.

### Slide 2: One question, three answers

Show hands, but only **one** question — there isn't time for four:

> "Who's debugged a CI failure that reproduced nowhere else?"

Expand **CI** here, the first time you say it — "continuous integration, the thing that runs your tests when you push." One clause, then move on.

Then the diagram: **Laptop → CI → Production**, drifting apart. Each provisioned differently — brew and a README on the laptop, a Dockerfile or a pre-baked runner image in CI, a golden server image or a Kubernetes config in production. Three sources of truth for one question: *what software does this project need?*

*(Say "golden server image" rather than "AMI," and "Kubernetes config" rather than "Helm chart" — both are undefined jargon that buy you nothing here.)*

**Say:** "Drift isn't a discipline problem, it's a design problem. We use three mechanisms and act surprised when they disagree."

### Slide 3: Why your package manager can't fix it

The conceptual setup for everything after. Don't rush it.

`apt install nodejs` is a **mutation of global shared state**:

- One version wins — installing Node 24 removes Node 22.
- The result depends on *when* you ran it.
- The result depends on what was already there.
- Nothing describes what you got. `dpkg -l` describes the *machine*, not the *project*.

**Say:** "Two projects needing different versions of the same thing are in direct conflict, and nothing in this model can tell you what a build actually consumed."

---

## Act 2 — Docker's sleight of hand (2 min, 2 slides)

**Tone:** the room likes Docker. You are not attacking Docker; you're isolating one job — *defining a dev/CI environment* — that it's heavy for. Say that out loud.

### Slide 4: The reproducibility sleight of hand

The whole Docker argument on one slide, and the highest value-per-second in the talk.

> **A Dockerfile is not reproducible. A Docker image is immutable.**
> We conflate those constantly.

```dockerfile
FROM buildkite/agent:3          # mutable tag
RUN apt-get update \            # whatever is current TODAY
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm@9    # a range, mutable registry
```

Build that today and in six months: different images. Nothing in the format prevents it.

**Say:** "We get repeatability by freezing the *output* of a nondeterministic process, then treating the frozen blob as the source of truth. That works until you need to change something — because then you re-run the nondeterministic process. The recipe was never what you trusted. The snapshot was."

### Slide 5: And the day-two bill

Fast — four bullets, fifteen seconds:

- A second artifact outside your repo, versioned on its own schedule.
- A registry to run, pay for, authenticate to, garbage-collect.
- The tag-bump dance: edit, build, push, then bump the tag in a *separate* PR.
- Nothing links the image to the commit that needed it.

**Say:** "To answer 'what tools does my build need,' we stood up a pipeline that itself needs maintaining. What if we shipped the *recipe* instead, precisely enough that the snapshot is redundant?"

---

## Act 3 — Nix, one idea (2 min, 1 slide)

**Discipline:** teach *exactly one* idea — the hash is the identity of the recipe. Rollbacks and two MySQLs are consequences of that, not extra topics. No Nix language, no flakes vs. channels, no NixOS. You have two minutes. History is 20 seconds; the hash and what it buys you is the rest.

### Slide 9: Packages as pure functions

- Nix: package manager + build system, started 2003 from Eelco Dolstra's PhD work at Utrecht. **23 years old.**
- **nixpkgs** — "Nix packages," its package collection, the equivalent of Homebrew's formulas or Debian's archive. ~120,000 projects / 147,000 packages: **the largest general-purpose package collection there is**, ahead of Homebrew, Debian, and the Arch User Repository. (repology.org, Aug 2026)
- Runs on any Linux and macOS. **You do not need NixOS.** Say this explicitly — it's the most common confusion.

*(Say "largest general-purpose package collection," not "largest package repository in existence." npm has ~3 million packages and PyPI ~500,000 — they're language registries rather than general-purpose collections, but if you overclaim, someone will correct you and you'll spend your tightest act relitigating it.)*

> `apt install` is a **statement**. Nix is an **expression**.

```
build(source, deps, compiler, flags, …) → /nix/store/<hash>-name-version
```

The hash is computed from *every* input, recursively — all the way down to the C standard library that nearly everything else is built on. Change any input → different hash → different path. Nothing is ever mutated or overwritten.

A real one, from this repo's lockfile:

```
/nix/store/srhnlxadg479lhf3r6ijjc0arsxaimzs-hello-2.12.3
```

**Say:** "That's not a checksum of the output. It's an identity derived from the complete recipe — every input, recursively, down to libc. Two machines computing the same hash are asking for the same software built the same way, by construction. Change any input, you get a different directory. The old one is not overwritten. That's the whole trick."

### What the hash buys you (this is the 90 seconds)

These two are the point of the slide. Don't rush them to get to the demo.

**Two MySQLs.** Callback to Act 1 — two projects, one machine, they fight:

**Say:** "That's why you can have two MySQLs on the same laptop. 5.7 and 8.0, or two 8.0s built against different OpenSSLs. Different inputs, different hashes, different directories. They don't know the other exists. apt has one slot — `/usr/bin/mysql`. Nix has as many slots as you have recipes. nvm can do two Nodes. It cannot do two MySQLs whose dependency trees disagree."

*(Don't say they share nothing — identical inputs collapse to the same path, which is the other half of the trick. Two MySQLs with different OpenSSLs still share zlib if zlib is the same recipe. Mention only if a Nix person asks.)*

**Rollback.**

**Say:** "And that's why rollback is real. Last week's tools are still on disk. You are not re-downloading from a mirror that may have moved, or hoping a registry still has that tag. You point at a path that never left. If you did delete it, the recipe rebuilds the same bits."

One more sentence, because two later slides depend on it and nothing else in the talk explains it: entering one of these environments just puts those store paths at the front of **`PATH`** — the list of directories your shell searches when you type a command. No container, no virtual machine. That's what makes it *reproducibility* rather than *isolation*, which is the honest limitation you'll land in Act 7. The environment they activated in Act 0 is a set of these paths. Another repo, another set. They coexist.

Then straight into the demo. The hard-way frame is one sentence on the next slide.

---

## Act 4 — DEMO: the hard way (5 min)

Commands, output, and timings below are measured on Nix 2.31.5, not estimated.

**Say, then type:** "Not because you should ever work this way, but because in five minutes you'll see exactly what the easy way is doing for you."

### Beat 1 — The naive version, and why it's a lie (45s)

Start with what a beginner writes after ten minutes of Googling:

```nix
# shell.nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [ pkgs.nodejs_22 pkgs.pnpm ];
}
```

**Say:** "Four lines. Looks great. And it is *not reproducible* — `<nixpkgs>` is a channel, which is a mutable pointer. This is the Docker `latest` problem wearing a different hat. To actually pin it I need the modern approach, flakes."

### Beat 2 — The honest version (90s)

Show the file, and narrate the ugly parts by pointing at them:

```nix
{
  description = "Node dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
          (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.nodejs_22 pkgs.pnpm ];
        };
      });
    };
}
```

Point at, in order — this is the *whole point* of the demo:

1. **A lazy functional language.** A `let … in`, a lambda, attribute sets, `${}` interpolation.
2. **`genAttrs` + `legacyPackages`** — boilerplate that exists because flake outputs are keyed per-system, and I want four of them (Intel and Apple Silicon, Linux and Mac). Nothing about my project. *(Don't say it exists "only" for cross-platform support — you'd still need `devShells.x86_64-linux.default` for a single system. Wanting four is what forces the helper function.)*
3. **`legacyPackages`** — named that because there's history here you're now inheriting.
4. **20 lines, of which ~2 are about my project.** Node and pnpm. That's it.

**Say:** "I want two tools. Eighteen of these twenty lines are ceremony."

### Beat 3 — The footgun (45s) ⚡ *crowd-pleaser*

```console
$ nix develop --command node --version
error: Path 'flake.nix' in the repository "/tmp/hardway" is not tracked by Git.

       To make it visible to Nix, run:

       git -C "/tmp/hardway" add "flake.nix"
```

**Say:** "Flakes only see git-tracked files. My file is right there on disk and Nix refuses to look at it. To be fair, that error message is *much* better than it used to be — this used to just silently not work. Fixing it means `git add` a file I haven't finished writing."

```console
$ git add flake.nix
```

Then, on the *next* run, the second papercut:

```console
warning: Git tree '/tmp/hardway' is dirty
```

"It generated a `flake.lock` — which is now itself untracked, so the tree is dirty. Every run warns me about it."

### Beat 4 — It works, and it's genuinely good (60s)

```console
$ time nix develop --command bash -c 'node --version; pnpm --version'
copying path '/nix/store/xv1lykwi8n984ips4rpjv1imfwqpak31-nodejs-22.20.0' from 'https://cache.nixos.org'...
copying path '/nix/store/v2w0wxqcjqf74i6gys0l6dmhqg0ykmmc-pnpm-10.15.1' from 'https://cache.nixos.org'...
v22.20.0
10.15.1

real    0m22.013s
```

Then warm:

```console
$ time nix develop --command node --version
v22.20.0

real    0m0.486s
```

**Say:** "Twenty-two seconds cold, half a second warm — and it's fetching prebuilt binaries from a cache, not compiling. The guarantees are real: that `flake.lock` pins a nixpkgs commit, so this resolves identically on my machine, your machine, and CI. **Nix delivers.** My complaint isn't that Nix doesn't work. It's what I had to write to get here."

### Beat 5 — Score the hard way (30s)

Slide, on screen while you talk:

| What I wanted | What it cost |
|---|---|
| Node + pnpm | 20 lines of a functional language |
| Cross-platform | `genAttrs` / `legacyPackages` boilerplate |
| Pinned | Flakes — which vanilla Nix ships **disabled** behind an experimental flag |
| A file on disk | `git add` before Nix will look at it |
| Env vars and setup hooks | Available, but as raw shell strings inside a Nix expression |
| Services (Postgres, Redis, your API) | **Not available.** Separate tooling entirely. |

**Say:** "Note the last two rows. I got packages. I *can* set environment variables and a setup script, but only by embedding shell code inside a Nix expression. And a Postgres for local dev? Not here — that's a different tool on top."

> **Accuracy warning — do not claim env vars and hooks are unavailable.** `mkShell` genuinely supports both: any attribute becomes an environment variable, and `shellHook` runs on entry. Verified:
>
> ```console
> $ nix-shell mkshell-test.nix --run 'echo "$API_PORT / $GREETING"'
> hook ran: API_PORT=8080 GREETING=from mkShell
> 8080 / from mkShell
> ```
>
> Only **services** are truly absent from a plain `devShell` (you'd reach for process-compose, devenv, or similar). Overstating this is the single most likely thing to get you corrected by a Nix user in the room, and it costs you nothing to be precise — "declarative fields versus embedded shell strings, and no services at all" is still a clear win for Flox.

### Pre-flight

- **Warm the store first** — run the whole demo once beforehand. Cold with no cache is minutes, not 22 seconds.
- **Have a recorded fallback.** Conference wifi will humiliate you.
- Terminal ≥18pt, tested on the actual projector.
- Reset between rehearsals: `rm -rf /tmp/hardway && mkdir -p /tmp/hardway && cd /tmp/hardway && git init`
- Vanilla Nix needs `--extra-experimental-features 'nix-command flakes'`; Determinate Nix enables them by default. Know which you're demoing on and mention it — it's another point on the scoreboard.

---

## Act 5 — DEMO: the easy way (3 min)

Same goal, same guarantees, fresh directory. Side by side with the first terminal if you can — the visual contrast does the work.

### Beat 1 — The whole thing (60s)

Type it live. It's short enough.

```console
$ flox init
✔ Created environment 'easyway' (x86_64-linux)            real 0m0.070s

$ flox install nodejs_22 pnpm
✔ 'nodejs_22', 'pnpm' installed to environment 'easyway'  real 0m2.097s

$ flox activate -- bash -c 'node --version; pnpm --version'
v22.23.1
11.9.0                                                    real 0m0.450s
```

**Say:** "Two commands. No language. Warm activation is 0.45 seconds — same ballpark as `nix develop`'s 0.49. You are not paying for the ergonomics at runtime."

*(Versions differ from the flake because Flox pins its own nixpkgs snapshot — both are pinned, just to different revisions. Mention only if asked.)*

### Beat 2 — The file (45s)

**Do not run a bare `cat` here.** `flox init` generates a ~97-line manifest that is mostly a helpful commented template. Run `cat` live and the audience sees a wall of comments at the exact moment you're claiming concision — you'd be arguing against yourself on screen. Strip them:

```console
$ grep -v '^\s*#' .flox/env/manifest.toml | grep -v '^$'
```

```toml
schema-version = "1.14.0"

[install]
nodejs_22.pkg-path = "nodejs_22"
pnpm.pkg-path = "pnpm"
```

Say "flox generates a commented template; this is the signal" — one clause, and it reads as honest rather than evasive.

Put the two side by side. **This is the money moment:**

| | Raw Nix | Flox |
|---|---|---|
| What you write | 20 lines of Nix | 4 lines of TOML |
| Language to learn | Yes | No |
| Cross-platform | Hand-rolled `genAttrs` | Automatic, in the lock |
| Pinned | `flake.lock` (27 lines) | `manifest.lock` (260 lines) |
| Git tracking required | Yes, or it won't run | No |

**Say:** "Same engine. Same mechanism. Same guarantees. The line count isn't even the story — the story is that one of these requires learning a lazy functional language and the other is a list."

> **Don't say "same store paths."** They aren't: your flake resolved Node 22.20.0 and Flox resolved 22.23.1, because they pin different nixpkgs revisions — and both versions are visible on screen in your two terminals. Claiming identical paths one beat after the audience watched them differ is the kind of thing that costs you the room. Either say "same mechanism," or pin the flake to Flox's revision beforehand so the claim becomes literally true.

Have an answer ready for the one row that favors raw Nix — `manifest.lock` is ten times longer than `flake.lock`: both are generated and neither is hand-edited, and Flox's is longer because it pins every package's resolved store path individually, where `flake.lock` pins only the nixpkgs input and re-derives the rest. More bytes, more precision, still nothing you write.

Let the two-column slide sit for a beat before you talk. Twenty lines versus four is the argument; you don't need a callback to a prior slide.

### Beat 3 — And then it does more (45s) ⚡ *the beat that converts people*

Show the manifest, then run it.

```toml
[vars]
API_PORT = "8080"

[hook]
on-activate = '''
  echo "env ready: node $(node --version), API_PORT=$API_PORT"
'''

[services]
api.command = "node -e '…http server on process.env.API_PORT…'"
```

```console
$ flox activate --start-services -- bash -c 'sleep 3; curl -s localhost:$API_PORT; flox services status'
env ready: node v22.23.1, API_PORT=8080
hi
NAME       STATUS       PID
api        Running     2764
```

**Say:** "The hook ran on entry. The variable was set. A service started and served traffic. So this one file just replaced my package list, my `.env`, my setup script, *and* my `docker-compose.yml` for local services. Remember the last row of the hard-way scoreboard? Raw Nix devShells don't do any of this."

### Beat 4 — Land it (30s)

**Say:** "The hard way wasn't wasted — you now know what's underneath: a store where every path is a hash of its whole recipe, a lockfile pinning a nixpkgs revision, symlinks on `PATH`. Flox isn't hiding Nix from you. It's saving you from typing it."

One line about what Flox *is*, for credibility — 15 seconds, no more:

> Open source command-line tool over Nix, out of **D. E. Shaw**'s internal tooling — one of the largest enterprise Nix deployments anywhere. Spun out as a company in 2022; $27M raised to date.

> **Two corrections from the earlier draft.** "$27M led by NEA" was wrong on both halves: the round **NEA** — New Enterprise Associates — led was a **$16.5M Series A**, and $27M is *total* funding to date. Say either "$16.5M Series A led by New Enterprise Associates" or just "$27M raised," not the two welded together.
>
> Honestly, consider cutting the funding line altogether. For a room of working developers the D. E. Shaw provenance is the part that confers credibility — "this is a productized version of the layer a large firm already had to build to get Nix adopted internally." Venture funding tells them nothing about whether the tool works, and it costs you five seconds you don't have in a 20-minute slot.

### Pre-flight

- Warm store. Reset with `rm -rf /tmp/easyway`.
- Pre-write the `[vars]`/`[hook]`/`[services]` manifest and paste it — do **not** live-type TOML containing an embedded JS one-liner.
- `export FLOX_DISABLE_METRICS=true` in your demo shell.

---

## Act 6 — Buildkite and the plugin (3:30, 3 slides)

You have three and a half minutes. **Do not teach Buildkite.** Land one architectural fact, then the payoff.

### Slide 8: Buildkite in 30 seconds, and the one fact that matters

- Continuous integration and delivery platform (**CI/CD**), founded 2013 in Melbourne. OpenAI, Anthropic, Uber, Shopify, Canva.
- **Hybrid model:** Buildkite hosts the control plane — orchestration, the web interface, logs. **You run the agents** on your own infrastructure. Agents poll *out*; nothing inbound. Your code and secrets never leave your perimeter.

Diagram: Buildkite Cloud | your infra, arrow pointing outward.

**Say:** "Contrast: GitHub Actions and CircleCI default to *their* runners with *their* preinstalled images. Buildkite defaults to *your* compute."

### Slide 9: Which makes this your problem specifically

**The pivot. Slow down.**

If you own the agents, you own **what's installed on them**. There is no `ubuntu-latest` with fifty toolchains. Your options have been:

1. Install toolchains on the agent host → agents become pets, versions conflict.
2. Bake an agent image per toolchain → back to Act 2's registry pipeline, now for CI infra.
3. Wrap every step in the Docker plugin → an image to maintain per step.
4. Install tools at the top of every job → slow, and per Act 2, not reproducible.

**Say:** "Buildkite's greatest strength — you own the build environment — is exactly what makes 'what's installed on my agents' a permanent problem. We just spent ten minutes on a really good answer to that question."

### Slide 10: The plugin, and its entire implementation

The gap: Flox ships a GitHub Actions action, a CircleCI orb, and a GitLab component. **For Buildkite there's no official integration** — the closest prior art is [jbayer/flox-buildkite](https://github.com/jbayer/flox-buildkite), a set of shell scripts you copy into your agent image and `source` in every step. This plugin adopts its caching ideas as declarative config.

*(Say "no official integration," not "nothing." The prior art exists, this repo's README credits it, and someone who's found it will call you out. Crediting it costs five seconds and makes you look better than claiming an empty field.)*

Usage — note the reference is `imkarrer/flox`, because Buildkite strips the `-buildkite-plugin` suffix from the repo name:

```yml
steps:
  - label: ":flox: build"
    plugins:
      - imkarrer/flox#v1.0.0:
          command: npm run build
```

A Buildkite plugin is just **a git repo with hook scripts** — no framework to learn, nothing to publish anywhere. So here's the whole thing:

```bash
exec flox activate "${FLOX_ARGS[@]}" -c "${COMMAND}"
```

**Say:** "That's the punchline — the part that runs your build is one line. `flox activate -c`." Pause for the laugh; it's the good kind — *oh, that's all it is.*

Then the honest follow-up, which is a **better** story than the old "it's only seventy lines" version:

**Say:** "The whole plugin is about four hundred lines across four hooks, and I want to be straight about where they go, because it's the interesting part. One line runs your build. The other four hundred make flox *exist* on a throwaway agent — download the right `.deb`, `.rpm`, or `.pkg` for the architecture, start the Nix daemon or fall back to single-user mode on containers without systemd, seed a cold `/nix` cache volume — and make cold builds fast by wiring up a shared binary cache. That's the work you'd otherwise hand-roll in every pipeline, which is exactly why it's a plugin instead of a snippet in your README."

*(Don't say "seventy lines across three hooks" — that was true at v1 and isn't now. Current: `command` 38, `environment` 282, `post-command` 83, `pre-exit` 3 = 406 across four hooks. Verify before you present; this repo is moving.)*

The code slide should still be the one line, but the real hook branches for an empty argument list, because bash 3.2 — which is what macOS ships — aborts on `"${arr[@]}"` when the array is empty and `set -u` is on. Show the simplified version and say "roughly":

```bash
exec flox activate "${FLOX_ARGS[@]}" -c "${COMMAND}"
```

If you have 20 spare seconds, the monorepo config sells itself:

```yml
steps:
  - plugins:
      - imkarrer/flox#v1.0.0:
          dir: backend
          command: cargo build
  - plugins:
      - imkarrer/flox#v1.0.0:
          dir: frontend
          command: vite build
```

---

## Act 7 — Tradeoffs and close (1:30, 2 slides)

### Slide 11: When *not* to do this

Never cut this. With developers, the honest-limitations slide is where you gain credibility — and it defuses your sharpest Q&A.

- **Nix gives reproducibility, not isolation.** It's `PATH` manipulation, not a sandbox. Untrusted build steps still want a container.
- **If the image is your deliverable, keep building images.** And `flox containerize` turns an environment into a standard container image — the **OCI** format Docker and Kubernetes both consume — so it's not either/or.
- **If your dependency isn't in nixpkgs**, you're writing a Nix *derivation* — a build recipe in the Nix language — which is the exact difficulty Flox otherwise hides. This is the real adoption tax.
- **Cold start isn't free.** Warm activation is fast (0.45s), and the numbers you showed — 22s for the flake, ~2.6s for Flox — were measured against an already-populated store. A genuinely cold agent also pays to install flox and realize every package with no cache, which is longer. **Measure it on your own runner before quoting a number.** Three mitigations, all in this repo: bake flox into a slim agent image (there's a Dockerfile), point the plugin at a shared S3-compatible binary cache (`s3-cache-bucket`, read *and* signed write-back via `s3-cache-push`), or seed a cold `/nix` volume from the image. This is the strongest answer you have on this slide — the cold-start objection is real, and you've already built the fix.

**Say:** "I'm not asking you to delete Docker. I'm asking you to stop using it to answer a question a text file answers better."

### Slide 12: Close

Three lines:

1. Docker ships an immutable **snapshot**. Nix ships a deterministic **recipe**.
2. Nix has been right for 23 years and hard for most of them.
3. Your build environment belongs in your repo, in the same commit as the code that needs it.

```bash
brew install flox                 # macOS
                                  # Linux: .deb / .rpm from flox.dev/docs/install-flox/install

cd your-project && flox init && flox install <thing> && flox activate
```

> flox.dev/docs/install-flox/install · github.com/imkarrer/flox-buildkite-plugin · buildkite.com/docs/pipelines/architecture

> **Don't put a `curl | bash` one-liner here.** Flox doesn't ship one; `https://flox.dev/install` returns 404 (verified). Current paths are `brew install flox` on macOS, a `.pkg` installer, `.deb`/`.rpm` from `downloads.flox.dev`, or `nix profile install --accept-flake-config 'github:flox/flox/latest'` where Nix already exists. Since there's no single cross-platform one-liner, point at the docs URL rather than inventing one — a command that fails on your closing slide is the last thing the room sees.

**Closing line:** "You only have to do the hard one once — and I already did it for you."

Then the photo: anyone who wrote on a shirt, up front, one shot. Don't force it — empty hands are the honest outcome of the opening bet.

---

## If you're overrunning

Cut in this order. Decide *now*, not on stage:

1. **Act 0 landing slide** — keep the fail, skip "you're a Flox user." Saves 15s.
2. **Act 4 Beat 1** (the naive `shell.nix`) — go straight to the flake. Saves 45s.
3. **Slide 5** (day-two bill) — fold one bullet into Slide 4. Saves 45s.
4. **Act 6's monorepo snippet.** Saves 20s.
5. **Act 4 Beat 3** (the footgun) — painful, it's a crowd-pleaser, but it's 45s of a papercut rather than a structural point.
6. **Act 5 Beat 3** (services) — only if desperate. It's the beat that converts people.

**Never cut:** Act 0's fail (if you skip the landing, keep the fail), Slide 3 (mutable global state), Slide 4 (the sleight of hand), Slide 6 (pure functions), Act 4 Beat 2 (the ugly flake — *the entire premise*), Act 5 Beat 2 (side by side), Slide 9 (why Buildkite makes it acute), Slide 11 (tradeoffs).

**Hard rule:** if you reach Act 6 with under 3 minutes left, drop to Slide 10 only — usage plus the one-line implementation. The plugin is the *conclusion*, not the content, and the audience will forgive a rushed ending far more readily than a rushed hard-way demo. The demo is what they came for.

---

## Q&A prep

The five you'll actually get in a 20-minute slot.

**"Isn't this just Docker with extra steps?"**
Inverted, actually. Docker distributes a snapshot of a nondeterministic build; Flox distributes a deterministic recipe. And a manifest is a text file in your repo, not an artifact in a registry.

**"Why not just use Nix directly? / What about devenv, devbox?"**
If you know Nix and like flakes, use them — you saw it work. Flox adds a no-Nix-required CLI, FloxHub for org-wide sharing, and bundles vars, hooks, and services in one TOML. devenv and devbox occupy similar ground; the Buildkite plugin question is orthogonal to which you pick.

**"What if a package isn't in nixpkgs?"**
The honest adoption tax. At ~147k packages it's rarer than you'd guess, but when it happens you're writing a derivation — the difficulty Flox otherwise hides.

**"macOS? Apple Silicon?"**
Yes — the lock resolves for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin` (*darwin* is macOS — say so, it isn't obvious). Two committed files cover Intel and ARM laptops plus x86 CI. This is the thing that cost you `genAttrs` boilerplate in the hard-way demo.

**"How's this different from asdf/nvm/mise?"**
Those manage runtime versions for languages they have plugins for. This manages *everything* — Postgres, ffmpeg, protoc, system libraries — with a real lockfile, no global mutable state, plus vars, hooks, and services in the same file.

**"Can I trust a plugin from some guy's GitHub?"**
Good instinct. Pin the git ref and read it — ~400 lines of bash across four hooks, and the one that runs your command is 38 of them. It's covered by unit tests written in Bats (the Bash Automated Testing System) plus a real `flox activate` smoke test, both running on every push. Say this *before* someone asks.

---

## Production notes

- **Open from the PDF.** Title slide on the projector before anyone sits. Act 0's fail happens in a terminal you switch to; then the browser takes the projector and you stay in Marp for the rest of the talk.
- **A clean terminal and an activated one.** The fail dies if `$FLOX_ENV` is set. Confirm `command -v marp` is empty in the clean one the morning of — a global `marp` from npm would make `make` succeed.
- **20 shirts, 20 sharpies.** Count them. The swag bit is the cover for clone + install; without it you have dead air and no closer photo.
- **Two terminals side by side**, `/tmp/hardway` and `/tmp/easyway`, both pre-warmed. The visual contrast between a 20-line flake and a 4-line TOML does more work than anything you say. Open [`demo/CHEATSHEET.md`](demo/CHEATSHEET.md) on the laptop; the projector gets the terminal. Paste the flake and `services.toml`. Type only the short commands.
- **Record both demos as fallback video.** Non-negotiable for a 20-minute slot — you cannot absorb a wifi failure.
- **Diagrams needed:** (1) laptop/CI/prod drifting, Slide 2. (2) Buildkite hybrid, Slide 8.
- **Act 5 has a little slack now.** Its beats sum to 3:00 (60+45+45+30) with Beat 4 as a landing line rather than a second demo. Act 4's beats still sum to ~4:30 inside a 5:00 budget. Don't steal from Act 5 to pad Act 4 — Act 5 is the one where you're typing live.
- **Use block-style YAML for the monorepo snippet in Act 6.** The compressed flow style is valid (the `#` in `plugin#v1.0.0` isn't a comment because no whitespace precedes it), but it's dense and inconsistent with every other snippet in the deck.

- **Verify plugin facts against `main` the day before.** This repo moves fast, and three claims in this plan went stale inside two weeks: the plugin reference (`imkarrer/flox`, not `imkarrer/flox-buildkite-plugin`), the hook line count (406 across four hooks, not 70 across three), and the install mechanism. Re-run `wc -l hooks/*` and skim `plugin.yml` before you finalize slides.
- **Still no git tags**, despite the README referencing `#v1.0.0` throughout, and your slides use the same pin. Either tag `v1.0.0` or change the slides to `#main` — the pipeline already self-tests against `imkarrer/flox#main`. Someone will copy that line off your slide the same night, and an unresolvable ref is a bad first impression.
- **New since v1, worth knowing even if you don't present it:** `activation-mode` (dev/run), an S3-compatible binary cache with signed write-back (`s3-cache-*` plus a `post-command` hook), cold `/nix` volume seeding, and single-user Nix fallback for containers without systemd. The cache is the one that matters on stage — it's your answer to the cold-start objection.
- **Local hook:** if you can name a Chippewa Valley company or project that's felt "works on my machine," use it in Act 1 instead of the generic hand-raise.
