# Known Issues

## Aura data blocked during combat on some Classic beta clients

**Status:** Not fixable in this addon; likely a client-side restriction/bug.

### What we tried

A "per-buff visibility conditions" feature (e.g. "only remind me about this
buff while in combat / out of combat / resting") was implemented and then
reverted after testing on a Classic beta client (`_classic_beta_`).

### What we found

While testing a buff conditioned to "In Combat Only":

- Out of combat, the buff's presence was detected correctly.
- On entering combat, the missing-buff icon appeared correctly.
- After casting the buff (now active, still in combat), the icon did
  **not** disappear, and further icons could appear unexpectedly.

Diagnosing this (via a temporary `/sbt debugbuff` command, since removed)
showed that every aura-lookup API - `C_UnitAuras.GetPlayerAuraBySpellID`,
`C_UnitAuras.GetAuraDataBySpellName`, and even `AuraUtil.ForEachAura` /
`C_UnitAuras.GetAuraSlots` - returned nothing for a buff that was visibly
active on the player, but **only while in combat**. Out of combat, the
exact same lookups worked fine.

`AuraUtil.ForEachAura` surfaced the underlying error directly:

```
GetAuraSlots(): Auras cannot be accessed when secret while tainted by
'Uwowea_buff_tracker'
```

### Interpretation

This is a client-side protection that blocks **addon** (tainted) code from
reading aura data during combat when it's flagged "secret" - seemingly for
*all* auras, not just specific mechanics, on this beta build. Since our
own buff-presence detection uses exactly these APIs, the addon can't
determine whether a tracked buff is active at all while in combat, making
any combat-only condition (and potentially core buff tracking accuracy in
combat in general) unreliable on this client.

This is outside what can be worked around from addon Lua - it would need
either a client-side fix/adjustment from Blizzard, or turns out to be
specific to this particular beta build and stops reproducing in a later
patch.

### If revisiting this

- Re-test on a current build before re-attempting: check whether
  `AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura) ... end, true)`
  still errors with the "secret"/tainted message while in combat.
- If it no longer reproduces, the per-buff condition feature (git history:
  the commit(s) around "per-buff visibility conditions and named
  profiles") can be reinstated largely as-is.
