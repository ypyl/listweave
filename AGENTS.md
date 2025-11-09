# ListWeave Project

This document provides an overview of the ListWeave project for agent-based development.

## Project Overview

ListWeave is a web-based, hierarchical note-taking application. It allows users to create and manage nested lists of items, providing a flexible structure for organizing information. The application is designed for efficient keyboard-based interaction and features a robust tagging and filtering system.

## Technology Stack

- **Frontend Framework:** [Elm](https://elm-lang.org/)
- **Build Tool:** `elm make`
- **Language:** Elm
- **Styling:** CSS-in-Elm (as seen in `Theme.elm`)
- **Interop:** Uses JavaScript ports for DOM interactions like caret positioning, focus management, and file operations.

## Key Features

- **Hierarchical Lists:** Items can be nested to create a tree-like structure. Users can indent and outdent items.
- **Collapsible Items:** Parent items can be collapsed or expanded to show or hide their children.
- **In-place Editing:** Items can be edited directly in the list view.
- **Tagging System:** Users can add tags to items using the `@tag` syntax. Tags are automatically parsed and can be used for filtering.
- **Tag Autocompletion:** A popup suggests existing tags as the user types.
- **Search and Filtering:** A dedicated search toolbar allows filtering the list by:
  - Full-text search of item content.
  - Selecting one or more tags.
- **Keyboard Navigation:** Extensive keyboard shortcuts are available for:
  - Moving items up and down.
  - Indenting/outdenting items.
  - Creating, saving, and deleting items.
  - Navigating between items.
  - Cut, copy, and paste functionality.
- **Code Blocks:** The application correctly handles code blocks, ignoring `@tag` syntax within them.
- **Data Persistence:** The entire list of items can be exported to a `listweave-data.json` file and imported back into the application.
- **Timestamps:** Items automatically track their creation and update times.

## Project Structure

- `src/Main.elm`: The main entry point of the Elm application. It contains the core model, update logic, view, and subscriptions.
- `src/ListItem.elm`: Defines the `ListItem` data structure and contains functions for manipulating items (e.g., creating, deleting, indenting, sorting).
- `src/SearchToolbar.elm`: Manages the state and logic for the search and filtering toolbar.
- `src/TagPopup.elm`: Handles the logic for the tag autocompletion popup.
- `src/TagsUtils.elm`: Provides utility functions for parsing and manipulating tags.
- `src/KeyboardHandler.elm`: Manages all keyboard shortcuts and their corresponding actions.
- `src/Clipboard.elm`: Implements the cut, copy, and paste functionality.
- `src/Theme.elm`: Contains the application's styling, defined as Elm functions.
- `elm.json`: The project's dependency and configuration file.
- `docs/`: Contains markdown files with detailed specifications for various features.
- `index.html`: The main HTML file that loads the compiled Elm JavaScript.
