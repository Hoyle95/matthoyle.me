# matthoyle.me: project guide

Personal site for **Matt Hoyle, aka "Mental.Glitch"**: a designer & tinkerer from the UK, born ’95.
It's one page with a cyberpunk, "digital" look. Live at **https://matthoyle.me/**.

This file is for anyone (human or LLM) picking the project back up. Read **Owner preferences** before
changing anything visual; those are decisions that have already been made and revisited.

---

## Files

| Path | What it is |
|---|---|
| `index.html` | The whole site. HTML, CSS (in `<style>`) and JS (in `<script>` at the end) in one file. No build step, no dependencies. |
| `images/me.webp` | Profile photo, full size (1000px). |
| `images/me-512.jpg` | 512px copy of the photo. Chosen via `srcset` for most screens, since it's shown at 170–220px. Regenerate it if the photo changes. |
| `images/me.jpg` | JPEG copy of the same photo, used **only** for link previews (Open Graph / Twitter). Some platforms don't reliably show WebP. |
| `images/projects/*.jpg` | Project thumbnails, 800×500 screenshots taken at a 1280×800 viewport. Made with `tools/capture-thumbnail.ps1`. |
| `robots.txt`, `sitemap.xml` | For search engines. Bump `<lastmod>` in the sitemap when content changes. |
| `fonts/*.woff2` | Self-hosted fonts (Latin subsets from Google Fonts, SIL Open Font License): Orbitron 800–900 (one file), Chakra Petch 400, JetBrains Mono 400. Declared with `@font-face` at the top of the `<style>`, and preloaded in `<head>`. |
| `js/count.js` | GoatCounter's analytics script, self-hosted (GoatCounter's docs allow this; see below). |
| `tools/serve.ps1` | Local web server (`http://localhost:8765/`) for testing in a browser. |
| `tools/capture-thumbnail.ps1` | Screenshots a live site into `images/projects/`. |
| `tools/device-test.ps1` | Emulates 10 phones, tablets and desktops (with touch and a slowed processor on phones) and checks the page on each. See **Testing**. |

