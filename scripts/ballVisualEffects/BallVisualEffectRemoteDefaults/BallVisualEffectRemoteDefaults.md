# BallVisualEffectRemoteDefaults

**Purpose:** Client-side fallbacks when **DodgeballRemotes** VFX attributes are missing (stale **DodgeballService** paste). Values must stay in sync with **DodgeballBallVisualEffectsConfig**.

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `BallVisualEffectRemoteDefaults` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/BallVisualEffectRemoteDefaults` | **ModuleScript** |

After changing **DodgeballBallVisualEffectsConfig**, update this module’s numbers to match, then re-paste **DodgeballService** so remotes mirror at runtime.