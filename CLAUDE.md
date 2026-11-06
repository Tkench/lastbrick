# Last Brick: notes for Claude

Last Brick (https://lastbrick.co.uk) helps people turn a box of mixed LEGO back into
sets: add a set and see exactly which pieces are missing, scan a piece or a
minifigure, and keep a "Looking for" list across all sets. It's run by Tracey (UK),
who buys bulk LEGO, rebuilds the sets inside and resells them. Free to use; the
first set or minifigure needs no account.

## How Tracey likes to work (important)

- **Ask before changing anything.** Questions like "is it possible…" or "I'm
  thinking…" get an explanation and options only. Build only after a clear go-ahead.
- **Show screenshots before anything goes live.**
- **Commit locally, push only after Tracey says "upload".** When a stop hook
  complains about unpushed commits, just reply that you're waiting for "upload".
- Keep the app **simple**. Explain things in plain, friendly English, without jargon.
- Mockups first for design changes (she likes 2–3 versions to compare).
- Privacy matters: link only Last Brick's brand social accounts, never personal ones.
  Nothing identifying is collected in Stats.
- Parked on purpose (don't push): Google/Apple sign-in, turning off email
  confirmation, the minifigure account step. Reddit plan was parked.
- Don't share access with the other AI reviewers she sometimes asks for opinions.

## Releasing

- Branch: **`claude/modest-shannon-2k2srb`**. It is the default branch and the
  GitHub Pages source, so pushing to it puts the site live (in about a minute).
- Push with:
  `git fetch -q origin claude/modest-shannon-2k2srb && git rebase -q origin/claude/modest-shannon-2k2srb; git push -u origin claude/modest-shannon-2k2srb`
  (rebase first: a weekly GitHub Action commits minifigure-index updates).
- Every release: bump `APP_VERSION` and `APP_DATE` at the top of `app.js` (shown in
  Settings and sent with problem reports) **and** the `brickfinder-shell-vNN` cache
  name in `sw.js`.
- No model names in commits. Commits end with the Co-Authored-By / Claude-Session
  lines given in the session.
- **Supabase changes are run by Tracey** in the Supabase SQL Editor. When the app
  depends on new SQL, send her the file and ask her to run it **before** "upload".
  The SQL files are written to be safe to run again.

## How it's built

Plain HTML/CSS/JavaScript, no build step.

- `index.html`: shell, static welcome text for search engines (hidden when JS runs).
- `app.js`: the whole app (hash routes: `#sets`, `#add`, `#set/<num>`, `#addfig`,
  `#missing` (Looking for), `#scan`, `#settings`, `#help`, `#demo`, `#stats`).
  The welcome screen shows for new visitors.
- `styles.css`, `sw.js` (offline cache; leaves videos alone),
  `404.html` (sends paths like `/demo` to `/#demo`, keeping link tags).
- `about.html`, `privacy.html`, `terms.html`, `robots.txt`, `sitemap.xml`.
- `how-it-works.mp4/.jpg`: the welcome screen's How it works video (a real screen
  recording of King's Castle 6080), made with Playwright screencast frames + ffmpeg.
- `data/figindex/`: minifigure and set index built weekly by
  `.github/workflows/minifig-index.yml` running `tools/build-fig-index.mjs`
  (figs.json, sets.json, allsets.json for search by name, legs.json, p/ shards).
  Never commit test copies of these files.

### Supabase (project `nioytuzuejdzznaxvlic`)

- Accounts (email + password, confirmation emails via **Brevo** SMTP), each user's
  sets in `user_data` (`supabase/setup.sql`).
- `supabase/functions/rebrickable/index.ts`: the parts-list helper. Holds the
  Rebrickable key, caches lookups in `set_cache`. Questions: `?set=`, `?fig=`,
  `?figsearch=`, `?figfind=`, `?partfigs=` (colours of a piece / figures using it),
  `?partsets=&color=` (sets using a piece in a colour, for "rare piece"),
  `?setfigs=`. Tracey redeploys it by pasting the file in Edge Functions → Code.
- `supabase/stats.sql`: `visits`, `funnel` (steps people reach, once per device;
  the allowed step names are in a check constraint, so **new steps need this file
  re-run**), `admins`, and `admin_stats(period)` for the Stats page (period:
  `today`, `yesterday`, `7`, `30`, `all`).
- `supabase/reports.sql`: problem reports. `supabase/confirm-reminder.sql`: hourly
  job that resends the confirmation email once, 1–7 days after sign-up.
- `supabase/email-templates/`: branded emails pasted into Supabase.

### Tracking

- Link tags: `?utm_source=facebook&utm_content=group24` is saved as
  `facebook/group24` (see `VISIT_SOURCE`). It copes with `&amp;`, `%26`, tags after
  `#`, Instagram's added tags, ig/fb short names and fbclid/igsh.
- Video links use the example page: `lastbrick.co.uk/?utm_source=youtube&utm_content=short11#demo`.
  Opened from a link, the example shows a red welcome, tappable numbers 1–3, one
  button ("Try it with your own set") and "Save it for later"; no tab bar.
- `funnelStep(name)` counts a step once per device (skipped on localhost unless
  `window.FUNNEL_TEST`). Stats page: Settings → Stats (admin only).
- Cloudflare Web Analytics is also on the site (domain DNS stays at Namecheap).

## Other services

- Domain at **Namecheap**; `hello@lastbrick.co.uk` and `social@lastbrick.co.uk` forward to
  Tracey's Gmail. She replies as hello@ through Gmail "Send mail as" using Brevo
  SMTP (port 465, SSL).
- Google Search Console verified (meta tag in `index.html`), sitemap submitted.
- Social: Facebook, Instagram @lastbrick.co.uk, YouTube @lastbrickuk,
  TikTok @lastbrick.co.uk (linked from about.html).

## Testing

- Check syntax: `node --check app.js`.
- Playwright and Chromium are preinstalled (headless shell at
  `/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell`;
  run scripts with `NODE_PATH=$(npm root -g)`). Serve the folder with a small Node
  http server, block the service worker (`serviceWorkers: 'block'`), and mock
  Supabase/Rebrickable with `page.route`. Don't run `playwright install`.
- The cloud environment named **lastbrick** can reach `cdn.rebrickable.com` and the
  Supabase project (for real pictures and parts lists in recordings/screenshots).
- SQL: test upgrades in a local Postgres 16 with a small mock `auth` schema
  (`auth.users`, `auth.uid()` reading `current_setting('test.uid')`, roles `anon`
  and `authenticated`). Insert the admin user before running stats.sql. Run the
  live version first, then the new one, then the new one again.
- Re-check after welcome-screen changes that "How it works ↓" still shows above
  the tab bar on short phones (667px and 780px tall).

## Open items (as of 6 Nov 2026)

- Minifigures: few people add them and scanning is a bit unreliable. Review on
  Sat 7 Nov whether to make it less prominent, fix glitches, or hide it.
- Watch the 7-day Stats: Started was 27% of new visitors (week to 6 Nov); see
  whether the How it works video, the "No LEGO to hand?" option and the example
  page improve it.
