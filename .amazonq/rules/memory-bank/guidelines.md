# ListWeave Development Guidelines

## Code Quality Standards

### Elm Language Conventions
- **Module Structure**: Follow standard Elm module organization with clear exposing lists
- **Type Definitions**: Use custom types with descriptive constructors (e.g., `ListItem`, `Msg` variants)
- **Function Naming**: Use descriptive camelCase names that clearly indicate purpose
- **Documentation**: Include module-level documentation and type annotations for all functions

### Formatting and Style
- **Indentation**: Use 4-space indentation consistently throughout codebase
- **Line Length**: Keep lines readable, break long function calls across multiple lines
- **Whitespace**: Use blank lines to separate logical sections within functions
- **Comments**: Use `--` for single-line comments, avoid excessive inline comments

### Code Organization Patterns
- **Single Responsibility**: Each function should have one clear purpose
- **Pure Functions**: Prefer pure functions over stateful operations where possible
- **Pattern Matching**: Use comprehensive pattern matching with explicit case handling
- **Error Handling**: Use Maybe and Result types for safe error handling

## Architectural Patterns

### Elm Architecture (TEA)
- **Model**: Centralized application state with clear type definitions
- **Update**: Pure functions that transform state based on messages
- **View**: Functions that render HTML based on current model state
- **Subscriptions**: Handle external events and time-based operations

### Data Flow Patterns
- **Immutable Updates**: Always return new state rather than mutating existing
- **Message Passing**: Use custom message types for all user interactions
- **Command Handling**: Separate side effects into Cmd values
- **State Management**: Keep all application state in the main model

### Component Structure
- **Module Separation**: Separate concerns into focused modules (ListItem, TagPopup, TagsUtils)
- **Type Safety**: Leverage Elm's type system for compile-time guarantees
- **Recursive Operations**: Use recursive functions for tree-like data structures
- **Helper Functions**: Extract common operations into reusable utility functions

## Implementation Standards

### List and Tree Operations
- **Recursive Processing**: Use recursive functions for nested list operations
- **Pattern Matching**: Handle empty lists and single-item cases explicitly
- **Accumulator Pattern**: Use accumulator parameters for efficient list building
- **Tree Traversal**: Implement depth-first traversal for hierarchical data

### State Management
- **Record Updates**: Use record update syntax for modifying nested data
- **Conditional Logic**: Use case expressions for complex state transitions
- **Default Values**: Provide sensible defaults for optional fields
- **Type Aliases**: Use type aliases for complex record structures

### User Interface Patterns
- **Event Handling**: Use Html.Events for user interactions
- **Dynamic Styling**: Apply styles conditionally based on state
- **Keyboard Navigation**: Implement keyboard shortcuts for power users
- **Responsive Design**: Use flexible CSS for different screen sizes

## Common Code Idioms

### List Processing
```elm
-- Recursive list processing with accumulator
processItems : (a -> b) -> List a -> List b -> List b
processItems fn remaining acc =
    case remaining of
        [] -> List.reverse acc
        item :: rest -> processItems fn rest (fn item :: acc)
```

### Tree Operations
```elm
-- Recursive tree traversal pattern
mapTree : (a -> a) -> Tree a -> Tree a
mapTree fn tree =
    case tree of
        Node data children ->
            Node (fn data) (List.map (mapTree fn) children)
```

### State Updates
```elm
-- Safe record updates with pattern matching
updateItem : Int -> (Item -> Item) -> List Item -> List Item
updateItem targetId updateFn items =
    List.map (\item ->
        if item.id == targetId then
            updateFn item
        else
            item
    ) items
```

### Error Handling
```elm
-- Maybe chaining for safe operations
findAndUpdate : Int -> List Item -> Maybe (List Item)
findAndUpdate id items =
    findItem id items
        |> Maybe.map (updateItem id)
        |> Maybe.map (\updated -> replaceItem updated items)
```

## Development Best Practices

### Testing Approach
- **Pure Function Testing**: Focus on testing pure functions with predictable outputs
- **Edge Case Coverage**: Test empty lists, single items, and boundary conditions
- **Type-Driven Development**: Let type signatures guide implementation

### Performance Considerations
- **Lazy Evaluation**: Use Html.Lazy for expensive view computations
- **Efficient Updates**: Minimize DOM updates through strategic rendering
- **Memory Management**: Avoid creating unnecessary intermediate data structures

### Debugging Strategies
- **Debug Mode**: Use `--debug` flag during development for time-travel debugging
- **Console Logging**: Use Debug.log sparingly for troubleshooting
- **Type Annotations**: Add explicit type annotations to catch errors early

### Code Maintenance
- **Refactoring**: Extract common patterns into reusable functions
- **Documentation**: Keep module documentation current with code changes
- **Version Control**: Make atomic commits with descriptive messages
- **Code Review**: Review changes for type safety and architectural consistency