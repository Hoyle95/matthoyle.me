# matthoyle.me: project guide

Personal site for **Matt Hoyle, aka "Mental.Glitch"**: a designer & tinkerer from the UK, born ’95. One page with a
cyberpunk / terminal look. Live at **https://matthoyle.me/**. Repo: `git@github.com:Hoyle95/matthoyle.me.git` (branch `main`).

This file is for anyone (human or LLM) picking the project back up. Read **Working with the owner** and
**Owner preferences** before changing anything; those are decisions that have already been made and revisited.

---

## Working with the owner (read first)

- **Suggestions need a yes first.** When asked for ideas, list them and wait. Only build what the owner picks.
  When a request is clear ("make X blue"), just do it.
- **Keep the site simple.** The owner rejected an interactive terminal (typed commands like `help`, `clear`,
  `rm -rf /`) as "getting too complicated" and had it fully removed. Prefer polishing what's there over adding systems.
- **Never change the look as a side effect.** Optimisations and clean-ups must look identical.
- **Test after every visual change** (see **Testing**), and describe results in plain language. The owner isn't
  interested in code details, but does want to know about trade-offs.
- **Commits:** only when asked. **Always bump the build number, then check the sitemap date, first** (see
  **Commits**). Never push; the owner pushes.
- **Writing style:** British English (colour, optimise), and the name is always **"Matt Hoyle"**, never "Matthew".

---

## Files

