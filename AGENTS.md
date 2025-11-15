# Project Guidelines: Vanilla Web Development

This document outlines the core principles and techniques for developing this project. The goal is to build a static web application using only vanilla web technologies, without relying on external frameworks or build tools.

## Core Technologies

-   **HTML:** For content structure.
-   **CSS:** For styling.
-   **JavaScript:** For application logic and interactivity.

## Key Principles

1.  **No Frameworks or Build Tools:** We will not use any JavaScript frameworks (like React, Vue, Angular) or build tools (like Webpack, Vite, Parcel). Development should be possible with just a text editor and a web browser.

2.  **Component-Based Architecture:**
    -   **Web Components:** We will use the Web Components standard (Custom Elements, Shadow DOM, HTML Templates) as the fundamental building block for creating reusable UI components. This is the vanilla alternative to framework-specific components.

3.  **Styling:**
    -   **Modern CSS:** We will leverage modern CSS features (e.g., Custom Properties, Grid, Flexbox) for all styling needs.
    -   **No Pre-processors:** We will not use CSS pre-processors like SASS/SCSS or tools like PostCSS.

4.  **Application Structure:**
    -   **Static Site:** The project will be a static website, meaning it consists of only HTML, CSS, and JavaScript files that can be served directly by a simple web server without any server-side rendering or logic.
    -   **Single-Page Applications (SPA):** For SPA-like functionality, we will implement routing and state management using vanilla JavaScript techniques.

---

## Web Components Guide

This section details the standards and practices for creating Web Components within this project.

### 1. Core Technologies

-   **Custom Elements:** The foundation for creating new HTML tags with custom behavior. All components will be classes extending `HTMLElement`.
-   **Shadow DOM:** Provides encapsulation for DOM and CSS. This should be used sparingly.
-   **HTML Templates:** The `<template>` and `<slot>` elements will be used for creating reusable and flexible markup, especially within components that use Shadow DOM.

### 2. Custom Element Best Practices

-   **Naming:** All custom element tags must contain a dash and be prefixed with `lw-` to avoid conflicts (e.g., `<lw-list>`).
-   **Registration:** Register components using `customElements.define('lw-tag-name', ComponentClass)`. This should be centralized in a main `app.js` file to keep track of all components.
-   **Lifecycle:**
    -   `constructor()`: Use for initial setup that does not touch the DOM, like attaching a Shadow DOM.
    -   `connectedCallback()`: The primary method for DOM manipulation, rendering, and adding event listeners. It can be called multiple times if an element is moved.
-   **Closing Tags:** Custom elements are **not** self-closing. Always use a full closing tag (e.g., `<lw-list></lw-list>`).

### 3. Attributes, Properties, and State

-   **`observedAttributes`**: To monitor changes to attributes, define a `static get observedAttributes() { return ['attr1', 'attr2']; }`.
-   **`attributeChangedCallback(name, oldValue, newValue)`**: This callback will fire when any attribute listed in `observedAttributes` is changed. Use this to trigger UI updates.
-   **Central `update()` Method**: Create a single `update()` method within a component to handle all DOM updates. Call this from `connectedCallback()` and `attributeChangedCallback()` to centralize rendering logic.
-   **Properties vs. Attributes**: For passing complex data (objects, arrays), use JavaScript properties with getters and setters. Attributes should primarily be used for simple string or number-based configuration.
    ```javascript
    // In your component class
    set listData(data) {
      this._listData = data;
      this.update();
    }

    get listData() {
      return this._listData;
    }
    ```

### 4. Shadow DOM: To Use or Not to Use?

Shadow DOM provides strong encapsulation but comes with performance and complexity costs.

-   **Avoid Shadow DOM for:**
    -   Simple, lightweight components that don't have complex internal structure.
    -   Components that need to be easily styled from the outside.
-   **Use Shadow DOM for:**
    -   Components that require style isolation to prevent conflicts with global CSS.
    -   Complex components that need to hide their internal structure (e.g., a date picker).
    -   Components that need to render children into specific locations using `<slot>`.

### 5. Data Passing Strategies

1.  **Child to Parent (Events):**
    -   A child component should communicate with its parent by dispatching a `CustomEvent`.
    -   The parent will listen for this event and act accordingly.
    ```javascript
    // In child component
    this.dispatchEvent(new CustomEvent('item-added', { detail: { text: 'New Item' } }));

    // In parent component
    childElement.addEventListener('item-added', (e) => {
      console.log(e.detail.text);
    });
    ```

2.  **Parent to Child (Properties for Complex Data):**
    -   This is the recommended way to pass objects or arrays to a **stateful** child component.
    -   The parent gets a reference to the child element and sets a property on it.
    ```javascript
    // In parent
    const listComponent = this.querySelector('lw-list');
    listComponent.listData = [{ id: 1, text: 'Item 1' }];
    ```

3.  **Parent to Child (Methods for Actions):**
    -   This is the recommended way to interact with **stateless** child components.
    -   The parent calls a public method on the child element to trigger an action.
    ```javascript
    // In parent
    const summaryComponent = this.querySelector('lw-summary');
    summaryComponent.update(newList);
    ```

---

## Styling Guide

This section outlines the CSS strategy for the project, focusing on structure, maintainability, and modern, browser-native features.

### 1. CSS Reset

-   A minimal CSS reset will be used to establish a consistent baseline across all browsers. This is the first stylesheet to be imported.

### 2. File Organization

