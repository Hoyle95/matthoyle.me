# matthoyle.me: project guide

Personal site for **Matt Hoyle, aka "Mental.Glitch"**: a developer based in South East UK, born ’95.
It's one page with a cyberpunk, "digital" look. Live at **https://matthoyle.me/**.

This file is for anyone (human or LLM) picking the project back up. Read **Owner preferences** before
changing anything visual; those are decisions that have already been made and revisited.

---

## Files

| Path | What it is |
|---|---|
| `index.html` | The whole site. HTML, CSS (in `<style>`) and JS (in `<script>` at the end) in one file. No build step, no dependencies. |
| `images/me.webp` | Profile photo shown on the page. |
| `images/me.jpg` | JPEG copy of the same photo, used **only** for link previews (Open Graph / Twitter). Some platforms don't reliably show WebP. |
| `images/projects/*.jpg` | Project thumbnails, 800×500 screenshots taken at a 1280×800 viewport. Made with `tools/capture-thumbnail.ps1`. |
| `robots.txt`, `sitemap.xml` | For search engines. Bump `<lastmod>` in the sitemap when content changes. |
| `tools/serve.ps1` | Local web server (`http://localhost:8765/`) for testing in a browser. |
| `tools/capture-thumbnail.ps1` | Screenshots a live site into `images/projects/`. |

Only Google Fonts is loaded from outside the site. Everything else is local.

---

## Page structure (top to bottom)

1. **Background layers**, all `position: fixed` and `aria-hidden`:
   - `#particles`: canvas "digital rain" of katakana, hex and code symbols. Mostly cyan, ~15% of columns magenta. Columns near the cursor speed up. Canvas `opacity: 0.4`, with a radial mask that dims the centre so text stays readable.
   - `.blob.one/two/three`: large blurred violet, magenta and cyan glows drifting slowly.
   - `.grid-floor`: synthwave perspective grid scrolling along the bottom.
   - `.scanlines` (with a sweeping light bar) and `.noise` (film grain).
   - `.hud.tl/.tr/.bl/.br`: corner readouts: status, live UK clock (`#clock`), build and FPS (`#fps`), signal. The bottom two are hidden under 700px.
   - Custom cursor (`.cursor-dot` + `.cursor-ring`). Hidden on touch devices (`hover: none`).
2. **Hero** (`header.hero`):
   - Avatar in a spinning conic-gradient ring.
   - `h1.name` "Matt Hoyle". JS splits it into per-letter spans for the flip-in, then a shimmer.
   - "aka".
   - `.glitch#alias` "Mental.Glitch": RGB-split glitch slices, a flicker, and a periodic character scramble.
3. **One terminal window** (`section.panel.terminal`). Everything else lives inside it, revealed as a sequence of typed commands:
   - `cat about.txt` → About text (typewriter, with some phrases highlighted yellow).
   - `./socials.sh` → four social link cards (`nav.links#socials`).
   - `ls ~/projects` → `# websites I've built for other people & host myself` + project cards (`.projects-wrap#projects`).
4. **Footer**: `© <year> Matt Hoyle`, and nothing else.

---

## Design system

### Colour tokens (`:root`)

| Token | Value | Used for |
|---|---|---|
| `--bg` | `#07030f` | Page background (near-black purple) |
| `--cyan` | `#00f0ff` | Primary neon: prompts' `:~$`, glitch, rain, cursor dot |
| `--magenta` | `#ff2bd6` | Secondary neon: caret, cursor ring, HUD corners, About quote bar |
| `--violet` | `#8a2bff` | Blobs, favicon crescent, `theme-color` (Discord embed bar) |
| `--yellow` | `#ffe600` | Highlighted words in the About text only |
| `--text` | `#eae6ff` | Body text |
| `--muted` | `#a79fc9` | Secondary text: handles, descriptions, comments |
| `--glass` | `rgba(20,10,40,.45)` | Panel background (plus `backdrop-filter: blur`) |
| `--border` | `rgba(255,255,255,.12)` | Hairline borders |