**Everything the page loads is self-hosted.** The only outside connection is the GoatCounter pageview report, sent to
`https://hoyle95.goatcounter.com/count` (stats at https://hoyle95.goatcounter.com/). Keep it that way. It was measured
on a simulated 4G phone: first paint was ~14% faster and full load ~49% faster than with Google Fonts and `gc.zgo.at`.
- **Analytics:** `<script data-goatcounter="https://hoyle95.goatcounter.com/count" async src="js/count.js">` in `<head>`.
  GoatCounter's docs ("Host count.js somewhere else") allow self-hosting; the `/count` endpoint is guaranteed to stay
  compatible. The `data-goatcounter` attribute is what tells it where to report, so keep it. The one downside is no
  automatic updates, so refresh `js/count.js` from https://gc.zgo.at/count.js now and then. It doesn't count `localhost`.
- **Fonts:** see **Fonts** below.

---

## Page structure (top to bottom)

1. **Background layers**, all `position: fixed` and `aria-hidden`:
   - `#particles`: canvas "digital rain" of katakana, hex and code symbols. Mostly cyan, ~15% of columns magenta. Columns near the cursor speed up. Canvas `opacity: 0.4`, with a radial mask that dims the centre so text stays readable.
   - `.blob.one/two/three`: large blurred violet, magenta and cyan glows drifting slowly.
   - `.grid-floor`: synthwave perspective grid scrolling along the bottom.
   - `.scanlines` (with a sweeping light bar) and `.noise` (film grain).
   - `.hud.tl/.tr/.bl/.br`: corner readouts: status, clock (top right), `BUILD v1.5` and FPS (`#fps`), and `LOAD` / `RESPONSE` / `SIGNAL` bars (bottom right).
     - **`RESPONSE` and `LOAD`** are real, measured once per visit with the Navigation Timing API. `RESPONSE` is the server response time (`responseStart − requestStart`); it shows `CACHED` if the page came from the browser cache. `LOAD` is the full page load (`loadEventEnd`). Both are shown in ms, or in seconds from 1000ms.
     - **`SIGNAL` bars** follow the server response time (`SIGNAL_LEVELS` / `showSignal()`). Cached counts as full signal.

       | Response | Bars | Colour |
       |---|---|---|
       | under 100ms | 5 | green |
       | under 200ms | 4 | green |
       | under 400ms | 3 | yellow |
       | under 800ms | 2 | orange |
       | slower | 1 | red |

     - **Phones:** all four corners show on phones (the owner wants the bottom ones visible too).
       - **1260px and below:** the 920px terminal reaches under the bottom corners, so they get a dark rounded backing (fading in with their text), which keeps content scrolling under them readable. Wider screens have clear margins and no backing.
       - **700px and below:** the footer also gets extra bottom padding (`body > footer`) so it sits clear of the corners.
       - **440px and below:** the HUD gets a slightly smaller font and tighter spacing, so the top corners don't collide (checked at 320px with the longest time zone).
     - **Top-right clock** (three lines, updated every second):
       - `#server-time` shows the owner's UK time, e.g. `SERVER 16:44:09 UTC+1`.
       - `#client-time` shows the visitor's local time, e.g. `CLIENT 11:44:09 UTC-4`.
       - `#time-gap` shows the difference, e.g. `5H BEHIND`, `4H 30M AHEAD` or `SAME TIME`.
     - **Daylight saving is automatic. Don't hard-code offsets, and there's no need for a time API.** The UK offset is worked out every tick from the browser's built-in `Europe/London` rules (`ukTime.formatToParts`). It was checked to the second at both UK changes: 01:59:59 BST → 01:00:00 GMT, and 00:59:59 GMT → 02:00:00 BST. The one thing it relies on is the visitor's device clock being roughly right.
   - Custom cursor (`.cursor-dot` + `.cursor-ring`). Hidden on touch devices (`hover: none`).
2. **Hero** (`header.hero`):
   - Avatar in a spinning conic-gradient ring.
   - `h1.name` "Matt Hoyle". JS splits it into per-letter spans for the flip-in, then a shimmer.
   - "aka".
   - `.glitch#alias` "Mental.Glitch": RGB-split glitch slices, a flicker, and a periodic character scramble.
3. **One terminal window** (`section.panel`). Everything else lives inside it, revealed as a sequence of typed commands:
   - `cat about.txt` → About text (typewriter, with some phrases highlighted yellow).
   - `./socials.sh` → four social link cards (`nav.links#socials`).
   - `ls ~/projects` → `# websites I've built for other people` + project cards (`.projects-wrap#projects`).
4. **Footer**: `© <year> Matt Hoyle`, and nothing else.

---

## Design system

### Colour tokens (`:root`)

| Token | Value | Used for |
|---|---|---|
| `--bg` | `#07030f` | Page background (near-black purple) |
| `--cyan` | `#00f0ff` | Primary neon: prompts' `:~$`, glitch, rain, cursor dot |
| `--magenta` | `#ff2bd6` | Secondary neon: caret, cursor ring, HUD corners |
| `--violet` | `#8a2bff` | Blobs, favicon crescent, `theme-color` (Discord embed bar) |
| `--yellow` | `#ffe600` | Highlighted words in the About text only |
| `--text` | `#eae6ff` | Body text |
| `--muted` | `#a79fc9` | Secondary text: handles, descriptions, comments |
| `--border` | `rgba(255,255,255,.12)` | Hairline borders |

Other fixed colours:
- **Prompt username** `matt@glitch` is terminal green `#39ff88`.
- **Terminal title-bar dots** are the macOS red, yellow and green.
- **Name gradient** is white → cyan → magenta. The **avatar ring** uses only those same three colours (`#fff`, cyan, magenta).
- **Card `--brand` colours**, used for the glow, spotlight, icon and tags:
  - Socials: Instagram `#ff3d8b`, YouTube `#ff2a2a`, Twitch `#a970ff`, Discord `#6f7dff`.
  - Projects: each card sets `style="--brand: …"` inline from that site's own theme colour.

### Fonts (self-hosted)

Self-hosted in `fonts/` (no Google Fonts requests). Each has an `@font-face` with Google's Latin `unicode-range` and `font-display: swap`, plus a `<link rel="preload">`. Only the weights in use are included. If you need a new weight or character set, download that woff2 from Google Fonts (read the `css2?family=…` stylesheet for the file URL), add it to `fonts/`, and add an `@font-face` for it.

Use the CSS variables `--display`, `--body` and `--mono` rather than repeating font names. The one exception is the rain's glyph sheet (`buildAtlas()` in the JS), which can't read CSS variables. The rain waits for the fonts (`document.fonts.ready`), but only up to 1.5s. After that it starts with fallback glyphs and redraws them when the font arrives.

| Font | Role |
|---|---|
| **Orbitron** (800/900) | Display: the name, alias and card titles. Always uppercase or short. |
| **Chakra Petch** (400) | Body text, including the About paragraph. |
| **JetBrains Mono** (400) | Anything "terminal": prompts, commands, comments, handles, tags, HUD, browser bars. |

### Components and conventions

- **Terminal prompt line**:
  ```html
  <p class="term-line"><span class="prompt">matt@glitch<b>:~$</b></span> command</p>
  ```
  Prompt lines that appear later in the sequence also get `queued-cmd`. The command is the line's last `<span>`, which JS clears and re-types.
- **Terminal comment**: `<p class="term-comment"># …</p>` (muted mono).
- **Terminal border pulse** (`.panel-border`): a cyan band with a fading tail sweeps diagonally from the top-left corner to the bottom-right, lighting the whole border. It's a 300% gradient layer moved with `transform`.
  - **Timing:** it fades in at the top-left, travels at a steady (linear) speed, and fades out as its head lands on the bottom-right. It then pauses, and each cycle is 4.5s.
  - **Don't ease it:** with `ease-in-out`, the pulse slowed as it reached the bottom-right corner and its dim tail lingered there, which looked broken.
  - **Keep the ring a whole number of pixels** (`padding: 2px`). At 1.5px the browser snapped the inner edge unevenly, making the bottom-right corner render thinner and less round than the top-left.
- **Link card** (`a.link-card.<platform>`): icon, name and handle. Inline SVG icons use `fill: currentColor`. Hover effects:
  - 3D tilt that follows the mouse
  - radial spotlight
  - shine sweep
  - brand-colour glow
- **Project card** (`a.project-card`): a fake browser bar with the domain over the screenshot (scanlines and a brand tint that clear on hover, plus a quick glitch), then title, one-line description and 1–2 lowercase tags. It has the same tilt and spotlight as link cards (shared JS).
- **Links** to external sites use `target="_blank" rel="me noopener"` on the socials, so profiles can verify ownership, and `rel="noopener"` on projects.
- **Glow style**: neon via layered `text-shadow`/`box-shadow` in the element's own colour. Hover states brighten borders to `--brand`.

---

## Load and animation sequence

Timings are tuned; the owner asked for the socials to show quickly.

**Intro (0–0.95s, `--intro`):** the page opens like it's booting up.
- A dim overlay (`.intro-dim`) covers the background.
- The four HUD corner brackets appear together as a small 80px frame in the middle of the screen. They then open out to the corners (`hud-open`, 0.2–0.95s, GPU transform; `--dx`/`--dy` per corner, `--edge` = corner inset).
- At `--intro`, the HUD text (`.hud-text`) fades in, the overlay fades away, and the content below starts.

Everything after the intro is offset by `--intro`. In CSS that's `calc(var(--intro) + …)`; in JS it's the `INTRO` constant, read from the CSS variable. Change `--intro` to lengthen or shorten the intro, and everything else shifts with it.

| When (after the intro) | What |
|---|---|
| +0.2s | Avatar pops in |
| +0.5s + 0.06s/letter | Name letters flip in |
| +1.5s | "aka" fades up |
| +1.8s | Alias fades up. It scrambles then, every 5s, and on hover. |
| +1.4s | Terminal panel fades in (`data-revealAt`, counted from page load; panels scrolled to later appear immediately) |
| +0.2s | About types at 9–18ms/char |
| +0.15s | `./socials.sh` types at 25–50ms/char. Output appears 120ms later, cards staggered 0.07s. |
| +0.45s | `ls ~/projects` types, then project cards appear (staggered 0.07s) |

- **Sequencing code**: `typeOut(text, render, delay, pause, done)` is the shared typewriter. `runCommand(n, output, done)` shows the n-th `queued-cmd` line, types its command, then adds `.show` to the output element. `startTerminal()` chains them.
- **Adding a command**: to chain another command after projects, add a new `queued-cmd` line and output element, then call `runCommand(2, …)` from the previous command's `done` callback in `startTerminal()`.

### Accessibility and fallbacks (keep these working)

- **`prefers-reduced-motion`** (a deliberate OS setting, off by default everywhere): there is no intro, no dim overlay, no entrance effects and no delays (`--intro: 0s`; all delays are forced to 0). The whole page fades in once (`page-fade`, 0.5s), and commands and outputs show instantly.
- **`<noscript>` styles**: everything is visible without JS.
- **No-JS error banner** (`.js-off`, inside a `<noscript>` at the top of `<main>`): a yellow terminal-style "● ERR_JS_DISABLED" label (no background or border), with a blinking dot, a soft glow and a slight flicker. It fades in with the HUD text after the intro. JS visitors never see or load it.
  - **768px and wider:** it's pinned top-centre (`position: fixed`), level with the first line of the top HUD corners, in the HUD's type size and spacing.  - **Phones:** there's no room between the top corners, so it sits in the page flow, centred just below them (≤440px adds a top margin to clear them). To preview it in Chrome: DevTools → `Ctrl+Shift+P` → "Disable JavaScript" → reload.
- **About text and command text** are written into the HTML (for crawlers and no-JS visitors). JS reads them from the HTML, clears them on load and re-types them, so the HTML is the single source of truth.
- **Decorative layers** are `aria-hidden`. The About section has `aria-label="About me"`.

---

## Owner preferences (decided, don't undo)

- **Name**: always **"Matt Hoyle"**, never "Matthew". That applies to page text, meta tags, JSON-LD, alt text and docs.
- **Aesthetic**: cyberpunk, developer or terminal feel, flashy and animated, but **readability comes first**.
- **Nothing may shift the layout.** The alias scramble used to make the page "shake"; it's fixed by locking `#alias` to the measured width and height of the final text (`lockAliasSize()`). Keep that when touching the alias.
- **The name must stay on one line on mobile.** `.name` has `white-space: nowrap` and `font-size: clamp(1.25rem, 7.2vw, 4.6rem)`. Per-letter inline-block spans otherwise wrap mid-word. Checked at 320, 360 and 412px.
- **One terminal window only.** Socials and projects are commands in the same terminal, not separate panels or sections.
- **Removed on request; don't re-add:**
  - the "About me" / "Find me online" headings
  - the tag chips in About
  - the quote bar (left border line) beside the About text
  - the scrolling marquee banner at the bottom
  - the arrows on social buttons
  - the orbiting dots around the avatar
  - "made with ♥ & a little glitch" in the footer
- **Performance (mobile especially)**: animate `transform` and `opacity` only, never `top`, `background-position` and the like, which repaint every frame. Examples already on the page: the grid floor, scan line, terminal border (`.panel-border`) and grain. The rain draws glyphs from a pre-rendered sprite sheet (`buildAtlas()`) instead of calling `fillText` every frame. Any optimisation must leave the look unchanged.
- **Text selection highlight is transparent** (`::selection { background: transparent }`).
- **Avatar ring** uses only the name's colours (white, cyan, magenta). The sharp ring (`::before`) spins by animating the gradient's angle (`@property --ring-angle`), **not** by rotating the element. With `transform: rotate`, mobile browsers dropped the sharp ring after fast scrolling and left only the blurred glow. The blurred glow (`::after`) does rotate with a transform, which is cheaper and safe. Both take 4s, so they stay in step.
- **Avatar hover glitch** runs as a short burst (~1.6s, `img-glitch` × 4), not infinitely. It replays each time the mouse re-enters.
- **Favicon**: an inline SVG data URI in `<head>`. It's a circle with a white → cyan → magenta gradient and a soft, blurred violet crescent on the bottom-right edge ("more purple, but not 50/50").
- **`<title>`**: "Matt Hoyle aka Mental.Glitch" (the word "aka", not a dash).
- **Terminal commands should fit what they show**: `cat` for text, `./socials.sh` for the visual link buttons, `ls` for the projects list.
- **The background can be touched only when asked.**

---

## How to…

**Add or change a social link.** Update all three places:
1. The `<a class="link-card …">` in `#socials`. Add a `.link-card.<name> { --brand: … }` rule for a new platform.
2. `sameAs` in the JSON-LD `<script type="application/ld+json">` in `<head>`.
3. The card stagger rules (`.links.show .link-card:nth-child(n)`, shared with project cards), if you add a fifth card.

**Add a project:**
1. Take a thumbnail:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-thumbnail.ps1 -Url https://example.com/ -Name example
   ```
   For sites with lazy-loading photo galleries, add `-NotReadySelector "<css for not-yet-loaded items>"`. The owner's craft sites use `".banner__collage-img:not(.is-loaded)"`.
2. **Look at the image** before using it. Grey or black tiles mean something hadn't loaded.
3. Copy an existing `a.project-card` block in `.projects`. Set:
   - `--brand` to the site's theme colour (check its `<meta name="theme-color">`)
   - the domain in the browser bar
   - `src` and `alt`
   - a one-sentence description
   - 1–2 lowercase tags
4. If there are now more than four cards, extend the shared `:nth-child(n)` stagger rules.

**Change the About text.** Edit the `#about` element content. The phrases in the JS `highlight` array render yellow, so update that array if the wording changes. Also consider updating the matching descriptions in `<meta name="description">`, `og:description`, `twitter:description` and the JSON-LD.

**Change the domain.** Search and replace `https://matthoyle.me/` across `index.html`, `robots.txt` and `sitemap.xml`. Open Graph and Twitter image URLs must be absolute.

---

## Testing

- **Device test (run it after visual or layout changes)**: start `tools\serve.ps1`, then run `powershell -NoProfile -ExecutionPolicy Bypass -File tools\device-test.ps1`. Every device should show:
  - `errors: none`, `sequenceDone` / `cardsShown` / `nameOneLine` / `hudCornersIn` / `bottomCornersReadable` / `footerClear` all true
  - `horizontalOverflow: 0`
  - `hudTopOverlap` / `hudBottomOverlap` false

  Options: `-Only "iPhone 14"`, `-ReducedMotion`, `-NoJs`, `-Shots`. The first frame or two on phones is the initial page build (typically 50–250ms at 4× CPU), which is expected. The intro animation runs on the GPU, so it isn't held up. It can't test Safari or Firefox; check those on real devices.
- **Local server**: run `powershell -NoProfile -ExecutionPolicy Bypass -File tools\serve.ps1`, then open `http://localhost:8765/`. Browser extensions (Claude in Chrome) refuse `file://` URLs.
- **Chrome background throttling**: Chrome throttles tabs it treats as background, so the FPS HUD reads ~1 and the typing crawls. That isn't a bug in the page. To fast-forward the sequence from the console, run:
  ```js
  window.setTimeout = f => (queueMicrotask(f), 0)
  ```
- **Owner's Chrome zoom**: the owner's Chrome renders zoomed out (`innerWidth` reported 2560 in a ~1280px window). Don't rely on it for layout-width screenshots.
- **Phone widths with headless Edge**: headless won't make a window narrower than ~500px. To test phone widths, load the page in fixed-width `<iframe>`s (e.g. 320, 360, 412px) inside a wrapper page and screenshot that. For static screenshots, also inject CSS that disables animations and forces `.panel, .link-card, .project-card, .name .char, …` to `opacity: 1`. Otherwise you'll capture the pre-animation state.
- **PowerShell 5.1**: `Invoke-RestMethod` / `ConvertFrom-Json` pass a JSON array down the pipeline as one object, so unroll it with `ForEach-Object { $_ }`. Also, `Set-Content` defaults to ANSI; write files as UTF-8 without a BOM (`[IO.File]::WriteAllText(..., (New-Object Text.UTF8Encoding $false))`) so characters like `’` survive.
- **No Python, Node or ImageMagick on this machine.** Image conversion uses Windows' built-in WPF imaging (`PresentationCore`: `BitmapDecoder`, `JpegBitmapEncoder`), which can also *decode* WebP.

---

## Commits

The owner commits themselves, with short lowercase messages (e.g. `no wrap`,
`load animation is faster, selection highlight colour is now transparent`). Don't commit unless asked.
