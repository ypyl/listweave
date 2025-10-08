# Height Consistency Fix - Edit vs View Mode

## Problem
Edit mode textarea height (29px) was inconsistent with view mode height (28.8px), causing visual jumps when switching between modes.

## Root Cause
1. **CSS Normalize Conflict**: The normalize CSS set `line-height: 1.15` for textarea elements, overriding the intended `line-height: 1.8`
2. **AutoResize Function**: Used `scrollHeight` which calculated height differently than view mode's line-height-based rendering

## Solution

### 1. CSS Fix (styles.css)
```css
/* Override normalize line-height for textarea */
textarea {
  line-height: 1.8 !important;
}
```

Remove conflicting rule from normalize section:
```css
/* REMOVED: line-height: 1.15; from textarea rules */
button,
input,
optgroup,
select,
textarea {
  font-family: inherit;
  font-size: 100%;
  margin: 0;
}
```

### 2. JavaScript AutoResize Fix (index.html)
```javascript
function autoResize() {
  const lineHeight = 1.8;
  const fontSize = parseFloat(getComputedStyle(this).fontSize);
  const lines = this.value.split('\n').length;
  const calculatedHeight = lines * lineHeight * fontSize;
  this.style.height = calculatedHeight + "px";
}
```

**Before**: Used `scrollHeight` which was inconsistent
**After**: Calculate height = lines × line-height × font-size

## Key Principles
- Both edit and view modes must use identical `line-height: 1.8`
- Height calculation must be deterministic and consistent
- CSS specificity issues require `!important` or rule removal
- JavaScript height calculation should match CSS rendering logic

## Files Modified
- `src/styles.css`: Added textarea line-height override, removed normalize conflict
- `index.html`: Updated autoResize function to use consistent calculation