port module Main exposing (main)

import Actions exposing (SortOrder(..))
import Browser
import Browser.Dom
import Browser.Events
import Clipboard
import Html exposing (Html, br, code, div, span, text)
import Html.Attributes exposing (attribute, id, style)
import Html.Events exposing (on, onBlur, onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Json.Encode as Encode
import KeyboardHandler
import ListItem exposing (ListItem(..), deleteItem, editItemFn, findEditingItem, findNextItem, findPreviousItem, getAllTags, getChildren, getContent, getId, getNextId, indentItem, insertItemAfter, isCollapsed, isEditing, mapItem, moveItemInTree, newEmptyListItem, newListItem, outdentItem, removeItemCompletely, saveItemFn, setAllCollapsed, toggleCollapseFn, updateItemContentFn)
import Regex
import SearchToolbar exposing (addTagToSelected, getFilteredItems, getSelectedTags, getUpdatedCursorPosition, resetUpdatedCursorPosition, selectTag)
import TagPopup exposing (currentSource, hidePopup, isVisible, navigateDown, navigateUp, showPopup)
import TagsUtils exposing (Change(..), isInsideTagBrackets, isTagRegex)
import Task
import Theme
import Time exposing (Month(..), Posix, millisToPosix)



-- PORTS


port clickedAt : ({ id : Int, pos : Int } -> msg) -> Sub msg


port setCaret : { id : Int, pos : Int } -> Cmd msg


port requestCursorPosition : () -> Cmd msg


port receiveCursorPosition : (D.Value -> msg) -> Sub msg


port getSearchInputPosition : () -> Cmd msg


port setSearchInputCursor : Int -> Cmd msg


port getCurrentCursorPosition : Int -> Cmd msg


port receiveCurrentCursorPosition : (D.Value -> msg) -> Sub msg


port downloadJson : { filename : String, content : String } -> Cmd msg


port readFile : () -> Cmd msg


port receiveFile : (D.Value -> msg) -> Sub msg



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
    }


