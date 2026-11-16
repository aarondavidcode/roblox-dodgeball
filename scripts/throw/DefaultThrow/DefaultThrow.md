# DefaultThrow

**Purpose:** Standard straight-line throw: applies impulse from the thrower’s hand using `THROW_IMPULSE` and power 0–1 from the client. Sets ball attributes so **DodgeballService** can apply OUT rules.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `throw` | `ServerScriptService/throw` | **Folder** |
| `DefaultThrow` | `ServerScriptService/throw/DefaultThrow` | **ModuleScript** |

Paste from [DefaultThrow.lua](./DefaultThrow.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

**Depends on:** `DodgeballConfig` in `ServerScriptService`.

## What you build in Studio

Nothing beyond the folder and module above. Balls and arena are covered in [DodgeballService.md](../DodgeballService/DodgeballService.md).

## What scripts create

This module does not create instances. **DodgeballService** `require`s it (or another profile module).

## Config knobs

| Key | Role |
|-----|------|
| `THROW_IMPULSE` | Base impulse at 100% power |
| `ACTIVE_THROW_PROFILE` | Set to `Default` for this module; future throws = new ModuleScripts in `throw/` and change this string |

## Adding more throw types later

1. Add a new **ModuleScript** under `ServerScriptService/throw/` (e.g. `CurveThrow`).
2. Export the same pattern: `throw(context)` and optional `onThrowStarted`.
3. Set `ACTIVE_THROW_PROFILE` in **DodgeballConfig** to the module name (without path).

## What not to build

Do not put throw modules under **ReplicatedStorage** or **Workspace**. Keep them server-side under `throw/`.