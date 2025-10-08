# SearchToolbar Component Requirements

## Task Overview

Extract the search and collapse/expand functionality from Main.elm into a dedicated SearchToolbar component. This component will provide a clean interface for filtering list items and managing the overall visibility state of the hierarchical list.

### User Story
As a user, I want a dedicated toolbar that allows me to:
- Search through list content and tags with real-time filtering
- Quickly collapse all items to see the top-level structure
- Quickly expand all items to see the full hierarchy
- Have these controls grouped together in an intuitive interface

### Success Criteria ✅ COMPLETED
- ✅ SearchToolbar component renders independently with its own state management
- ✅ Search functionality filters items in real-time as user types
- ✅ Collapse/Expand buttons work correctly with the hierarchical list
- ✅ Component integrates seamlessly with existing Main.elm architecture
- ✅ No regression in existing functionality

## Technical Requirements

### Functional Requirements

#### Search Functionality
- **Real-time filtering**: Filter items as user types in search input
- **Content matching**: Search through item content (all lines)
- **Tag matching**: Search through item tags
- **Case-insensitive search**: Convert both query and content to lowercase for matching
- **Hierarchical filtering**: Show parent items if children match, show children if parents match
- **Empty query handling**: Show all items when search query is empty

#### Collapse/Expand Controls
- **Collapse All**: Set all items to collapsed state recursively
- **Expand All**: Set all items to expanded state recursively
- **Visual feedback**: Clear button labels and appropriate styling

#### UI/UX Requirements
- **Grouped layout**: Search input and buttons arranged horizontally with consistent spacing
- **Responsive design**: Maintain layout integrity across different screen sizes
- **Consistent styling**: Match existing application design patterns
- **Accessibility**: Proper labels and keyboard navigation support

### Non-Functional Requirements

#### Performance
- **Efficient filtering**: Minimize re-computation during search
- **Debouncing**: Consider debouncing search input for large datasets (future enhancement)
- **Memory efficiency**: Avoid creating unnecessary intermediate data structures

#### Maintainability
- **Pure functions**: All filtering logic should be pure and predictable
- **Clear interfaces**: Well-defined component boundaries and message passing
- **Type safety**: Leverage Elm's type system for compile-time guarantees

### Integration Requirements

#### Parent-Child Communication
- **Search query state**: Managed within SearchToolbar component
- **Filtered items**: Parent applies filtering using SearchToolbar's query
- **Collapse/Expand actions**: Sent to parent for direct list state modification

#### Data Dependencies
- **List items**: Requires access to current list structure for filtering
- **Search query**: Internal state management within component

## Implementation Approach

### Affected Files
- **New file**: `src/SearchToolbar.elm` - Main component module
- **Modified**: `src/Main.elm` - Integration and message handling
- **Potentially modified**: `src/ListItem.elm` - If filtering utilities need extraction

### Component Structure

#### SearchToolbar.elm Module ✅ IMPLEMENTED
```elm
module SearchToolbar exposing (Model, Msg, init, update, view, getSearchQuery)

-- Model: Contains search query state
type alias Model = { searchQuery : String }

-- Messages: Internal component messages (not exposed)
type Msg 
    = SearchQueryChanged String
    | CollapseAllClicked
    | ExpandAllClicked

-- Functions
init : Model
update : Msg -> Model -> List ListItem -> ( Model, List ListItem )
view : Model -> Html Msg
getSearchQuery : Model -> String

-- Note: filterItems stays in Main.elm, collapse/expand handled internally
```

#### Main.elm Integration
- Remove `viewCollapseExpandButtons` function
- Keep `filterItems` function (needs ListItem module access)
- Remove `SearchQueryChanged` from main Msg type (handled internally)
- Remove `CollapseAll`, `ExpandAll` from main Msg type (handled via SearchToolbarMsg)
- Add `SearchToolbarMsg SearchToolbar.Msg` to main Msg type
- Update model: replace `searchQuery : String` with `searchToolbar : SearchToolbar.Model`
- Update view to use `SearchToolbar.view` and `filterItems (SearchToolbar.getSearchQuery model.searchToolbar) model.items`

### Data Structure Changes

#### Model Updates
```elm
-- In Main.elm, replace:
-- searchQuery : String
-- With:
-- searchToolbar : SearchToolbar.Model
```

