# ListWeave Project Structure

## Directory Organization

### Root Level
- `elm.json` - Elm project configuration and dependencies
- `index.html` - Main HTML entry point with JavaScript ports
- `lw-elm.js` - Compiled Elm application
- `README.md` - Build instructions
- `.gitignore` - Git ignore patterns

### Source Code (`src/`)
- `Main.elm` - Main application module with core logic
- `ListItem.elm` - List item data structures and utilities
- `TagPopup.elm` - Tag management popup component
- `TagsUtils.elm` - Tag-related utility functions
- `styles.css` - Application styling

### Documentation (`docs/`)
- Component refactoring plans
- Implementation guides
- Feature requirements
- Technical specifications

### Build Artifacts (`elm-stuff/`)
- Compiled Elm modules and dependencies
- Generated code and build cache

## Core Components

### Main Application (`Main.elm`)
- **Model**: Application state management
- **Update**: Message handling and state transitions
- **View**: UI rendering and event handling
- **Subscriptions**: External event handling

### Data Layer (`ListItem.elm`)
- ListItem type definitions
- Tree manipulation functions
- Item creation and modification utilities

### UI Components
- **TagPopup**: Tag selection and management interface
- **Search**: Real-time filtering functionality
- **Editing**: In-place text editing with auto-resize

## Architectural Patterns

### Elm Architecture (TEA)
- Unidirectional data flow
- Pure functions for updates
- Immutable state management
- Command-based side effects

### Component Structure
- Modular component design
- Message-based communication
- Reusable utility functions
- Separation of concerns

### Data Flow
1. User interactions generate messages
2. Update function processes messages
3. Model state is updated immutably
4. View renders new state
5. JavaScript ports handle DOM interactions