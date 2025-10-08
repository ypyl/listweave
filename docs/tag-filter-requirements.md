# Tag Filter Feature Requirements

## Task Overview
Implement tag-based filtering functionality that allows users to select specific tags during search and filter list items based on those selected tags, working in conjunction with existing text search.

## User Story
As a user, I want to filter my hierarchical lists by specific tags so that I can quickly find all items related to particular topics or categories, while still being able to use text search simultaneously.

## Success Criteria
- Users can type `@tagname` in search input to trigger tag suggestions popup
- Selected tags appear as removable chips below the search input
- Items are filtered using AND logic for both text search and selected tags
- Visual feedback shows which tags matched in filtered items
- Existing popup component is reused for tag suggestions

## Technical Requirements

### Functional Requirements
1. **Tag Selection in Search Input**
   - Detect `@` character in search input to trigger tag suggestions
   - Show popup with matching tags below search input
   - Allow tag selection via Enter key or click from popup
   - Auto-extract tags: typing `@tagname ` (with space) automatically extracts tag to chips and removes from search text
   - Support keyboard navigation (Up/Down arrows) in tag popup

2. **Selected Tags Display**
   - Display selected tags as horizontal chips/badges below search input
   - Each tag chip has an 'X' button for removal
   - Include "Clear all tags" button when tags are selected
   - Tags persist until manually removed

3. **Filtering Logic**
   - Apply AND logic: items must match ALL selected tags
   - Apply AND logic between text search and tag filtering
   - Maintain hierarchical filtering (show parent if child matches)
   - Filter in real-time as tags are added/removed

4. **Visual Feedback**
   - Highlight matched tags in filtered items (similar to existing tag highlighting)
   - Show clear indication when no items match current filters

### Non-Functional Requirements
- **Performance**: Filtering should be responsive for lists up to 1000 items
- **Usability**: Tag selection should feel consistent with existing item editing
- **Accessibility**: Tag chips should be keyboard accessible

## Implementation Approach

### Data Structure Changes
**Model Updates:**
```elm
type alias Model =
    { -- existing fields...
    , selectedTags : List String
    -- Reuse existing popup, popupTags, currentHighlightedTag
    }
```

### Message Types
**Modified Messages:**
```elm
type Msg
    = -- existing messages...
    | SearchQueryChanged String Int  -- MODIFY: add cursor position
    | SearchTagSelected String
    | RemoveSelectedTag String
    | ClearAllSelectedTags
    -- Reuse existing ChangeCurrentHighlightedTag, HidePopup
```

### UI/UX Changes
1. **Search Input Enhancement**
   - Change search input from `onInput SearchQueryChanged` to `preventDefaultOn "input"` with decoder for both value and selectionStart (same pattern as textarea)
   - Add `preventDefaultOn "keydown"` to handle Enter key for tag selection and Up/Down navigation
   - Implement tag detection logic (reuse `TagsUtils.isInsideTagBrackets`)
   - Implement tag extraction logic to automatically move completed `@tag ` patterns to selectedTags
   - Add keyboard event handling for tag popup navigation (Up/Down arrows)

2. **Selected Tags Display**
   - Add horizontal tag chips container below search input
   - Style tag chips with background color and X button
   - Add "Clear all" button with conditional visibility

3. **Popup Positioning**
   - Position tag popup below search input (calculate input element position, not cursor position)
   - Modify `viewPopupTag` to trigger tag selection on click (works for both search and textarea contexts)
   - Reuse existing popup, popupTags, currentHighlightedTag fields
   - Reuse existing popup styling and viewPopup component

### Port Requirements
**New Ports:**
```elm
port getSearchInputPosition : () -> Cmd msg
-- Reuse existing receiveCursorPosition for search input positioning
```

**Note**: The search input positioning will be different from textarea cursor positioning - we need the input element's bounding box, not cursor coordinates.

## Affected Modules/Files

### Main.elm
- **Model**: Add selectedTags field only (reuse existing popup fields)
- **Update**: Add new message handlers for tag selection/removal
- **View**: Modify `viewCollapseExpandButtons` to include tag chips
- **Filtering**: Update `filterItems` function to handle tag filtering

### TagsUtils.elm
- No changes needed (reuse existing functions)

### index.html
- Add JavaScript handlers for search input cursor positioning

## Acceptance Criteria

### Core Functionality
- [ ] Typing `@tag` in search input shows matching tag suggestions
- [ ] Selecting a tag from popup adds it to selected tags list
- [ ] Typing `@tag ` (with space) auto-extracts tag to chips and removes from search text
- [ ] Multiple tags can be typed in search field: `@todo some text @urgent`
- [ ] Selected tags appear as removable chips below search input
- [ ] Items are filtered to show only those containing ALL selected tags
- [ ] Text search and tag filtering work together (AND logic)
- [ ] Removing tags updates filtering in real-time

### User Experience
- [ ] Tag popup appears below search input (not at cursor)
- [ ] Keyboard navigation works in tag popup (Up/Down, Enter, Escape)
- [ ] Tag chips have clear visual design with X buttons
- [ ] "Clear all tags" button appears when tags are selected
- [ ] Filtered items highlight matched tags

### Edge Cases
- [ ] Empty search with selected tags shows only tagged items
- [ ] No matching items shows appropriate empty state
- [ ] Duplicate tag selection is prevented
- [ ] Tag popup hides when clicking outside or pressing Escape
- [ ] Search input maintains focus after tag selection
- [ ] Auto-extraction works for multiple tags in same input
- [ ] Search text remains after tags are extracted
- [ ] Tag extraction works on space, Enter, and other word boundaries

## Implementation Notes

### Potential Challenges
1. **Popup Positioning**: Calculate search input position instead of cursor position
2. **State Management**: Coordinating search text and selected tags state
3. **Performance**: Efficient filtering with multiple criteria

### Dependencies
- Reuses existing popup component and styling
- Leverages existing TagsUtils functions
- Requires new JavaScript ports for search input handling

### Performance Considerations
- Debounce filtering operations if needed for large lists
- Optimize tag matching algorithms for real-time filtering
- Consider memoization for expensive filter operations

## Testing Strategy
- Test tag selection flow from search input
- Verify filtering logic with various tag combinations
- Test keyboard navigation in tag popup
- Validate tag chip removal functionality
- Test integration between text search and tag filtering