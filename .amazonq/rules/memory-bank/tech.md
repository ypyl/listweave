# ListWeave Technology Stack

## Programming Languages
- **Elm 0.19.1** - Primary application language
- **JavaScript** - DOM manipulation and browser APIs
- **HTML5** - Application structure
- **CSS3** - Styling and layout

## Core Dependencies
- `elm/browser 1.0.2` - Browser application framework
- `elm/core 1.0.5` - Core Elm functionality
- `elm/html 1.0.0` - HTML generation
- `elm/json 1.1.3` - JSON encoding/decoding
- `elm/regex 1.0.0` - Regular expression support
- `elm/time 1.0.0` - Time handling

## Development Commands

### Build Application
```bash
elm make src/Main.elm --output=lw-elm.js --debug
```

### Development Workflow
1. Edit Elm source files in `src/`
2. Run build command to compile
3. Open `index.html` in browser
4. Use browser dev tools for debugging

## Architecture Features

### Elm-JavaScript Interop
- **Ports**: Bidirectional communication between Elm and JavaScript
- **setCaret**: Position cursor in text inputs
- **resizeTextarea**: Auto-resize text areas
- **requestCursorPosition**: Get cursor coordinates
- **getPosition**: Handle click positioning
- **clickedAt**: Process click events

### Browser APIs Used
- **Local Storage**: Persistent data storage
- **DOM Manipulation**: Dynamic text area resizing
- **Caret Positioning**: Cursor management
- **Event Handling**: Mouse and keyboard interactions

### Build System
- Standard Elm compiler
- No additional build tools required
- Debug mode enabled for development
- Single JavaScript output file

## Development Environment
- Any text editor with Elm support
- Modern web browser
- Elm compiler installed globally
- No additional dependencies or frameworks required