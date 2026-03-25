# DailyArc Theme System — Implementation Specs

Extracted from mockup HTML files. All values are exact and must be matched in Swift.

---

## TACTILE THEME (Neumorphic)

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| backgroundPrimary | `#E8ECF1` | Main background, all surfaces |
| backgroundWarm | `#EDE8E3` | Zen Garden warm variant |
| backgroundDark | `#2D3748` | Dark mode variant |
| accent | `#6366F1` | Indigo primary |
| accentLight | `rgba(99,102,241,0.15)` | Indigo 15% for tints |
| pink | `#EC4899` | Secondary accent |
| success | `#10B981` | Green, toggle ON |
| streak | `#F97316` | Orange fire streak |
| textPrimary | `#334155` | Main text |
| textSecondary | `#64748B` | Secondary text |
| textTertiary | `#94A3B8` | Dim text |
| darkText | `#E2E8F0` | Dark mode text |
| darkAccent | `#818CF8` | Dark mode accent (lighter indigo) |

### Shadows (THE defining design element)

**Raised (default resting state):**
```
Large:  6px 6px 12px rgba(163,177,198,0.6), -6px -6px 12px rgba(255,255,255,0.8)
Medium: 4px 4px 8px rgba(163,177,198,0.5), -4px -4px 8px rgba(255,255,255,0.7)
Small:  3px 3px 6px rgba(163,177,198,0.5), -3px -3px 6px rgba(255,255,255,0.7)
```

**Pressed (active/selected state):**
```
Large:  inset 4px 4px 8px rgba(163,177,198,0.6), inset -4px -4px 8px rgba(255,255,255,0.8)
Medium: inset 3px 3px 6px rgba(163,177,198,0.5), inset -3px -3px 6px rgba(255,255,255,0.7)
Small:  inset 2px 2px 4px rgba(163,177,198,0.5), inset -2px -2px 4px rgba(255,255,255,0.7)
```

**Floating (hero elements):**
```
10px 10px 20px rgba(163,177,198,0.5), -10px -10px 20px rgba(255,255,255,0.9)
```

**Warm variant shadows:**
```
Raised: 6px 6px 12px rgba(174,164,150,0.5), -6px -6px 12px rgba(255,255,255,0.7)
Pressed: inset 4px 4px 8px rgba(174,164,150,0.5), inset -4px -4px 8px rgba(255,255,255,0.7)
```

**Dark mode shadows:**
```
Raised: 6px 6px 12px rgba(0,0,0,0.5), -6px -6px 12px rgba(55,65,81,0.5)
Pressed: inset 4px 4px 8px rgba(0,0,0,0.5), inset -4px -4px 8px rgba(55,65,81,0.5)
Floating: 10px 10px 20px rgba(0,0,0,0.6), -10px -10px 20px rgba(55,65,81,0.4)
```

**Tab bar shadow:** `0 -4px 12px rgba(163,177,198,0.3)`

### Corner Radii
| Component | Radius |
|-----------|--------|
| Cards/panels | 16px |
| Floating panels | 20px |
| Buttons (date nav) | 12px |
| Small buttons/icons | 10px |
| Toggle switch | 15px |
| Mood circles | 50% (circular) |
| Zen Garden tiles | 24px |
| Tab icons | 14px |
| Slider track | 18px |
| Habit grid buttons | 18px |

### Typography
- **Font family:** `-apple-system, BlinkMacSystemFont, SF Pro, system-ui`
- **Font design:** `.default` (San Francisco)
- **Display:** 44px weight 800, letter-spacing -2px
- **Title:** 24px weight 800
- **Heading:** 20px weight 700
- **Section label:** 12px weight 700, letter-spacing 1px, uppercase
- **Body:** 15px weight 600 (habit names), 14px weight 400 (body)
- **Caption:** 12px, 11px, 10px (various labels)

### Key Components

**Progress Dial (220px):**
- Outer: 220x220, border-radius 50%, floating shadow
- Inner face: 180x180, pressed shadow
- SVG arc: r=75, stroke-width 8, gradient #6366F1 to #EC4899
- Background stroke: rgba(163,177,198,0.2)
- Center: 44px weight 800 text
- Drop-shadow on arc: 0 0 4px rgba(99,102,241,0.4)

**Mood Buttons (52px):**
- Size: 52x52px, circular
- Emoji: 24px
- Raised: medium shadow
- Pressed (selected): inset shadow + gradient background rgba(99,102,241,0.12) to rgba(236,72,153,0.1)

