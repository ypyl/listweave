# Copy and Paste List Items

## Task Overview

-   **Brief description:** This feature will allow users to copy a list item and its children and paste it elsewhere in the list.
-   **User story:** As a user, I want to be able to duplicate a list item and its entire hierarchy, so I can easily reuse content without having to manually re-enter it.
-   **Success criteria:** Users can press `Alt+C` to copy the currently focused item, and `Alt+V` to paste it as a sibling of the currently focused item.

## Technical Requirements

-   **Functional requirements:**
    -   When the user presses `Alt+C` on a list item, the item and its children should be copied to an internal clipboard.
    -   When the user presses `Alt+V`, the copied item (with its children) should be inserted below the currently focused item, at the same indentation level.
    -   The pasted item should be a deep copy, meaning it gets new IDs for the parent and all its children.
    -   The `created` and `updated` timestamps for the new items should be set to the time of pasting.
-   **Non-functional requirements:**
    -   The copy-paste operation should be fast and responsive.
-   **Integration requirements:**
    -   This feature should integrate with the existing `KeyboardHandler.elm` to capture the `Alt+C` shortcut.
    -   The pasting logic will reuse or extend the existing `Alt+V` (cut/paste) functionality.

## Implementation Approach

-   **Affected modules/files:**
    -   `src/KeyboardHandler.elm`: To add the `Alt+C` key combination to trigger the copy action.
    -   `src/Main.elm`: The `Model` will need a field to store the copied item (e.g., `copiedItem : Maybe ListItem`). The `update` function will handle the `CopyItem` and `PasteItem` messages.
    -   `src/ListItem.elm`: Will need a function to perform a deep copy of a list item, recursively assigning new IDs and updating timestamps.
-   **Data structure changes:**
    -   The main `Model` in `src/Main.elm` will be updated to hold the copied item.
-   **UI/UX changes:**
    -   No direct UI changes, as this is a keyboard-driven feature.
-   **Port requirements:**
    -   No JavaScript interop is expected.

## Acceptance Criteria

-   **Testable conditions for completion:**
    -   Focus on an item and press `Alt+C`.
    -   Focus on another item and press `Alt+V`.
    -   Verify that the copied item and its children are inserted below the focused item.
    -   Verify that the pasted items have new IDs and updated `created`/`updated` timestamps.
    -   Verify that the original item remains in its place.
-   **Edge cases to handle:**
    -   Pasting when nothing has been copied yet (should do nothing).
    -   Copying an item with a large number of nested children.
-   **Error scenarios:**
    -   No specific error scenarios are anticipated.

## Implementation Notes

-   **Potential challenges:**
    -   The recursive logic for deep-copying items and assigning new IDs needs to be correct to avoid ID collisions.
-   **Dependencies on other features:**
    -   Depends on the existing item rendering and keyboard handling infrastructure.
