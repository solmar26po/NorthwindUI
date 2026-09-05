// Original Northwind outline icons. Run: npm install --no-save sharp
// Then: node scripts/build-icons.cjs (from the repository root).
const fs = require('node:fs');
const crypto = require('node:crypto');
const sharp = require('sharp');
const icons = {
  home: '<path d="m3 10 9-7 9 7v9a2 2 0 0 1-2 2h-4v-7H9v7H5a2 2 0 0 1-2-2Z"/>',
  sliders: '<path d="M4 6h6m5 0h5M4 12h2m5 0h9M4 18h9m5 0h2"/><circle cx="12.5" cy="6" r="2.5"/><circle cx="8.5" cy="12" r="2.5"/><circle cx="15.5" cy="18" r="2.5"/>',
  eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
  settings: '<path d="m10 2-1 3-2 .9-3-.6-2 3.4 2 2.4v2l-2 2.4 2 3.4 3-.6 2 .9 1 3h4l1-3 2-.9 3 .6 2-3.4-2-2.4v-2l2-2.4-2-3.4-3 .6-2-.9-1-3Z"/><circle cx="12" cy="12" r="3.2"/>',
  window: '<rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 9v11"/><path d="M6 6.5h.01m3 0h.01"/>',
  palette: '<path d="M12 3a9 9 0 1 0 0 18h1a2 2 0 0 0 1.4-3.4 1.7 1.7 0 0 1 1.2-2.9H18a3 3 0 0 0 3-3A8.7 8.7 0 0 0 12 3Z"/><g fill="white" stroke="none"><circle cx="7" cy="10" r="1.2"/><circle cx="10" cy="6.8" r="1.2"/><circle cx="14.5" cy="7" r="1.2"/><circle cx="17.3" cy="10.5" r="1.2"/></g>',
  save: '<path d="M5 3h12l4 4v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z"/><path d="M8 3v6h8V3M7 21v-7h10v7M13 5v2"/>',
  keyboard: '<rect x="2" y="5" width="20" height="14" rx="3"/><path d="M6 9h.01M10 9h.01M14 9h.01M18 9h.01M6 12h.01M10 12h.01M14 12h.01M18 12h.01M8 16h8"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 6.5V12l4 2.5"/>',
  activity: '<path d="M2 12h5l3-8 4 16 3-8h5"/>',
  target: '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.5"/><path d="M12 2v3m0 14v3M2 12h3m14 0h3"/>',
  sparkles: '<path d="m10 3 2.3 6.7L19 12l-6.7 2.3L10 21l-2.3-6.7L1 12l6.7-2.3ZM19 2v5m-2.5-2.5h5M20 17v4m-2-2h4"/>',
  search: '<circle cx="10.5" cy="10.5" r="7"/><path d="m16 16 5 5"/>',
  'chevron-down': '<path d="m5 9 7 7 7-7"/>',
  toggle: '<rect x="2" y="6" width="20" height="12" rx="6"/><circle cx="16" cy="12" r="3"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6m0-10h.01"/>',
  comet: '<circle cx="16.5" cy="7.5" r="4.5"/><path d="m4 4 4 1M3 10l5 1m1 5 1 5m4-6 1 5M3 21l7-7"/>',
  snowflake: '<path d="M12 2v20M3.3 7l17.4 10M3.3 17 20.7 7M9 4l3 3 3-3M9 20l3-3 3 3M3.5 10l4.1-1.1-1.1-4.1M17.5 19.2l-1.1-4.1 4.1-1.1M3.5 14l4.1 1.1-1.1 4.1M17.5 4.8l-1.1 4.1 4.1 1.1"/>',
  type: '<path d="M4 7V4h16v3M12 4v16m-4 0h8"/>',
  layers: '<path d="m12 3 10 5-10 5L2 8ZM3 12l9 4.5 9-4.5M3 16l9 4.5 9-4.5"/>',
};
const cell = 96, columns = 5;
const names = Object.keys(icons);
const groups = names.map((name,i)=>`<g id="${name}" transform="translate(${i%columns*cell} ${Math.floor(i/columns)*cell}) scale(4)">${icons[name]}</g>`).join('\n');
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="480" height="384" viewBox="0 0 480 384"><g fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${groups}</g></svg>`;
(async()=>{
  fs.mkdirSync('assets',{recursive:true});
  fs.writeFileSync('assets/NorthwindIcons.svg',svg);
  const png=await sharp(Buffer.from(svg)).png().toBuffer();
  fs.writeFileSync('assets/NorthwindIcons.png',png);
  const hash=crypto.createHash('sha256').update(png).digest('hex').slice(0,12);
  const data=`-- BEGIN GENERATED ICON DATA (scripts/build-icons.cjs)\nlocal ICON_ATLAS_FILE = "northwind-icons-${hash}.png"\nlocal ICON_ATLAS_PNG = "${png.toString('base64')}"\nlocal ICON_ATLAS_NAMES = {\n${names.map(n=>'    "'+n+'",').join('\n')}\n}\n-- END GENERATED ICON DATA`;
  const library=fs.readFileSync('Library.lua','utf8');
  if(!library.includes('-- BEGIN GENERATED ICON DATA')) throw new Error('Missing icon data markers');
  fs.writeFileSync('Library.lua',library.replace(/-- BEGIN GENERATED ICON DATA[\s\S]*?-- END GENERATED ICON DATA/,data));
  console.log(`Built ${names.length} icons; PNG ${png.length} bytes; ${hash}`);
})();
