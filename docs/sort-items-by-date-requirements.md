# Task: Implement Date-Based Sorting for List Items

## Task Overview
- **Brief description**: Introduce a UI control to sort list items by their creation or last update timestamp.
- **User story**: As a user, I want to be able to sort my list items by date, so I can easily find the most recently added or updated items.
- **Success criteria**: The user can toggle between the default manual sorting and date-based sorting. When date-based sorting is active, all items, including nested children, are sorted chronologically.

## Technical Requirements
- **Functional requirements**:
    - Add a sort control (e.g., a button or a dropdown) to the UI.
    - The control should allow switching between "Manual" and "By Date" sorting.
    - When "By Date" is selected, the list items should be sorted hierarchically based on their `created` or `updated` timestamp. Parent items are sorted first, and then their children are sorted within each parent.
    - The sorting should be descending (newest first).
- **Non-functional requirements**:
    - The sorting operation should be performant and not block the UI, even for large lists.
    - The selected sort order should be persisted across sessions.
- **Integration requirements**:
    - The new sorting logic will integrate with the existing `Main.elm` module, which manages the state of the list.
    - The `ListItem.elm` module may need to be updated to ensure timestamps are correctly handled.

## Implementation Approach
- **Affected modules/files**:
    - `src/Main.elm`: To add the new sorting logic and state.
    - `src/SearchToolbar.elm`: To add the UI control for sorting.
    - `src/ListItem.elm`: To ensure it has the necessary date fields.
    - `index.html`: If any new UI elements require HTML changes.
- **Data structure changes**:
    - The main model in `Main.elm` will need a new field to store the current sort order (e.g., `sortOrder : SortOrder` where `SortOrder` is a custom type `type SortOrder = Manual | ByDate`).
- **UI/UX changes**:
    - A new control will be added to the `SearchToolbar`.
    - The list view will re-render to reflect the new sort order.
- **Port requirements**:
    - No new JavaScript interop is anticipated for this feature.

## Acceptance Criteria
- **Testable conditions for completion**:
    - When the user clicks the "By Date" sort option, the list is re-sorted with the newest items first.
    - The hierarchical structure is maintained during sorting.
    - Switching back to "Manual" sorting restores the original order.
    - The chosen sort order is saved and restored when the application is reloaded.
- **Edge cases to handle**:
    - Sorting an empty list.
    - Sorting a list with only one item.
    - Sorting a list with deeply nested items.
- **Error scenarios**:
    - No specific error scenarios are expected, but the implementation should be robust.

## Implementation Notes
- **Potential challenges**:
    - Implementing the hierarchical sorting logic efficiently in Elm.
    - Ensuring the UI updates smoothly after sorting.
- **Dependencies on other features**:
    - This feature depends on the existing list item structure, which includes `created` and `updated` timestamps.
- **Performance considerations**:
    - For large lists, the sorting algorithm should be optimized to avoid performance bottlenecks.