**Toggle Switch:**
- Size: 56x30px, radius 15px
- ON: gradient(135deg, #6366F1, #818CF8), inset shadow
- OFF: background #E8ECF1, pressed shadow
- Thumb: 24x24px circle, raised shadow, positioned 3px from edge

**Counter Buttons (+/-):**
- Size: 32x32px, radius 10px, raised shadow
- Display: 36x32px, pressed shadow
- Value: 17px weight 700, accent color

**Energy Slider:**
- Track: 36px height, radius 18px, pressed shadow
- Fill: gradient(90deg, rgba(99,102,241,0.2), rgba(99,102,241,0.35))
- Handle: 32x32px circle, border 2px rgba(99,102,241,0.3), raised shadow

**Habit Grid (Control Surface):**
- Buttons: 80x80px, radius 18px
- Raised default, pressed on completion
- Completed overlay: rgba(99,102,241,0.08) gradient + 1px accent border
- Emoji: 30px, label: 10px weight 600

**Gauge Dials (Stats - 110px):**
- Outer: 110x110, medium shadow
- Inner: 88x88, pressed shadow
- SVG: r=32, stroke-width 6, dasharray 150/52
- Center: 24px weight 700

---

## COMMAND THEME (Sci-Fi Terminal)

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| background | `#000000` | Pure OLED black |
| surface | `#0A0A14` | Dark blue-black surface |
| panel | `#111122` | Card/panel background |
| grid | `rgba(99,102,241,0.08)` | Grid overlay lines |
| primary | `#6366F1` | Indigo |
| cyan | `#22D3EE` | Primary accent (sci-fi signature) |
| success | `#22C55E` | Green, system online |
| warning | `#EAB308` | Caution yellow |
| alert | `#EF4444` | Alert red |
| streak | `#F97316` | Thrust orange |
| textPrimary | `#E2E8F0` | Light gray main text |
| textSecondary | `rgba(255,255,255,0.5)` | 50% white |
| textAccent | `#22D3EE` | Cyan data readouts |

### Glow Effects
| Element | Box-shadow |
|---------|-----------|
| Cyan glow | `0 0 20px rgba(34,211,238,0.3)` |
| Cyan strong | `0 0 30px rgba(34,211,238,0.5), 0 0 60px rgba(34,211,238,0.15)` |
| Indigo glow | `0 0 20px rgba(99,102,241,0.3)` |
| Green glow | `0 0 15px rgba(34,197,94,0.3)` |
| Orange glow | `0 0 15px rgba(249,115,22,0.3)` |
| Text glow (cyan) | `text-shadow: 0 0 20px rgba(34,211,238,0.4)` |
| Green toggle | `0 0 8px rgba(34,197,94,0.5)` |
| Tab active | `0 0 8px rgba(34,211,238,0.5)` |

### Grid Overlay Pattern
```css
background-image:
  linear-gradient(rgba(99,102,241,0.08) 1px, transparent 1px),
  linear-gradient(90deg, rgba(99,102,241,0.08) 1px, transparent 1px);
background-size: 30px 30px;
```

### Scanline Overlay
```css
repeating-linear-gradient(
  transparent, transparent 2px,
  rgba(0,0,0,0.03) 2px, rgba(0,0,0,0.03) 4px
)
```

### Borders
| Component | Border |
|-----------|--------|
| Panel | `1px solid rgba(99,102,241,0.12)` |
| Panel left accent | `3px wide, accent color, 50% opacity` |
| Cards | `1px solid rgba(255,255,255,0.08)` |
| Selected card | `border-color: #22D3EE` + cyan glow |
| Input underline | `1px solid #22D3EE` + `0 1px 0 0 rgba(34,211,238,0.3)` |
| Protocol selected | `border-left: 2px solid #22D3EE` |
| Habit status row | `border-bottom: 1px solid rgba(255,255,255,0.04)` |
| HUD outer ring | `2px solid rgba(34,211,238,0.15)` |
| HUD mid rings | `2px dashed rgba(99,102,241,0.2)`, `2px solid rgba(34,197,94,0.15)` |

### Corner Radii
| Component | Radius |
|-----------|--------|
| Buttons | 2px (minimal/angular) |
| Heatmap cells | 1px |
| Segmented control | 8px |
| Tab bar icons | 36px diameter |
| Toggle switch | 2px (rectangular) |
| Config avatar | Hexagon (clip-path) |

### Typography
- **Font family (display/data):** `'Courier New', 'Courier', monospace`
- **Font family (body):** `system-ui, -apple-system, sans-serif`
- **Display headers:** weight 200, letter-spacing 0.2em, uppercase
- **Data readouts:** monospace, weight 700, letter-spacing 0.05em, cyan color
- **Labels:** weight 600, 10px, letter-spacing 0.15em, uppercase
- **Body:** weight 400, 14px, system font
- **Section header:** 12px monospace, letter-spacing 0.05em
- **Boot text:** 13px monospace, line-height 1.8
- **Status badges:** 9px weight 700, letter-spacing 0.1em, monospace
- **HUD center %:** 36px weight 700, monospace, cyan + text-shadow glow
- **Tactical labels:** 9px weight 600, letter-spacing 0.15em, uppercase

### Key Components

**Tactical HUD Ring (240px SVG):**
- Outer circle: r=116, stroke 3px, cyan gradient
- Habit ring 1: r=94, stroke 2px, #6366F1, opacity 0.8
- Habit ring 2: r=78, stroke 2px, #22C55E, opacity 0.7
- Habit ring 3: r=62, stroke 2px, #F97316, opacity 0.7
- Gradient: linearGradient from #22D3EE to #6366F1
- Drop-shadow filters on each arc
- Crosshairs: 1px lines at 50%, rgba(34,211,238,0.06)

**Status Dots (8px):**
- Green: #22C55E + glow, blinks 2s (opacity 1→0.3→1)
- Amber: #F97316 + glow, blinks 1.5s (opacity 1→0.4→1)
- Red: #EF4444, blinks 1s (opacity 1→0.3→1)
- Dim: rgba(255,255,255,0.15), no blink

**Toggle Switch (Sci-Fi):**
- Size: 44x22px, radius 2px
- Background: panel
- Border: 1px solid rgba(255,255,255,0.15)
- Indicator: 14x14px, radius 1px
- OFF: rgba(255,255,255,0.3), positioned left 3px
- ON: #22C55E, positioned left 25px, glow 0 0 8px

**Panel (.cmd-panel):**
- Background: #111122
- Border: 1px solid rgba(99,102,241,0.12)
- Padding: 16px
- Left accent bar: 3px wide, absolute, primary color, 50% opacity

**Radar Display (180px):**
- Outer circle: 1px border rgba(34,211,238,0.2)
- Inner circles: inset 20px (0.12 opacity), inset 40px (0.08 opacity)
- Sweep arm: 50% width, 2px height, gradient(90deg, cyan, transparent), rotates 360deg in 3s
- Dots: 8px circles, success color + glow

**Habit Status Row:**
- Padding: 10px 0
- Status dot (8px) + emoji (14px) + name (12px mono) + progress bar (4px height)
- Fill bar: dynamic width, color matches status
- Count: 11px mono, green+bold if complete

**Heatmap Cells:**
- Radius: 1px
- Empty: panel background
- l1: rgba(34,211,238,0.15)
- l2: rgba(34,211,238,0.3)
- l3: rgba(99,102,241,0.5) + 3px glow
- l4: rgba(99,102,241,0.8) + 5px glow
- Grid gap: 2px

### Animations

| Animation | Spec | Duration |
|-----------|------|----------|
| Boot line appear | translateY(4px)→0, opacity 0→1 | 0.3s ease, staggered 0.2-3.6s delays |
| Progress bar fill | width 0→100% | 1.2s ease, 0.9s delay |
| Blink cursor | border-color cyan→transparent | 1s infinite |
| Scan line | top -2px→100% | 4s linear infinite |
| Pulse glow | shadow 10px→25px+60px | 2s infinite |
| Data flicker | opacity 1→0.7→0.9→1 | 5s infinite |
| Radar sweep | rotate 0→360deg | 3s linear infinite |
| Status blink (green) | opacity 1→0.3→1 | 2s infinite |
| Status blink (amber) | opacity 1→0.4→1 | 1.5s infinite |
| Status blink (red) | opacity 1→0.3→1 | 1s infinite |
| Type expand | width 0→100% | 1.5s steps(N) forwards |
| Pulse text | opacity 0.4→1→0.4 | 2s infinite |
| Float up (particles) | translateY(0)→-200px, scale 1→0 | 2.5-3.5s infinite |
| Shimmer | left -100%→100% | 3s infinite |

---

## THEME PICKER UX

### Onboarding Theme Picker
- **Background:** #111111 (neutral)
- **Cards:** 170px wide, 200px+ tall, radius 20px
- **Card border:** 2.5px solid rgba(255,255,255,0.08)
- **Card background:** #1A1A1A
- **Selected Tactile:** border #6366F1, glow rgba(99,102,241,0.3), scale 1.02
- **Selected Command:** border #22D3EE, glow rgba(34,211,238,0.3), scale 1.02
- **Badge:** 24x24px circle with checkmark in theme accent color

### Button Morphing
- **Tactile selected:** Button becomes neumorphic (raised shadow, #E8ECF1 bg, #334155 text)
- **Command selected:** Button becomes terminal ("INITIATE >>", monospace, cyan border + glow, transparent bg)

### Settings Integration
- **Tactile settings:** Segmented control with raised/pressed states, neumorphic color dots
- **Command settings:** Monospace "> SYS.CONFIG" header, segmented control with cyan active state

### Transition Effect
- Split-screen with glowing crack line at center
- Cyan crack (4px, 0 0 20px + 0 0 40px glow) for Tactile→Command
- Indigo crack (4px, same glow pattern) for Command→Tactile
- Fading side: 0.5-0.6 opacity + 1px blur
- Appearing side: 0.85-0.9 opacity
