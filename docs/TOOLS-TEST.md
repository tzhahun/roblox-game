# Tools to install (test)

Roblox has no full “headless game engine” on your PC. Testing is **in Studio**, **on Roblox test servers**, and optionally **CI** that runs Luau checks—not a full play simulation in GitLab runners.

## Required for automated tests

| Tool | Purpose | Install |
|------|---------|---------|
| **TestEZ** | Unit/integration tests in Luau | `wally install` (already in `wally.toml`) |
| **Roblox Studio** | Run TestEZ, Play Solo, multiplayer test | Same as build |
| **Rojo** | Sync `tests/` into the place before running | `aftman install` |

### Run tests in Studio (manual)

1. `rojo serve` and connect Rojo in Studio.
2. Ensure TestEZ is under `Packages` (from Wally).
3. Add a **Server** script (or use Roblox’s test runner plugin) that requires TestEZ and runs `tests/`.
4. **Test** tab → **Run** (or your custom runner script).

Typical runner pattern (ServerScriptService):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage.Packages.TestEZ)
TestEZ.TestBootstrap:run({ script.Parent.Parent.tests })
```

Adjust paths to match where Rojo places `tests`.

## Strongly recommended

| Tool | Purpose |
|------|---------|
| **Selene** | Catch bugs before Studio (`selene src tests`) |
| **Stylua** | Consistent code in reviews |
| **Roblox Studio — Play Solo** | Smoke-test gameplay locally |
| **Roblox Studio — Start Server + Players** | Test replication, multiple clients |

## Optional

| Tool | Purpose |
|------|---------|
| **TestService** (built into Studio) | Official test runner UI for tagged tests |
| **Roblox Open Cloud** | Automated uploads; not a game test runner |
| **Team Test** (Studio) | Collaborators join your unpublished place |

## What you cannot fully replace locally

- **Real device performance** — use Roblox on phone/tablet after publish to a private/unlisted experience.
- **Live production data** — use a separate “Staging” place ID.
- **Full CI playtest** — GitLab runners cannot run Studio; CI here only lints/formats (see `.gitlab-ci.yml`).

## Verify test setup

```powershell
selene src tests
stylua --check src tests
```

In Studio: run your TestEZ bootstrap once; all specs should pass.

## Test checklist before publish

- [ ] `selene` clean on `src` and `tests`
- [ ] TestEZ green in Studio
- [ ] Play Solo: core loop works
- [ ] 2-player server: replication / remotes work
- [ ] No errors in **Output** and **Developer Console** (F9 in client)
