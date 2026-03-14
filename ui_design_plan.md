# Potions Roulette — UI Design Plan

## Visual Identity: "Dark Alchemy"

Inspired by the monster reference — a monochromatic, horror-dramatic figure screaming from the void with blood-red number overlays. The game's UI should feel like you're sitting across from a **cursed alchemist** in a dark dungeon, gambling with potions.

### Core Aesthetic Pillars

| Pillar | Description |
|---|---|
| **Monochromatic Base** | Near-black backgrounds, dark greys, desaturated textures. All "neutral" UI is greyscale. |
| **Selective Color** | Color is *rare* and *meaningful*. It only appears to signal game events — blood red for damage, toxic green for poison, ethereal cyan for healing, deep purple for chaos. |
| **3D Horror Character** | A 3D-rendered "Alchemist" figure (inspired by the monster reference) is the visual anchor. Pale skin, glowing eyes, exaggerated features. Reacts to game events in real time. |
| **2D Game Layer** | Cards, potions, HUD, and UI chrome are all 2D — clean, readable, and laid out on a flat plane. The 3D character sits *behind* the 2D layer, creating depth. |
| **Dramatic Typography** | Large, bold numbers (HP, damage) in textured, slightly distressed fonts. Numbers should feel carved or burned into the screen — not clean UI text. |

---

## Color System

| Token | Hex | Usage |
|---|---|---|
| `bg-void` | `#0A0A0A` | Primary background — near-black void |
| `bg-surface` | `#1A1A1A` | Card backs, panels, table surface |
| `text-primary` | `#D4D4D4` | Labels, descriptions |
| `text-muted` | `#666666` | Secondary info, inactive elements |
| `accent-damage` | `#CC0000` | Damage numbers, fire icons, blood effects |
| `accent-poison` | `#44CC44` | Poison effects, lingering venom glow |
| `accent-heal` | `#33CCCC` | Heal numbers, heal particle effects |
| `accent-chaos` | `#9933CC` | Chaos card glow, Chaos Wheel rim |
| `accent-shield` | `#CCAA33` | Shield icon, over-heal golden border |
| `accent-white-hot` | `#FFFFFF` | Glowing eyes of the Alchemist, critical UI highlights |

> [!IMPORTANT]
> Color should feel like it's *emerging from darkness*. Use glow/bloom shaders on colored elements so they bleed light into the surrounding dark UI. This mimics the monster reference where the pale figure glows against the black void.

---

## 3D Character: The Alchemist

The central visual anchor of the game, positioned in the **upper-center** of the screen behind the 2D game layer.

### Design (Influenced by Monster Reference)
- **Base:** Pale grey/white skin, desaturated, almost corpse-like
- **Face:** Exaggerated mouth (can open wide for reactions), glowing white pupil-less eyes
- **Hands:** Long-fingered, pale, always visible — used to "present" potions and react to events
- **Lighting:** Single dramatic light source from below (horror convention), deep shadows on upper face

### Real-Time Reactions (Emotional Feedback)
The Alchemist reacts to game events, creating **emotional mirrors** for the player:

| Game Event | Alchemist Reaction |
|---|---|
| Player takes damage | Head tilts forward, mouth opens into a grin, eyes brighten |
| Player heals | Slight recoil, eyes narrow, subtle growl animation |
| Lingering Poison applied | Hands rub together, green mist seeps from fingers |
| Chaos Wheel spin | Leans in close to the camera, eyes widen with anticipation |
| HP Swap triggers | Head snaps back, mouth opens in a scream (like the reference) |
| Player near death (≤2 HP) | Leans forward aggressively, breathing becomes visible (fog from mouth) |
| AI near death (≤2 HP) | Recoils, hands come up defensively, eyes flicker |
| Player wins | Dramatic death animation — dissolves into black smoke |
| Player loses | Lunges toward camera, screen cracks, fade to black |

> [!NOTE]
> These reactions are what make the 3D element worthwhile. Without them, the character is just decoration. With them, the Alchemist becomes the emotional heartbeat of the game.

---

## Screen Layouts

### 1. Main Gameplay Screen

