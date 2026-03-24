# Design System Specification: The Monolithic Narrative

## 1. Overview & Creative North Star: "Hyper-Focus Brutalism"
This design system is not a utility; it is a high-performance instrument. Designed for the Vercel mobile ecosystem, the Creative North Star is **Hyper-Focus Brutalism**. 

We move beyond the "app" feel to create an "environment." This is achieved by stripping away the chrome of traditional mobile UI—no dividers, no heavy borders, and no unnecessary decorations. Instead, we use **intentional asymmetry** and **tonal layering** to guide the developer’s eye. The interface should feel like a high-end editorial terminal: authoritative, lightning-fast, and sophisticated. We prioritize content density without clutter, using extreme contrast to highlight what matters (code, deployment status) and subtle grays to recede everything else.

---

## 2. Colors: High-Contrast Monochromatism
The palette is rooted in absolute blacks and whites, utilizing the Material-mapped tokens to create depth in a dark-default environment.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning or containment. 
Boundary definition must be achieved through:
1.  **Background Color Shifts:** A `surface-container-low` (#1B1C1C) section sitting on a `surface` (#121414) background.
2.  **Negative Space:** Utilizing the `spacing-8` (2rem) or `spacing-10` (2.5rem) tokens to create "air" between logical blocks.

### Surface Hierarchy & Nesting
Treat the UI as a series of stacked, physical layers. 
- **Base Layer:** `surface` (#121414)
- **Secondary Containers:** `surface-container-low` (#1B1C1C) for grouped content.
- **Priority Elements:** `surface-container-high` (#292A2A) for active cards or interactive modules.
- **Deep Nesting:** For code blocks or terminal outputs, use `surface-container-lowest` (#0D0E0F) to "carve" into the page.

### The "Glass & Gradient" Rule
To elevate the "sophisticated" persona, floating elements (like Bottom Sheets or Navigation Bars) must use **Glassmorphism**.
- **Token:** `surface-variant` (#343535) at 70% opacity.
- **Effect:** `backdrop-blur: 20px`. 
- **Signature CTA Texture:** Main Action Buttons should use a subtle linear gradient from `primary` (#FFFFFF) to `secondary-fixed-dim` (#C6C6C7) at a 45-degree angle to provide a metallic, premium sheen.

---

## 3. Typography: The Geist Aesthetic
We utilize the **Geist/Inter** family to convey technical precision. The hierarchy is designed for "skimmability"—developers need to find the error or the build URL in milliseconds.

- **Display & Headline (The Editorial Voice):** Use `display-md` (2.75rem) with tight letter-spacing (-0.04em). These are for "Big Moments" like deployment success counts.
- **Title & Body (The Content):`title-sm` (1rem) for card headers; `body-md` (0.875rem) for metadata.
- **Label (The Metadata):** Use `label-sm` (0.6875rem) in all-caps with increased letter-spacing (0.05em) for deployment environments (e.g., PRODUCTION, PREVIEW).

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are too "software-standard." We use light to define space.

- **The Layering Principle:** Place a `surface-container-lowest` (#0D0E0F) card on a `surface-container-low` (#1B1C1C) background to create a "recessed" look for logs.
- **Ambient Shadows:** For floating Modals, use a shadow with a 40px blur at 6% opacity, using the `on-surface` (#E3E2E2) color. It should feel like a soft glow from the screen rather than a drop shadow.
- **The "Ghost Border" Fallback:** If a border is required for accessibility in high-light environments, use `outline-variant` (#444748) at **15% opacity**. This creates a whisper of a line that defines the edge without breaking the "No-Line" rule.

---

## 5. Components

### Buttons (The Kinetic Tools)
- **Primary:** `primary` (#FFFFFF) background, `on-primary` (#2F3131) text. Sharp `radius-sm` (0.125rem) for a brutalist feel.
- **Secondary:** Transparent background with the "Ghost Border" and `primary` text.
- **Building State:** A linear-gradient animation using `primary` and `surface-bright` (#383939) moving left to right.

### Cards & Lists (The Narrative Flow)
- **Constraint:** Never use a divider line. 
- **Pattern:** Use a `surface-container-low` background for the card. For list items within the card, use a `surface-variant` background on hover/press to indicate interactivity.
- **Status Indicators:** 
    - **Success:** Solid `6px` circle in Vercel Green (derived from custom branding).
    - **Error:** `error` (#FFB4AB) text with a `error-container` (#93000A) subtle glow.
    - **Building:** `secondary` (#C7C6C6) with a pulse animation.

### Deployment Input Fields
- **Styling:** `surface-container-lowest` background. No border. On focus, the bottom edge gains a 2px `primary` (#FFFFFF) "underline" indicator.
- **Micro-copy:** All helper text must use `label-sm` in `on-surface-variant` (#C4C7C8).

### Navigation (The Horizon)
- **Bottom Nav:** Full `backdrop-blur` (20px) with `surface-container` at 80% opacity. 
- **Active State:** No icons in boxes. Use a single 4px white dot (`primary`) below the active icon.

---

## 6. Do’s and Don’ts

### Do
- **Do** use `surface-container-highest` for "active" or "pressed" states to create a tactile feel.
- **Do** lean into white space. If a screen feels crowded, increase the spacing from `spacing-4` to `spacing-8`.
- **Do** use high-contrast `on-background` white text for primary headers to ensure professional authority.

### Don't
- **Don't** use generic rounded corners. Stick to `DEFAULT` (0.25rem) or `sm` (0.125rem). Avoid `xl` unless it’s a pill-shaped status badge.
- **Don't** use pure grey (#888888) for text if readability is a priority; use `on-surface` (#E3E2E2) to keep the "high-end" glow.
- **Don't** add "Close" buttons to every modal—allow "tap-to-dismiss" on the background to maintain the minimalist aesthetic.