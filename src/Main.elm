port module Main exposing (main)

import Actions exposing (SearchToolbarAction)
import Browser
import Browser.Dom
import Browser.Events
import Clipboard
import Html exposing (Html, code, div, span, text, textarea)
import Html.Attributes exposing (id, rows, value)
import Html.Events exposing (on, onBlur, onClick, preventDefaultOn, stopPropagationOn)
import Json.Decode as D
import KeyboardHandler
import ListItem exposing (ListItem(..), deleteItem, editItemFn, expandToItem, filterItems, findEditingItem, findNextItem, findPreviousItem, getAllTags, getChildren, getContent, getId, getNextId, getTags, indentItem, insertItemAfter, isCollapsed, isEditing, mapItem, moveItemInTree, newEmptyListItem, newListItem, outdentItem, saveItemFn, setAllCollapsed, toggleCollapseFn, updateItemContentFn)
import NewItemButton
import Regex
import SearchToolbar exposing (getUpdatedCursorPosition, resetUpdatedCursorPosition)
import TagPopup exposing (currentSource, isVisible, navigateUp)
import TagsUtils exposing (Change(..), isInsideTagBrackets, isTagRegex)
import Task
import Time exposing (Month(..), Posix, millisToPosix)
import TagPopup exposing (navigateDown)
import TagPopup exposing (hidePopup)
import TagPopup exposing (showPopup)



-- PORTS


port clickedAt : ({ id : Int, pos : Int } -> msg) -> Sub msg


port setCaret : { id : Int, pos : Int } -> Cmd msg


port getPosition : { id : Int, clientX : Int, clientY : Int } -> Cmd msg


port requestCursorPosition : Int -> Cmd msg


port receiveCursorPosition : (D.Value -> msg) -> Sub msg


port resizeTextarea : Int -> Cmd msg


port getSearchInputPosition : () -> Cmd msg


port setSearchInputCursor : Int -> Cmd msg


port getCurrentCursorPosition : Int -> Cmd msg


port receiveCurrentCursorPosition : (D.Value -> msg) -> Sub msg



-- MODEL


type alias Model =
    { items : List ListItem
    , cursorPos : Maybe Int
    , caretTask : Maybe ( Int, Int )
    , pendingTagInsertion : Maybe String
    , tagPopup : TagPopup.Model
    , searchToolbar : SearchToolbar.Model
    , noBlur : Bool
    , clipboard : Clipboard.Model
    , selectedTags : List String
    }


