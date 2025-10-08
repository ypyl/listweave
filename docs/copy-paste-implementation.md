# Copy/Paste Implementation

## User Interface
- Alt+X: Cut current item (only when item is in edit mode)
- Alt+V: Paste cut item after currently selected item
- Esc: Restore cut item to original position (takes priority over popup dismissal when clipboard not empty)

## Behavior
- Cut item should be removed from original position and stored in clipboard
- Paste should insert the cut item with all its children after target item
- Only one item can be in clipboard at a time
- "Currently selected item" = item that is currently in edit mode
- Focus stays on current item after paste/restore operations
- If clipboard is empty, Alt+V should do nothing
- If trying to cut when clipboard not empty, restore previous cut item first, then cut new item
- Alt+V only works when an item is in edit mode (target for paste)

## Implementation Details

### Model Changes
- Add `clipboard : Maybe ListItem` to Model
- Add `clipboardOriginalPosition : Maybe (Maybe Int, Int)` to Model
- clipboardOriginalPosition stores (parentId, childIndex) where Nothing parentId = root level

### Messages
- Add CutItem, PasteItem, and RestoreCutItem messages

### Event Handling
- In viewEditableItem onKeyDown, handle Alt+X (Other 88) and Alt+V (Other 86)
- Handle Esc key to restore cut item (takes priority over popup dismissal when clipboard not empty)

### Operations
- Cut: remove item from tree using deleteItem, store in clipboard with original position
- Paste: insert clipboard item after target using insertItemAfter at same level, clear clipboard
- Esc: restore clipboard item to original position using insertItemAfter, clear clipboard
- For root level items: use list index and special handling in restoration logic