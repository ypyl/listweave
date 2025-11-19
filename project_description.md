# Project Description: ListWeave

## 1. Overview

ListWeave is a hierarchical note-taking application designed for organizing information in a structured and flexible way. It allows users to create nested lists, add rich content to each item, and categorize information using tags. The application is highly interactive, with a focus on keyboard-driven workflows and efficient information management.

## 2. Core Features

### 2.1. List Management

*   **Hierarchical Structure:** Users can create nested lists by indenting and outdenting items, forming a tree-like hierarchy.
*   **Create, Edit, Delete:** Users can add new items, edit existing ones in-place, and delete items.
*   **Collapse and Expand:** Parent items can be collapsed or expanded to show or hide their children, allowing users to focus on specific parts of the list.
*   **Reordering:** Items can be moved up and down within the list.

### 2.2. Content and Formatting

*   **Rich Text:** List items support rich text content.
*   **Tagging:** Users can embed tags within the content of an item using the `@` symbol (e.g., `@todo`, `@project-x`). These tags are automatically parsed and associated with the item.
*   **Code Blocks:** The application supports code blocks, which are rendered in a monospace font and are excluded from tag parsing.

### 2.3. Search and Filtering

*   **Global Search:** A search bar at the top of the application allows users to search for text across all list items.
*   **Tag Filtering:** Users can filter the list to show only items that contain specific tags. Selected tags appear as chips in the search area.
*   **Combined Filtering:** Text search and tag filtering can be used together for more specific queries.

### 2.4. Interaction and Workflow

*   **In-Place Editing:** List items are edited directly in the main view using `contenteditable` elements, providing a seamless editing experience.
*   **Keyboard-Driven:** The application is designed to be used primarily with the keyboard. It offers a comprehensive set of shortcuts for common actions, including:
    *   Creating new items
    *   Indenting and outdenting
    *   Moving items up and down
    *   Cutting, copying, and pasting items
    *   Navigating between items
*   **Tag Popup:** When a user starts typing a tag, a popup appears with suggestions based on existing tags in the application.
*   **Clipboard:** The application has its own internal clipboard for cutting, copying, and pasting list items and their children.

### 2.5. Data Management

*   **Import/Export:** The entire list structure and content can be exported to a JSON file for backup or migration. Users can also import data from a JSON file to restore a previous state.
