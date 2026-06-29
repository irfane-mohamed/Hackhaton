# ⚔ Crypta Obscura

> Pixel-art dungeon crawler RPG with a full Skill Tree — built in **Godot 4.2**

[![Godot Export](https://github.com/YOUR_USERNAME/crypta-obscura/actions/workflows/godot-export.yml/badge.svg)](https://github.com/YOUR_USERNAME/crypta-obscura/actions)
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
crypta_obscura/
├── project.godot          # Godot project config
├── export_presets.cfg     # Windows / Linux / Web exports
├── icon.svg               # Game icon
├── scenes/
│   └── Main.tscn          # Root scene
├── scripts/
│   ├── GameState.gd       # 📌 Autoload — all player data & skill logic
│   ├── AudioManager.gd    # 📌 Autoload — procedural SFX (no audio files needed)
│   ├── DungeonGenerator.gd# BSP procedural map generation
│   ├── Dungeon.gd         # Map rendering + entity management + fog of war
│   ├── Player.gd          # Pixel-art player sprite + grid movement
│   ├── CombatSystem.gd    # Turn-based combat logic (signals-based)
│   ├── CombatScreen.gd    # Combat overlay UI
│   ├── SkillTreePanel.gd  # Skill tree UI with tooltips
│   ├── HUD.gd             # HP/MP/XP bars, combat log
│   └── Main.gd            # Scene orchestrator
└── .github/
    └── workflows/
        └── godot-export.yml  # CI: build & deploy to GitHub Pages
```

### Key design decisions

- **No external assets** — all graphics drawn via `_draw()` with GDScript; audio generated procedurally via `AudioStreamGenerator`
- **Signal-driven** — combat, stats, skill unlocks all use Godot signals for clean decoupling
- **No black/white** — entire color palette uses amethyst/purple/gold tones only
- **Autoloads** — `GameState` and `AudioManager` are singletons accessible globally

---

## 🚀 Getting Started

### Prerequisites

- [Godot 4.2+](https://godotengine.org/download/) (standard, not Mono/C#)

### Run locally

```bash
git clone https://github.com/YOUR_USERNAME/crypta-obscura.git
cd crypta-obscura
godot project.godot
```

Press **F5** (or the ▶ button) to run.

### Export

Open **Project → Export**, select a platform preset, and click **Export Project**.

The GitHub Actions workflow (`.github/workflows/godot-export.yml`) automates this on every push to `main`.

---

## 🌐 GitHub Pages (Web build)

The CI pipeline automatically deploys the Web export to **GitHub Pages** on every push to `main`.

To enable it on your fork:
1. Go to **Settings → Pages**
2. Set source to **GitHub Actions**
3. Push to `main` — the workflow handles the rest

---

## 📦 Releases

Tag a commit with `v*` to trigger an automatic GitHub Release with zipped builds for all platforms:

```bash
git tag v1.0.0
git push origin v1.0.0
```

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
- 💾 Save/load system (Godot `ConfigFile`)
- 🎲 More enemy types & boss rooms
- 🏆 Leaderboard (floor reached)
- 🎵 Procedural music (extend `AudioManager`)
- 📱 Mobile touch controls
