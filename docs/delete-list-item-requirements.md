### Task Overview
- **Brief description of the feature**: Add a delete icon to each list item to allow users to delete individual items.
- **User story or use case**: As a user, I want to be able to easily delete a single item from my list when it's no longer needed.
- **Success criteria**: A delete icon is present on each list item. Clicking the icon deletes that specific item from the list.

### Technical Requirements
- **Functional requirements**:
    - A delete icon should be displayed within each `ListItem` component.
    - Clicking the delete icon on a list item should delete that specific item from the list.
- **Non-functional requirements**:
    - The delete action should feel instantaneous to the user.
    - The list view should update smoothly after an item is deleted.
- **Integration requirements**:
    - The delete functionality needs to be integrated into the `ListItem` component and handled in the main update loop.

### Implementation Approach
- **Affected modules/files**:
    - `src/Main.elm`:
        - In the `update` function, modify the `DeleteItem` message handler to use the `removeItemCompletely` function from the `ListItem` module.
        - Import `removeItemCompletely` from `ListItem`.
        - In the `viewListItem` function, add a delete icon (e.g., "❌").
        - The icon will have an `onClick` event that triggers the `DeleteItem` message with the current item.
    - `src/ListItem.elm`: No changes needed. The existing `removeItemCompletely` function will be used.
    - `src/Actions.elm`: No changes needed. The existing `DeleteItem` message type in `Main.elm` will be reused.
    - `src/styles.css`: Can be used to add custom styling to the delete icon.

### Data structure changes
- None.

### UI/UX changes
- A new delete icon (e.g., a trash can or 'x' icon) will be added to each list item.

### Port requirements
- None.

### Acceptance Criteria
- **Testable conditions for completion**:
    - A delete icon is visible on every list item.
    - Clicking the delete icon on a specific item removes only that item from the list.
    - The rest of the list items remain unchanged.
- **Edge cases to handle**:
    - Deleting the only item in the list.
- **Error scenarios**: None expected.

### Implementation Notes
- **Potential challenges**: Ensuring the icon is well-placed and doesn't clutter the item view.
- **Dependencies on other features**: None.
- **Performance considerations**: Negligible.
- **Note on `ListItem` functions**: The `ListItem` module contains both `deleteItem` and `removeItemCompletely`. We must use `removeItemCompletely` as it deletes the item and its children, whereas `deleteItem` has a different behavior of preserving child items.