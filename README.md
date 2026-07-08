# 🧪 Chroma Sort

An addictive **ball-sort puzzle** in a single, dependency-free HTML file. Pour colored balls between glass tubes until each tube holds one color. Built to feel *juicy* — arc-pour animations, synthesized sound, and a steady drip of little rewards.

**▶️ Play:** open `index.html` in any browser, or enable GitHub Pages (see below).

![Chroma Sort](https://img.shields.io/badge/vanilla-JS-f7df1e) ![No build](https://img.shields.io/badge/build-none-brightgreen) ![Single file](https://img.shields.io/badge/single-file-blue)

## How to play

- Tap a tube to lift its top run of one color, tap another tube to **pour**.
- A pour is legal onto an **empty tube** or onto the **same color** with room to spare.
- Clear the board when every tube is empty or filled with a single color.
- **Keyboard:** number keys `1–9` select tubes, `Esc` deselects, `⌘/Ctrl+Z` undoes.

## Features

- **Three modes**
  - **Endless** — a gentle difficulty ramp from 3 up to 12 colors (2 spare tubes).
  - **Hard** — a real difficulty spike: only **1 spare tube**, capped at 9 colors for reliable, brutal boards.
  - **Daily** — a **seeded** puzzle that is *identical for everyone on a given date*.
- **Every level is guaranteed solvable** — boards are dealt at random and verified by a built-in DFS solver before being served.
- **Real hints** — the same solver suggests an actual winning move (never a dead end).
- **Star ratings** vs. the solver's par, a **win streak**, and a **live timer**.
- **Personal-best leaderboard** — highest Endless/Hard level, best streak, daily streak, and a 7-day daily calendar (stored locally).
- **Colorblind mode** — distinct monochrome symbols on every ball (and on balls mid-pour).
- **Juice** — arc-pour animations, Web Audio SFX (pluck / plop / complete-chime / win fanfare), confetti, haptics.
- **Light & dark themes**, respects `prefers-reduced-motion`, and remembers your progress between sessions.

## Tech

- One file, zero dependencies, no build step. Vanilla HTML/CSS/JS.
- Web Audio API for all sound (synthesized — no audio assets).
- Canvas confetti; Web Animations API for the pour arcs.
- `localStorage` for progress, settings, and the leaderboard.

## Run locally

```bash
# just open it
open index.html

# or serve it (any static server)
python3 -m http.server 8000   # then visit http://localhost:8000
```

## Deploy to GitHub Pages

Settings → Pages → Build from branch → `main` / root. The game is served at
`https://<user>.github.io/chroma-sort/`.

## License

MIT — see [LICENSE](LICENSE).
