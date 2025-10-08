# Ignore Tags in Code Block - Implementation Documentation

## Task Overview

### Description
✅ **COMPLETED** - Implemented functionality to prevent tag recognition and processing within code blocks (content between triple backticks ```). Tags inside code blocks are treated as literal text and are not clickable, searchable, or included in tag extraction.

### User Story
As a user writing code examples or technical documentation in ListWeave, I want tags inside code blocks to be treated as literal text so that code examples containing @ symbols don't create unwanted tag links or interfere with tag-based filtering.

### Success Criteria - ✅ ALL ACHIEVED
- ✅ Tags within code blocks are not clickable
- ✅ Tags within code blocks are not extracted for tag filtering
- ✅ Tags within code blocks are not included in tag autocomplete suggestions
- ✅ Code blocks maintain their visual styling while ignoring tag processing
- ✅ Mixed content (code blocks and regular text) handles tags correctly in each context

## Technical Requirements

### Functional Requirements

1. **Tag Extraction Filtering**
   - Modify `extractTags` function in `ListItem.elm` to skip content within code blocks
   - Code blocks are defined as content between triple backticks (```)
   - Support both inline and multi-line code blocks

2. **Content Rendering Updates**
   - Update `viewContent` and `renderContent` functions in `Main.elm` to skip tag processing within code blocks
   - Maintain existing code block styling while preventing tag link generation

3. **Tag Popup Suppression**
   - Prevent tag autocomplete popup from appearing when typing within code blocks
   - Update `isInsideTagBrackets` logic to consider code block context

4. **Search and Filter Consistency**
   - Ensure tag-based filtering ignores tags within code blocks
   - Maintain content-based search functionality within code blocks

### Non-Functional Requirements

1. **Performance**: Minimal impact on rendering performance
2. **Maintainability**: Clean separation of code block detection logic
3. **Consistency**: Uniform behavior across all tag-related features

### Integration Requirements

- Integrate with existing code block rendering logic in `viewStaticItem`
- Maintain compatibility with current tag system architecture
- Preserve existing keyboard navigation and editing functionality

## Implementation Approach - ✅ COMPLETED

### Affected Modules/Files

1. **`src/TagsUtils.elm`** - ✅ COMPLETED
   - Added `processContent` function for unified code block detection
   - Updated `isInsideTagBrackets` to prevent popup in code blocks
   - Implemented line-based code block parsing

2. **`src/ListItem.elm`** - ✅ COMPLETED
   - Modified `extractTags` function to use `processContent`
   - Tags in code blocks are filtered out during extraction

3. **`src/Main.elm`** - ✅ COMPLETED
   - Updated `viewStaticItem` to use unified `processContent`
   - Code blocks render as plain text (no tag processing)
   - Regular text blocks continue to process tags normally
   - Removed redundant filtering from `viewContent`

### Data Structure Changes
✅ No changes to core data structures required. Implementation uses utility functions for code block detection.

### UI/UX Changes - ✅ IMPLEMENTED
- ✅ No visual changes to code blocks (styling preserved)
- ✅ Tags within code blocks appear as plain text (no blue color, no click handlers)
- ✅ Tag popup does not appear when typing @ symbols within code blocks

### Port Requirements
✅ No new JavaScript interop required.

## Implementation Strategy - ✅ COMPLETED

### Unified Architecture Approach
Implemented a clean, unified approach using a single `processContent` function that separates code blocks from regular text:

```elm
-- TagsUtils.elm - Unified code block detection
processContent : List String -> List ( Bool, List String )
processContent content =
    -- Processes lines and returns (isCode, lines) tuples
    -- Handles ``` markers to identify code block boundaries

isInsideCodeBlock : Int -> String -> Bool
isInsideCodeBlock cursorPos content =
    -- Uses processContent to determine if cursor is in code block

isInsideTagBrackets : Int -> String -> Maybe ( String, String )
isInsideTagBrackets cursorPos content =
    if isInsideCodeBlock cursorPos content then
        Nothing  -- Suppress tag popup in code blocks
    else
        -- existing tag detection logic
```

### Tag Extraction Filtering - ✅ COMPLETED
```elm
-- ListItem.elm - Filter tags from code blocks
extractTags : String -> List String
extractTags content =
    let
        lines = String.lines content
        blocks = TagsUtils.processContent lines
        
        -- Only extract tags from non-code blocks
        textBlocks = 
            blocks
                |> List.filter (\(isCode, _) -> not isCode)
                |> List.concatMap (\(_, blockLines) -> blockLines)
                |> String.join "\n"
    in
    Regex.find isTagRegex textBlocks |> List.filterMap (...)