```
┌──────────────────────────────────────────┐
│              [AI HP: 10]                 │  ← Blood-red number, top center
│                                          │
│          ╔══════════════════╗             │
│          ║   3D ALCHEMIST   ║             │  ← 3D layer, behind everything
│          ║   (upper body)   ║             │
│          ╚══════════════════╝             │
│                                          │
│       ┌─────────┐   ┌─────────┐          │
│       │ POTION  │   │ POTION  │          │  ← 2D potion bottles, glow effects
│       │   A     │   │   B     │          │
│       │   ??    │   │   ??    │          │
│       └─────────┘   └─────────┘          │
│                                          │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐    │
│  │🔥│ │🔥│ │☠️│ │☠️│ │💚│ │💚│ │💚│    │  ← 2D card hand, bottom
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘    │
│                                          │
│ [SHIELD: ●]  [PLAYER HP: 10]  [PEEK: 1] │  ← HUD bar, bottom
└──────────────────────────────────────────┘
```

**Key details:**
- The Alchemist occupies ~30% of screen height, centered, slightly transparent at edges to blend into void
- Potion bottles sit on a faintly lit stone shelf — the only "3D-lit" 2D element
- Cards fan out in an arc at the bottom, selectable with hover glow
- HP numbers are **large** (like the red "6" and "7" in the reference) — damage/heal numbers appear as big floating text that fades

### 2. Crafting Phase (Active Player's Turn)

```
┌──────────────────────────────────────────┐
│              [AI HP: 10]                 │
│                                          │
│          ║   ALCHEMIST watches   ║       │
│                                          │
│      POTION A              POTION B      │
│     ┌────────┐            ┌────────┐     │
│     │ DROP   │            │ DROP   │     │  ← Drag & drop zones
│     │ 2 CARDS│            │ 2 CARDS│     │
│     └────────┘            └────────┘     │
│                                          │
│  [ 🔥 ] [ 🔥 ] [ ☠️ ] [ ☠️ ] [ 💚 ]...  │  ← Draggable cards
│                                          │
│         [PLAYER HP: 10]                  │
└──────────────────────────────────────────┘
```

- Cards are dragged up into potion slots
- When both potions are filled, a "BREW" button pulses with a red glow
- Alchemist leans in during crafting, hands hovering over the table

### 3. Opponent Choice Phase

```
┌──────────────────────────────────────────┐
│                                          │
│       ALCHEMIST presents potions         │
│       (hands gesture left & right)       │
│                                          │
│     ┌─────────┐       ┌─────────┐       │
│     │ POTION  │       │ POTION  │       │
│     │   A     │       │   B     │       │
│     │  ???    │       │  ???    │       │
│     │ [PICK]  │       │ [PICK]  │       │
│     └─────────┘       └─────────┘       │
│                                          │
│        "CHOOSE YOUR FATE"                │  ← Gothic text, fades in
│                                          │
│  [PEEK] ← tap to reveal one potion      │
└──────────────────────────────────────────┘
```

- Potions wobble subtly, emitting faint colored smoke
- If player uses Peek: one potion's contents are revealed with a dramatic glass-crack effect
- Alchemist's eyes track the player's cursor/selection

### 4. Chaos Wheel Screen

```
┌──────────────────────────────────────────┐
│                                          │
│        ALCHEMIST behind the wheel        │
│        (eyes wide, leaning forward)      │
│                                          │
│           ╭───────────────╮              │
│          ╱   CHAOS WHEEL   ╲             │
│         │  ⚔  💀  ☁  🧪  ✋  💚 │         │  ← 6 segments, spinning
│          ╲                 ╱             │
│           ╰───────────────╯              │
│               ▲ pointer                  │
│                                          │
│          [ SPIN ] (or auto)              │
└──────────────────────────────────────────┘
```

- Wheel has a physical weight feel — starts fast, decelerates with ticking sounds
- Each segment glows its accent color as the pointer passes over it
- When landing: screen flash + Alchemist reaction + large floating text announcing the effect
- HP Swap: special full-screen swirl animation + Alchemist scream

### 5. Ability Roll Screen

```
┌──────────────────────────────────────────┐
│                                          │
│        "ALCHEMIST'S OFFERING"            │
│                                          │
│     ┌──────────┐    ┌──────────┐         │
│     │  📦 CARD │    │  👁 PEEK │         │
│     │  Random  │    │  Ability │         │
│     │ (no chaos)│    │ (stored) │         │
│     └──────────┘    └──────────┘         │
│                                          │
│        ← Roll determines which →         │
│                                          │
└──────────────────────────────────────────┘
```

