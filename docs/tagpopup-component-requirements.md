# TagPopup Component Extraction Requirements

## Task Overview

Extract the tag autocomplete popup functionality from Main.elm into a separate TagPopup component following Elm's parent-child component architecture pattern.

### User Story
As a user typing @tag syntax in a list item, I want to see a popup with matching tag suggestions that I can navigate and select using keyboard shortcuts, so that I can quickly reference existing tags without typing them fully.

### Success Criteria
- TagPopup component is fully extracted from Main.elm
- All existing popup functionality is preserved
- Component follows Elm Architecture (TEA) pattern
- Clean parent-child message passing interface
- No regression in user experience

## Technical Requirements

### Functional Requirements

1. **Tag Autocomplete Display**
   - Show popup when user types @tag syntax
   - Display matching tags filtered by prefix
   - Position popup relative to cursor position
   - Hide popup when not needed

2. **Keyboard Navigation**
   - Up/Down arrows to navigate through tag suggestions
   - Enter to select highlighted tag
   - Escape to dismiss popup
   - Left/Right arrows to dismiss popup when not in tag context

3. **Tag Selection**
   - Insert selected tag at cursor position
   - Replace partial tag text with complete tag
   - Update cursor position after insertion

4. **Visual Feedback**
   - Highlight currently selected tag
   - Consistent styling with application theme
   - Proper positioning and sizing

### Non-Functional Requirements

1. **Performance**
   - Minimal re-rendering when popup state changes
   - Efficient tag filtering
   - Smooth keyboard navigation

2. **Usability**
   - Popup appears instantly when typing @tag
   - Intuitive keyboard shortcuts
   - Clear visual indication of selected item

### Integration Requirements

1. **Parent Component Interface**
   - Clean message passing for popup events
   - State synchronization with parent
   - Cursor position coordination

2. **Dependencies**
   - TagsUtils module for tag parsing
   - ListItem module for tag extraction
   - Browser ports for cursor positioning

## Implementation Approach

### New Module Structure

**File**: `src/TagPopup.elm` ✅ IMPLEMENTED

```elm
module TagPopup exposing 
    ( Model, Msg(..), init, update, view
    , isVisible, getHighlightedTag, getTags, setTags
    )

-- Component state
type alias Model = 
    { position : Maybe (Int, Int, Int)  -- top, left, width
    , tags : Maybe (List String)
    , highlightedTag : Maybe String
    }

-- Component messages  
type Msg
    = Show (Int, Int, Int) (List String)
    | Hide
    | NavigateUp
    | NavigateDown
    | HighlightTag String

-- Uses nested Elm architecture pattern with Html.map
-- No Config type needed - parent uses Html.map TagPopupMsg
```

### Affected Files

1. **Main.elm** - Remove popup-related code, integrate TagPopup component
2. **src/TagPopup.elm** - New component module
3. **No changes to TagsUtils.elm** - Reuse existing tag utilities

### Data Structure Changes ✅ IMPLEMENTED

**Main.elm Model Changes:**
```elm
-- REMOVED these fields:
-- , popup : Maybe ( Int, Int, Int )
-- , popupTags : Maybe (List String)  
-- , currentHighlightedTag : Maybe String

-- ADDED this field:
, tagPopup : TagPopup.Model
```

**Main.elm Msg Changes:**
```elm
-- REMOVED unused messages:
-- | ChangeCurrentHighlightedTag String (no longer needed)

-- ADDED this message:
| TagPopupMsg TagPopup.Msg
```

### UI/UX Changes

- No visual changes to end user
- Same popup positioning and styling
- Identical keyboard navigation behavior
- Same tag selection functionality

### Port Requirements

- Reuse existing `requestCursorPosition` port
- Reuse existing `receiveCursorPosition` port  
- No new JavaScript interop needed

## Acceptance Criteria

### Testable Conditions

1. **Popup Display**
   - [x] Popup appears when typing @tag syntax
   - [x] Popup shows filtered tags matching prefix
   - [x] Popup positioned correctly relative to cursor
   - [x] Popup hidden when not in tag context

