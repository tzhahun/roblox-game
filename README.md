# Roblox Game

Professional Roblox development setup using **Rojo** (filesystem ↔ Studio sync), **Aftman** (tool versions), and **Wally** (Luau packages).

## Quick start

1. Install tools (see [docs/TOOLS-BUILD.md](docs/TOOLS-BUILD.md)).
2. Install test tools (see [docs/TOOLS-TEST.md](docs/TOOLS-TEST.md)).
3. Open Roblox Studio → create or open a place → enable **Plugin** → install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) plugin.
4. In this repo root:

   ```powershell
   aftman install
   wally install
   rojo serve
   ```

5. In Studio: Rojo plugin → **Connect** (default `localhost:34872`).

## Project layout

```
src/
  client/     # LocalScripts (StarterPlayerScripts)
  server/     # Server scripts (ServerScriptService)
  shared/     # ReplicatedStorage modules
tests/        # TestEZ specs (run in Studio or CI)
```

## GitHub

Repo: **https://github.com/tzhahun/roblox-game**

Clone:

```powershell
git clone https://github.com/tzhahun/roblox-game.git
cd roblox-game
```

Push local changes (after [GitHub CLI](https://cli.github.com/) login, or use the website):

```powershell
cd C:\Users\User\projects\roblox-game
git remote set-url origin https://github.com/tzhahun/roblox-game.git
git push -u origin main
```

Create the repo on GitHub if it does not exist yet:

```powershell
gh auth login
gh repo create tzhahun/roblox-game --private --source=. --remote=origin --push
```
