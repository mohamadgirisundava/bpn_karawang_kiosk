# Design System — BPN Karawang Kiosk

Living reference for the visual language of this app. Written so a future
session (human or Claude) can build a new screen that looks like it belongs,
without re-deriving these decisions from scratch. When in doubt, match what's
here rather than inventing a new pattern.

This app shares its brand palette with the companion display app
(`bpn_karawang_display`, the TV/monitor screen at the physical counters) —
same navy/gold identity, same flat card language. If you're touching both
repos, keep them visually in sync.

## Philosophy

- **Flat, not skeuomorphic.** No gradients, no heavy shadows, no pill-shaped
  buttons. One consistent small radius everywhere.
- **One navy identity, not per-item colors.** Counters/loket used to each get
  their own accent color (`CounterEntity.color`) rendered per-card. That's
  gone from the presentation layer — every screen now uses the same
  navy/gold/neutral palette regardless of which counter is displayed. The
  `color`/`icon` fields still exist on `CounterEntity` (backend-driven), just
  don't render them as a per-card accent anymore.
- **Minimal iconography.** The loket-selection menu and the info cards
  deliberately have no decorative icons (matches the display app). Icons are
  used only functionally: back arrow, refresh, print, admin gear — never as
  a "this counter is X" identity marker.
- **Never let the kiosk scroll.** It's a fixed 7" touchscreen. See
  [Layout: never scroll](#layout-never-scroll).

## Color palette

Source: `lib/core/constants/app_colors.dart`.

| Token | Hex | Usage |
|---|---|---|
| `AppColors.navy` | `#1B456F` | Primary brand color. Headers, primary buttons, headings, tappable-card accent bar. |
| `AppColors.gold` | `#FACB1D` | CTA highlight (e.g. "Cetak Tiket") and the accent border under every header bar. |
| `AppColors.goldLight` | `#EFCF47` | Text-on-navy accents (header subtitle, clock date). |
| `AppColors.green` | `#95C535` | Success *state* only (e.g. success checkmark). Not a brand accent. |
| `AppColors.orange` | `#C46829` | Priority/warning semantic only (PRIORITAS badge). |
| `AppColors.orangeLight` | `#E6A62B` | Reserved variant of orange. |
| `AppColors.lightBlue` | `#2C8FD0` | Reserved accent, not currently used in presentation layer. |
| `AppColors.olive` | `#D2B845` | Reserved variant. |
| `AppColors.white` | `#FFFFFF` | Card backgrounds, text-on-navy. |
| `AppColors.background` | `#EEF2F6` | Screen background (scaffold). |
| `AppColors.textDark` | `#1B2E40` | Primary body text on light backgrounds. |
| `AppColors.textMuted` | `#5C7488` | Secondary/caption text, muted labels. |
| `AppColors.border` | `#DBE3EA` | Card borders, divider lines. |
| `AppColors.danger` | `#D64545` | Reserved for error states (distinct from `Colors.red` used ad hoc for destructive buttons — see [known inconsistency](#known-inconsistencies)). |

**Rule:** don't introduce a new color for a new component. Pick from this
table. If a semantic case doesn't fit (not primary, not destructive, not
priority, not success), it's `navy` by default.

## Typography

Two self-hosted variable fonts (offline-safe, no CDN):

- **`Nunito`** — default body font, set as `ThemeData.fontFamily` in
  `main.dart`. Used for everything unless explicitly overridden.
- **`NunitoSans`** — header font. Explicitly set via `fontFamily:
  'NunitoSans'` on text inside the navy header bar of every screen (title,
  subtitle, and the `ClockWidget` time/date). Nowhere else.

Font files live in `assets/fonts/` (`Nunito-Variable.ttf`,
`NunitoSans-Variable.ttf`), declared in `pubspec.yaml` at weights 400/500/600/700.

All font sizes go through `Responsive.sp()` — never a bare number. See below.

## Responsive scaling system

Source: `lib/core/utils/responsive.dart`. Call `Responsive.init(context)` once
at the top of every screen's `build()` before using any of the helpers below.

```dart
_scaleFactor = (screenWidth / 600).clamp(0.85, 1.5);

sp(size) => size * _scaleFactor;              // font size
w(size)  => size * _scaleFactor;               // horizontal dimension/padding
r(size)  => size * _scaleFactor;               // border radius
h(size)  => size * (screenHeight / 1024);      // vertical dimension/padding
```

### ⚠️ The one gotcha that has caused real bugs: `h()` vs `sp()`/`w()`

`sp()`/`w()`/`r()` all share one scale, based on **width** (baseline 600).
`h()` uses a **different, independent** scale based on **height** (baseline
1024, assuming a tall portrait device). On this kiosk's actual landscape
orientation, these two scales diverge a lot — width-scale can be clamped at
1.5x while height-scale sits around 0.6x on the same screen.

**Consequence:** if you give a button/container a fixed `height:` computed
with `Responsive.h()`, but its text is sized with `Responsive.sp()`, the box
and the text scale at different rates and the button ends up squashed or
oversized depending on aspect ratio. This exact bug hit multiple buttons this
session and was fixed by removing the fixed height everywhere.

**Rules:**
- **Never set an explicit `height:`** on anything containing text sized with
  `sp()` (buttons, badges, header bars). Let height be intrinsic — derive it
  from `EdgeInsets.symmetric(vertical: Responsive.sp(N))` padding instead of
  a `SizedBox`/`Container` height. This is why `AppButtonStyles` never
  specifies a height.
  - Header bars are an accepted exception (see [Header bar](#header-bar)) —
    their vertical padding legitimately uses `h()` because they're pure
    chrome with no button-style height/text coupling.
- `h()` is fine for **pure vertical spacers** (`SizedBox(height: Responsive.h(N))`
  between two elements) and decorative fixed-height lines (divider bars,
  border widths) that aren't wrapping scaled text.
- `w()` is fine everywhere for horizontal spacing/sizing since it shares
  `sp()`'s scale.

### Grid columns

`Responsive.gridColumns`: 3 columns if width > 900, 2 if > 500, else 1.

## Spacing & radius

- **Border radius:** always `BorderRadius.circular(Responsive.r(4))`. No
  other radius value is used anywhere in the app. Never a bare `4` — that
  breaks scaling (see [known inconsistencies](#known-inconsistencies) for the
  one place this still needs cleanup).
- **Card border:** `Border.all(color: AppColors.border)`, 1px (unscaled — a
  hairline border doesn't need to scale).
- **Outer screen padding:** roughly `Responsive.w(14–20)` depending on
  screen — kept compact, not generous. Don't reach for 24–32; that reads as
  "too loose" on a small kiosk screen (this was explicitly trimmed down this
  session).

## Components

### Buttons — `AppButtonStyles`

Source: `lib/core/constants/app_button_styles.dart`. **Every** button in the
app must use one of these three — never inline `ElevatedButton.styleFrom(...)`
etc. This is the single source of truth for button height, padding, font,
and radius; only color varies per call site.

```dart
AppButtonStyles.elevated({Color? background, Color? foreground})
// Filled button. Default navy/white. Override for semantic color:
//   background: Colors.red   → destructive (e.g. "Keluar")
//   background: AppColors.gold, foreground: AppColors.navy → CTA highlight (e.g. "Cetak Tiket")

AppButtonStyles.outlined({Color? color})
// Bordered secondary button. Default navy border/text.

AppButtonStyles.text({Color? color})
// Plain text button (dialog "Batal", "Kembali", etc). Default textMuted.
```

Shared shape across all three: `EdgeInsets.symmetric(horizontal: w(24),
vertical: sp(14))` (text button uses `w(16)`/`sp(12)`), radius `r(4)`, font
`Nunito` `sp(16)` (bold for elevated), icon size `sp(20)`. No explicit
`height:` — see the [h() vs sp() gotcha](#️-the-one-gotcha-that-has-caused-real-bugs-h-vs-spw)
above for why.

### Header bar

Every screen (`home_screen`, `queue_info_screen`, `ticket_screen`) opens with
the same chrome:

- `Container` filling width, `color: AppColors.navy`.
- Bottom border: `BorderSide(color: AppColors.gold, width: Responsive.h(3))`.
- Padding: `top: MediaQuery.padding.top + Responsive.h(10)`, `bottom:
  Responsive.h(10)`, `left: Responsive.w(8–14)`, `right: Responsive.w(14)`.
- Leading element: logo (home screen, long-press opens hidden admin menu) or
  a back-arrow `IconButton` (utility screens), `size: Responsive.sp(20)`.
- Title text: `fontFamily: 'NunitoSans'`, bold, white. Home screen also has a
  goldLight subtitle line beneath it. Utility screens (`queue_info`,
  `ticket`) use a single-line title at `Responsive.sp(16)`.
- Trailing: `ClockWidget` on the home screen (also `NunitoSans`), or an empty
  `SizedBox(width: Responsive.w(40))` spacer to visually balance the leading
  `IconButton` on utility screens.

### Cards

Two distinct card patterns exist for two distinct purposes — don't blend
them.

**1. Menu card** (home screen's loket-selection grid — the thing the user
*taps* to take an action):

- White bg, `Border.all(color: AppColors.border)`, radius `r(4)`.
- Stronger shadow than info cards — signals tappability:
  `BoxShadow(color: AppColors.navy.withValues(alpha: 0.14), blurRadius: 8,
  offset: Offset(0, 3))`.
- A `Responsive.h(4)` solid navy bar pinned to the bottom edge
  (`Positioned(left: 0, right: 0, bottom: 0, ...)`, needs `clipBehavior:
  Clip.antiAlias` on the parent `Container` so it respects the corner
  radius) — this is the tappability cue, not the card border.
- Content: name (bold navy) + description (muted) centered, then a small
  pill row showing "now serving" + "waiting count". **No icon.**
- `PRIORITAS` badge, when present, is a `Positioned(top: 0, right: 0)`
  overlay with only the outer corner rounded — never a normal
  Column child. (It was a Column child originally; that pushed the rest of
  the content down and broke vertical centering. Wrap the main content in
  `Positioned.fill` inside the same `Stack` so it keeps filling the card —
  a bare `Stack` gives its children *loose* constraints, so without
  `Positioned.fill` the content shrinks to its intrinsic size and sticks to
  the top-left instead of centering.)

**2. Info/display card** (queue-info screen's per-counter status card, and
the final "your ticket number" card) — mirrors the counter-card component in
the companion display app:

- Same white/border/radius as above, but the flat shadow tier: `alpha 0.08,
  blurRadius: 3, offset: Offset(0, 1)`.
- Header: counter name **uppercase**, small, muted, bold-ish
  (`letterSpacing: 0.6`) — not the card's main focal point.
- A 1px `Container(height: 1, color: AppColors.border)` divider directly
  under the header.
- The number (queue code) is the visual focus: large, bold, navy,
  `fontFeatures: [FontFeature.tabularFigures()]` (keeps digits aligned
  as they change).
- Same `PRIORITAS` badge convention as the menu card (`Positioned` corner
  overlay, not a content-flow child).

### Dialogs

`AlertDialog` with `shape: RoundedRectangleBorder(borderRadius:
BorderRadius.circular(Responsive.r(4)))`. Title is a `Row` of `Icon`
(navy, `sp(28)`) + `SizedBox(width: w(8))` + bold navy `Text` (`sp(18)`).
Body text `sp(14)`, `textMuted`. Actions use `AppButtonStyles.text()` /
`.elevated()` — never inline-styled.

### Layout: never scroll

The kiosk is a fixed-size touchscreen; nothing should ever require the user
to scroll.

- **Repeating item grids** (loket selection, queue-info cards): a
  `LayoutBuilder` computes `childAspectRatio` from the *actual* available
  width/height divided by the *actual* row/column count for the current item
  list, then `GridView.builder` with `physics: const
  NeverScrollableScrollPhysics()`. This means the grid always exactly fills
  its space and reflows cell size as the item count changes — it never
  needs scroll and never clips.
- **Single-block content that might be too tall** (ticket confirm view,
  ticket result view): wrap in `FittedBox(fit: BoxFit.scaleDown)` with the
  child `Column` set to `mainAxisSize: MainAxisSize.min`. If it fits, it
  renders at natural size; if it doesn't, the whole block scales down
  uniformly — never crops, never needs `SingleChildScrollView`.

## Known inconsistencies

Kept here instead of silently fixed so they're a deliberate backlog item, not
a surprise:

- `Colors.red` (Flutter's default Material red) is used directly in several
  places — the "Keluar Aplikasi" destructive button, the "PIN salah"
  snackbar, the exit list-tile icon, and the network-error icon
  (`Colors.red.shade300`) — instead of `AppColors.danger` (`#D64545`).
  They're visually close but not identical. Worth reconciling to
  `AppColors.danger` everywhere, or formally adopting `Colors.red` as the
  danger color and removing `AppColors.danger` if it's meant to be the same
  thing.
