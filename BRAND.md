# HarvestHub — Brand Guidelines & Design System (Locked v1.0)


## 1. Brand Identity

HarvestHub represents freshness, direct farmer-to-consumer relationships,
and the warmth of local agriculture. The palette blends fresh **greens**
(growth, produce) with warm **autumn tones** (harvest, earthiness), plus a
neutral system-color set for payments and order status so those states
never get visually confused with brand color.

---

## 2. Color Palette

### Primary & Supporting

| Name | Hex | Usage |
|---|---|---|
| Main Green (Primary) | `#25995C` | Primary buttons, app bar, active icons, primary branding |
| Deep Green (Secondary) | `#0D5F4E` | Headers, footers, inactive states, typography accents, overlays |

### Autumn Accents (Harvest Theme)

| Name | Hex | Usage |
|---|---|---|
| Autumn Rust | `#D97736` | Highlight text, secondary buttons, "Restock Alerts", promo banners |
| Wheat Gold | `#ECA12A` | Ratings (stars), "New" badges, AI Assistant chat bubbles |
| Earthy Soil | `#6B4423` | Subtle borders, category cards for root vegetables/grains |

### System / Status Colors

| Name | Hex | Usage |
|---|---|---|
| Success | `#16A34A` | Payment successful, order confirmed, available pickup slots |
| Error | `#DC2626` | Payment declined, out-of-stock badges, cancel order actions |
| Warning | `#F59E0B` | Order pending, processing payment indicators |

### Neutrals / Surface

| Name | Hex | Usage |
|---|---|---|
| Background | `#F9FAFB` | App background — makes greens/autumn accents pop |
| Surface | `#FFFFFF` | Cards, elevated panels |
| Text Primary | `#1B1B1B` | Body copy |
| Text Secondary | `#6B7280` | Helper text, timestamps, placeholders |
| Border | `#E5E7EB` | Hairlines, input borders |

### Proposed Additions (added for completeness)

| Name | Hex | Rationale |
|---|---|---|
| Soft Green | `#DCF2E7` | Main Green has no light tint; needed for chip backgrounds, hover states, subtle section fills without falling back to gray |
| Disabled Green | `#A9CDBB` | A muted primary so disabled buttons read as "brand, but inactive" rather than generic gray |
| Scrim | `#0D5F4E` at 40% opacity | Modal/bottom-sheet overlay tied to the brand's deep green instead of default black |

These three are implemented in `app_colors.dart` but should be treated as
**proposed** until explicitly approved — everything above them in this
document is locked.

---

## 3. Typography

- **Typeface:** Poppins (via `google_fonts`), chosen for clean, highly
  legible letterforms at small sizes — satisfies the SRS §1.7
  Accessibility requirement ("clear and legible fonts").
- Full scale defined in `lib/presentation/theme/text_styles.dart`
  (`AppTextStyles`).

---

## 4. Logo Construction

The submitted brand art arrives as **layered pieces**, not one flat file.
Understanding the layering is what makes the splash animation possible:

| Asset | What it is |
|---|---|
| `leaf_swoosh_light.png` / `leaf_swoosh_medium.png` | The large leaf swoosh that sits behind/right of "Hub" |
| `leaf_sprout_bright.png` | The upper, brighter-teal leaflet of the small 2-leaf sprout above the "H" |
| `leaf_sprout_dark.png` | The lower, darker-teal leaflet of that same sprout |
| `wordmark_only.png` | "HarvestHub" text, no leaf elements |
| `logo_full_combined.png` | The official, pre-composited mark — **this is the authoritative logo file**; all other pieces exist to build the assembly animation toward it |

**Construction order (back to front):** swoosh leaf → sprout leaflets →
wordmark. This is also the order the splash-screen animation reveals them
in (see §5).

**Do:**
- Use `logo_full_combined.png` as-is for any static placement (headers,
  about screen, marketing).
- Use `logo_mark_transparent.png` (generated, mark-only) for anywhere a
  square/compact icon is needed and the wordmark would be illegible.

**Don't:**
- Recolor the leaf mark or wordmark.
- Stretch the logo to a non-original aspect ratio.
- Place the mark-only icon anywhere the full wordmark would fit — the
  wordmark should appear whenever there's room for it.

---

## 5. Animated Splash Concept

On cold launch, the mark **assembles itself** rather than appearing as a
static image:

1. **Swoosh leaf** fades and scales in from behind (0–45% of the timeline).
2. **Sprout leaflets** slide/fade in above the "H" (25–65%).
3. **Wordmark** slides up and fades in beneath (50–85%).
4. The hand-assembled pieces **crossfade into the real
   `logo_full_combined.png`** file (80–100%) — guaranteeing the resting
   frame is pixel-identical to the official logo, regardless of how the
   individual pieces were positioned during assembly.

Implemented in `lib/presentation/screens/splash/animated_logo.dart` and
hosted by `splash_screen.dart`. See `LAUNCHER_ICON_SETUP.md` for how this
relates to the separate, static **native** splash screen.

---

## 6. Generated Icon Set

Because the source art is flat 500×500px artwork with no square,
text-free version suitable for a launcher icon, one was produced by
cropping the swoosh mark and recompositing it at 1024×1024 (see
`LAUNCHER_ICON_SETUP.md` for the full file list and generation config).
This is flagged as **generated, not hand-designed** — acceptable as a
foundation, but worth a real design pass before store submission.

---

## 7. Directory Structure

```
lib/
├── presentation/               # UI Tier
│   ├── screens/
│   │   ├── splash/
│   │   │   ├── splash_screen.dart
│   │   │   └── animated_logo.dart
│   │   ├── customer/
│   │   ├── farmer/
│   │   └── admin/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── text_styles.dart
│   │   └── colors/
│   │       ├── app_colors.dart
│   │       └── status_colors.dart
│   └── widgets/
├── application/                 # Business Logic Tier
└── data/                        # Data Tier (Firebase repositories/models)

assets/
├── images/products/
├── icons/app_icon/              # generated launcher icon set
└── splash_screen/                # logo layers + combined logo
```

Full project-wide blueprint (all tiers, Firebase collections, screen
inventory) is in `PROJECT_BLUEPRINT.md`.
