#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
#  CRYPTA OBSCURA — GitHub Setup Script
#  Run this ONCE after cloning / downloading the project.
#  Usage: bash setup_github.sh
# ─────────────────────────────────────────────────────────────────────
set -e

REPO_NAME="crypta-obscura"
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       ⚔  CRYPTA OBSCURA — GitHub Setup  ⚔           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# 1. Init git if not already
if [ ! -d ".git" ]; then
  echo "→ Initializing git repository..."
  git init
  git branch -M main
else
  echo "→ Git already initialized."
fi

# 2. Stage everything
echo "→ Staging all files..."
git add .

# 3. First commit
if git diff --cached --quiet; then
  echo "→ Nothing to commit (already clean)."
else
  git commit -m "🎮 Initial commit — Crypta Obscura Godot 4 project

- Procedural BSP dungeon generation
- Turn-based combat system
- 12-node skill tree (3 tiers, 4 branches)
- Pixel-art rendering (no external assets)
- Procedural audio (no audio files needed)
- Fog of war
- GitHub Actions CI: Windows / Linux / Web export
- GitHub Pages web deploy"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Next steps to push to GitHub:"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "1. Create a new repository on GitHub:"
echo "   https://github.com/new"
echo "   Name: ${REPO_NAME}"
echo "   Visibility: Public (required for free GitHub Pages)"
echo "   ⚠ Do NOT initialize with README/gitignore (we have our own)"
echo ""
echo "2. Connect and push:"
echo ""
echo "   git remote add origin https://github.com/YOUR_USERNAME/${REPO_NAME}.git"
echo "   git push -u origin main"
echo ""
echo "3. Enable GitHub Pages:"
echo "   Settings → Pages → Source: GitHub Actions"
echo ""
echo "4. The CI workflow will auto-export on every push to main."
echo "   Check: Actions tab → '🎮 Godot Export'"
echo ""
echo "5. To create a versioned release:"
echo "   git tag v1.0.0 && git push origin v1.0.0"
echo ""
echo "═══════════════════════════════════════════════════════"
echo " ⚠  IMPORTANT: You need Godot 4.2 installed to run/edit."
echo "    Download: https://godotengine.org/download/"
echo "    Open the project: godot project.godot"
echo "═══════════════════════════════════════════════════════"
echo ""
