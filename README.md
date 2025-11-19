```markdown
elm make src/Main.elm --output=lw-elm.js --debug

```

## Editing list item (contenteditable) flow

This project uses a contenteditable div for each list item. Editing involves both Elm and JavaScript communicating through Elm ports. The section below documents the end-to-end flow, the port contracts, Elm messages, and helpful debugging tips.

High-level sequence (user edits an item):

1. User focuses and edits the contenteditable div (rendered with id `item-<id>` in `src/Main.elm`).
2. The browser detects input and JavaScript collects caret/selection info when requested by Elm. Elm receives edited content via the `editableInput` port and sends commands back to JS when it needs the caret or to set the caret.
3. Elm decodes the port payload and dispatches `EditableInput` (or related) messages which update the Model and may trigger tag-popup logic or caret-related tasks.
4. If Elm needs the current caret coordinates to position the TagPopup, it uses `requestCursorPosition` port; `index.html` responds by computing coordinates and sending them back via `receiveCursorPosition`.
5. If Elm needs the current character offset inside the contenteditable element (for inserting a selected tag), it uses `getCurrentCursorPosition` which the JS responds to by sending `receiveCurrentCursorPosition` with `{ itemId, tag, cursorPos }`.
6. Elm handles actions like InsertSelectedTag, SaveItem, UpdateItemContent, etc. Some actions ask JS to set the caret via the `setCaret` port which triggers the JS handler to place the cursor in the right text node and offset.

Ports and contracts (summary)

- editableInput (Sub Msg)
	- JS -> Elm
	- Payload decoded by `editableInputDecoder` into `EditableInput { id : Int, content : String, cursorPos : Int }`
	- Sent when JS wants Elm to know the latest innerHTML/content (see `Main.elm`'s subscriptions for usage)

- requestCursorPosition (Cmd Int)
	- Elm -> JS
	- JS computes caret coordinates relative to viewport using the current Selection and sends back through `receiveCursorPosition`

- receiveCursorPosition (Sub Msg)
	- JS -> Elm
	- Payload is an object with `{ top: Int, left: Int, width: Int }`; Elm decodes and handles `GotCursorPosition`

- getCurrentCursorPosition (Cmd Int)
	- Elm -> JS
	- Elm asks JS to send the numeric character offset inside the focused contenteditable for a given `itemId`.

- receiveCurrentCursorPosition (Sub Msg)
	- JS -> Elm
	- Payload decoded to extract `{ itemId, tag, cursorPos }`. Elm reacts by inserting tags or continuing tag-insertion logic (see `GotCurrentCursorPosition` handling in `Main.elm`).

- setCaret (Cmd { id : Int, pos : Int })
	- Elm -> JS
	- Elm instructs JS to place the caret at `pos` inside element `item-<id>`. JS locates text nodes and BRs to compute the correct Range.

Key Elm messages involved (non-exhaustive)

- EditableInput { id, content, cursorPos }
	- Dispatched from the `editableInput` port decoder. Triggers `UpdateItemContent` after verifying the item exists (uses `ListItem.findInForest`).

- UpdateItemContent item content cursorPos currentTime
	- Updates the item content in the model. If the cursor is inside tag brackets, this can open/update the TagPopup and request the caret coordinates (via `requestCursorPosition`) so the popup can be positioned.

- GotCursorPosition top left width
	- Received from `receiveCursorPosition`. If the TagPopup has tags, Elm will call `showPopup` with the coordinates.

- GetCurrentCursorPosition and GotCurrentCursorPosition
	- Used when Elm needs the numeric cursor offset to do tag insertion (InsertSelectedTag). JS computes the offset and sends it back to Elm via `receiveCurrentCursorPosition`.

- InsertSelectedTag item tag cursorPos currentTime
	- Elm computes new content with the selected tag inserted at `cursorPos`, updates the model, hides the TagPopup, and enqueues a `setCaret` action by setting `caretTask = Just ( itemId, newCaretPos )` so the `subscriptions` will send a `SetCaret` message on the next animation frame.

How JS in `index.html` supports this flow

- `app.ports.editableInput` subscription: Elm provides a decoder; when JS sends payloads they become `EditableInput` messages in Elm.
- `app.ports.setCaret.subscribe`: JS focuses the contenteditable `item-<id>` and walks its childNodes to set a Range and place the caret at the requested character offset. BR nodes are treated as one character each.
- `app.ports.requestCursorPosition.subscribe`: JS computes visible coordinates for the current selection range and sends `{ top, left, width }` back through `receiveCursorPosition`.
- `app.ports.getCurrentCursorPosition.subscribe`: JS computes the numeric cursor offset inside the focused element and sends `{ itemId, tag, cursorPos }` back via `receiveCurrentCursorPosition`.

Data shapes to watch

- editableInput payload (JS -> Elm): { id: Int, content: String, cursorPos: Int }
- receiveCursorPosition payload (JS -> Elm): { top: Int, left: Int, width: Int }
- receiveCurrentCursorPosition payload (JS -> Elm): { itemId: Int, tag: String, cursorPos: Int }
- setCaret payload (Elm -> JS): { id: Int, pos: Int }

Edge cases and debugging tips

- Contenteditable structure: the JS `setCaret` implementation iterates text nodes and treats BR as one character. If your content has nested elements or unexpected nodes (e.g., spans introduced by browser paste), offsets may be off. Inspect `item-<id>.childNodes` in the console to verify node types and lengths.
- Multiline handling: line breaks are represented by BR nodes and newlines in text nodes. Caret offset counting must match `ListItem` parsing and Elm's `String.split "\\n"` behavior.
- Tag detection: TagPopup logic relies on `isInsideTagBrackets` which expects the cursor offset inside the text content; mismatched offsets cause the popup to not appear or insert tags in the wrong place.
- Port message decoding: If Elm side rejects a port payload due to decoder mismatch, the subscription falls back to `NoOp` in `Main.elm`. Use `console.log` in JS before sending ports to confirm shapes.
- Race conditions: Elm sometimes sets `caretTask` which `subscriptions` turns into a `SetCaret` on animation frame. If the DOM isn't yet updated, the target element may not be focused. `Browser.Dom.focus` is used in some flows; use `FocusResult` messages to trace focus attempts.

Small checklist for reproducing and debugging

1. Open devtools console and add logging to all port handlers in `index.html`.
2. While editing a contenteditable item, watch messages from JS to Elm (editableInput, receiveCursorPosition, receiveCurrentCursorPosition) and from Elm to JS (requestCursorPosition, getCurrentCursorPosition, setCaret).
3. If a TagPopup doesn't appear, verify `cursorPos` sent in `EditableInput` matches expectations and that `isInsideTagBrackets` returns a non-Nothing result.

If you'd like, I can:

- Add logging wrappers around the relevant ports in `index.html` to make runtime debugging easier.
- Generate a sequence diagram-style ASCII or Mermaid diagram to include in this README section.
