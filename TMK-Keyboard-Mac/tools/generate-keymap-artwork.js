const fs = require("fs");
const path = require("path");

const projectRoot = path.resolve(__dirname, "..");
const assetsDir = path.join(projectRoot, "assets");
const outFile = path.join(assetsDir, "tmk-keyboard-mapping.svg");

const rows = [
  [
    ["1", "1", "႑"],
    ["2", "2", "႒"],
    ["3", "3", "႓"],
    ["4", "4", "႔"],
    ["5", "5", "႕"],
    ["6", "6", "႖"],
    ["7", "7", "႗"],
    ["8", "8", "႘"],
    ["9", "9", "႙"],
    ["0", "0", "႐"],
  ],
  [
    ["Q", "ၸ", "ꩡ"],
    ["W", "တ", "ၻ"],
    ["E", "ၼ", "ꧣ"],
    ["R", "မ", "႞"],
    ["T", "ဢ", "ြ"],
    ["Y", "ပ", "ၿ"],
    ["U", "ၵ", "ၷ"],
    ["I", "င", "ရ"],
    ["O", "ဝ", "သ"],
    ["P", "ႁ", "ႀ"],
    ["[", "ꧡ", "ꧢ"],
    ["]", "ꩦ", "ꩨ"],
    ["\\", "ꩧ", "ꩩ"],
  ],
  [
    ["A", "ေ", "ဵ"],
    ["S", "ႄ", "ႅ"],
    ["D", "ိ", "ီ"],
    ["F", "်", "ႂ်"],
    ["G", "ွ", "ႂ"],
    ["H", "ႉ", "ံ"],
    ["J", "ႇ", "ႆ"],
    ["K", "ု", "ို"],
    ["L", "ူ", "ိူ"],
    [";", "ႈ", "း"],
    ["'", "ꧦ", "႟"],
  ],
  [
    ["Z", "ၽ", "ၾ"],
    ["X", "ထ", "ꩪ"],
    ["C", "ၶ", "ꧠ"],
    ["V", "လ", "ꩮ"],
    ["B", "ယ", "ျ"],
    ["N", "ၺ", "ႊ"],
    ["M", "ၢ", "ႃ"],
    [",", ",", "၊"],
    [".", ".", "။"],
    ["/", "/", "?"],
  ],
];

const esc = (value) =>
  String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

const width = 2400;
const height = 1320;
const keyW = 142;
const keyH = 132;
const gap = 16;
const startY = 340;
const rowGap = 22;
const rowOffsets = [360, 120, 200, 280];

function textSize(value) {
  return Array.from(value).length > 1 ? 40 : 50;
}

function key(label, normal, shift, x, y) {
  const normalSize = textSize(normal);
  const shiftSize = textSize(shift);
  return `
    <g class="key" transform="translate(${x}, ${y})">
      <rect class="key-body" width="${keyW}" height="${keyH}" rx="14"/>
      <line class="divider" x1="18" y1="66" x2="${keyW - 18}" y2="66"/>
      <text class="key-label" x="18" y="34">${esc(label)}</text>
      <text class="shift-output" x="${keyW / 2}" y="52" font-size="${shiftSize}">${esc(shift)}</text>
      <text class="normal-output" x="${keyW / 2}" y="112" font-size="${normalSize}">${esc(normal)}</text>
    </g>`;
}

const keysSvg = rows
  .map((row, rowIndex) => {
    const y = startY + rowIndex * (keyH + rowGap);
    return row
      .map(([label, normal, shift], colIndex) => {
        const x = rowOffsets[rowIndex] + colIndex * (keyW + gap);
        return key(label, normal, shift, x, y);
      })
      .join("");
  })
  .join("");

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f7f1e8"/>
      <stop offset="0.58" stop-color="#eef5f4"/>
      <stop offset="1" stop-color="#f4eef6"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
      <feDropShadow dx="0" dy="14" stdDeviation="13" flood-color="#233038" flood-opacity="0.16"/>
    </filter>
    <style>
      .title {
        fill: #17313a;
        font-family: "Avenir Next", "Helvetica Neue", Arial, sans-serif;
        font-size: 88px;
        font-weight: 800;
        letter-spacing: 0;
      }
      .subtitle,
      .legend,
      .footer {
        fill: #40515a;
        font-family: "Avenir Next", "Helvetica Neue", Arial, sans-serif;
        letter-spacing: 0;
      }
      .subtitle {
        font-size: 34px;
        font-weight: 500;
      }
      .legend {
        font-size: 28px;
        font-weight: 650;
      }
      .footer {
        font-size: 24px;
        font-weight: 500;
      }
      .key-body {
        fill: #fffdf9;
        stroke: #c9d2d1;
        stroke-width: 2;
        filter: url(#shadow);
      }
      .divider {
        stroke: #d6dedc;
        stroke-width: 2;
      }
      .key-label {
        fill: #69787f;
        font-family: "Avenir Next", "Helvetica Neue", Arial, sans-serif;
        font-size: 25px;
        font-weight: 800;
        letter-spacing: 0;
      }
      .shift-output,
      .normal-output {
        font-family: "Noto Sans Myanmar", "Myanmar MN", "Padauk", "Avenir Next", sans-serif;
        font-weight: 650;
        text-anchor: middle;
        dominant-baseline: middle;
        letter-spacing: 0;
      }
      .shift-output {
        fill: #8b2f4f;
      }
      .normal-output {
        fill: #0f6b6b;
      }
      .legend-swatch-shift {
        fill: #8b2f4f;
      }
      .legend-swatch-normal {
        fill: #0f6b6b;
      }
      .panel {
        fill: rgba(255, 255, 255, 0.58);
        stroke: #d8dfdd;
        stroke-width: 2;
      }
    </style>
  </defs>
  <rect width="${width}" height="${height}" fill="url(#bg)"/>
  <rect class="panel" x="70" y="70" width="${width - 140}" height="${height - 140}" rx="28"/>
  <text class="title" x="120" y="165">TMK Keyboard</text>
  <text class="subtitle" x="124" y="220">Shan Unicode keyboard mapping for macOS</text>
  <g transform="translate(124, 272)">
    <circle class="legend-swatch-shift" cx="14" cy="14" r="10"/>
    <text class="legend" x="36" y="23">Shift output appears at the top of each key</text>
    <circle class="legend-swatch-normal" cx="656" cy="14" r="10"/>
    <text class="legend" x="678" y="23">Normal output appears at the bottom</text>
  </g>
  ${keysSvg}
  <text class="footer" x="120" y="1218">ANSI physical layout. Command, Control, and Option shortcuts keep QWERTY behavior.</text>
</svg>
`;

fs.mkdirSync(assetsDir, { recursive: true });
fs.writeFileSync(outFile, svg, "utf8");
console.log(outFile);
