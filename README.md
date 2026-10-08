# linuxbren.github.io

Personal site: retro-styled tools for Omarchy ([tidefiles](https://github.com/linuxbren/tidefiles),
[flyover](https://github.com/linuxbren/flyover), [flyover-pill](https://github.com/linuxbren/flyover-pill)).
One static `index.html`, plain HTML/CSS plus a few lines of JS for the copy
buttons, no build step. Served by GitHub Pages from `master`.

Live at https://linuxbren.github.io.

## Deploying

**Always push website changes live.** Pushing to `master` publishes the site
within a minute or so. Check the page locally at desktop (1280px) and phone
(390px) width first, then push and confirm the deployed page. (Brenden's rule
covers websites only; other code waits for his OK before pushing.)

## Layout ("A + C combo", Hackerman theme)

- **Nav:** `linuxbren ✈` wordmark; tools · hangar · about · github ↗.
- **Hero:** prompt line, h1 "Retro tools for Omarchy.", lede, two buttons.
- **Toolbox (`#tools`):** a three-column grid (`auto-fit, minmax(300px, 1fr)`;
  one column on phones) of equal cards, in this order: tidefiles, flyover, flyover-pill.
  Each card leads with its own kind of shot:
  - tidefiles: a 16:10 terminal window with one screenshot
  - flyover: a round radar, a live looping clip in a circular mask, max 300px
  - flyover-pill: a 72px bar strip with the pill at actual size

  Then the name, a version/language chip, a one-paragraph pitch, the install
  command with a copy button, and links. Long per-tool detail lives in each
  tool's README, not here.
- **In the hangar (`#hangar`):** dashed "soon" cards for upcoming projects.
- **About (`#about`)** strip with interest chips, then the footer.

Colors are CSS variables on `:root` (bg `#0b0c16`, panel `#11132a`, accent
`#82fb9c`, links `#7fd7ff`, border `#2d3450`). Fonts: JetBrains Mono for the
body, Chakra Petch 700 for the wordmark and h1 (Google Fonts). The page leads
with the `linuxbren` identity; X posts are deliberately left out for now.

### Whole-card links

Each tool card links to its GitHub repo through the "stretched link" pattern.
The card title (`a.card-link`) is the real link, and its `::after` covers the
card. The inner links (`p a`, `.links a`) and the code box (`.cmd`, which
holds the copy button) sit above it with `position: relative; z-index: 2`.
That keeps releases/crates.io/screensaver links working, makes copy never
navigate, and keeps the command text selectable. Don't wrap a card in an
`<a>` or nest anchors. On hover or focus-within the card's border goes accent
and it lifts 3px (no lift under `prefers-reduced-motion`).

## Assets

Everything in `assets/` is loaded by `index.html`:

| file | used for |
|---|---|
| `tidefiles-images.webp` | tidefiles card (1200px webp made from tidefiles' `docs/screenshots/tabs.png`, v0.7.0) |
| `flyover-ascii-demo.webm` | flyover's round radar (looping Braille-mode clip, 480×508) |
| `flyover-ascii.webp` | poster frame for that clip |
| `pill.webp` | flyover-pill bar strip (540×60, shown at actual size) |

Screenshots from other repos are converted with
`magick in.png -resize 1200x -quality 82 -define webp:method=6 out.webp`.

### Recording the flyover clip

`scripts/record-flyover-demo.sh [sixel|ascii] [seconds] [name] [warmup]` runs
the real `flyover --screensaver` in a window, captures frames with `grim`, and
writes `assets/<name>.webm` plus a `.gif`. The `.gif` is for READMEs and isn't
committed here. The window takes whatever size the tiling layout gives it, so
check that the radar comes out centered: the old Sixel clip didn't, which is
why the round radar uses the Braille clip. The circular crop in CSS
(`object-position: 50% 18%; transform: scale(1.1)`) is tuned for a scope
centered in a roughly 480×508 frame.

## Open items

- **✈ in the wordmark** renders as a color emoji on some systems, because
  neither web font has the glyph. An inline SVG plane would fix it.
- **No `og:image` yet.** The OG title/description/url tags are in place.
