# Potions Roulette - 4 Hour Hackathon Plan

## One-Sentence Pitch

Two players take turns pairing four random ingredients into two hidden potions; the opponent picks one to drink, and the combo effect decides the round.

## Lock This Scope Now

This is the version to build today:

- Local 2-player hotseat only
- 2D only
- One main gameplay screen
- Four ingredients: Fire, Poison, Heal, Chaos
- At the start of each turn, the active player gets 4 random ingredients
- The active player pairs the 4 ingredients into Potion A and Potion B
- The opponent chooses one potion to drink
- Only the chosen potion resolves
- Unchosen potion is discarded
- First player to 0 HP loses

## MVP Rules

### Turn Loop

1. Pass device to active player
2. Show 4 random ingredients
3. Active player assigns 2 cards to Potion A and 2 cards to Potion B
4. Pass device to opponent
5. Opponent chooses Potion A or Potion B
6. Resolve the chosen combo
7. Apply win check
8. Swap turns

### Starting State

- Player 1 HP: 10
- Player 2 HP: 10
- No shield mechanic
- No deck management
- No card counts
- No ability roll
- No AI

### Combo Table

| Combo | Effect |
|---|---|
| Fire + Fire | 2 damage to drinker |
| Poison + Poison | 2 damage to drinker |
| Fire + Poison | 3 damage to drinker |
| Heal + Heal | Heal drinker for 2 |
| Heal + Chaos | Heal a random player for 1 |
| Fire + Chaos | Damage a random player for 1 |
| Poison + Chaos | 1 damage now, plus 1 damage to drinker at the start of their next turn |
| Chaos + Chaos | Roll Chaos event |
| Fire + Heal | No effect |
| Poison + Heal | No effect |

### Chaos Event Table

Roll 1d6:

1. HP Swap
2. Friendly Fire: drinker takes 2
3. Toxic Cloud: both players take 1
4. Alchemist's Gift: active player heals 1
5. Thief's Brew: opponent heals 1
6. Miracle Brew: drinker heals 3

These can be tuned later. Keep the implementation simple today.

## Cut List

Do not spend time on these until the MVP is playable:

- 3D alchemist
- advanced AI
- per-3-turn ability system
- shield / overheal carryover
- animated chaos wheel
- particle polish
- sound mixing
- complex menus

## Team Split

### Person 1: Integrator / Game Lead

- Own `main`
- Pull everyone else's work
- Resolve conflicts
- Keep the game always runnable
- Decide cuts fast

### Person 2: Core Gameplay

- Turn state machine
- Combo resolution
- HP updates
- lingering poison
- win condition

### Person 3: Main UI

- Single gameplay scene
- labels for HP, turn, status
- ingredient buttons
- potion choice buttons
- result log

### Person 4: Art / Presentation

- ingredient icons
- potion bottle visuals
- background
- color coding for Fire / Poison / Heal / Chaos
- replace placeholder buttons with usable art where possible

### Person 5: Juice / QA / Build Support

- screen transitions for pass-device moments
- simple reveal animation
- chaos event feedback text
- test every combo
- keep a written bug list

## Branch Strategy

Do not have all five people push directly to `main`.

- `main`: integrator only
- `feature/core-gameplay`
- `feature/main-ui`
- `feature/art-pass`
- `feature/juice-qa`

Rule:

- Pull from `main` before starting work
- Push to your feature branch often
- Merge into `main` every 30 to 45 minutes
- No force pushes to `main`

## 4-Hour Timeline

### 0:00-0:20

- Agree on MVP rules above
- Assign owners
- Create branches
- Set up `Main.tscn` and core script

### 0:20-1:20

- Core gameplay and basic UI in parallel
- Goal: text-only playable loop

Definition of success:

- start turn
- get 4 ingredients
- assign 2 potions
- choose potion
- resolve effect
- switch turn

### 1:20-2:10

- Add chaos outcomes
- Add lingering poison
- Add pass-device screen
- Add readable colors and labels

### 2:10-3:00

- Add art and layout improvements
- Improve feedback for reveal and damage/heal
- Test edge cases

### 3:00-3:30

- Full playtest cycles
- Fix bugs only
- Cut anything unstable

### 3:30-4:00

- Build packaging
- Final balance tweaks only if safe
- Demo rehearsal

## Whiteboard Version

Write this exactly:

`MVP = 2D hotseat bluff game`

`Turn: draw 4 random ingredients -> pair into 2 potions -> opponent picks 1 -> resolve -> swap`

`Keep: combos, bluffing, chaos, poison tick`

`Cut: 3D, AI, shield, ability rolls, fancy wheel`

`Goal in 1 hour: ugly but playable`

`Goal in 2 hours: complete rules`

`Goal in 3 hours: presentation pass`

`Last hour: fix bugs and rehearse`

## Scene / Script Plan

Keep it to one scene if needed:

- `project/scenes/Main.tscn`
- `project/scripts/main.gd`

If there is time, split later:

- `project/scripts/game_logic.gd`
- `project/scripts/ui_controller.gd`

## Definition Of Done

The game is done when:

- Two players can complete a full match
- All 10 combos resolve correctly
- Chaos + Chaos always produces a valid outcome
- Poison + Chaos ticks on the next turn
- The active player and chooser can understand whose turn it is
- No soft-locks

## If Time Is Failing

Make these cuts in order:

1. Remove chaos special table animation
2. Remove custom art and keep colored buttons
3. Remove extra text polish
4. Replace random heal/damage flavor with direct effects
5. Reduce chaos outcomes to 3 results instead of 6
