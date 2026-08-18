# Talks

| File | What it is |
|---|---|
| [`slides.md`](slides.md) | The deck — 26 slides, [Marp](https://marp.app) markdown, speaker notes inline |
| [`chippewa-valley-devs.md`](chippewa-valley-devs.md) | Long-form script: rationale, demo pre-flight, Q&A prep, accuracy notes |
| [`demo/CHEATSHEET.md`](demo/CHEATSHEET.md) | Copy-paste blocks for the live demos — open this on the laptop, terminal on the projector |
| [`theme/flox.css`](theme/flox.css) | Flox-branded Marp theme |
| [`assets/`](assets) | Flox logos, from [flox/flox](https://github.com/flox/flox/tree/main/img) |

Rehearse from `chippewa-valley-devs.md`; present from `slides.md`.

## Following along in the room

```console
$ git clone https://github.com/imkarrer/flox-buildkite-plugin
$ cd flox-buildkite-plugin/docs/talks
$ make                            # will fail — that's the point
$ flox activate -- make serve     # http://localhost:8080/slides.md
```

Need Flox first? [Install it](https://flox.dev/docs/install-flox/install) (`brew install flox` on macOS; `.deb` / `.rpm` on Linux; WSL is fine). Then the four commands above. You did not install Marp. You activated a toolchain that lives in this directory.

## Building

The toolchain is pinned in a Flox environment, so there's nothing to install:

```console
$ flox activate -- make          # html + pdf
$ flox activate -- make serve    # live preview at localhost:8080/slides.md
$ flox activate -- make check    # fail if any slide overflows the canvas
$ flox activate -- make pptx     # PowerPoint, if the venue insists
$ flox activate -- make png      # one PNG per slide
```

Output lands in `build/`, which is gitignored. `make` is the whole build; there
is no `npm install`.

The PDF is generated with `--pdf-notes`, so the speaker notes travel with it as
annotations — that's the file to put on a backup laptop.

### Presenting

The talk *opens* from the PDF, then switches to the live deck — that's Act 0,
and the room does it with you. Sequence:

1. Put `build/slides.pdf` on the projector, title slide. Ask people to clone;
   advance to slide 2 so they have the commands. Pass shirts and sharpies.
2. In a **clean** terminal — no `flox activate`, `command -v marp` empty —
   run `make` and let it fail. Read the error out loud.
3. `flox activate -- make serve`, open http://localhost:8080/slides.md, press
   <kbd>P</kbd> for presenter view (notes, next slide, timer). Arrow keys
   advance. <kbd>F</kbd> is fullscreen without notes.

The PDF is the backup: it was generated with `--pdf-notes`, so the speaker
notes travel with it as annotations. Keep it on a second laptop.

Live demos: projector gets the terminal, laptop gets
[`demo/CHEATSHEET.md`](demo/CHEATSHEET.md). Paste the flake and the services
TOML — don't type them. Short commands (`git add`, `flox init`) you type.

## The theme

`theme/flox.css` uses Flox's real palette and typeface, read out of flox.dev's
own stylesheets rather than eyeballed:

| Token | Value | Used for |
|---|---|---|
| black | `#1b1b1b` | dark slide background, code blocks |
| purple | `#711aff` | primary accent, headings rule, emphasis |
| violet | `#af54ff` | list markers, kickers |
| rose | `#f47bff` | accent on dark slides |
| orange | `#ff7c32` | gradient terminus |
| yellow | `#ffd02b` | strings in code |
| grays | `#fafafa` → `#9b9b9b` | panels, muted text |

Type is [Geist](https://vercel.com/font) and Geist Mono, pinned in the Flox
environment so the deck renders correctly with no network at all. The theme also
`@import`s them from Google Fonts as a fallback for building outside the
environment. Every slide carries a gradient hairline across the top; the logo
appears on the opening and closing slides.

### Slide classes

Set per slide with `<!-- _class: … -->`:

| Class | Effect |
|---|---|
| `title` | Large centered title treatment, room for the logo and a `.meta` block |
| `dark` | `#1b1b1b` background, rose accents — for section breaks and impact lines |
| `lead` | One big centered statement; use a blockquote for the line itself |
| `demo` | Demo marker: kicker, huge title, `.cmd` subtitle |
| `tight` | Denser type for slides carrying a table or a lot of code |

Layout helpers: `.cols` (two columns, `.narrow-left` variant), `.wall` around a
code block that must run small to fit, `.kicker`, `.big`, `.small`, `.tiny`,
`.muted`, `.center`.

### The `rhyme` layout

`.rhyme` is the flake-vs-TOML slide: cramped "hard way" on the left, one short
thing on the right, matching results in `.match`:

```html
<div class="rhyme">
<div class="grind">
<div class="label">Raw Nix — flake.nix</div>
… 20-line flake …
<span class="match">20 lines of Nix</span>
</div>
<div class="shortcut">
<div class="label">Flox — manifest.toml</div>
… 4-line TOML …
<span class="match">4 lines of TOML</span>
</div>
</div>
```

The contrast is the argument — don't restyle one column without the other.

## Checking for overflow

The one deck bug you can't catch by eye: the markdown looks fine, the preview
looks fine, and the bottom two lines of a code block are gone on the projector.
`make check` renders the deck in headless Chromium and measures every slide
against the 720px canvas, including content silently clipped inside a scroll
container.

Run it after editing. The `grind` column on the flake-vs-TOML slide fits a full
20-line flake with only a few pixels to spare.

It distinguishes "this slide overflows" (exit 1) from "I could not measure
reliably" (exit 2) — a missing font or a bad render is reported as the latter,
because a check that cries wolf is a check you learn to ignore.
