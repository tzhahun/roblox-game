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

## GitLab

Create the remote project (once `glab` is authenticated):

```powershell
glab repo create roblox-game --private --description "Roblox game (Rojo + Luau)" --remote origin
git push -u origin main
```

Or create the project in the GitLab UI, then:

```powershell
git remote add origin https://gitlab.com/<your-group>/roblox-game.git
git push -u origin main
```