Other fixed colours:
- **Prompt username** `matt@glitch` is terminal green `#39ff88`.
- **Terminal title-bar dots** are the macOS red, yellow and green.
- **Name gradient** is white → cyan → magenta. The **avatar ring** uses only those same three colours (`#fff`, cyan, magenta).
- **Card `--brand` colours**, used for the glow, spotlight, icon and tags:
  - Socials: Instagram `#ff3d8b`, YouTube `#ff2a2a`, Twitch `#a970ff`, Discord `#6f7dff`.
  - Projects: each card sets `style="--brand: …"` inline from that site's own theme colour.

### Fonts (Google Fonts)

| Font | Role |
|---|---|
| **Orbitron** (500/800/900) | Display: the name, alias and card titles. Always uppercase or short. |
| **Chakra Petch** (400/500/700) | Body text, including the About paragraph. |
| **JetBrains Mono** (400/700) | Anything "terminal": prompts, commands, comments, handles, tags, HUD, browser bars. |

### Components and conventions

- **Terminal prompt line**:
  ```html
  <p class="term-line"><span class="prompt">matt@glitch<b>:~$</b></span> command</p>
  ```
  Prompt lines that appear later in the sequence also get `queued-cmd` and a typed `<span data-text="…">`.
- **Terminal comment**: `<p class="term-comment"># …</p>` (muted mono).
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

| When | What |
|---|---|
| 0.2s | Avatar pops in |
| 0.5s + 0.06s/letter | Name letters flip in |
| 1.5s | "aka" fades up |
| 1.8s | Alias fades up. It scrambles at 1.8s, then every 5s and on hover. |
| 1.4s | Terminal panel fades in (`data-revealAt`, counted from page load; panels scrolled to later appear immediately) |
| +0.2s | About types at 8–20ms/char |
| +0.15s | `./socials.sh` types at 25–50ms/char. Output appears 120ms later, cards staggered 0.07s. |
| +0.45s | `ls ~/projects` types, then project cards appear (staggered 0.07s) |

- **Sequencing code**: `runCommand(line, cmdEl, output, done)` shows a prompt line, types its `data-text`, then adds `.show` to the output element.
- **Adding a command**: to chain another command after projects, add a new `queued-cmd` line and output element, then call `runCommand` from the previous command's `done` callback in `showSocials()`.

### Accessibility and fallbacks (keep these working)

- **`prefers-reduced-motion`**: all animation is effectively off, and commands and outputs show instantly.
- **`<noscript>` styles**: everything is visible without JS.
- **About text and command text** are written into the HTML (for crawlers and no-JS visitors). JS clears them on load and re-types them. **If you change the About text, change it in both the element content and `data-text`.**
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
  - the scrolling marquee banner at the bottom
  - the arrows on social buttons
  - the orbiting dots around the avatar
  - "made with ♥ & a little glitch" in the footer
- **Text selection highlight is transparent** (`::selection { background: transparent }`).
- **Avatar ring** uses only the name's colours (white, cyan, magenta).
- **Favicon**: an inline SVG data URI in `<head>`. It's a circle with a white → cyan → magenta gradient and a soft, blurred violet crescent on the bottom-right edge ("more purple, but not 50/50").
- **`<title>`**: "Matt Hoyle aka Mental.Glitch" (the word "aka", not a dash).
- **Terminal commands should fit what they show**: `cat` for text, `./socials.sh` for the visual link buttons, `ls` for the projects list.
- **The background can be touched only when asked.**

---

## How to…

**Add or change a social link.** Update all three places:
1. The `<a class="link-card …">` in `#socials`. Add a `.link-card.<name> { --brand: … }` rule for a new platform.
2. `sameAs` in the JSON-LD `<script type="application/ld+json">` in `<head>`.
3. The card stagger rules (`.links.show .link-card:nth-child(n)`), if you add a fifth card.

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
4. If there are now more than three cards, add a `.projects-wrap.show .project-card:nth-child(n)` stagger rule.

**Change the About text.** Edit the `#about` element content **and** its `data-text`. The phrases in the JS `highlight` array render yellow, so update that array if the wording changes. Also consider updating the matching descriptions in `<meta name="description">`, `og:description`, `twitter:description` and the JSON-LD.

**Change the domain.** Search and replace `https://matthoyle.me/` across `index.html`, `robots.txt` and `sitemap.xml`. Open Graph and Twitter image URLs must be absolute.

---

## Testing

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