#### Message Flow
1. User types in search: SearchToolbar updates internal query state
2. User clicks Collapse/Expand: SearchToolbar sends `CollapseAllClicked`/`ExpandAllClicked` to parent via `SearchToolbarMsg`
3. Parent receives `SearchToolbarMsg (CollapseAllClicked)` and applies `setAllCollapsed True/False` to items list
4. Parent calls `filterItems` with current query from SearchToolbar model

### UI/UX Changes

#### Layout Structure
- Maintain existing horizontal layout with flex display
- Keep consistent spacing (8px gap between elements)
- Preserve existing button and input styling
- Ensure proper margin-bottom (16px) for separation from list

#### Visual Consistency
- Match existing button styling and behavior
- Maintain input field appearance and placeholder text
- Preserve responsive behavior

## Acceptance Criteria ✅ COMPLETED

### Core Functionality
- [x] SearchToolbar component renders with search input and two buttons
- [x] Search input filters list items in real-time based on content and tags
- [x] "Collapse All" button collapses all list items recursively
- [x] "Expand All" button expands all list items recursively
- [x] Empty search query shows all items without filtering

### Integration Testing
- [x] Component integrates with Main.elm without breaking existing functionality
- [x] Search state is properly managed within SearchToolbar component
- [x] Parent-child message passing works correctly
- [x] No memory leaks or performance regressions

### Edge Cases
- [x] Search with special characters works correctly
- [x] Search with very long queries doesn't break layout
- [x] Rapid typing in search input doesn't cause issues
- [x] Collapse/Expand works correctly with filtered results
- [x] Search works correctly with deeply nested hierarchies

### Error Scenarios
- [x] Component handles empty list gracefully
- [x] Invalid search patterns don't crash the application
- [x] Component recovers properly from malformed data

## Implementation Notes

### Potential Challenges

#### State Synchronization
- SearchToolbar manages query state, Main.elm applies filtering
- Need to ensure SearchToolbar model updates trigger re-filtering in parent

#### Performance Considerations
- Filtering large lists efficiently without blocking UI
- Avoiding unnecessary re-renders during rapid search input

#### Component Boundaries
- SearchToolbar: UI and search query state management
- Main.elm: Filtering logic (needs ListItem functions) and list state management
- Clear separation: SearchToolbar doesn't directly modify list items

### Dependencies
- No new external dependencies required
- Relies on existing ListItem module functions
- Uses standard Elm HTML and Events modules

### Future Enhancements
- Search result highlighting
- Advanced search operators (AND, OR, NOT)
- Search history/suggestions
- Keyboard shortcuts for collapse/expand
- Search within specific fields (content only, tags only)

### Testing Strategy
- Manual testing of all functionality
- Browser-based integration testing
- Performance validation with sample data

## Development Approach ✅ COMPLETED

### Phase 1: Component Extraction ✅
1. ✅ Create SearchToolbar.elm module with basic structure
2. ✅ Extract filtering logic from Main.elm (kept in Main.elm as planned)
3. ✅ Extract view functions for toolbar elements

### Phase 2: Integration ✅
1. ✅ Update Main.elm model: replace `searchQuery` with `searchToolbar : SearchToolbar.Model`
2. ✅ Update Main.elm update function to handle `SearchToolbarMsg` with improved encapsulation
3. ✅ Update Main.elm view: replace `viewCollapseExpandButtons model` with `SearchToolbar.view model.searchToolbar |> Html.map SearchToolbarMsg`
4. ✅ Update filtering call: `filterItems (SearchToolbar.getSearchQuery model.searchToolbar) model.items`
5. ✅ Add `SearchToolbarMsg SearchToolbar.Msg` to main Msg type

### Phase 3: Validation & Refinement ✅
1. ✅ Manually verify all functionality works as before
2. ✅ Check for performance regressions through browser testing
3. ✅ Ensure proper error handling
4. ✅ Validate user experience and accessibility

## Implementation Summary ✅

The SearchToolbar component has been successfully implemented with enhanced encapsulation:

- **Component created**: `src/SearchToolbar.elm` with clean API
- **Encapsulated design**: Msg constructors not exposed, items handling internal
- **Update signature**: `update : Msg -> Model -> List ListItem -> ( Model, List ListItem )`
- **Integration**: Seamless integration with Main.elm using single message handler
- **Functionality preserved**: All search and collapse/expand features working correctly

This component extraction improves code organization, makes the search functionality more maintainable, and provides a foundation for future search enhancements.