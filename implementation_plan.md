# Potions Roulette — Godot Implementation Plan

## Overview
Turn-based card-strategy roulette. Two players brew potions, force the opponent to drink one. **Godot 4 + GDScript**.

Finalized rules: [Game Design Doc](file:///C:/Users/hp/.gemini/antigravity/brain/63fd72a9-8ae2-414b-9ea8-c77ba03dc0e6/game_design_analysis.md)

---

## Project Structure

```
game-project/
├── project.godot
├── scenes/
│   ├── Main.tscn              # Game orchestrator
│   ├── Card.tscn              # Card display (type, icon, glow)
│   ├── Potion.tscn            # Potion slot (2 hidden cards, selection anim)
│   ├── PlayerHUD.tscn         # HP bar, shield icon, hand, abilities
│   ├── ChaosWheel.tscn        # Spinning wheel popup for Chaos+Chaos
│   ├── AbilityRoll.tscn       # Ability roll popup (every 3 turns)
│   └── CoinToss.tscn          # Opening coin flip animation
├── scripts/
│   ├── main.gd                # State machine, turn loop
│   ├── card.gd                # Card enum + resource
│   ├── potion.gd              # Combo resolver (recipe dict)
│   ├── player.gd              # HP, hand, shield, lingering poison, abilities
│   ├── ai_opponent.gd         # AI crafting + choosing strategy
│   ├── ability_system.gd      # Roll, peek, card draw
│   ├── chaos_wheel.gd         # d6 roller + effect dispatcher
│   └── game_rules.gd          # All constants and config
├── assets/
│   ├── art/
│   ├── audio/
│   └── fonts/
└── README.md
```

---

## Key Mechanics to Implement

### Lingering Poison (Poison + Chaos)
- On resolve: deal 1 damage immediately
- Set `player.lingering_poison = true`
- At start of victim's next turn: deal 1 more damage, clear flag
- UI: pulsing green/purple venom overlay on HP bar

### Chaos Wheel (Chaos + Chaos)
- Animated spinning wheel with 6 segments
- Outcomes: HP Swap, Friendly Fire 2, Toxic Cloud 1+1, Alchemist's Gift, Steal Card, Miracle Heal 3
- Dramatic spin + slowdown before landing

### Shield (Over-heal)
- If heal would exceed HP cap (10): grant 1 HP Shield
- Shield absorbs next 1 damage, then breaks
- Expires if unused by next turn
- UI: golden border on HP bar

### Partial Peek (Ability)
- Stored as ability. On use: reveal contents of 1 of 2 offered potions
- AI uses peek strategically when opponent has Fire+Poison remaining

---

## Game State Machine

```
COIN_TOSS → DRAW_CARD → CRAFT_POTIONS → OPPONENT_CHOOSE
    → RESOLVE_POTION_1 → RESOLVE_POTION_2
    → CHECK_LINGERING_POISON → CHECK_WIN
    → (every 3 turns) ABILITY_ROLL
    → NEXT_TURN
```

---

## AI Strategy (Emotional Design)
- **Crafting:** Sometimes bluffs (puts strong combo in the "obvious" slot)
- **Choosing:** Estimates potion contents from visible card counts
- **Ability:** Prioritizes Peek when opponent has lethal combos remaining
- **Personality:** Slight random variance to feel human, not optimal

---

## Verification Plan

### Automated
- Test all 10 potion combos via GDScript test scene
- Validate Lingering Poison resolves and clears correctly
- Validate Shield absorb + expiry
- Validate Chaos Wheel each outcome
- Validate card draw, hand size, exhaustion

### Manual
- Full playthrough (3+ games)
- Verify Chaos Wheel animation + suspense timing
- Confirm peek reveals only 1 potion
- Check AI doesn't behave predictably
