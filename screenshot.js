const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const FILE = 'file:///' + path.resolve(__dirname, 'index.html').replace(/\\/g, '/');
const OUT  = path.join(__dirname, 'screenshots');

if (!fs.existsSync(OUT)) fs.mkdirSync(OUT);

const SECTIONS = [
  { id: 'hero',      label: '01-hero' },
  { id: 'features',  label: '02-features' },
  { id: 'how',       label: '03-how-it-works' },
  { id: 'picks',     label: '04-top-picks' },
  { id: 'community', label: '05-community' },
];

(async () => {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page    = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 2 });

  await page.goto(FILE, { waitUntil: 'networkidle0' });

  // Wait for fonts + animations to settle
  await new Promise(r => setTimeout(r, 1800));

  // Full page
  await page.screenshot({
    path: path.join(OUT, '00-full-page.png'),
    fullPage: true,
  });
  console.log('✓ 00-full-page.png');

  // Per-section
  for (const s of SECTIONS) {
    await page.evaluate(id => {
      document.getElementById(id)?.scrollIntoView({ behavior: 'instant' });
    }, s.id);

    await new Promise(r => setTimeout(r, 600));

    const el = await page.$(`#${s.id}`);
    if (!el) { console.warn(`  ✗ #${s.id} not found`); continue; }

    await el.screenshot({ path: path.join(OUT, `${s.label}.png`) });
    console.log(`✓ ${s.label}.png`);
  }

  await browser.close();
  console.log('\nAll screenshots saved to /screenshots/');
})();
