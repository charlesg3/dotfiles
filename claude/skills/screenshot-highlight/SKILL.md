---
name: screenshot-highlight
description: Take a screenshot of the current live-session page, optionally draw a red highlight box around one or more elements with ImageMagick, crop to the footer, and copy to the clipboard. Use when asked to screenshot or highlight an element in the live-session web UI.
---

# Skill: screenshot-highlight

Take a screenshot of the current live-session page, optionally draw a red highlight box around one or more elements, crop to the footer, and copy to the clipboard.

**Invocation:** `/screenshot-highlight` — no arguments needed. Describe what to highlight in context.

## Step 0. Ask the user what to highlight

Before doing anything, ask: "Should I highlight a specific element, or just take the whole screen?" If highlighting, ask which element (or get it from context). Proceed once you know.

## Step 1. Set viewport and hide overlays

Run this in a single `live-session eval` block:

```js
await page.setViewport({ width: 1200, height: 2000 });
await new Promise(r => setTimeout(r, 300)); // let Reagent finish re-rendering
await page.evaluate(() => {
  document.querySelectorAll('.inspect-explore').forEach(el => el.style.display = 'none');
});
```

## Step 2. Get the bounding box (if highlighting a specific element)

Get bounding boxes in the same eval block as the viewport set, or in a second eval — but always AFTER setting the viewport (coordinates change with viewport size).

```js
// By class
const box = await page.$eval('.my-class', el => {
  const r = el.getBoundingClientRect();
  return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
});

// By heading text (when no good class exists)
const box = await page.evaluate(() => {
  const h4 = [...document.querySelectorAll('h4')].find(el => el.textContent.includes('My Heading'));
  const sibling = h4.nextElementSibling; // entry-field below the heading
  const r1 = h4.getBoundingClientRect();
  const r2 = sibling ? sibling.getBoundingClientRect() : r1;
  return {
    x: Math.round(Math.min(r1.x, r2.x)),
    y: Math.round(r1.y),
    w: Math.round(Math.max(r1.right, r2.right) - Math.min(r1.x, r2.x)),
    h: Math.round(r2.bottom - r1.y)
  };
});
```

## Step 3. Take the screenshot, cropped to the footer

**Important:** Use `.footer-container` for the crop — NOT `.footer` (which has zero height due to CSS) and NOT `footer` (not present). The crop height must be positive or Puppeteer throws.

```js
const clip = await page.evaluate(() => {
  const footer = document.querySelector('.footer-container');
  if (!footer) return null;
  const r = footer.getBoundingClientRect();
  const h = Math.round(r.bottom);
  if (h <= 0) return null; // guard against zero-height
  return { x: 0, y: 0, width: Math.round(document.documentElement.clientWidth), height: h };
});
await page.screenshot({ path: '/tmp/screenshot-raw.png', ...(clip ? { clip } : {}) });
```

## Step 4. Draw highlight box with ImageMagick

Red stroke, faint red fill, 6px padding:

```bash
X1=$((box_x - 6))
Y1=$((box_y - 6))
X2=$((box_x + box_w + 6))
Y2=$((box_y + box_h + 6))

convert /tmp/screenshot-raw.png \
  -strokewidth 3 -stroke "#e53e3e" -fill "rgba(229,62,62,0.08)" \
  -draw "rectangle ${X1},${Y1} ${X2},${Y2}" \
  /tmp/screenshot-highlighted.png
```

For multiple elements, chain additional `-draw` calls. If boxes overlap, use a single bounding box covering both.

Skip this step if the user just wants a clean full-page screenshot.

## Step 5. Copy to clipboard

```bash
xclip -selection clipboard -t image/png -i /tmp/screenshot-highlighted.png
```

(Use `/tmp/screenshot-raw.png` if no highlight was drawn.)

## Known pitfalls

- `page.waitForTimeout()` does not exist — use `new Promise(r => setTimeout(r, ms))`.
- `.footer` has `top: 0, bottom: 0` (zero height) — always use `.footer-container` for the crop.
- `clickElement(page, selector)` takes a **selector string**, not an element handle. It lives in `lib/ui.mjs` and is exported via `lib/actions.mjs` as `actions.clickElement`.
- If the crop height evaluates to 0 or negative, Puppeteer throws `'height' in 'clip' must be positive` — guard with `if (h <= 0) return null`.
- Always set the viewport and hide overlays before querying bounding boxes — layout shifts after `setViewport`.
