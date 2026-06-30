# ⚔ Crypta Obscura

> Pixel-art dungeon crawler RPG with a full Skill Tree — built in **HTML5 / JavaScript (Canvas)**

🔗 **[Play it here](https://irfane-mohamed.github.io/Hackhaton/)**

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

---

## 🎮 Gameplay

Explore **procedurally generated dungeons**, fight monsters in **turn-based combat**, loot chests, pray at shrines, and invest skill points into a **branching Skill Tree** to tailor your build.

### Controls

| Key | Action |
|-----|--------|
| `Z / W / ↑` | Move up |
| `S / ↓` | Move down |
| `Q / A / ←` | Move left |
| `D / →` | Move right |
| `K` | Toggle Skill Tree panel |
| Walk into enemy | Start combat |
| Walk into chest | Open (collect gold) |
| Walk into shrine | Restore HP/MP + skill point |
| Walk into door `🚪` | Next floor |

---

## 🌟 Skill Tree

12 skills across **3 tiers**, 4 branches:

```
TIER 0 — Foundation
  💪 Force I      🛡 Défense I     ❤ Vitalité      ✨ Arcane I
         ↓               ↓          ↓    ↓               ↓
TIER 1 — Intermediate
  ⚔ Force II    🏰 Armure      🔮 Arcane II    💰 Pillard
         ↓               ↓               ↓         ↓
TIER 2 — Advanced
  🔥 Berserker  ⭐ Paladin     🌀 Archimage   🍀 Fortune
```

### Skill effects

| Skill | Effect |
|-------|--------|
| 💪 Force I (×3) | ATQ +2/lv |
| 🛡 Défense I (×3) | DEF +2/lv |
| ❤ Vitalité (×3) | HP max +8/lv |
| ✨ Arcane I | Unlocks spell attacks |
| ⚔ Force II (×2) | ATQ +4/lv + unlocks Heavy Strike |
| 🏰 Armure (×2) | DEF +3/lv + unlocks Shield action |
| 🔮 Arcane II (×2) | Recover 1 MP per spell cast |
| 💰 Pillard (×2) | +50% gold per level |
| 🔥 Berserker (×2) | ATQ +6 + 25% crit chance |
| ⭐ Paladin (×2) | Heal +3 HP after every combat |
| 🌀 Archimage | Spell multiplier ×3 instead of ×1.5 |
| 🍀 Fortune | +1 guaranteed chest per floor |

---

## 🏗 Architecture

```
Hackhaton/
└── docs/
    └── index.html   # Entire game: HTML + CSS + JS (Canvas rendering)
```

### Key design decisions

- **Single-file, zero dependencies** — the whole game (rendering, combat, skill tree, dungeon generation) runs in one self-contained `index.html`, no build step needed
- **No external assets** — all graphics drawn via Canvas 2D API (`fillRect`), no sprites/images required
- **No black/white** — entire color palette uses amethyst/purple/gold tones only
- **Procedural dungeon generation** — rooms connected via corridor carving, with enemies/chests/shrines scaled by floor depth

---

## 🚀 Getting Started

### Run locally

Just open `docs/index.html` in any modern browser — no server, no build, no install.

```bash
git clone https://github.com/irfane-mohamed/Hackhaton.git
cd Hackhaton
xdg-open docs/index.html   # or just double-click the file
```

---

## 🌐 GitHub Pages

The game is served directly from the `/docs` folder on the `main` branch via GitHub Pages.

🔗 **Live demo:** https://irfane-mohamed.github.io/Hackhaton/

---

## 🎨 Color Palette

| Role | Color | Hex |
|------|-------|-----|
| Background | Deep amethyst | `#1a0a2e` |
| Wall | Purple | `#3d1a5e` |
| Floor | Dark violet | `#2a0f45` |
| Player | Gold | `#f0c040` |
| Enemy | Crimson | `#e03060` |
| HP bar | Rose | `#df4060` |
| MP bar | Azure | `#4080e0` |
| XP bar | Emerald | `#40d060` |
| Chest | Cyan | `#40d0a0` |
| Exit | Sky blue | `#60a0ff` |
| Shrine | Amber | `#ffa040` |
| Skill gold | Gold | `#f0c040` |

> ⚠ **Constraint**: zero `#000000` (black) and zero `#ffffff` (white) anywhere in the codebase.

---

## 📄 License

MIT — see [LICENSE](LICENSE)

---

## 🤝 Contributing

PRs welcome! Ideas for extension:
- 🗺 Minimap overlay
- 💾 Save/load system (`localStorage`)
- 🎲 More enemy types & boss rooms
- 🏆 Leaderboard (floor reached)
- 🎵 Sound effects (Web Audio API)
- 📱 Mobile touch controls
