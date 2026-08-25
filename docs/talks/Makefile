# Renders the talk deck. Run inside the Flox environment in this directory:
#
#   flox activate -- make
#   flox activate -- make serve
#
# marp-cli, gnumake, and chromium are pinned in .flox/env/manifest.toml,
# and the activation hook points CHROME_PATH at the real browser path (not
# a /mnt/c wrapper — Marp CLI would otherwise treat it as Windows Chrome).
#
# `make` without that environment is supposed to fail. That's the opening
# of the talk: the toolchain is a file in the repo, not a thing you apt-get.

MARP  := marp
DECK  := slides.md
BUILD := build

# Marp does not search PATH for `chromium`. It honours CHROME_PATH, or a
# handful of distro locations that a Nix sandbox does not have. The activation
# hook sets this, but `flox build` skips hooks (`--skip-hook-on-activate`).
# HTML export does not need a browser, so a miss here is not fatal.
_resolved_chrome := $(shell ./resolve-chrome.sh 2>/dev/null)
ifneq ($(_resolved_chrome),)
  export CHROME_PATH := $(_resolved_chrome)
endif

.PHONY: all html pdf pptx png watch serve clean check check-marp

all: check-marp html pdf

html: check-marp $(BUILD)/slides.html
pdf: check-marp $(BUILD)/slides.pdf
pptx: check-marp $(BUILD)/slides.pptx
png: check-marp $(BUILD)/png

DEPS := $(DECK) theme/flox.css .marprc.yml

# Pedagogical failure for the opening demo. check-marp is a phony aggregator
# prerequisite, not a file prerequisite, so a leftover build/ does not hide
# the miss — `make` still fails if marp isn't on PATH.
check-marp:
	@command -v $(MARP) >/dev/null 2>&1 || { \
	  printf '%s\n' \
	    '' \
	    '  marp is not on PATH.' \
	    '' \
	    '  The toolchain for this deck lives in .flox/ — a file in this repo.' \
	    '  Activate it, then retry:' \
	    '' \
	    '    flox activate -- make serve' \
	    '' \
	    '  No Flox yet? https://flox.dev/docs/install-flox/install' \
	    '' >&2; \
	  exit 1; \
	}

$(BUILD)/slides.html: $(DEPS)
	$(MARP) $(DECK) -o $@

# --pdf-notes puts the speaker notes in the PDF as annotations, so the
# presenter copy carries the script with it.
$(BUILD)/slides.pdf: $(DEPS)
	$(MARP) $(DECK) --pdf --pdf-notes -o $@

$(BUILD)/slides.pptx: $(DEPS)
	$(MARP) $(DECK) --pptx -o $@

$(BUILD)/png: $(DEPS)
	$(MARP) $(DECK) --images png -o $(BUILD)/png/slide.png

# Live preview at http://localhost:8080 with reload on save.
#
# Do not pass `.` to --watch. After `flox activate`, `.flox/run` is a symlink
# into the Nix store; Marp's chokidar follows it and dies with EMFILE on macOS.
SERVE_ROOT := .serve

serve: check-marp
	@mkdir -p $(SERVE_ROOT)
	@for p in slides.md chippewa-valley-devs.md theme assets demo; do \
	  [ -e "$$p" ] || continue; \
	  ln -sfn "../$$p" "$(SERVE_ROOT)/$$p"; \
	done
	$(MARP) --server --watch $(SERVE_ROOT)

watch: check-marp
	$(MARP) $(DECK) --watch -o $(BUILD)/slides.html

# Fails if any slide overflows its 720px canvas — the failure mode that is
# invisible in the editor and obvious on a projector. Renders its own copy, so
# it takes the deck source rather than a build artifact.
check:
	@./check-overflow.sh $(DECK)

clean:
	rm -rf $(BUILD) $(SERVE_ROOT)
