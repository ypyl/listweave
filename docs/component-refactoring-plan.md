# Main.elm Component Refactoring Plan

## Overview
Analysis of Main.elm to identify potential components for extraction using parent-child component approach.

## Potential Components to Extract

### 1. **TagPopup Component**
- **Functions**: `viewPopup`, `viewPopupTag`
- **State**: `popup`, `popupTags`, `currentHighlightedTag`
- **Messages**: `HidePopup`, `ChangeCurrentHighlightedTag`, `InsertSelectedTag`
- **Purpose**: Handles tag autocomplete popup functionality

### 2. **SearchToolbar Component**
- **Functions**: `viewCollapseExpandButtons`
- **State**: `searchQuery`
- **Messages**: `CollapseAll`, `ExpandAll`, `SearchQueryChanged`
- **Purpose**: Manages search input and collapse/expand controls

### 3. **ListItemView Component**
- **Functions**: `viewListItem`, `viewStaticItem`, `viewEditableItem`
- **State**: Item-specific editing state, clipboard state
- **Messages**: All item-related messages (edit, save, move, etc.)
- **Purpose**: Renders individual list items with editing capabilities

### 4. **ContentRenderer Component**
- **Functions**: `viewContent`, `renderContent`
- **State**: None (pure rendering)
- **Messages**: `GoToItem` for tag navigation
- **Purpose**: Handles content rendering with tag highlighting and code blocks

### 5. **KeyboardHandler Component**
- **Functions**: Key handling logic from `viewEditableItem`
- **State**: None (event handling)
- **Messages**: All keyboard-related messages
- **Purpose**: Centralized keyboard shortcut handling

### 6. **ClipboardManager Component** ✅ COMPLETED
- **Functions**: Cut/paste logic from update function
- **State**: `clipboard`, `clipboardOriginalPosition`
- **Messages**: `CutItem`, `PasteItem`, `RestoreCutItem`
- **Purpose**: Manages cut/copy/paste operations
- **Status**: Extracted to `Clipboard.elm` module

## Recommended Extraction Priority

1. **TagPopup** - Self-contained with clear boundaries
2. **SearchToolbar** - Simple component with minimal dependencies
3. **ContentRenderer** - Pure rendering component
4. **ClipboardManager** ✅ - Isolated state management (COMPLETED)
5. **ListItemView** - Most complex, should be done last
6. **KeyboardHandler** - Cross-cutting concern, needs careful design

## Benefits of This Refactoring

- **Separation of Concerns**: Each component handles a specific responsibility
- **Reusability**: Components can be reused or tested independently
- **Maintainability**: Smaller, focused modules are easier to understand and modify
- **Type Safety**: Elm's type system ensures safe component boundaries
- **Performance**: Potential for better rendering optimization with focused components

## Implementation Notes

- Follow Elm Architecture (TEA) pattern for each component
- Maintain pure functional programming principles
- Use explicit type annotations for component interfaces
- Keep component boundaries clean with minimal coupling
- Consider message passing between parent and child components