- Dice roll or slot-machine animation determines outcome
- Alchemist "offers" the result — hands extend toward camera

---

## Animation & Effects System

### Damage Feedback
- **Number Pop:** Large damage number (blood-red, textured font) slams onto screen, shakes, then fades — mimicking the bold "6 7" in the reference
- **Screen Shake:** Brief directional shake toward the damaged player
- **HP Bar Drain:** HP bar drains with a liquid animation, leaving a brief red "ghost" of the lost HP
- **Vignette Flash:** Red vignette pulses at screen edges

### Heal Feedback
- **Number Float:** Cyan heal number floats upward gently
- **HP Bar Fill:** Liquid fill with a subtle glow ripple
- **Particle Burst:** Small cyan sparkle particles from HP bar

### Lingering Poison
- **Applied:** Green venom drips down the edges of the victim's HP bar
- **Ticking:** Soft toxic pulse every 2 seconds until it triggers
- **Trigger:** Green flash + damage number + venom clears

### Shield
- **Applied:** Golden shimmer wraps around HP bar
- **Absorbed Hit:** Shield cracks with glass-break SFX, fades away
- **Expired:** Quiet golden dust dissipation

### Critical Moments (≤2 HP)
- Background ambiance shifts to low heartbeat pulse
- Alchemist behavior intensifies (described above)
- Screen edges darken further (tighter vignette)
- Cards in hand may subtly tremble

---

## Typography

| Use | Font Style | Size | Weight |
|---|---|---|---|
| HP Numbers | Distressed serif / gothic (e.g., "UnifrakturCook" or custom) | 72–96px equivalent | Bold |
| Damage/Heal Popups | Same as HP | 120px+ for impact | Extra Bold |
| Card Labels | Clean sans-serif (e.g., "Inter" or "Rajdhani") | 14–16px | Medium |
| UI Labels | Clean sans-serif | 12–14px | Regular |
| "CHOOSE YOUR FATE" | All-caps gothic serif | 36px | Bold, letter-spaced |

---

## 2D / 3D Layer Separation (Godot Implementation)

| Layer | Content | Godot Node | Z-Index |
|---|---|---|---|
| **Background** | Pure black void + subtle fog particles | `ParallaxBackground` | 0 |
| **3D Character** | Alchemist model + animations | `SubViewport` with `Node3D` → rendered to `TextureRect` | 1 |
| **Game Table** | Faintly lit stone surface (2D sprite) | `Sprite2D` | 2 |
| **Potions** | 2D potion bottle sprites + glow shaders | `Sprite2D` + `CanvasItemShader` | 3 |
| **Cards** | 2D card sprites, draggable | `Control` nodes | 4 |
| **HUD** | HP bars, labels, ability slots | `CanvasLayer` | 5 |
| **Popups** | Damage numbers, Chaos Wheel, Ability Roll | `CanvasLayer` (overlay) | 6 |
| **Transitions** | Screen shake, vignette, fade-to-black | `CanvasLayer` (post-process) | 7 |

> [!TIP]
> The 3D Alchemist is rendered in a `SubViewport` and displayed as a 2D texture. This keeps the game fundamentally 2D (Godot 2D project) while seamlessly embedding a 3D character — best of both worlds without the complexity of a full 3D scene.

---

## Sound Design Direction

| Event | Sound Character |
|---|---|
| Ambient | Low drone, distant dripping, faint breathing |
| Card hover | Soft papery scrape |
| Card place into potion | Liquid bubble/plop |
| Potion brew | Sizzle + glass clink |
| Damage dealt | Low impact thud + glass crack |
| Heal applied | Soft chime + water trickle |
| Lingering Poison tick | Wet, acidic hiss |
| Chaos Wheel spin | Mechanical clicking, accelerating |
| Chaos Wheel land | Slam + reverb |
| HP Swap | Dramatic whoosh + dissonant chord |
| Near-death | Heartbeat replaces ambient |
| Win | Alchemist scream + silence |
| Lose | Deep rumble + screen crack |