| Path | What it is |
|---|---|
| `index.html` | The whole site: HTML, CSS (`<style>`) and JS (`<script>` at the end). No build step, no dependencies. |
| `images/me.webp` | Profile photo, full size (1000px). |
| `images/me-512.jpg` | 512px copy, picked via `srcset` for most screens (it's shown at 170–220px). Regenerate if the photo changes. |
| `images/me.jpg` | JPEG copy, used only as the JSON-LD `image` (search engines). |
| `images/og-card.jpg` | 1200×630 link-preview banner (`og:image`, Twitter `summary_large_image`). **Generated.** |
| `apple-touch-icon.png` | 180×180 iPhone/iPad home-screen icon (favicon circle on the dark background). **Generated.** |
| `images/projects/*.jpg` | Project thumbnails: 800×500 screenshots at a 1280×800 viewport, made with `tools/capture-thumbnail.ps1`. |
| `fonts/*.woff2` | Self-hosted Latin subsets (SIL OFL): Orbitron 800–900 (one file), Chakra Petch 400, JetBrains Mono 400. |
| `js/count.js` | GoatCounter analytics script, self-hosted (allowed by GoatCounter's docs). |
| `robots.txt`, `sitemap.xml` | For search engines. `robots.txt` keeps `/tools/` out of search results. **Bump `<lastmod>` in the sitemap when content changes.** |
| `tools/serve.ps1` | Local web server at `http://localhost:8765/`. |
| `tools/device-test.ps1` | Emulates 10 phones, tablets and desktops and checks the page on each (see **Testing**). |
| `tools/capture-thumbnail.ps1` | Screenshots a live site into `images/projects/`, waiting for lazy-loaded images. |
| `tools/og-card.html`, `tools/touch-icon.html` | Sources of the two generated images: the site's fonts, colours and effects as a still frame. |
| `tools/render-images.ps1` | Renders both (headless Edge, no server needed). **Re-run after changing the name, tagline, photo or favicon.** |

**Everything the page loads is self-hosted.** The only outside connection is the GoatCounter pageview report to
`https://hoyle95.goatcounter.com/count` (stats: https://hoyle95.goatcounter.com/). Keep it that way; on a simulated 4G
phone it made first paint ~14% faster and full load ~49% faster than Google Fonts + `gc.zgo.at`.
- **Analytics:** `<script data-goatcounter="https://hoyle95.goatcounter.com/count" async src="js/count.js">`. The
  `data-goatcounter` attribute tells it where to report, so keep it. The `/count` endpoint is guaranteed to stay
  compatible. There are no automatic updates, so refresh `js/count.js` from https://gc.zgo.at/count.js now and then.
  It doesn't count `localhost` visits.
- **Hosting:** static files served by **Caddy** (`file_server` from a Caddyfile). The Caddyfile isn't in this repo,
  and how files reach the server is up to the owner. `tools/` and this file are publicly reachable, and the owner is
  fine with that; they contain nothing sensitive, so keep it that way (no secrets, keys or personal paths).

---

## Page structure (top to bottom)

1. **Background layers** (`position: fixed`, `aria-hidden`):
   - `#particles`: canvas "digital rain" (katakana, hex, code symbols; mostly cyan, ~15% of columns magenta; columns near the cursor speed up). Opacity .4, with a radial mask that dims the centre.
   - `.blob.one/two/three` (drifting violet, magenta and cyan glows), `.grid-floor` (synthwave grid), `.scanlines` (with a sweeping light bar), `.noise` (film grain).
   - Custom cursor (`.cursor-dot` + `.cursor-ring`), mouse/trackpad only.
   - **HUD corners** (`.hud.tl/.tr/.bl/.br`), shown on all screen sizes:
     - **Top-left:** `SYS://MENTAL.GLITCH` and `● ONLINE`.
     - **Top-right clock** (updates every second):
       - `SERVER 16:44:09 UTC+1`: the owner's UK time.
       - `CLIENT 11:44:09 UTC-4`: the visitor's time.
       - `5H BEHIND` / `4H 30M AHEAD` / `SAME TIME`.
       - **Daylight saving is automatic:** the UK offset comes from the browser's `Europe/London` rules every tick
         (`ukTime.formatToParts`). Don't hard-code offsets and don't add a time API. It was checked to the second at
         both UK clock changes.
     - **Bottom-left:** `BUILD v1.7` and a real `FPS` counter (frames drawn by the rain loop).
     - **Bottom-right:** `LOAD` / `RESPONSE` / `SIGNAL`, measured once per visit with the Navigation Timing API:
       - `LOAD` is `loadEventEnd`.
       - `RESPONSE` is `responseStart − requestStart`, or `CACHED`.
       - `SIGNAL` bars follow the response time (`SIGNAL_LEVELS`): <100ms 5 green, <200ms 4 green, <400ms 3 yellow,
         <800ms 2 orange, slower 1 red. Cached counts as full.
     - **≤700px:** the footer gets extra bottom padding to clear the corners.
     - **≤440px:** the HUD text is smaller and tighter, so the top corners don't collide (checked at 320px with the
       longest time zone).
2. **Hero** (`header.hero`):
   - Avatar in a spinning ring.
   - `h1.name` "Matt Hoyle", split into per-letter spans for a flip-in, then a shimmer.
   - "aka".
   - `.glitch#alias` "Mental.Glitch": RGB-split slices, a flicker, and a character scramble every 5s and on hover.
3. **One terminal window** (`section.panel`) holding everything else, revealed as typed commands:
   - `cat about.txt` → the About text (typed out; some phrases highlighted yellow).
   - `./socials.sh` → four social link cards (`#socials`).
   - `ls ~/projects` → `# websites I've built for other people` + project cards (`#projects`).
4. **Footer**: `© <year> Matt Hoyle`, nothing else.

**About text (current):** "Designer & tinkerer from the UK, born in ’95." then a blank line, then "This is where I share my
random creative endeavours." The blank line is a real line break in the HTML (`white-space: pre-line`). Highlights (JS
`highlight` array): "Designer & tinkerer", "UK", "’95", "creative endeavours".

---

## Design system

| Token | Value | Used for |
|---|---|---|
| `--bg` | `#07030f` | Page background |
| `--cyan` | `#00f0ff` | Primary neon: `:~$`, glitch, rain, cursor dot, focus outline |
| `--magenta` | `#ff2bd6` | Secondary neon: typing caret, cursor ring, HUD brackets |
| `--violet` | `#8a2bff` | Blobs, favicon crescent, `theme-color` (Discord embed bar) |
| `--yellow` | `#ffe600` | About highlights, the no-JS error label |
| `--text` / `--muted` | `#eae6ff` / `#a79fc9` | Body / secondary text |
| `--border` | `rgba(255,255,255,.12)` | Hairline borders |

- **Other colours:**
  - Prompt `matt@glitch` is terminal green `#39ff88`; the title-bar dots are macOS red, yellow and green.
  - The name gradient and avatar ring use only white → cyan → magenta.
  - Card `--brand` colours drive the glow, spotlight, icon, tags and focus ring: Instagram `#ff3d8b`, YouTube
    `#ff2a2a`, Twitch `#a970ff`, Discord `#6f7dff`. Projects set `style="--brand: …"` from the site's own theme colour.
- **Fonts** (CSS variables `--display` / `--body` / `--mono`; don't repeat font names):
  - **Orbitron** 800/900: the name, alias and card titles.
  - **Chakra Petch** 400: body and About text.
  - **JetBrains Mono** 400: everything terminal-ish and the HUD.

  Each font has an `@font-face` (Latin `unicode-range`, `swap`) and a `<link rel="preload">`. To add a weight or
  script, download that woff2 (the file URL is in Google's `css2?family=…` stylesheet) and add an `@font-face` for it.
  The rain's glyph sheet (`buildAtlas()`) names the font itself. It waits for fonts up to 1.5s, then redraws when they
  arrive.
- **Terminal prompt line:** `<p class="term-line"><span class="prompt">matt@glitch<b>:~$</b></span> command</p>`.
  Later lines also get `queued-cmd`; their last `<span>` is the command JS re-types. Comments use
  `<p class="term-comment"># …</p>`.
- **Terminal border pulse** (`.panel-border`): a cyan band sweeps diagonally from top-left to bottom-right over the
  whole border, fading in and out (4.5s cycle including a pause).
  - Keep it **linear**: with easing, it stalled on the bottom-right corner.
  - Keep the ring a **whole number of pixels** (`padding: 2px`): at 1.5px the bottom-right corner rendered thinner.
- **Link cards** (`a.link-card.<platform>`): icon, name and handle. Hover gives a 3D tilt, spotlight, shine sweep and
  brand glow.
- **Project cards** (`a.project-card`): a fake browser bar with the domain over the screenshot (scanlines and a tint
  that clear on hover, plus a quick glitch), then title, one-line description and 1–2 lowercase tags.
- **Links:** socials use `target="_blank" rel="me noopener"` (the `me` verifies profile ownership); projects use
  `rel="noopener"`.
- **Keyboard focus** (`:focus-visible`, never shown for mouse clicks): a 2px neon outline, in the card's own colour on
  cards. Give any new link or control the same.

---

## Load and animation sequence

**Intro (0–0.95s, `--intro`), like the page booting up:**
- A dim overlay (`.intro-dim`) covers the background.
- The four HUD brackets start as an 80px frame in the centre of the screen and open out to the corners (`hud-open`).
  The frame is sized from `--view-w/--view-h`, set by JS, which excludes scrollbars.
- The HUD text (`.hud-text`) then fades in and the dim lifts.

Everything after it is offset by `--intro`: `calc(var(--intro) + …)` in CSS, and the `INTRO` constant in JS (read from
the CSS; accepts `s` or `ms`). Change `--intro` and everything shifts with it.

| After the intro | What |
|---|---|
| +0.2s | Avatar pops in |
| +0.5s, +0.06s per letter | Name letters flip in |
| +1.4s | Terminal panel fades in (`data-revealAt`; if scrolled to later, it appears immediately) |
| +1.5s / +1.8s | "aka" / alias fade up |
| then | About types (9–18ms/char) → `./socials.sh` (25–50ms/char) → cards (staggered 0.07s) → `ls ~/projects` → project cards |

Code: `typeOut()` is the shared typewriter; `runCommand(n, output, done)` types the n-th `queued-cmd` and shows its
output; `startTerminal()` chains them. The owner wants the socials to appear quickly, so don't slow this down.

### Accessibility and fallbacks (keep these working)

- **Reduced motion** (a deliberate OS setting, off by default): no intro, no effects, no delays (`--intro: 0s`). The
  whole page fades in once (`page-fade`, 0.5s) and all text appears instantly.
- **No JavaScript:** `<noscript>` styles show everything.
  - A yellow blinking **"● ERR_JS_DISABLED"** label (`.js-off`) appears.
    - **768px and wider:** pinned top-centre, level with the HUD's first line.
    - **Phones:** centred just below the top corners.
  - To preview it: Chrome DevTools → `Ctrl+Shift+P` → "Disable JavaScript" → reload.
- **The HTML is the source of truth:** the About text and command text are in the HTML (for crawlers and no-JS), and
  JS reads, clears and re-types them.
- **Decorative layers** are `aria-hidden`; the terminal has `aria-label="About me"`.

---

## Owner preferences (decided, don't undo)

- **Look:** cyberpunk / terminal, flashy and animated, but **readability comes first**.
- **Nothing may shift the layout.** The alias scramble is pinned to the final text's size (`lockAliasSize()`).
- **The name stays on one line on mobile** (`.name`: `nowrap`, `clamp(1.25rem, 7.2vw, 4.6rem)`; checked at 320–412px).
- **One terminal window only.** Socials and projects are commands in it, not separate sections.
- **Commands fit what they show:** `cat` for text, `./socials.sh` for the link buttons, `ls` for projects.
- **Avatar ring:**
  - It uses the name's colours only.
  - The sharp ring spins via the gradient angle (`@property --ring-angle`), **not** `transform: rotate`. Rotating made
    mobile browsers drop it after fast scrolling.
  - The blurred glow may rotate with a transform. Both take 4s.
- **Avatar hover glitch** is a short burst (~1.6s), not endless.
- **Favicon:** an inline SVG circle, white → cyan → magenta with a soft violet crescent bottom-right ("more purple,
  but not 50/50").
- **`<title>`:** "Matt Hoyle aka Mental.Glitch" ("aka", not a dash). Text selection highlight is transparent.
- **Performance:** animate only `transform` and `opacity` (not `top`, `background-position` and the like). The rain
  uses a pre-rendered glyph sheet, not per-frame `fillText`. Optimisations must look identical.
- **The background may only be touched when asked.**
- **Removed on request; don't re-add:**
  - About/"Find me online" headings
  - tag chips in About
  - the quote bar beside the About text
  - the dark backing behind the bottom HUD corners
  - the scrolling marquee
  - arrows on social buttons
  - orbiting dots around the avatar
  - "made with ♥ & a little glitch" in the footer
  - the interactive terminal / typed commands

**Suggested but not done (only on request):**
- a shorter intro for returning visitors
- caching and security headers (set in the owner's Caddyfile, not this repo)
- a matching 404 page
- an easter egg
- testing in Safari on a real iPhone (everything so far was tested in Edge/Chrome)

---

## How to…

**Add or change a social link:**
1. Edit the `<a class="link-card …">` in `#socials`; a new platform needs a `.link-card.<name> { --brand: … }` rule.
2. Update `sameAs` in the JSON-LD.
3. For a fifth card, extend the shared `:nth-child(n)` stagger rules.

**Add a project:**
1. Take a screenshot:
   `powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-thumbnail.ps1 -Url https://example.com/ -Name example`.
   For galleries that fade in, add `-NotReadySelector "…"` (the owner's craft sites use
   `".banner__collage-img:not(.is-loaded)"`).
2. **Look at the image:** grey or black tiles mean something hadn't loaded.
3. Copy an `a.project-card` block and set:
   - `--brand` (from the site's `theme-color`)
   - the domain
   - `src` and `alt`
   - a one-line description
   - 1–2 lowercase tags
4. For a fifth card, extend the stagger rules.

**Change the About text:**
1. Edit `#about` in the HTML.
2. Update the JS `highlight` array.
3. Update `<meta name="description">`, `og:description`, `twitter:description` and the JSON-LD `description`.
4. If the tagline changed, edit `tools/og-card.html` and run `tools\render-images.ps1`.
5. Bump the sitemap `<lastmod>`.

**Change the domain:** replace `https://matthoyle.me/` in `index.html`, `robots.txt` and `sitemap.xml` (preview image
URLs must be absolute), and edit the URL in `tools/og-card.html` and re-render.

**Check link previews:** the preview sites (opengraph.xyz, Facebook Sharing Debugger) only work on the live site, and
the preview image is loaded from the live URL, so check after deploying.

---

## Testing

- **Local server:** `powershell -NoProfile -ExecutionPolicy Bypass -File tools\serve.ps1` → `http://localhost:8765/`.
  Chrome extensions (Claude in Chrome) refuse `file://`; it needs browser tools enabled via `/chrome`.
- **Device test** (after any visual or layout change; needs the server running):
  `powershell -NoProfile -ExecutionPolicy Bypass -File tools\device-test.ps1`.
  - **Pass means:** `errors: none`; `sequenceDone`, `cardsShown`, `nameOneLine`, `hudCornersIn` and `footerClear` all
    true; `horizontalOverflow: 0`; and `hudTopOverlap` / `hudBottomOverlap` false.
  - **Options:** `-Only "iPhone 14","Desktop 1080p"`, `-ReducedMotion`, `-NoJs`, `-Shots` (saved to
    `%TEMP%\matthoyle-device-shots`).
  - Slow first frames on phones (50–250ms at 4× CPU) are the initial page build, which is expected.
  - It can't test Safari or Firefox.
- **Headless Edge** (`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`) is the tool for screenshots and
  checks. Drive it via the DevTools protocol, like the `tools/*.ps1` scripts do.
  - `--screenshot` with `--virtual-time-budget` fakes time, so network images never finish loading. Use real time via
    the DevTools protocol.
  - Headless can't go narrower than ~500px. For phone widths, emulate with `Emulation.setDeviceMetricsOverride`
    (as `device-test.ps1` does).
  - To inspect an animation at a moment, pause it (`document.getAnimations()`) and set `currentTime`, instead of
    racing it.
  - To capture video frames, use `Page.startScreencast` (page pixels only). Never record the screen:
    `getDisplayMedia` recorded the owner's desktop once.
- **Chrome quirks:**
  - Background tabs are throttled (FPS reads ~1, typing crawls). Fast-forward with
    `window.setTimeout = f => (queueMicrotask(f), 0)` in the console.
  - The owner's Chrome is zoomed out (`innerWidth` ≈ 2560 in a ~1280px window), so don't use it for layout
    screenshots.
- **Environment (Windows):**
  - PowerShell 5.1, Git Bash, curl and headless Edge are available; Python, Node and ImageMagick are not.
  - Convert images with WPF imaging (`PresentationCore`: `BitmapDecoder`, `JpegBitmapEncoder`; it can decode WebP).
- **PowerShell gotchas:**
  - The curly apostrophe in `’95` ends PowerShell strings, so edit lines containing it with the editor, not
    PowerShell.
  - Write files as UTF-8 without a BOM (`[IO.File]::WriteAllText(..., (New-Object Text.UTF8Encoding $false))`).
  - `Invoke-RestMethod` / `ConvertFrom-Json` pass a JSON array as one object; unroll it with `ForEach-Object { $_ }`.
  - `$args` is reserved.
  - Commands mixing `Remove-Item` with `\` in regex strings get blocked, so keep deletes in a separate command.

---

## Commits

Only when asked. Short lowercase messages (e.g. `no wrap`, `load animation is faster, selection highlight colour is now
transparent`), ending with the build.

**Before every commit, in this order:**
1. **Bump the build number:** `BUILD v1.x` in the bottom-left HUD (`.hud.bl` in `index.html`) and in **Page
   structure** above, up by 0.1.
2. **Check `sitemap.xml`:** if anything visitors or search engines see has changed since the last commit (page text,
   meta tags, images, layout), set `<lastmod>` to today's date. Changes only to `tools/`, `CLAUDE.md` or `robots.txt`
   don't need it. Add any new public page to the sitemap too.
3. Commit, ending the message with the build (e.g. `…, build v1.7`). Don't push.