-   CSS will be organized into multiple files and imported into a single root `index.css` file using `@import`. This keeps the HTML clean and the CSS modular.
-   The recommended file structure is:
    -   `/index.css`: The root file that imports all other CSS files in the correct order.
    -   `/styles/reset.css`: The cross-browser reset rules.
    -   `/styles/variables.css`: Global CSS Custom Properties for theme (colors, fonts, etc.).
    -   `/styles/global.css`: Global styles for the application (e.g., `body`, `a`, layout styles).
    -   `/components/component-name/component-name.css`: Styles that are specific to a single Web Component, located with the component's JavaScript file.

### 3. CSS Variables (Custom Properties)

-   A central `variables.css` file will define all theme-related values (colors, fonts, spacing) in the `:root` scope.
-   This allows for easy theming and maintenance. Components should reference these variables.

### 4. Scoping Styles

To avoid style conflicts, styles should be scoped locally to their respective components using one of the following methods:

1.  **Prefixed Selectors (Default Method):**
    -   For components that **do not** use Shadow DOM.
    -   All CSS rules in a component's stylesheet should be prefixed with the component's custom tag name. This creates a local namespace.
    -   Native CSS Nesting can be used for a cleaner syntax.
    ```css
    /* components/lw-list/lw-list.css */
    lw-list {
      display: block;
      border: 1px solid var(--border-color);
    }

    lw-list p {
      font-family: casual, cursive;
      color: darkblue;
    }
    
    /* Using CSS Nesting */
    lw-list {
      display: block;
      border: 1px solid var(--border-color);

      p {
        font-family: casual, cursive;
        color: darkblue;
      }
    }
    ```

2.  **Shadow DOM (For Encapsulation):**
    -   For components that **do** use Shadow DOM.
    -   Styles are automatically scoped and do not leak out.
    -   All necessary styles (including resets or shared styles) must be explicitly loaded into the shadow root via a `<link>` tag.
    -   CSS variables defined in the global scope are still accessible from within the Shadow DOM.
    ```javascript
    // In component's constructor
    this.shadowRoot.innerHTML = `
        <link rel="stylesheet" href="${import.meta.resolve('./component.css')}">
        <p>Shadowed Content</p>
    `;
    ```

---

## Application Architecture (SPA)

This section covers the high-level structure for building the project as a Single-Page Application (SPA).

### 1. Project Structure

-   The application will be bootstrapped from a root `<lw-app>` component defined in `/app/App.js`.
-   All application views (pages) and complex components will be organized within the `/app` directory.
-   Since this is a SPA, there will only be one `index.html` file.

### 2. Routing

-   **Hash-Based Routing:** The application will use hash-based routing (e.g., `example.com/#/users/1`).
    -   The current route is read from `window.location.hash`.
    -   Route changes are detected by listening to the `hashchange` event on the `window` object.
-   **`<lw-route>` Component:** A reusable routing component will be created to conditionally render content based on the current route.
-   **SEO Consideration:** This approach is **not SEO-friendly**. Search engines will only see the content of the initial page load. This is an acceptable trade-off for this project.

### 3. Security: XSS Prevention

-   To prevent Cross-Site Scripting (XSS), all user-provided data or dynamic content must be sanitized before being rendered into the DOM.
-   A tagged template literal function, `html`, will be created and used as a standard utility. This function will automatically encode HTML entities from variables, preventing malicious code injection.
    ```javascript
    import { html } from '../lib/html.js';

    // The html`` literal automatically encodes entities in the variables
    this.innerHTML = html`<li>${userInput}</li>`;
    ```

### 4. State Management

-   **The DOM is the State:** In our vanilla approach, the state is held directly within the DOM, primarily as properties and attributes on our Web Components.
-   **Lifting State Up:** This is the primary strategy for managing shared state.
    -   If multiple components depend on the same piece of state, that state should be "lifted up" to their closest common ancestor.
    -   The ancestor component becomes the "single source of truth."
    -   It passes state **down** to children via properties or attributes.
    -   Children communicate changes **up** to the parent via `CustomEvent`s.
-   **Core Principles:**
    -   **Group related state:** If you always update two variables together, merge them.
    -   **Avoid redundant state:** Calculate derived data during rendering instead of storing it in state.
    -   **Avoid duplication:** Do not store the same data in multiple places.
    -   **Prefer flat state:** Avoid deeply nested state objects where possible, as they are harder to update.
-   **Context Pattern (for Deeply Nested State):**
    -   To avoid "prop drilling" (passing state through many intermediate components), a context pattern can be used.
    -   A provider component (e.g., `<lw-theme-context>`) holds the state.
    -   Any descendant component can request access to this state by dispatching a special `context-request` event, subscribing to updates without needing the props to be passed down manually.

-   **Reactive State with Tiny Signals:** To implement fine-grained reactive state management, this project will use `signals.js`, a lightweight signals implementation. This allows state changes to automatically trigger UI updates where needed.
    -   **`signal(initialValue)`**: Creates a new signal, which is a container for a piece of state.
    -   **`.value`**: The property used to get or set the state of a signal.
    -   **`computed(() => {...}, [deps])`**: Creates a new signal whose value is derived from other signals. It automatically updates when its dependencies change.
    -   **`.effect(() => {...})`**: A function that runs automatically whenever a signal it depends on changes. This is the primary way to sync state with the DOM.
    ```javascript
    import { signal, computed } from './lib/signals.js';

    // 1. Create base state
    const todos = signal([
      { text: 'Buy milk', completed: true },
      { text: 'Walk the dog', completed: false },
    ]);

    // 2. Create derived state
    const incompleteCount = computed(() => {
      return todos.value.filter(todo => !todo.completed).length;
    }, [todos]);

    // 3. React to changes and update the DOM
    incompleteCount.effect(() => {
      document.getElementById('count').textContent = incompleteCount.value;
    });

    // 4. Mutating the signal's value will automatically update the count
    // todos.value = [...todos.value, { text: 'New todo', completed: false }];
    ```
