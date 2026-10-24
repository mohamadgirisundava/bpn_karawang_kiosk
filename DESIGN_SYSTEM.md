# Design System — BPN Karawang Kiosk

Living reference for the visual language of this app. Written so a future
session (human or Claude) can build a new screen that looks like it belongs,
without re-deriving these decisions from scratch. When in doubt, match what's
here rather than inventing a new pattern.

**This app shares one design system with `bpn_karawang_loket`** (Admin &
Petugas). Colors, radius scale, button variants, `CodeAvatar`,
`StatusBadge`, `BrandStripe`, and the facade illustration are the same
components in both repos — the kiosk versions only differ in that sizes go
through `Responsive` (see below). If you change one of them in either repo,
change the other too.

## Philosophy

- **Minimal, flat.** White surfaces on a very light grey background, 1px
  hairline borders, no gradients, no shadows. (The glossy "Aqua" buttons and
  avatars that used to live here — `GradientButton`, `GlossyAvatar`,
  `GlossyBadge` — were removed in the Oct 2026 redesign.)
- **Logo colors used sparingly, as markers.** Navy for primary actions and
  important numbers; gold for "this is yours / active"; green for "done";
  orange for priority/warning. Counters don't get per-counter accent colors
  (`CounterEntity.color` still exists, just isn't rendered as an accent).
- **The navy–gold–green stripe (`BrandStripe`) is the signature.** It sits on
  top of every header and at the bottom of the identity panel. It's the only
  ornament on the "taking a number" screens.
- **The facade illustration is for the screens outside the flow.** Idle,
  Istirahat, and Tutup use `IdentityLayout`: a navy panel with the office
  building's facade motif on the left, content on the right — the same layout
  as the Loket login screen. Don't put the illustration behind the service
  grid or ticket screens; there it competes with the numbers.
- **Tappable things say so.** Service cards and option cards end in a navy
  "Ambil nomor →" / "Pilih →" bar; back is a labeled "Kembali" button, not a
  bare arrow. Visitors include elderly people who rarely use touchscreens.
- **Never let the kiosk scroll.** See [Layout: never scroll](#layout-never-scroll).

## Color palette

Source: `lib/core/constants/app_colors.dart` — identical to Loket's.

| Token | Hex | Usage |
|---|---|---|
| `navy` | `#1B456F` | Primary buttons, numbers, tappable-card bars, identity panel. |
| `navySoft` | `#E8EEF5` | Tinted background for neutral highlight blocks ("Sisa antrian"). |
| `gold` | `#FACB1D` | Stripe, facade wave, printing spinner. Never as text on white. |
| `goldSoft` | `#FDF4D3` | Highlight block for the visitor's own number. |
| `green` | `#95C535` | Stripe only. |
| `success` | `#2E8B4E` | Success state (ticket printed, snackbar, printer OK). |
| `orange` / `orangeSoft` | `#C46829` / `#F8ECE3` | Priority badge, break/closed screens, printer warning. |
| `danger` | `#C93C3C` | Errors and destructive actions. Use this, never `Colors.red`. |
| `lightBlue` / `lightBlueSoft` | `#2C8FD0` / `#E6F2FA` | Info banner. |
| `background` | `#F4F6F9` | Scaffold background. |
| `white` | `#FFFFFF` | Cards, header, footer, dialogs. |
| `textDark` | `#15273A` | Headings and body text. |
| `textMuted` | `#56677A` | Labels, captions. |
| `border` | `#E2E7EE` | Card borders, dividers. |
| `borderStrong` | `#AFBBC8` | Outlined (secondary) button and "Kembali" button borders. |
| `onNavyMuted` | 80% white | Secondary text on the navy identity panel. |

**Rule:** don't introduce a new color for a new component. A tinted
background is `Color.alphaBlend(color.withValues(alpha: 0.1), white)` of an
existing token — that's how `CodeAvatar` and `StatusBadge` work.

## Typography

Two self-hosted variable fonts (offline-safe, no CDN), same split as Loket:

- **`NunitoSans`** (`AppTheme.fontFamily`) — default for all text, set in
  `AppTheme.light`.
- **`Nunito`** (`AppTheme.numberFamily`) — queue numbers, the clock, and
  service codes. Its rounded digits match the printed ticket and the Loket
  operator screen. Always pair with
  `fontFeatures: [FontFeature.tabularFigures()]`.

All font sizes go through `Responsive.sp()` — never a bare number.

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

`KioskScaler` (in `main.dart`'s builder) renders the whole app on a fixed
1920×1080 canvas and scales it to the real screen, so in practice
`sp/w/r` are always ×1.5 and `h` is ×~1.05. A Loket size of `15` therefore
becomes `Responsive.sp(15)` here and looks the same relative to the screen.

Because `Responsive` isn't initialized until the first screen builds,
`AppTheme.light` (built earlier) only holds colors and fonts. Sizes for
dialogs, buttons etc. live in the widgets (`KioskDialog`, `AppButton`, …).

### ⚠️ The one gotcha that has caused real bugs: `h()` vs `sp()`/`w()`

`sp()`/`w()`/`r()` share one scale (width-based); `h()` uses a different,
height-based one. If you give a box a fixed `height:` computed with `h()` but
size its text with `sp()`, the box and text scale at different rates and the
box ends up squashed or oversized.

**Rules:**
- **Never set an explicit `height:`** on anything containing `sp()` text
  (buttons, badges, header bars). Derive height from vertical padding in
  `sp()` units instead. `AppButton`, `KioskHeader` and `AppFooter` all do
  this.
- `h()` is fine for **pure vertical spacers** (`SizedBox(height: h(N))`).
- `w()` is fine everywhere for horizontal spacing/sizing.

### Grid columns

`Responsive.gridColumns`: 3 columns if width > 900, 2 if > 500, else 1.

## Spacing & radius

Source: `lib/core/constants/app_radius.dart` — same values as Loket, through
`Responsive.r()`:

| Token | Base | Used for |
|---|---|---|
| `AppRadius.control` (= `button`, `chip`) | 6 | Buttons, code boxes, menu rows |
| `AppRadius.card` | 8 | Number blocks, info boxes |
| `AppRadius.cardLarge` | 10 | Service cards, panels, dialogs |
| `AppRadius.badge` | 4 | `StatusBadge` |

- **Borders:** `Border.all(color: AppColors.border)`, 1px, unscaled.
- **Dividers:** `const Divider()` — the theme makes it 1px `border`.
- **Screen padding:** `Responsive.w(80)` horizontal, `Responsive.h(40–48)`
  vertical on content screens.

## Components

All in `lib/presentation/widgets/`.

### `AppButton` (`app_button.dart`)

The only filled/outlined button. Variants: `primary` (navy), `secondary`
(white, `borderStrong` outline, navy text), `destructive`, `success`,
`warning`. `large: true` for the main visitor action on a screen ("Ambil
Tiket", "Cetak Tiket Antrian", "Selesai"). `loading: true` keeps the color
and shows a spinner at the same height.

Tertiary text buttons ("Batal", "Tutup") use `AppButtonStyles.text()`.

### Header — `KioskHeader` (`brand.dart`)

White, `BrandStripe` on top, 1px divider at the bottom. Left side is either
`BrandLockup` (logo + "Kantor Pertanahan / Kabupaten Karawang", home screen;
`onLogoLongPress` opens the hidden satpam menu) or `KioskBackButton` (every
other screen). Then a vertical hairline, the screen title, and `trailing`
(usually `ClockWidget`).

### `IdentityLayout` + `FacadePainter` (`brand.dart`)

Idle / Break / Closed screens. Left 5/9: navy panel, facade motif, logo +
office name at the top (long-press target on Break/Closed), big title at the
bottom, `BrandStripe` along the bottom edge. Right 4/9: white, content
centered, left-aligned column starting with a large `CodeAvatar` icon.

`FacadePainter(scale: Responsive.scaleFactor)` — the scale keeps bar density
identical to the Loket login panel.

### Service card (home) and option card (applicant type)

`Material` white, 1px `border`, `cardLarge` radius, `Clip.antiAlias`,
`InkWell`. Content on top; a full-width navy bar at the bottom with the action
label and `arrow_forward_rounded` — that bar is the tappability cue. No
shadow. Service card: `CodeAvatar` code + name (muted) + description (bold)
+ `StatusBadge('Prioritas')` if priority; divider; two `_CardStat` numbers
(Sedang dilayani / Menunggu).

### `Panel`, `SectionLabel` (`brand.dart`)

`Panel` is the white bordered container (`cardLarge`). Pass
`padding: EdgeInsets.zero` and use `Divider`s between sections for
multi-part cards (ticket confirm, printed ticket). `SectionLabel` is the
small muted label above a number.

### `CodeAvatar`, `StatusBadge`

`CodeAvatar`: tinted square (or circle) with a service code or icon in full
color — service codes, dialog title icons, menu row icons, state icons on
Idle/Break/Closed and the ticket result. `StatusBadge`: tinted label in
sentence case ("Prioritas", "Sedang istirahat"), not uppercase.

### Dialogs — `KioskDialog` (`kiosk_dialog.dart`)

Every confirmation: `CodeAvatar` icon + bold title, muted body text,
actions `TextButton(style: AppButtonStyles.text())` + `AppButton`. Use the
icon color for severity (`danger` for Reset/Keluar, `orange` for Tetap Buka).

### Printed-ticket card

On the result screen the card imitates the paper ticket: `BrandStripe`,
logo + office + service, divider, "Nomor antrian Anda" with the number at
`sp(52)` Nunito, divider, date/time/queue rows, grey footnote strip. When
printing fails this is the visitor's only proof, so the number stays big
enough to photograph.

### Layout: never scroll

The kiosk is a fixed-size touchscreen; nothing should ever require the user
to scroll.

- **Repeating item grids** (service selection, queue-info cards): a
  `LayoutBuilder` computes `childAspectRatio` from the *actual* available
  width/height divided by the *actual* row/column count, then
  `GridView.builder` with `physics: const NeverScrollableScrollPhysics()`.
  The grid always exactly fills its space and reflows as the item count
  changes. Cards use a `Spacer` between their top and bottom halves so they
  stretch with the cell.
- **Single-block content that might be too tall** (ticket confirm view,
  ticket result view): wrap in `FittedBox` with the child `Column` set to
  `mainAxisSize: MainAxisSize.min`. If it fits, it renders at natural size;
  if not, the whole block scales down uniformly.