2. **Keyboard Navigation**
   - [x] Up arrow highlights previous tag
   - [x] Down arrow highlights next tag
   - [x] Enter selects highlighted tag
   - [x] Escape dismisses popup
   - [x] Left/Right arrows dismiss popup outside tag context

3. **Tag Selection**
   - [x] Selected tag replaces partial @tag text
   - [x] Cursor positioned after inserted tag
   - [x] Popup dismissed after selection
   - [x] Content updated correctly

4. **Component Integration**
   - [x] TagPopup.elm compiles without errors
   - [x] Main.elm integrates component correctly
   - [x] No circular dependencies
   - [x] Clean message passing interface

### Edge Cases

1. **Empty Tag List**
   - Popup hidden when no matching tags
   - No errors when navigating empty list

2. **Single Tag**
   - Navigation wraps correctly
   - Selection works with one item

3. **Cursor Positioning**
   - Handles cursor at tag boundaries
   - Works with multi-line content
   - Proper positioning near screen edges

4. **Rapid Typing**
   - Popup updates smoothly during fast typing
   - No flickering or positioning issues

### Error Scenarios

1. **Invalid Cursor Position**
   - Graceful handling of invalid positions
   - Fallback positioning when calculation fails

2. **Missing Tags**
   - Handle empty tag collections
   - No runtime errors with malformed data

## Implementation Notes

### Potential Challenges

1. **State Synchronization**
   - Keeping popup state in sync with parent
   - Managing cursor position updates
   - Coordinating with text editing

2. **Message Routing**
   - Proper parent-child message passing
   - Avoiding message loops
   - Clean separation of concerns

3. **Positioning Logic**
   - Extracting cursor positioning from Main.elm
   - Maintaining accurate popup placement
   - Handling edge cases near screen boundaries

### Dependencies

- No new external dependencies
- Reuse existing TagsUtils functions
- Maintain compatibility with current ports

### Performance Considerations

- Use Html.Lazy for popup rendering
- Minimize state updates
- Efficient tag filtering algorithms
- Avoid unnecessary re-renders

### Testing Strategy

- Unit tests for component logic
- Integration tests with parent component
- Manual testing of keyboard navigation
- Edge case validation

## Migration Plan

1. **Phase 1**: Create TagPopup.elm with basic structure ✅
2. **Phase 2**: Extract view functions from Main.elm ✅
3. **Phase 3**: Extract update logic and messages ✅
4. **Phase 4**: Integrate component into Main.elm ✅
5. **Phase 5**: Test and validate functionality ✅
6. **Phase 6**: Clean up unused code in Main.elm ✅

## Implementation Results

### ✅ COMPLETED SUCCESSFULLY

**Created TagPopup.elm module** with complete TEA architecture:
- `Model` type with position, tags, and highlightedTag fields
- `Msg` type with Show, Hide, NavigateUp, NavigateDown, HighlightTag variants
- `init`, `update`, `view` functions following TEA pattern
- Helper functions `findNext`, `findPrev` for tag navigation
- Helper functions `isVisible`, `getHighlightedTag`, `getTags`, `setTags` for encapsulation

**Updated Main.elm integration**:
- Replaced popup fields with `tagPopup : TagPopup.Model`
- Added `TagPopupMsg TagPopup.Msg` to main Msg type
- Updated all popup-related update logic to use TagPopup component
- Integrated TagPopup.view using nested Elm architecture: `TagPopup.view model.tagPopup |> Html.map TagPopupMsg`
- Updated keyboard navigation to use TagPopup messages
- Removed unused `ChangeCurrentHighlightedTag` message and `tagPopupConfig`

**Maintained all functionality**:
- Tag autocomplete popup appears when typing @tag syntax
- Up/Down arrow navigation through suggestions
- Enter key selects highlighted tag
- Escape dismisses popup
- Proper cursor positioning and visual feedback

**Key architectural improvements**:
- Clean separation of concerns
- Reusable component design
- Simplified nested Elm architecture pattern using `Html.map`
- Eliminated Config boilerplate for cleaner code
- Proper encapsulation with helper functions
- Maintainable and testable code structure

**Verification**:
- ✅ Code compiles without errors
- ✅ All existing functionality preserved
- ✅ No regression in user experience
- ✅ Component follows Elm best practices