initialModel : Model
initialModel =
    { items =
        [ newListItem
            { id = 1
            , content = [ "Meeting notes 2025-09-01", "Discussed project timeline with team. Action items: @todo @exercise" ]
            , tags = [ "todo", "exercise", "created:09/08/2025", "updated:09/08/2025" ]
            , collapsed = True
            , editing = False
            , created = millisToPosix 1757532035027
            , updated = millisToPosix 1757532035027
            , children =
                [ newListItem { id = 2, content = [ "Review requirements @todo" ], tags = [ "todo", "created:09/08/2025", "updated:09/08/2025" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027 }
                , newListItem { id = 7, content = [ "Schedule next meeting 2 @calendar" ], tags = [ "calendar", "created:09/08/2025", "updated:09/08/2025" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027 }
                , newListItem { id = 3, content = [ "Code example:", "```", "function test() {", "  // This @todo should not be clickable", "  return @value;", "}", "```", "But this @todo should work" ], tags = [ "todo", "code", "created:09/08/2025", "updated:09/08/2025" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027 }
                ]
            }
        , newListItem
            { id = 4
            , content = [ "Search Tutorial - How to use the search box", "Type text to search content across all items", "Use @tag to filter by specific tags (e.g., @todo)", "Selected tags appear as chips below search box" ]
            , tags = [ "tag", "todo", "created:09/08/2025", "updated:09/08/2025" ]
            , created = millisToPosix 1757532035027
            , updated = millisToPosix 1757532035027
            , collapsed = True
            , editing = False
            , children =
                [ newListItem { id = 5, content = [ "Text Search: Type any word to find matching items @search" ], tags = [ "search", "created:09/08/2025", "updated:09/08/2025" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027 }
                , newListItem { id = 6, content = [ "Tag Filtering: Type @tutorial to see only tutorial items @tutorial" ], tags = [ "tutorial", "created:09/08/2025", "updated:09/08/2025" ], collapsed = True, editing = False, children = [], created = millisToPosix 1757532035027, updated = millisToPosix 1757532035027 }
                ]
            }
        , newListItem
            { id = 8
            , content = [ "test" ]
            , tags = [ "created:09/08/2025", "updated:09/08/2025" ]
            , created = millisToPosix 1757532035027
            , updated = millisToPosix 1757532035027
            , collapsed = True
            , editing = False
            , children = []
            }
        ]
    , cursorPos = Nothing
    , caretTask = Nothing
    , pendingTagInsertion = Nothing
    , tagPopup = TagPopup.init
    , searchToolbar = SearchToolbar.init
    , noBlur = False
    , clipboard = Clipboard.init
    }


decode =
    D.map8
        (\items cursorPos caretTask pendingTagInsertion tagPopup searchToolbar noBlur clipboard ->
            { items = items
            , cursorPos = cursorPos
            , caretTask = caretTask
            , pendingTagInsertion = pendingTagInsertion
            , tagPopup = tagPopup
            , searchToolbar = searchToolbar
            , noBlur = noBlur
            , clipboard = clipboard
            }
        )
        (D.field "items" (D.list ListItem.decode))
        (D.field "cursorPos" (D.nullable D.int))
        (D.field "caretTask" (D.nullable (D.map2 Tuple.pair D.int D.int)))
        (D.field "pendingTagInsertion" (D.nullable D.string))
        (D.field "tagPopup" TagPopup.decode)
        (D.field "searchToolbar" SearchToolbar.decode)
        (D.field "noBlur" D.bool)
        (D.field "clipboard" Clipboard.decode)


encode : Model -> Encode.Value
encode model =
    Encode.object
        [ ( "items", Encode.list ListItem.encode model.items )
        , ( "cursorPos", Maybe.map Encode.int model.cursorPos |> Maybe.withDefault Encode.null )
        , ( "caretTask"
          , Maybe.map (\( a, b ) -> Encode.list Encode.int [ a, b ]) model.caretTask |> Maybe.withDefault Encode.null
          )
        , ( "pendingTagInsertion", Maybe.map Encode.string model.pendingTagInsertion |> Maybe.withDefault Encode.null )
        , ( "tagPopup", TagPopup.encode model.tagPopup )
        , ( "searchToolbar", SearchToolbar.encoder model.searchToolbar )
        , ( "noBlur", Encode.bool model.noBlur )
        , ( "clipboard", Clipboard.encode model.clipboard )
        ]



-- UPDATE


type Msg
    = ToggleCollapse ListItem
    | EditItem Int
      -- | UpdateItemContent ListItem String Int Posix
    | SaveItem ListItem String Posix
    | CreateItemAfter ListItem Posix
    | CreateItemAtStart Posix
    | GetCurrentTime (Posix -> Msg)
    | IndentItem Int ListItem
    | OutdentItem Int ListItem
    | DeleteItem ListItem
    | DeleteItemWithChildren ListItem
    | SaveAndCreateAfter ListItem String
    | FocusResult (Result Browser.Dom.Error ())
    | ClickedAt { id : Int, pos : Int }
    | SetCaret Int Int
    | SetSearchCursor Int
    | GotCursorPosition Int Int String Bool Bool
    | GotCurrentCursorPosition ListItem String Int
    | NoOp
    | MoveItemUp Int ListItem
    | SearchToolbarMsg SearchToolbar.Msg
    | MoveItemDown Int ListItem
    | ToggleNoBlur
    | InsertSelectedTag ListItem String Int Posix
    | NavigateToPreviousWithColumn ListItem Int
    | NavigateToNextWithColumn ListItem Int
    | ClipboardMsg Clipboard.Msg
    | TagPopupMsg TagPopup.Msg
    | ReceiveImportedModel D.Value
    | ItemInput ListItem String Posix
    | GetCurrentCursorPostion


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GetCurrentCursorPostion ->
            ( model, requestCursorPosition () )

        ReceiveImportedModel jsonValue ->
            case D.decodeValue decode jsonValue of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err _ ->
                    -- Optionally show an error (e.g., via a flag or toast)
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
                            let
                                ( searchToolbarUpdatedModel, _ ) =
                                    SearchToolbar.update (SearchToolbar.SearchKeyDown 13) model.searchToolbar
                            in
                            -- Tag selection from search input
                            ( { model | tagPopup = updatedmodel, searchToolbar = selectTag tag searchToolbarUpdatedModel }, Cmd.none )

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

        ToggleNoBlur ->
            ( { model | noBlur = not model.noBlur }, Cmd.none )

        SearchToolbarMsg searchToolbarMsg ->
            let
                ( updatedSearchToolbarModel, action ) =
                    SearchToolbar.update searchToolbarMsg model.searchToolbar

                withSearchToolbar =
                    { model | searchToolbar = updatedSearchToolbarModel }

                ( updatedModel, cmd ) =
                    case action of
                        Just act ->
                            case act of
                                Actions.AddNewItem ->
                                    update (GetCurrentTime CreateItemAtStart) withSearchToolbar

                                Actions.CollapseAll ->
                                    ( { withSearchToolbar | items = setAllCollapsed True withSearchToolbar.items }, Cmd.none )

                                Actions.ExpandAll ->
                                    ( { withSearchToolbar | items = setAllCollapsed False withSearchToolbar.items }, Cmd.none )

                                Actions.SetSortOrder sortOrder ->
                                    ( { withSearchToolbar | items = ListItem.sortItemsByDate sortOrder withSearchToolbar.items }, Cmd.none )

                                Actions.KeyEnter ->
                                    case TagPopup.getHighlightedTag model.tagPopup of
                                        Just tag ->
                                            ( { withSearchToolbar | searchToolbar = selectTag tag updatedSearchToolbarModel, tagPopup = hidePopup withSearchToolbar.tagPopup }, Cmd.none )

                                        Nothing ->
                                            ( withSearchToolbar, Cmd.none )

                                Actions.KeyArrowUp ->
                                    ( { withSearchToolbar | tagPopup = navigateUp withSearchToolbar.tagPopup }, Cmd.none )

                                Actions.KeyArrowDown ->
                                    ( { withSearchToolbar | tagPopup = navigateDown withSearchToolbar.tagPopup }, Cmd.none )

                                Actions.ImportModel ->
                                    ( withSearchToolbar, readFile () )

                                Actions.ExportModel ->
                                    let
                                        jsonString =
                                            encode withSearchToolbar |> Encode.encode 2
                                    in
                                    ( withSearchToolbar, downloadJson { filename = "listweave-data.json", content = jsonString } )

                                Actions.QueryChanged query cursorPos ->
                                    let
                                        tagPopupTags =
                                            isInsideTagBrackets cursorPos query
                                                |> Maybe.map
                                                    (\( tagSearchPrefix, _ ) ->
                                                        getAllTags withSearchToolbar.items
                                                            |> List.filter (String.startsWith tagSearchPrefix)
                                                    )

                                        ( updatedTagPopup, updatedCmd ) =
                                            case tagPopupTags of
                                                Just tags ->
                                                    if List.isEmpty tags then
                                                        ( hidePopup withSearchToolbar.tagPopup, Cmd.none )

                                                    else
                                                        ( TagPopup.setTags ( tags, TagPopup.FromSearchToolbar ) withSearchToolbar.tagPopup, getSearchInputPosition () )

                                                Nothing ->
                                                    ( hidePopup withSearchToolbar.tagPopup, Cmd.none )
                                    in
                                    ( { withSearchToolbar | tagPopup = updatedTagPopup }
                                    , updatedCmd
                                    )

                        Nothing ->
                            ( withSearchToolbar, Cmd.none )
            in
            ( updatedModel, cmd )

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
                |> (\( m, c ) -> update (GetCurrentTime (InsertSelectedTag item tag cursorPos)) m |> Tuple.mapSecond (\cmd -> Cmd.batch [ c, cmd ]))

        -- UpdateItemContent item content cursorPos currentTime ->
        --     let
        --         itemId =
        --             getId item
        --     in
        --     case isInsideTagBrackets cursorPos content of
        --         Just ( tagSearchPrefix, tag ) ->
        --             let
        --                 matchingTags =
        --                     getAllTags model.items
        --                         |> List.filter (String.startsWith tagSearchPrefix)
        --                         |> List.filter ((/=) tag)
        --                 updatedTagPopup =
        --                     if List.isEmpty matchingTags then
        --                         hidePopup model.tagPopup
        --                     else
        --                         TagPopup.setTags ( matchingTags, TagPopup.FromItem ) model.tagPopup
        --             in
        --             ( { model
        --                 | items = mapItem (updateItemContentFn item (String.split "\n" content) currentTime) model.items
        --                 , tagPopup = updatedTagPopup
        --                 , noBlur = List.isEmpty matchingTags |> not
        --               }
        --             , requestCursorPosition itemId
        --             )
        --         Nothing ->
        --             ( { model
        --                 | items = mapItem (updateItemContentFn item (String.split "\n" content) currentTime) model.items
        --                 , tagPopup = hidePopup model.tagPopup
        --               }
        --             , Cmd.none
        --             )
        MoveItemUp cursorPosition item ->
            ( { model | noBlur = True, items = moveItemInTree ListItem.moveItemUp item model.items }, Cmd.none )

        MoveItemDown cursorPosition item ->
            ( { model | noBlur = True, items = moveItemInTree ListItem.moveItemDown item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        IndentItem cursorPosition item ->
            ( { model | noBlur = True, items = indentItem item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        OutdentItem cursorPosition item ->
            ( { model | noBlur = True, items = outdentItem item model.items, caretTask = Just ( getId item, cursorPosition ) }, Cmd.none )

        GotCursorPosition top left fragment ok inCode ->
            if inCode || not ok then
                ( model, Cmd.none )

            else
                if String.startsWith "@" fragment then
                    let
                        matchingTags =
                            getAllTags model.items
                                |> List.filter (String.startsWith (String.dropLeft 1 fragment))
                        updatedTagPopup =
                            if List.isEmpty matchingTags then
                                hidePopup model.tagPopup
                            else
                                TagPopup.setTags ( matchingTags, TagPopup.FromItem ) model.tagPopup
                    in
                    ( { model | tagPopup = showPopup ( top, left ) matchingTags updatedTagPopup }, Cmd.none )
                else
                    ( model, Cmd.none )

        SaveItem item innerHTML currentTime ->
            if model.noBlur then
                ( model, Task.perform (\_ -> ToggleNoBlur) (Task.succeed ()) )

            else
                let
                    lines =
                        ListItem.parseInnerHtml innerHTML
                in
                ( { model
                    | items = (mapItem (updateItemContentFn item lines currentTime) >> mapItem (saveItemFn item)) model.items
                    , tagPopup = hidePopup model.tagPopup
                  }
                , Cmd.none
                )

        ItemInput item innerHTML currentTime ->
            let
                lines =
                    ListItem.parseInnerHtml innerHTML
            in
            ( { model
                | items = mapItem (updateItemContentFn item lines currentTime) model.items
                , tagPopup = hidePopup model.tagPopup
              }
            , Cmd.none
            )

        CreateItemAfter item currentTime ->
            let
                newId =
                    getNextId model.items

                newItems =
                    insertItemAfter item newId model.items currentTime |> mapItem (editItemFn newId)
            in
            ( { model | items = newItems }
            , Task.attempt FocusResult (Browser.Dom.focus ("input-id-" ++ String.fromInt newId))
            )

        CreateItemAtStart currentTime ->
            let
                newId =
                    getNextId model.items

                newModel =
                    { model | items = (newEmptyListItem currentTime newId |> editItemFn newId) :: model.items }
            in
            ( newModel, Task.attempt FocusResult (Browser.Dom.focus ("input-id-" ++ String.fromInt newId)) )

        GetCurrentTime msgFn ->
            ( model, Task.perform msgFn Time.now )

        SaveAndCreateAfter item innerHtml ->
            let
                ( afterSave, _ ) =
                    update (GetCurrentTime (SaveItem item innerHtml)) model
            in
            update (GetCurrentTime (CreateItemAfter item)) afterSave

        FocusResult _ ->
            ( model, Cmd.none )

        DeleteItem item ->
            ( { model | items = deleteItem item model.items }, Cmd.none )

        DeleteItemWithChildren item ->
            ( { model | items = removeItemCompletely item model.items }, Cmd.none )

        InsertSelectedTag item tag cursorPos currentTime ->
            let
                content =
                    String.join "\n" (getContent item)

                ( newContent, newCaretPos ) =
                    TagsUtils.insertTagAtCursor content tag cursorPos
            in
            ( { model
                | items = mapItem (updateItemContentFn item (String.split "\n" newContent) currentTime) model.items
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



-- VIEW


view : Model -> Html Msg
view model =
    div
        Theme.container
        (div []
            [ TagPopup.view model.tagPopup |> Html.map TagPopupMsg ]
            :: (SearchToolbar.view model.searchToolbar (isVisible model.tagPopup) |> Html.map SearchToolbarMsg)
            :: List.map (viewListItem model 0) (model.items |> getFilteredItems model.searchToolbar)
        )


viewItemContent : Model -> ListItem -> Html Msg
viewItemContent model item =
    let
        keyboardConfig =
            { tagPopup = model.tagPopup
            , clipboard = model.clipboard
            , onMoveItemUp = MoveItemUp
            , onMoveItemDown = MoveItemDown
            , onCutItem = \targetItem -> ClipboardMsg (Clipboard.CutItem targetItem model.items)
            , onCopyItem = \targetItem -> GetCurrentTime (\currentTime -> ClipboardMsg (Clipboard.CopyItem targetItem model.items currentTime))
            , onPasteItem = \targetItem -> ClipboardMsg (Clipboard.PasteItem targetItem model.items)
            , onDeleteItem = DeleteItem
            , onInsertSelectedTag = \targetItem tag cursorPos -> GetCurrentTime (InsertSelectedTag targetItem tag cursorPos)
            , onSaveAndCreateAfter = SaveAndCreateAfter
            , onIndentItem = IndentItem
            , onOutdentItem = OutdentItem
            , onTagPopupMsg = TagPopupMsg
            , onNavigateToPreviousWithColumn = NavigateToPreviousWithColumn
            , onNavigateToNextWithColumn = NavigateToNextWithColumn
            , onRestoreCutItem = ClipboardMsg (Clipboard.RestoreCutItem model.items)
            , onNoOp = NoOp
            }

        addBreaks : List (List (Html Msg)) -> List (Html Msg)
        addBreaks elements =
            List.indexedMap
                (\i el ->
                    if i < List.length elements - 1 then
                        el ++ [ br [] [] ]

                    else
                        el
                )
                elements
                |> List.concat

        staticContent =
            let
                contentBlocks =
                    TagsUtils.processContent (getContent item)

                viewBlock ( isCode, lines ) =
                    if isCode then
                        code Theme.codeBlock [ text (String.join "\n" lines) ]

                    else
                        lines |> List.map (viewContentWithSelectedTags model.items item (getSelectedTags model.searchToolbar)) |> addBreaks |> div Theme.content
            in
            if List.isEmpty (getContent item) then
                [ span Theme.contentEmpty [ text "empty" ] ]

            else
                List.map viewBlock contentBlocks

        onBlurCustom =
            if model.noBlur then
                []

            else
                let
                    innerHtml =
                        D.at [ "target", "innerHTML" ] D.string
                in
                [ on "blur" (D.map (\x -> GetCurrentTime (SaveItem item x)) innerHtml) ]

        onInputCustom =
            on "input" (D.succeed GetCurrentCursorPostion)
    in
    div
        (Theme.flexGrow
            ++ [ attribute "id" ("item-" ++ String.fromInt (getId item))
               , attribute "contenteditable" "true"
               , Html.Attributes.tabindex -1
               , onInputCustom
               , KeyboardHandler.onKeyDown keyboardConfig item
               ]
            ++ Theme.editableDiv
            ++ onBlurCustom
        )
        staticContent


viewListItem : Model -> Int -> ListItem -> Html Msg
viewListItem model level item =
    let
        arrow =
            if getChildren item |> List.isEmpty then
                span Theme.arrowEmpty []

            else
                span
                    (onClick (ToggleCollapse item) :: Theme.arrow)
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
                baseStyles =
                    if List.isEmpty (getChildren item) then
                        Theme.listItemRow

                    else
                        Theme.listItemRowWithChildren
            in
            div (Theme.indentStyle level ++ baseStyles)
                [ arrow
                , span Theme.bullet [ text "•" ]
                , viewItemContent model item
                , span [ onClick (DeleteItem item), style "cursor" "pointer", style "margin-left" "10px", style "margin-left" "auto" ] [ text "×" ]
                ]
    in
    div Theme.listItem
        (itemRow :: childrenBlock)


viewContentWithSelectedTags : List ListItem -> ListItem -> List String -> String -> List (Html Msg)
viewContentWithSelectedTags items item selectedTags content =
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
                        Theme.tagSelected

                    else
                        Theme.tag
            in
            [ text p
            , span
                (stopPropagationOn "click" (D.succeed ( SearchToolbarMsg (addTagToSelected tag), True )) :: tagStyle)
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
                case D.decodeValue (D.map5 GotCursorPosition (D.field "top" D.int) (D.field "left" D.int) (D.field "word" D.string) (D.field "ok" D.bool) (D.field "inCode" D.bool)) value of
                    Ok msg ->
                        msg

                    Err _ ->
                        GotCursorPosition 0 0 "" False False
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
        , receiveFile ReceiveImportedModel
        ]
