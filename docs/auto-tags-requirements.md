# Auto-Generated Tags for List Items

## Task Overview

-   **Brief description:** This feature will automatically add tags to list items based on their creation date, last update date, and whether they contain a code block.
-   **User story:** As a user, I want items to be automatically tagged with their creation and update dates, and also to be tagged if they contain code, so I can easily filter and find items based on this metadata.
-   **Success criteria:** List items are automatically tagged as described, and these tags are visible and usable for filtering.

## Technical Requirements

-   **Functional requirements:**
    -   When a new list item is created, it must be tagged with the current date in `created:mm/dd/yyyy` format.
    -   When a list item is modified, it must be tagged with the current date in `updated:mm/dd/yyyy` format. If an `updated` tag already exists, it should be replaced with the new date.
    -   If a list item's content contains a markdown code block (```), it must be tagged with `code`.
    -   If a code block is removed from an item, the `code` tag should be removed.
-   **Non-functional requirements:**
    -   The tagging process should be efficient and not introduce any noticeable delay for the user when creating or editing items.
-   **Integration requirements:**
    -   The auto-generated tags should be integrated into the existing tagging system.
    -   They should appear in the tag list and be usable by the tag filtering mechanism.

## Implementation Approach

-   **Affected modules/files:**
    -   `src/ListItem.elm`: The `ListItem` model will need to be updated to handle the new tags. The logic for adding/updating items will need to be modified.
    -   `src/TagsUtils.elm`: May need modifications to handle the specific logic for these auto-tags.
    -   `src/Main.elm`: The main update function will likely be involved in triggering the tag updates.
-   **Data structure changes:**
    -   No major changes to the `ListItem` data structure are anticipated, as it already supports a list of tags.
-   **UI/UX changes:**
    -   The auto-generated tags will appear alongside user-added tags.
    -   Consider if these tags should be visually distinct from user-added tags (e.g., different color or icon). For now, they will be treated the same.
-   **Port requirements:**
    -   No new JavaScript interop is expected for this feature.

## Acceptance Criteria

-   **Testable conditions for completion:**
    -   Create a new item and verify it has a `created:mm/dd/yyyy` tag with the correct date.
    -   Edit an existing item and verify it has an `updated:mm/dd/yyyy` tag with the correct date.
    -   Create an item with a code block and verify it has the `code` tag.
    -   Remove the code block from an item and verify the `code` tag is removed.
    -   Filter by an auto-generated tag (e.g., `code`) and verify only matching items are shown.
-   **Edge cases to handle:**
    -   Item is created and edited on the same day. It should have both `created:` and `updated:` tags with the same date.
    -   An item is edited multiple times on the same day. The `updated:` tag should reflect the date of the last edit.
-   **Error scenarios:**
    -   There are no specific error scenarios anticipated, as this is about adding metadata.

## Implementation Notes

-   **Potential challenges:**
    -   Ensuring the date formatting is consistent.
    -   The logic to detect the presence of a code block must be robust.
-   **Dependencies on other features:**
    -   This feature depends on the existing tagging and filtering functionality.

## Detailed Implementation Plan

Based on the analysis of the `src` directory, here is a detailed plan for implementation:

### 1. Modify `src/ListItem.elm`

This file contains the core logic for `ListItem` creation and updates.

#### a. Add a Date Formatting Helper

A private helper function will be added to format `Posix` time into the desired `mm/dd/yyyy` string format.

```elm
formatDateToMDY : Posix -> String
formatDateToMDY posix =
    let
        zone = Time.utc -- Or appropriate timezone
        month = Time.toMonth zone posix |> Time.monthNumber
        day = Time.toDay zone posix
        year = Time.toYear zone posix
    in
    String.padLeft 2 '0' (String.fromInt month) ++ "/" ++ String.padLeft 2 '0' (String.fromInt day) ++ "/" ++ String.fromInt year
```

#### b. Update `updateItemContentFn`

This function is called when an item's content is modified. It will be updated to include the auto-tagging logic.

```elm
updateItemContentFn : ListItem -> String -> Posix -> ListItem -> ListItem
updateItemContentFn (ListItem current) content currentTime (ListItem item) =
    if item.id == current.id then
        let
            lines =
                String.lines content

            finalLines =
                if List.all String.isEmpty lines then
                    []
                else
                    lines

            -- Extract user-defined tags from content
            userTags =
                extractTags content

            -- Check for the presence of a code block
            hasCodeBlock =
                TagsUtils.processContent lines
                    |> List.any (\(isCode, _) -> isCode)

            -- Generate auto-tags
            autoTags =
                [ "created:" ++ formatDateToMDY item.created
                , "updated:" ++ formatDateToMDY currentTime
                ] ++ (if hasCodeBlock then ["code"] else [])

            -- Combine user tags and auto-tags, ensuring uniqueness
            allTags =
                Set.fromList (userTags ++ autoTags) |> Set.toList
        in
        ListItem { item | content = finalLines, tags = allTags, updated = currentTime }

    else
        ListItem item
```

#### c. Update `newEmptyListItem`

This function is used to create a new, empty list item. It will be modified to add the `created` and `updated` date tags upon creation.

```elm
newEmptyListItem : Posix -> Int -> ListItem
newEmptyListItem posix id =
    let
        autoTags =
            [ "created:" ++ formatDateToMDY posix
            , "updated:" ++ formatDateToMDY posix
            ]
    in
    ListItem { id = id, content = [], tags = autoTags, children = [], collapsed = True, editing = False, created = posix, updated = posix }
```

### 2. Review `src/Main.elm`

The `initialModel` in `Main.elm` contains hardcoded data. After implementing the changes in `ListItem.elm`, the tags for the initial data will need to be manually updated to include the auto-generated tags for consistency.

For example, for an item in `initialModel`:
```elm
-- before
{ id = 1, ..., tags = [ "todo", "exercise" ], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027, ... }

-- after (assuming the date is 09/01/2025)
{ id = 1, ..., tags = [ "todo", "exercise", "created:09/01/2025", "updated:09/01/2025" ], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027, ... }
```

This implementation strategy centralizes the auto-tagging logic within `ListItem.elm`, making it easy to maintain and ensuring that all new and updated items are correctly tagged.