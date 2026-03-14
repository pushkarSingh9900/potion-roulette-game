# Potions Roulette — Finalized Game Design

## Design Philosophy
> Every decision maximizes **tension**, **surprise**, and **consequence**. Players should feel dread when choosing potions, relief when healing, and adrenaline when combos land.

---

## Core Rules

| Aspect | Detail |
|---|---|
| Players | Human vs. AI |
| Starting HP | 10 (Player 1), 11 (Player 2 — compensates for going second) |
| HP Cap | **10** — over-heal converts to a 1 HP **Shield** (absorbs next hit, expires next turn) |
| Starting Hand | 2 Fire, 2 Poison, 3 Heal, 5 Chaos (12 cards each) |
| Turn Start | Coin toss decides who goes first |
| Card Draw | Active player draws 1 card at the start of their crafting turn |
| Win Condition | First to 0 HP loses |
| Visibility | All card counts and stored abilities are visible. Potion contents are hidden. |

---

## Potion Recipes (Final)

| Combo | Effect | Emotion |
|---|---|---|
| 🔥 Fire + Fire | 2 damage | Satisfying aggression |
| ☠️ Poison + Poison | 2 damage | Calculated strike |
| 🔥☠️ Fire + Poison | **3 damage** | High-risk power play — the "big combo" |
| 💚 Heal + Heal | 2 heal | Sweet relief |
| 💚🌀 Heal + Chaos | 1 heal to **random** player | Hopeful gamble |
| 🔥🌀 Fire + Chaos | 1 damage to **random** player | Reckless chaos |
| ☠️🌀 Poison + Chaos | **Lingering Poison** — 1 damage now + 1 damage at start of victim's next turn | Dread & anticipation |
| 🌀🌀 Chaos + Chaos | Roll the **Chaos Wheel** (see below) | Pure adrenaline |
| 🔥💚 Fire + Heal | Nothing | Wasted potential |
| ☠️💚 Poison + Heal | Nothing | Neutralized |

> [!NOTE]
> **Poison + Chaos as Lingering Poison** is the standout design choice. The delayed damage creates a ticking-bomb effect — the victim *knows* they'll take 1 more damage next turn. This generates anticipation and dread, two of the most engaging emotions in games.

---

## 🌀 Chaos Wheel (Chaos + Chaos Outcomes)

Roll 1d6:

| Roll | Effect | Emotion |
|---|---|---|
| 1 | **HP Swap** — both players exchange HP values | Euphoria or despair — the ultimate reversal |
| 2 | **Friendly Fire** — 2 damage to the player who brewed this potion | Backfire panic |
| 3 | **Toxic Cloud** — 1 damage to both players | Shared dread |
| 4 | **Alchemist's Gift** — both players draw 1 random card | Unexpected opportunity |
| 5 | **Steal** — victim steals 1 random card from the brewer | Power shift |
| 6 | **Miracle Brew** — victim heals 3 HP | Hope from chaos |

> [!IMPORTANT]
> The HP Swap (roll 1) is the emotional centerpiece of the Chaos Wheel. When a losing player swaps to the lead, or a winning player suddenly drops to 2 HP, it creates the most memorable moments in the game.

---

## Ability Roll (Every 3 Turns)

Both players roll. Two possible outcomes:

| Outcome | Effect | Design Rationale |
|---|---|---|
| **Card Draw** | Gain 1 random card (Fire, Poison, or Heal — no Chaos) | Refuels options, extends game |
| **Partial Peek** | Store an ability: reveal **1 of the 2** potions next time you choose | Powerful but not game-breaking — you still gamble on the other |

> [!NOTE]
> Peek reveals only 1 potion (not both). This preserves tension: you know one potion is safe/deadly, but the other is still a gamble. The moment of deciding whether to trust your info or take the unknown potion is peak engagement.

---

## Summary of Adopted Flaw Fixes

| Flaw | Fix | Impact |
|---|---|---|
| Poison+Chaos undefined | Lingering Poison (1 now + 1 next turn) | Creates unique dread mechanic |
| Card exhaustion too fast | Draw 1 card per crafting turn | Extends game by 2–3 rounds |
| Chaos is dead weight | Stronger Chaos combos + Chaos Wheel | Chaos cards become exciting, not frustrating |
| Peek too powerful | Peek reveals only 1 of 2 potions | Preserves tension in every choice |
| No HP cap | Cap at 10, over-heal → 1 HP Shield | Every HP point feels precious |
| Chaos+Chaos vague | Defined Chaos Wheel table | Implementable and balanced |
| Turn order advantage | Player 2 starts with 11 HP | Simple, fair compensation |
| Fire+Poison OP? | **Kept at 3 damage** | It's the "highlight reel" combo — emotional peaks need high stakes |