initialModel : Model
initialModel =
    { items =
        [ newListItem
            { id = 1
            , content = [ "Meeting notes 2025-09-01", "Discussed project timeline with team. Action items: @todo @exercise" ]
            , tags = [ "todo", "exercise" ]
            , collapsed = True
            , editing = False
            , created = millisToPosix 1757532035027
            , children =
                [ newListItem { id = 2, content = [ "Review requirements @todo" ], tags = [ "todo" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027 }
                , newListItem { id = 7, content = [ "Schedule next meeting 2 @calendar" ], tags = [ "calendar" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027 }
                , newListItem { id = 3, content = [ "Code example:", "```", "function test() {", "  // This @todo should not be clickable", "  return @value;", "}", "```", "But this @todo should work" ], tags = [ "todo" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027 }
                ]
            }
        , newListItem
            { id = 4
            , content = [ "Search Tutorial - How to use the search box", "Type text to search content across all items", "Use @tag to filter by specific tags (e.g., @todo)", "Selected tags appear as chips below search box" ]
            , tags = [ "tag", "todo" ]
            , created = millisToPosix 1757532035027
            , collapsed = True
            , editing = False
            , children =
                [ newListItem { id = 5, content = [ "Text Search: Type any word to find matching items @search" ], tags = [ "search" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027 }
                , newListItem { id = 6, content = [ "Tag Filtering: Type @tutorial to see only tutorial items @tutorial" ], tags = [ "tutorial" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027 }
                ]
            }
        ]
    , cursorPos = Nothing
    , caretTask = Nothing
    , pendingTagInsertion = Nothing
    , tagPopup = TagPopup.init
    , searchToolbar = SearchToolbar.init
    , noBlur = False
    , clipboard = Clipboard.init
    , selectedTags = []
    }



-- UPDATE


type Msg
    = ToggleCollapse ListItem
    | EditItem Int
    | UpdateItemContent ListItem String Int
    | SaveItem ListItem
    | CreateItemAfter ListItem
    | CreateItemAfterWithTime ListItem Posix
    | CreateItemAtEnd
    | CreateItemAtEndWithTime Posix
    | IndentItem Int ListItem
    | OutdentItem Int ListItem
    | DeleteItem ListItem
    | SaveAndCreateAfter ListItem
    | FocusResult (Result Browser.Dom.Error ())
    | ClickedAt { id : Int, pos : Int }
    | SetCaret Int Int
    | SetSearchCursor Int
    | GotCursorPosition Int Int Int
    | GotCurrentCursorPosition ListItem String Int
    | NoOp
    | MoveItemUp Int ListItem
    | SearchToolbarMsg SearchToolbar.Msg
    | MoveItemDown Int ListItem
    | ToggleNoBlur
    | EditItemClick ListItem Int Int
    | InsertSelectedTag ListItem String Int
    | NavigateToPreviousWithColumn ListItem Int
    | NavigateToNextWithColumn ListItem Int
    | ClipboardMsg Clipboard.Msg
    | TagPopupMsg TagPopup.Msg
    | SearchTagSelected String
    | RemoveSelectedTag String
    | ClearAllSelectedTags
    | AddTagToSelected String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TagPopupMsg tagPopupMsg ->
            let
                ( updatedmodel, action ) =
                    TagPopup.update tagPopupMsg model.tagPopup
            in
            case action of
                Just (Actions.HighlightTag tag) ->
                    case currentSource model.tagPopup of
                        Just TagPopup.FromSearchToolbar ->
                            -- Tag selection from search input
                            update (SearchTagSelected tag) { model | tagPopup = updatedmodel }

                        Just TagPopup.FromItem ->
                            -- Tag selection from textarea - get current cursor position
                            case findEditingItem model.items of
                                Just ( editingItem, _ ) ->
                                    ( { model | tagPopup = updatedmodel, pendingTagInsertion = Just tag }, getCurrentCursorPosition (getId editingItem) )

                                Nothing ->
                                    ( { model | tagPopup = updatedmodel }, Cmd.none )

                        _ ->
                            ( { model | tagPopup = updatedmodel }, Cmd.none )

                _ ->
                    ( { model | tagPopup = updatedmodel }, Cmd.none )

        EditItemClick item x y ->
            ( model, getPosition { id = getId item, clientX = x, clientY = y } )

        ToggleNoBlur ->
            ( { model | noBlur = not model.noBlur }, Cmd.none )

        SearchToolbarMsg searchToolbarMsg ->
            let
                ( updatedSearchToolbarModel, action ) =
                    SearchToolbar.update searchToolbarMsg model.searchToolbar

                ( updatedModel, cmd ) =
                    case action of
                        Just act ->
                            case act of
                                Actions.CollapseAll ->
                                    ( { model | items = setAllCollapsed True model.items }, Cmd.none )

                                Actions.ExpandAll ->
                                    ( { model | items = setAllCollapsed False model.items }, Cmd.none )

                                Actions.KeyEnter ->
                                    case TagPopup.getHighlightedTag model.tagPopup of
                                        Just tag ->
                                            update (SearchTagSelected tag) model

                                        Nothing ->
                                            ( model, Cmd.none )

                                Actions.KeyArrowUp ->
                                    ( { model | tagPopup = navigateUp model.tagPopup }, Cmd.none )

                                Actions.KeyArrowDown ->
                                    ( { model | tagPopup = navigateDown model.tagPopup }, Cmd.none )

                                Actions.QueryChanged query cursorPos ->
                                    let
                                        tagPopupTags =
                                            isInsideTagBrackets cursorPos query
                                                |> Maybe.map
                                                    (\( tagSearchPrefix, _ ) ->
                                                        getAllTags model.items
                                                            |> List.filter (String.startsWith tagSearchPrefix)
                                                    )

                                        ( updatedTagPopup, updatedCmd ) =
                                            case tagPopupTags of
                                                Just tags ->
                                                    if List.isEmpty tags then
                                                        ( hidePopup model.tagPopup, Cmd.none )

                                                    else
                                                        ( TagPopup.setTags ( tags, TagPopup.FromSearchToolbar ) model.tagPopup, getSearchInputPosition () )

                                                Nothing ->
                                                    ( hidePopup model.tagPopup, Cmd.none )
                                    in
                                    ( { model | tagPopup = updatedTagPopup }
                                    , updatedCmd
                                    )

                        Nothing ->
                            ( model, Cmd.none )
            in
            ( { updatedModel | searchToolbar = updatedSearchToolbarModel }, cmd )

        ToggleCollapse item ->
            ( { model | items = mapItem (toggleCollapseFn item) model.items }
            , Cmd.none
            )

        ClickedAt { id, pos } ->
            update (EditItem id) { model | cursorPos = Just pos }

        EditItem id ->
            let
                newModel =
                    { model | items = mapItem (editItemFn id) model.items }

                ( updatedModel, command ) =
                    case model.cursorPos of
                        Just pos ->
                            ( { newModel | caretTask = Just ( id, pos ) }, Cmd.none )

                        Nothing ->
                            let
                                inputId =
                                    "input-id-" ++ String.fromInt id
                            in
                            ( newModel, Task.attempt FocusResult (Browser.Dom.focus inputId) )
            in
            ( { updatedModel | cursorPos = Nothing }, command )

        SetCaret itemId pos ->
            ( { model | caretTask = Nothing }, setCaret { id = itemId, pos = pos } )

        SetSearchCursor pos ->
            ( { model | searchToolbar = resetUpdatedCursorPosition model.searchToolbar }, setSearchInputCursor pos )

        GotCurrentCursorPosition item tag cursorPos ->
            ( { model | pendingTagInsertion = Nothing }, Cmd.none )
                |> (\( m, c ) -> update (InsertSelectedTag item tag cursorPos) m |> Tuple.mapSecond (\cmd -> Cmd.batch [ c, cmd ]))

        UpdateItemContent item content cursorPos ->
            let
                itemId =
                    getId item
            in
            case isInsideTagBrackets cursorPos content of
                Just ( tagSearchPrefix, tag ) ->
                    let
                        matchingTags =
                            getAllTags model.items
                                |> List.filter (String.startsWith tagSearchPrefix)
                                |> List.filter ((/=) tag)

                        updatedTagPopup =
                            if List.isEmpty matchingTags then
                                hidePopup model.tagPopup

                            else
                                -- Store tags temporarily - position will be set when GotCursorPosition arrives
                                TagPopup.setTags ( matchingTags, TagPopup.FromItem ) model.tagPopup
                    in
                    ( { model
                        | items = mapItem (updateItemContentFn item content) model.items
                        , tagPopup = updatedTagPopup
                        , noBlur = List.isEmpty matchingTags |> not
                      }
                    , Cmd.batch [ requestCursorPosition itemId, resizeTextarea itemId ]
                    )

                Nothing ->
                    ( { model
                        | items = mapItem (updateItemContentFn item content) model.items
                        , tagPopup = hidePopup model.tagPopup
                      }
                    , resizeTextarea itemId
                    )

        MoveItemUp cursorPosition item ->
            ( { model | noBlur = True, items = moveItemInTree ListItem.moveItemUp item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        MoveItemDown cursorPosition item ->
            ( { model | noBlur = True, items = moveItemInTree ListItem.moveItemDown item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        IndentItem cursorPosition item ->
            ( { model | noBlur = True, items = indentItem item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        OutdentItem cursorPosition item ->
            ( { model | noBlur = True, items = outdentItem item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        GotCursorPosition top left width ->
            case TagPopup.getTags model.tagPopup of
                Just tags ->
                    ( { model | tagPopup = showPopup ( top, left, width ) tags model.tagPopup }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveItem item ->
            if model.noBlur then
                ( model, Task.perform (\_ -> ToggleNoBlur) (Task.succeed ()) )

            else
                ( { model
                    | items = mapItem (saveItemFn item) model.items
                    , tagPopup = hidePopup model.tagPopup
                  }
                , Cmd.none
                )

        CreateItemAfter item ->
            ( model, Task.perform (CreateItemAfterWithTime item) Time.now )

        CreateItemAfterWithTime item currentTime ->
            let
                newId =
                    getNextId model.items

                newItems =
                    insertItemAfter item newId model.items currentTime |> mapItem (editItemFn newId)
            in
            ( { model | items = newItems }
            , Task.attempt FocusResult (Browser.Dom.focus ("input-id-" ++ String.fromInt newId))
            )

        CreateItemAtEnd ->
            ( model, Task.perform CreateItemAtEndWithTime Time.now )

        CreateItemAtEndWithTime currentTime ->
            let
                newId =
                    getNextId model.items

                newModel =
                    { model | items = model.items ++ [ newEmptyListItem currentTime newId |> editItemFn newId ] }
            in
            ( newModel, Task.attempt FocusResult (Browser.Dom.focus ("input-id-" ++ String.fromInt newId)) )

        SaveAndCreateAfter item ->
            let
                ( afterSave, _ ) =
                    update (SaveItem item) model
            in
            update (CreateItemAfter item) afterSave

        FocusResult _ ->
            ( model, Cmd.none )

        DeleteItem item ->
            ( { model | items = deleteItem item model.items }, Cmd.none )

        InsertSelectedTag item tag cursorPos ->
            let
                content =
                    String.join "\n" (getContent item)

                ( newContent, newCaretPos ) =
                    TagsUtils.insertTagAtCursor content tag cursorPos
            in
            ( { model
                | items = mapItem (updateItemContentFn item newContent) model.items
                , tagPopup = hidePopup model.tagPopup
                , noBlur = False
                , caretTask = Just ( getId item, newCaretPos )
              }
            , Cmd.none
            )

        NavigateToPreviousWithColumn item columnPos ->
            case findPreviousItem item model.items of
                Just prevItem ->
                    let
                        prevId =
                            getId prevItem

                        prevContent =
                            String.join "\n" (getContent prevItem)

                        prevLines =
                            String.lines prevContent

                        lastLine =
                            List.reverse prevLines |> List.head |> Maybe.withDefault ""

                        targetPos =
                            min columnPos (String.length lastLine)

                        lineStartPos =
                            String.length prevContent - String.length lastLine

                        finalPos =
                            lineStartPos + targetPos
                    in
                    ( { model | items = mapItem (editItemFn prevId) model.items, caretTask = Just ( prevId, finalPos ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        NavigateToNextWithColumn item columnPos ->
            case findNextItem item model.items of
                Just nextItem ->
                    let
                        nextId =
                            getId nextItem

                        nextContent =
                            String.join "\n" (getContent nextItem)

                        firstLine =
                            String.lines nextContent |> List.head |> Maybe.withDefault ""

                        targetPos =
                            min columnPos (String.length firstLine)
                    in
                    ( { model | items = mapItem (editItemFn nextId) model.items, caretTask = Just ( nextId, targetPos ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ClipboardMsg clipboardMsg ->
            let
                ( updatedClipboard, updatedItems, maybeCaretTask ) =
                    Clipboard.update clipboardMsg model.clipboard

                newCaretTask =
                    case maybeCaretTask of
                        Just caretTask ->
                            Just caretTask

                        Nothing ->
                            model.caretTask
            in
            ( { model
                | clipboard = updatedClipboard
                , items = updatedItems
                , caretTask = newCaretTask
              }
            , Cmd.none
            )

        SearchTagSelected tag ->
            if String.isEmpty tag || List.member tag model.selectedTags then
                ( model, Cmd.none )

            else
                ( { model
                    | selectedTags = model.selectedTags ++ [ tag ]
                    , tagPopup = hidePopup model.tagPopup
                  }
                , Cmd.none
                )

        RemoveSelectedTag tag ->
            ( { model | selectedTags = List.filter ((/=) tag) model.selectedTags }, Cmd.none )

        ClearAllSelectedTags ->
            ( { model | selectedTags = [] }, Cmd.none )

        AddTagToSelected tag ->
            if String.isEmpty tag || List.member tag model.selectedTags then
                ( model, Cmd.none )
            else
                ( { model | selectedTags = model.selectedTags ++ [ tag ] }, Cmd.none )



-- HELPERS


andThen : (model -> ( model, Cmd msg )) -> ( model, Cmd msg ) -> ( model, Cmd msg )
andThen fn ( model, cmd ) =
    let
        ( nextModel, nextCmd ) =
            fn model
    in
    ( nextModel, Cmd.batch [ cmd, nextCmd ] )



-- VIEW


viewSelectedTags : List String -> Html Msg
viewSelectedTags selectedTags =
    if List.isEmpty selectedTags then
        text ""

    else
        div
            [ Html.Attributes.style "margin-bottom" "12px"
            , Html.Attributes.style "display" "flex"
            , Html.Attributes.style "flex-wrap" "wrap"
            , Html.Attributes.style "gap" "6px"
            , Html.Attributes.style "align-items" "center"
            ]
            (List.map viewTagChip selectedTags ++ [ viewClearAllButton ])


viewTagChip : String -> Html Msg
viewTagChip tag =
    div
        [ Html.Attributes.style "background" "#e3f2fd"
        , Html.Attributes.style "border" "1px solid #90caf9"
        , Html.Attributes.style "border-radius" "12px"
        , Html.Attributes.style "padding" "4px 8px"
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "gap" "4px"
        , Html.Attributes.style "font-size" "12px"
        ]
        [ text ("@" ++ tag)
        , span
            [ onClick (RemoveSelectedTag tag)
            , Html.Attributes.style "cursor" "pointer"
            , Html.Attributes.style "color" "#666"
            , Html.Attributes.style "font-weight" "bold"
            , Html.Attributes.style "user-select" "none"
            ]
            [ text "×" ]
        ]


viewClearAllButton : Html Msg
viewClearAllButton =
    div
        [ onClick ClearAllSelectedTags
        , Html.Attributes.style "background" "#f5f5f5"
        , Html.Attributes.style "border" "1px solid #ccc"
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "padding" "4px 8px"
        , Html.Attributes.style "cursor" "pointer"
        , Html.Attributes.style "font-size" "12px"
        , Html.Attributes.style "user-select" "none"
        ]
        [ text "Clear all" ]


view : Model -> Html Msg
view model =
    div
        [ Html.Attributes.style "max-width" "800px"
        , Html.Attributes.style "margin" "0 auto"
        , Html.Attributes.style "padding" "20px"
        , onClick (TagPopupMsg TagPopup.Hide)
        ]
        ((TagPopup.view model.tagPopup |> Html.map TagPopupMsg)
            :: (SearchToolbar.view model.searchToolbar (isVisible model.tagPopup) |> Html.map SearchToolbarMsg)
            :: viewSelectedTags model.selectedTags
            :: (List.map (viewListItem model 0) (filterItems (SearchToolbar.getSearchQuery model.searchToolbar) model.selectedTags model.items) ++ [ NewItemButton.view CreateItemAtEnd ])
        )


viewListItem : Model -> Int -> ListItem -> Html Msg
viewListItem model level item =
    let
        arrow =
            if getChildren item |> List.isEmpty then
                span [ Html.Attributes.style "width" "20px", Html.Attributes.style "display" "inline-block", Html.Attributes.style "line-height" "1.8" ] []

            else
                span
                    [ onClick (ToggleCollapse item)
                    , Html.Attributes.style "cursor" "pointer"
                    , Html.Attributes.style "user-select" "none"
                    , Html.Attributes.style "width" "20px"
                    , Html.Attributes.style "min-width" "20px"
                    , Html.Attributes.style "display" "inline-flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "line-height" "1.8"
                    ]
                    [ if isCollapsed item then
                        text "+"

                      else
                        text "-"
                    ]

        childrenBlock =
            if isCollapsed item then
                []

            else
                List.map (viewListItem model (level + 1)) (getChildren item)

        itemRow =
            let
                styles =
                    [ Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "flex-start"
                    , Html.Attributes.style "margin-left" (String.fromInt (level * 24) ++ "px")
                    , Html.Attributes.style "max-width" "80%"
                    ]

                extraStyles =
                    if List.isEmpty (getChildren item) then
                        []

                    else
                        [ Html.Attributes.style "margin-bottom" "5px" ]
            in
            div (styles ++ extraStyles)
                [ arrow
                , span
                    [ Html.Attributes.style "width" "20px"
                    , Html.Attributes.style "min-width" "20px"
                    , Html.Attributes.style "display" "inline-flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "user-select" "none"
                    , Html.Attributes.style "line-height" "1.8"
                    ]
                    [ text "•" ]
                , if isEditing item then
                    viewEditableItem model item

                  else
                    viewStaticItem model.items model.selectedTags item
                ]
    in
    div
        [ Html.Attributes.style "margin-bottom" "5px"
        , Html.Attributes.style "background" "#f5f5f5"
        , Html.Attributes.style "border" "1px solid #ccc"
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "padding" "4px 8px"
        , Html.Attributes.style "font-size" "12px"
        ]
        (itemRow :: childrenBlock)


viewStaticItem : List ListItem -> List String -> ListItem -> Html Msg
viewStaticItem items selectedTags item =
    let
        onClickCustom =
            let
                clientXDecoder =
                    D.field "clientX" D.int

                clientYDecoder =
                    D.field "clientY" D.int
            in
            on "click" (D.map2 (\x y -> EditItemClick item x y) clientXDecoder clientYDecoder)

        contentBlocks =
            TagsUtils.processContent (getContent item)

        viewBlock ( isCode, lines ) =
            if isCode then
                div []
                    [ code
                        [ Html.Attributes.style "display" "block"
                        , Html.Attributes.style "white-space" "pre-wrap"
                        , Html.Attributes.style "line-height" "1.8"
                        , Html.Attributes.style "background" "#f5f5f5"
                        , Html.Attributes.style "padding" "8px"
                        , Html.Attributes.style "border-radius" "4px"
                        , Html.Attributes.style "margin" "4px 0"
                        , Html.Attributes.style "font-family" "monospace"
                        ]
                        (List.map (\line -> div [] [ text line ]) lines)
                    ]

            else
                div []
                    (List.map
                        (\line ->
                            div
                                [ Html.Attributes.style "white-space" "pre-wrap"
                                , Html.Attributes.style "line-height" "1.8"
                                ]
                                (viewContentWithSelectedTags items item line selectedTags)
                        )
                        lines
                    )
    in
    div [ id ("view-item-" ++ String.fromInt (getId item)), Html.Attributes.tabindex -1, Html.Attributes.style "flex-grow" "1" ]
        [ div [ Html.Attributes.class "content-click-area", onClickCustom ]
            (if List.isEmpty (getContent item) then
                [ span [ Html.Attributes.style "color" "#aaa", Html.Attributes.style "line-height" "1.8" ] [ text "empty" ] ]

             else
                List.map viewBlock contentBlocks
            )
        ]


viewEditableItem : { a | noBlur : Bool, tagPopup : TagPopup.Model, clipboard : Clipboard.Model, items : List ListItem } -> ListItem -> Html Msg
viewEditableItem { noBlur, tagPopup, clipboard, items } item =
    let
        keyboardConfig =
            { tagPopup = tagPopup
            , clipboard = clipboard
            , onMoveItemUp = MoveItemUp
            , onMoveItemDown = MoveItemDown
            , onCutItem = \targetItem -> ClipboardMsg (Clipboard.CutItem targetItem items)
            , onPasteItem = \targetItem -> ClipboardMsg (Clipboard.PasteItem targetItem items)
            , onDeleteItem = DeleteItem
            , onInsertSelectedTag = InsertSelectedTag
            , onSaveAndCreateAfter = SaveAndCreateAfter
            , onIndentItem = IndentItem
            , onOutdentItem = OutdentItem
            , onTagPopupMsg = TagPopupMsg
            , onNavigateToPreviousWithColumn = NavigateToPreviousWithColumn
            , onNavigateToNextWithColumn = NavigateToNextWithColumn
            , onRestoreCutItem = ClipboardMsg (Clipboard.RestoreCutItem items)
            , onNoOp = NoOp
            }
    in
    div [ Html.Attributes.style "flex-grow" "1" ]
        [ textarea
            [ Html.Attributes.id ("input-id-" ++ String.fromInt (getId item))
            , value (String.join "\n" (getContent item))
            , preventDefaultOn "input"
                (D.map2
                    (\value selectionStart ->
                        ( UpdateItemContent item value selectionStart, False )
                    )
                    (D.field "target" (D.field "value" D.string))
                    (D.field "target" (D.field "selectionStart" D.int))
                )
            , onBlur
                (if noBlur then
                    NoOp

                 else
                    SaveItem item
                )
            , KeyboardHandler.onKeyDown keyboardConfig item
            , rows (List.length (getContent item))
            , Html.Attributes.style "box-sizing" "border-box"
            , Html.Attributes.style "overflow-y" "hidden"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "border" "none"
            , Html.Attributes.style "outline" "none"
            , Html.Attributes.style "background" "transparent"
            , Html.Attributes.style "width" "100%"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "padding" "0"
            , Html.Attributes.style "margin" "0"
            , Html.Attributes.style "display" "block"
            , Html.Attributes.style "line-height" "1.8"
            ]
            []
        ]


viewContentWithSelectedTags : List ListItem -> ListItem -> String -> List String -> List (Html Msg)
viewContentWithSelectedTags items item content selectedTags =
    let
        pieces =
            Regex.split isTagRegex content

        matches =
            Regex.find isTagRegex content
    in
    case pieces of
        [ first ] ->
            [ text first ]

        _ ->
            renderContentWithSelectedTags items item pieces matches selectedTags


renderContentWithSelectedTags : List ListItem -> ListItem -> List String -> List Regex.Match -> List String -> List (Html Msg)
renderContentWithSelectedTags items item pieces matches selectedTags =
    case ( pieces, matches ) of
        ( p :: ps, m :: ms ) ->
            let
                tag =
                    case m.submatches of
                        (Just t) :: _ ->
                            t

                        _ ->
                            ""

                isSelectedTag =
                    List.member tag selectedTags

                tagStyle =
                    if isSelectedTag then
                        [ Html.Attributes.style "background" "#ffeb3b"
                        , Html.Attributes.style "color" "#000"
                        , Html.Attributes.style "font-weight" "bold"
                        ]

                    else
                        [ Html.Attributes.style "color" "#007acc" ]
            in
            [ text p
            , span
                ([ stopPropagationOn "click" (D.succeed ( AddTagToSelected tag, True ))
                 , Html.Attributes.style "cursor" "pointer"
                 , Html.Attributes.style "user-select" "none"
                 , Html.Attributes.style "white-space" "nowrap"
                 ]
                    ++ tagStyle
                )
                [ text m.match ]
            ]
                ++ renderContentWithSelectedTags items item ps ms selectedTags

        ( p :: _, [] ) ->
            [ text p ]

        _ ->
            []



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ clickedAt ClickedAt
        , case model.caretTask of
            Just ( id, pos ) ->
                Browser.Events.onAnimationFrame
                    (\_ -> SetCaret id pos)

            Nothing ->
                Sub.none
        , case getUpdatedCursorPosition model.searchToolbar of
            Just pos ->
                Browser.Events.onAnimationFrame
                    (\_ -> SetSearchCursor pos)

            Nothing ->
                Sub.none
        , receiveCursorPosition
            (\value ->
                case D.decodeValue (D.map3 GotCursorPosition (D.field "top" D.int) (D.field "left" D.int) (D.field "width" D.int)) value of
                    Ok msg ->
                        msg

                    Err _ ->
                        GotCursorPosition 0 0 0
            )
        , receiveCurrentCursorPosition
            (\value ->
                case
                    D.decodeValue
                        (D.map3
                            (\itemId tag cursorPos ->
                                case findEditingItem model.items of
                                    Just ( editingItem, _ ) ->
                                        case model.pendingTagInsertion of
                                            Just pendingTag ->
                                                GotCurrentCursorPosition editingItem pendingTag cursorPos

                                            Nothing ->
                                                NoOp

                                    Nothing ->
                                        NoOp
                            )
                            (D.field "itemId" D.int)
                            (D.field "tag" D.string)
                            (D.field "cursorPos" D.int)
                        )
                        value
                of
                    Ok msg ->
                        msg

                    Err _ ->
                        NoOp
            )
        ]
