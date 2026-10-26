// Makes the video intro, end and footer images in video/.
// Run: node tools/make-video-art.js video
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const out = process.argv[2];
fs.mkdirSync(out, { recursive: true });

// Same logo drawing as brandArt() in app.js.
const C = { r: ['#d9312b', '#a61f1b'], y: ['#f6c31b', '#c99a06'], b: ['#2f80d1', '#1d5ea3'], g: ['#3aa64a', '#277a34'] };
function art(cls = '') {
  const U = 34;
  const brick = (x, y, n, c) => { const [f, e] = C[c]; let s = '';
    for (let i = 0; i < n; i++) s += `<rect x="${x + i * U + 8.5}" y="${y - 8}" width="17" height="10" rx="2.5" fill="${f}" stroke="${e}" stroke-width="2.5"/>`;
    return `${s}<rect x="${x + 1}" y="${y}" width="${n * U - 2}" height="44" rx="3.5" fill="${f}" stroke="${e}" stroke-width="2.5"/>`; };
  const row = (x, y, p) => p.map(([n, c]) => { const b = brick(x, y, n, c); x += n * U; return b; }).join('');
  return `<svg class="${cls}" viewBox="128 300 400 208"><rect x="136" y="491" width="384" height="7" rx="3.5" fill="#000" opacity=".08"/>
  ${row(141, 446, [[2, 'b'], [3, 'g'], [3, 'r'], [3, 'g']])}${row(175, 402, [[3, 'r'], [3, 'g'], [3, 'y']])}${row(209, 358, [[4, 'y'], [3, 'b']])}${brick(277, 314, 3, 'r')}</svg>`;
}

const base = `<style>
*{box-sizing:border-box;margin:0}
html,body{width:100%;height:100%;font-family:Inter,sans-serif;color:#1b1b1f}
.red{background:radial-gradient(ellipse at 50% 85%,#e03a3a 0%,#d01012 55%,#c40d10 100%);color:#fff;
  display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}
.card{background:#fff;border-radius:48px;box-shadow:0 18px 50px rgba(0,0,0,.22);display:flex;align-items:center;justify-content:center}
.card svg{width:100%;height:auto}
.title{font-weight:800;letter-spacing:-.03em;line-height:1}
.sub{font-weight:700;line-height:1.2}
.url{font-weight:600;opacity:.9}
.pill{background:#fff;color:#d01012;font-weight:800;border-radius:999px;box-shadow:0 10px 30px rgba(0,0,0,.2)}
.free{position:absolute;background:#f6c31b;color:#1b1b1f;border:8px solid #fff;border-radius:50%;font-weight:800;
  display:flex;align-items:center;justify-content:center;transform:rotate(-14deg);box-shadow:0 10px 30px rgba(0,0,0,.2)}
.bar{position:absolute;display:flex;align-items:center;background:#fff;border-radius:28px;box-shadow:0 8px 28px rgba(0,0,0,.28);overflow:hidden}
.bar .mark{flex:none}
.bar .wm{font-weight:800;letter-spacing:-.02em;white-space:nowrap}
.bar .wm b{color:#d01012;font-weight:800}
.bar .site{margin-left:auto;align-self:stretch;display:flex;align-items:center;background:#d01012;color:#fff;font-weight:700;white-space:nowrap}
</style>`;

const pages = {
  // Intro cards
  'intro-landscape': [1920, 1080, `<body class="red">
    <div style="position:relative"><div class="card" style="width:720px;height:400px;padding:40px 60px">${art()}</div></div>
    <h1 class="title" style="font-size:180px;margin-top:60px">Last Brick</h1>
    <p class="sub" style="font-size:60px;margin-top:28px">Find the missing pieces. Finish every set.</p></body>`],
  'intro-portrait': [1080, 1920, `<body class="red">
    <div class="card" style="width:760px;height:440px;padding:44px 64px">${art()}</div>
    <h1 class="title" style="font-size:170px;margin-top:80px">Last Brick</h1>
    <p class="sub" style="font-size:66px;margin-top:40px">Find the missing pieces.<br>Finish every set.</p></body>`],
  // End cards
  'outro-landscape': [1920, 1080, `<body class="red">
    <div style="position:relative"><div class="card" style="width:560px;height:310px;padding:30px 46px">${art()}</div>
      <div class="free" style="width:190px;height:190px;font-size:52px;right:-120px;top:-70px">FREE</div></div>
    <h1 class="title" style="font-size:120px;margin-top:56px">Rebuild your old sets</h1>
    <p class="sub" style="font-size:52px;margin-top:22px;opacity:.95">Add a set, tick what you have, see what's missing.</p>
    <div class="pill" style="font-size:72px;padding:28px 72px;margin-top:56px">lastbrick.co.uk</div></body>`],
  'outro-portrait': [1080, 1920, `<body class="red">
    <div style="position:relative"><div class="card" style="width:680px;height:380px;padding:36px 56px">${art()}</div>
      <div class="free" style="width:210px;height:210px;font-size:58px;right:-70px;top:-100px">FREE</div></div>
    <h1 class="title" style="font-size:120px;margin-top:90px">Rebuild your<br>old sets</h1>
    <p class="sub" style="font-size:56px;margin-top:40px;opacity:.95">Add a set, tick what you have,<br>see what's missing.</p>
    <div class="pill" style="font-size:72px;padding:30px 70px;margin-top:80px">lastbrick.co.uk</div></body>`],
  // Footers: transparent full-frame overlays, so they line up when dropped on top of a video.
  'footer-landscape': [1920, 1080, `<body>
    <div class="bar" style="left:48px;right:48px;bottom:40px;height:112px;padding-left:28px">
      <div class="mark" style="width:150px">${art()}</div>
      <div class="wm" style="font-size:56px;margin-left:22px">Last <b>Brick</b></div>
      <div class="sub" style="font-size:36px;margin-left:36px;color:#6b6b76;font-weight:600">Find the missing pieces. Finish every set.</div>
      <div class="site" style="font-size:44px;padding:0 44px">lastbrick.co.uk</div></div></body>`],
  'footer-portrait': [1080, 1920, `<body>
    <div class="bar" style="left:60px;right:60px;bottom:330px;height:120px;padding-left:26px">
      <div class="mark" style="width:150px">${art()}</div>
      <div class="wm" style="font-size:54px;margin-left:18px">Last <b>Brick</b></div>
      <div class="site" style="font-size:38px;padding:0 34px">lastbrick.co.uk</div></div></body>`],
};

(async () => {
  const b = await chromium.launch();
  for (const [name, [w, h, body]] of Object.entries(pages)) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.setContent(`<!doctype html><html><head>${base}</head>${body}</html>`);
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: path.join(out, name + '.png'), omitBackground: name.startsWith('footer') });
    await p.close();
  }
  await b.close();
})();
