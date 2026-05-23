# Tools to install (build)

Install these on your **Windows** dev machine. Order matters: do **Aftman** first so Rojo and other CLIs get pinned versions from `aftman.toml`.

## Required

| Tool | Purpose | Install |
|------|---------|---------|
| **Roblox Studio** | Build worlds, UI, publish the experience | [Create on Roblox](https://www.roblox.com/create) → download Studio |
| **Git** | Version control, GitHub | [git-scm.com](https://git-scm.com/download/win) |
| **Aftman** | Pin Rojo, Stylua, Selene, etc. | `winget install UpliftGames.Aftman` or [releases](https://github.com/LPGhatguy/aftman/releases) |
| **Rojo** | Sync `src/` into Studio; team workflow | `aftman install` (see `aftman.toml`) |
| **Rojo Studio plugin** | Connect Studio to `rojo serve` | [Rojo plugin install](https://rojo.space/docs/v7/getting-started/installation/) |

After cloning this repo:

```powershell
cd C:\Users\User\projects\roblox-game
aftman install
wally install
```

## Strongly recommended

| Tool | Purpose | Install |
|------|---------|---------|
| **Wally** | Luau package manager (TestEZ, frameworks) | `aftman install` |
| **Stylua** | Format Luau | `aftman install` |
| **Selene** | Lint Luau | `aftman install` |
| **Luau LSP** (extension) | Autocomplete, types in Cursor/VS Code | Extension: *Luau Language Server* |
| **GitHub CLI (`gh`)** | Create repos, PRs from terminal | `winget install GitHub.cli` then `gh auth login` |

## Optional (larger games)

| Tool | Purpose |
|------|---------|
| **Blender** | Custom meshes (export FBX → Studio) |
| **GIMP / Aseprite** | Textures, 2D art |
| **Moonwave** | API docs from comments |
| **Lune** | Run Luau outside Studio (scripts/tooling; not full Roblox API) |

## Verify build toolchain

```powershell
aftman --version
rojo --version
wally --version
stylua --version
selene --version
```

Then:

```powershell
rojo serve
```

Connect from Studio. You should see `src` tree under the place.

## Cursor / VS Code extensions

- **Luau Language Server** — IntelliSense for `.luau` files
- **Rojo** (optional) — project.json awareness
- **Stylua** — format on save (point to aftman’s `stylua.exe`)
