# Potions Roulette — Development Tasks

## Phase 1: Design
- [x] Create project directory
- [x] Analyze game design for flaws
- [x] Finalize game rules (all flaws resolved)
- [x] Create Godot implementation plan
- [x] Create UI design plan (dark alchemy aesthetic)

## Phase 2: Core Implementation (Godot)
- [x] Set up Godot project structure (project.godot, folders)
- [x] Implement `game_rules.gd` (constants, combo table)
- [x] Implement `card.gd` (card types, data model)
- [x] Implement `player.gd` (HP, shield, lingering poison, hand, abilities)
- [x] Implement `potion.gd` (combo resolver)
- [x] Implement `chaos_wheel.gd` (d6 roller, effect dispatch)
- [x] Implement `ability_system.gd` (roll, peek, card draw)
- [x] Implement `main.gd` (state machine, turn loop)
- [x] Implement `ai_opponent.gd` (crafting, choosing, bluffing)

## Phase 3: UI & Scenes
- [x] Build `Card.tscn` + `Potion.tscn`
- [x] Build `PlayerHUD.tscn` (HP bar, shield, hand display)
- [x] Build `ChaosWheel.tscn` (spinning wheel animation)
- [x] Build `CoinToss.tscn` + `AbilityRoll.tscn`
- [x] Build `Main.tscn` (layout, 3D Alchemist SubViewport)

## Phase 4: Polish
- [ ] Card art and potion effects
- [ ] Sound effects and music
- [ ] Animations (damage shake, heal glow, poison drip, Alchemist reactions)
- [ ] Playtesting and balance tuning
