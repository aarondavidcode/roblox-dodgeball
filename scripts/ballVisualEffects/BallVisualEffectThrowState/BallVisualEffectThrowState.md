# BallVisualEffectThrowState

**Purpose:** Shared client rules for **all** ball visual effects. Gate effects on **“can still eliminate”** (`InThrowWindow` + throw metadata, same as **DodgeballService** `isLiveThrow`), not wall-clock throw window alone.

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `BallVisualEffectThrowState` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/BallVisualEffectThrowState` | **ModuleScript** |

Paste from [BallVisualEffectThrowState.lua](./BallVisualEffectThrowState.lua).

## API (new effects)

| Function | Use |
|----------|-----|
| `shouldShowForLiveEliminationThrow(ball, context)` | **Required gate** — true only when ball is not held and server says throw can still eliminate. |
| `canStillEliminate(ball, throwOutWindowSeconds)` | Same check with explicit window (usually `context.throwOutWindowSeconds`). |
| `isBallHeld(ball)` | Suppress VFX while carried. |
| `resolveEffectiveThrowSpeed(ball, context)` | Speed for intensity / secondary gates (replication lag vs `LastThrowSpeed`). |
| `isAboveHitSpeedWithHysteresis(speed, context, currentlyActive)` | Optional, when effect also cares about `HIT_MIN_SPEED`. |

**Do not** reimplement `LastThrowTime` / `InThrowWindow` checks inside individual effect modules.