```

### Content Rendering Updates - ✅ COMPLETED
```elm
-- Main.elm - Separate rendering for code vs text blocks
viewBlock ( isCode, lines ) =
    if isCode then
        -- Render as plain text in styled code block
        code [...] (List.map (\line -> div [] [ text line ]) lines)
    else
        -- Process tags normally for text blocks
        div [] (List.map (\line -> div [...] (viewContent items item line)) lines)
```

## Acceptance Criteria

### Functional Tests

1. **Tag Extraction**
   - ✅ Tags in regular text are extracted normally
   - ✅ Tags within single-line code blocks are ignored
   - ✅ Tags within multi-line code blocks are ignored
   - ✅ Tags before/after code blocks are processed normally

2. **Content Rendering**
   - ✅ Tags in regular text remain clickable and styled
   - ✅ @ symbols in code blocks appear as plain text
   - ✅ Code block styling is preserved
   - ✅ Mixed content renders correctly

3. **Tag Popup Behavior**
   - ✅ Typing @ in regular text shows tag popup
   - ✅ Typing @ in code blocks does not show tag popup
   - ✅ Popup dismisses when entering code block

4. **Search and Filter**
   - ✅ Tag-based filtering ignores code block tags
   - ✅ Content search works within code blocks
   - ✅ Tag autocomplete excludes code block tags

### Edge Cases

1. **Malformed Code Blocks**
   - Handle unclosed code blocks gracefully
   - Handle nested backticks appropriately

2. **Mixed Content**
   - Code blocks with tags before/after
   - Multiple code blocks in same content
   - Empty code blocks

3. **Editing Scenarios**
   - Adding/removing code block markers
   - Cursor movement between code and text
   - Copy/paste operations

### Error Scenarios

1. **Invalid Markdown**: Graceful handling of malformed code blocks
2. **Performance**: No significant slowdown with large code blocks
3. **Memory**: No memory leaks from regex operations

## Implementation Notes - ✅ COMPLETED

### Challenges Resolved

1. **✅ Code Block Detection**: Implemented efficient line-based parsing instead of complex regex
2. **✅ Architecture Consolidation**: Unified two different code block detection methods into single `processContent` function
3. **✅ Clean Separation**: Code blocks render as plain text, regular text processes tags normally

### Key Design Decisions

1. **Line-Based Processing**: Used `processContent` to parse content line-by-line for better maintainability
2. **Separation of Concerns**: Code blocks and text blocks handled by different rendering paths
3. **Single Source of Truth**: All code block detection uses unified `processContent` function
4. **No Redundant Filtering**: Removed unnecessary filtering since code blocks don't call tag processing

### Dependencies - ✅ INTEGRATED
- ✅ Integrated with existing regex utilities in `TagsUtils.elm`
- ✅ Enhanced code block rendering logic in `Main.elm`
- ✅ Updated tag extraction system in `ListItem.elm`

### Performance Optimizations - ✅ IMPLEMENTED
- ✅ Efficient line-based parsing (no complex regex operations)
- ✅ Single-pass content processing
- ✅ Eliminated redundant code block filtering
- ✅ Minimal impact on rendering performance

### Testing Results - ✅ VERIFIED
- ✅ Manual testing confirmed all acceptance criteria met
- ✅ Code blocks render correctly with plain text
- ✅ Tag functionality preserved in regular text
- ✅ Tag popup suppressed in code blocks
- ✅ Tag extraction excludes code block content

## Implementation Summary

### Final Architecture
The implementation uses a clean, unified approach:

1. **`TagsUtils.processContent`**: Single function that separates content into code/text blocks
2. **Code Block Rendering**: Plain text rendering (no tag processing)
3. **Text Block Rendering**: Normal tag processing with `viewContent`
4. **Tag Extraction**: Filters out code blocks before extracting tags
5. **Tag Popup**: Suppressed when cursor is in code blocks

### Code Changes Summary
- **TagsUtils.elm**: Added `processContent`, updated `isInsideTagBrackets`
- **ListItem.elm**: Modified `extractTags` to use line-based filtering
- **Main.elm**: Updated rendering to separate code/text blocks, removed redundant filtering

### Benefits Achieved
- ✅ Single source of truth for code block detection
- ✅ Clean separation of concerns
- ✅ Efficient performance with minimal overhead
- ✅ Maintainable architecture
- ✅ All requirements met

## Future Enhancements

1. **Language-Specific Handling**: Different rules for different code languages
2. **Inline Code Support**: Extend to single-backtick inline code
3. **Configuration**: User preference for tag behavior in code blocks
4. **Syntax Highlighting**: Enhanced code block rendering with syntax highlighting