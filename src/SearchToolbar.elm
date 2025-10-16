module SearchToolbar exposing (Model, Msg(..), addTagToSelected, decode, encoder, getFilteredItems, getSelectedTags, getUpdatedCursorPosition, init, resetUpdatedCursorPosition, selectTag, update, view)

import Actions exposing (SearchToolbarAction(..), SortOrder(..))
import Html exposing (Html, div, input, span, text)
import Html.Attributes exposing (id, placeholder, style, type_, value)
import Html.Events exposing (onClick, preventDefaultOn)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import ListItem exposing (ListItem, filterItems)
import Regex
import Theme



-- CONSTANTS


tagRegex : Regex.Regex
tagRegex =
    Regex.fromString "@[a-zA-Z0-9-_]*"
        |> Maybe.withDefault Regex.never


whitespaceRegex : Regex.Regex
whitespaceRegex =
    Regex.fromString "\\s+"
        |> Maybe.withDefault Regex.never



-- MODEL


type alias Model =
    { searchQuery : String
    , updatedCursorPosition : Maybe Int
    , selectedTags : List String
    }


encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "searchQuery", Encode.string model.searchQuery )
        , ( "updatedCursorPosition"
          , Maybe.map Encode.int model.updatedCursorPosition
                |> Maybe.withDefault Encode.null
          )
        , ( "selectedTags", Encode.list Encode.string model.selectedTags )
        ]


decode : Decoder Model
decode =
    Decode.map3 Model
        (Decode.field "searchQuery" Decode.string)
        (Decode.field "updatedCursorPosition" (Decode.nullable Decode.int))
        (Decode.field "selectedTags" (Decode.list Decode.string))


getUpdatedCursorPosition : Model -> Maybe Int
getUpdatedCursorPosition model =
    model.updatedCursorPosition


init : Model
init =
    { searchQuery = ""
    , updatedCursorPosition = Nothing
    , selectedTags = []
    }


getSelectedTags : Model -> List String
getSelectedTags model =
    model.selectedTags


getFilteredItems : Model -> List ListItem -> List ListItem
getFilteredItems model =
    filterItems model.searchQuery model.selectedTags



-- UPDATE


type Msg
    = SearchQueryChanged String Int
    | CollapseAllClicked
    | ExpandAllClicked
    | SearchKeyDown Int
    | SortOrderChanged String
    | RemoveSelectedTag String
    | ClearAllSelectedTags
    | AddTagToSelected String
    | ExportModel
    | ImportModel


addTagToSelected : String -> Msg
addTagToSelected tag =
    AddTagToSelected tag


update : Msg -> Model -> ( Model, Maybe SearchToolbarAction )
update msg model =
    case msg of
        SearchQueryChanged query cursorPos ->
            ( { model | searchQuery = query }
            , Just (Actions.QueryChanged query cursorPos)
            )

        CollapseAllClicked ->
            ( model, Just Actions.CollapseAll )

        ExpandAllClicked ->
            ( model, Just Actions.ExpandAll )

        SortOrderChanged sortOrder ->
            ( model, Just (Actions.SetSortOrder (getSortOrder sortOrder)) )

        SearchKeyDown key ->
            case key of
                13 ->
                    -- Enter key
                    let
                        ( cleanQuery, cursorPos ) =
                            removeTagFromQueryWithPosition model.searchQuery
                    in
                    ( { model | searchQuery = cleanQuery, updatedCursorPosition = Just cursorPos }, Just Actions.KeyEnter )

                38 ->
                    -- Up arrow
                    ( model, Just Actions.KeyArrowUp )

                40 ->
                    -- Down arrow
                    ( model, Just Actions.KeyArrowDown )

                _ ->
                    ( model, Nothing )

        RemoveSelectedTag tag ->
            ( { model | selectedTags = List.filter ((/=) tag) model.selectedTags }, Nothing )

        ClearAllSelectedTags ->
            ( { model | selectedTags = [] }, Nothing )

        AddTagToSelected tag ->
            if String.isEmpty tag || List.member tag model.selectedTags then
                ( model, Nothing )

            else
                ( { model | selectedTags = model.selectedTags ++ [ tag ] }, Nothing )

        ExportModel ->
            ( model, Just Actions.ExportModel )

        ImportModel ->
            ( model, Just Actions.ImportModel )


selectTag : String -> Model -> Model
selectTag tag model =
    if String.isEmpty tag || List.member tag model.selectedTags then
        model

    else
        { model
            | selectedTags = model.selectedTags ++ [ tag ]
        }



-- VIEW


getSortOrder : String -> SortOrder
getSortOrder sortOrder =
    case sortOrder of
        "Updated Date" ->
            ByUpdatedDate

        "Created Date" ->
            ByCreatedDate

        _ ->
            ByCreatedDate


view : Model -> Bool -> Html Msg
view model listenKeydownEvents =
    div []
        [ div Theme.searchToolbar
            [ input
                ([ type_ "text"
                 , id "search-input"
                 , placeholder "Search... (type @tag to filter by tags)"
                 , value model.searchQuery
                 , preventDefaultOn "input" inputDecoder
                 , preventDefaultOn "keydown" (keydownDecoder listenKeydownEvents)
                 ]
                    ++ Theme.searchInput
                )
                []
            ]
        , div Theme.searchToolbar
            [ viewSelectedTags model.selectedTags
            , div
                Theme.select
                [ text "Sort by"
                , div Theme.buttonGroup
                    [ div (onClick (SortOrderChanged "Created Date") :: Theme.buttonGroupFirst) [ text "created" ]
                    , div (onClick (SortOrderChanged "Updated Date") :: Theme.buttonGroupLast) [ text "updated" ]
                    ]
                , text "date"
                ]
            ]
        , div Theme.searchToolbar
            [ div Theme.buttonGroup
                [ div
                    (onClick CollapseAllClicked :: Theme.buttonGroupFirst)
                    [ text "▲" ]
                , div
                    (onClick ExpandAllClicked :: Theme.buttonGroupLast)
                    [ text "▼" ]
                ]
            , div (style "margin-left" "auto" :: Theme.buttonGroup)
                [ div (onClick ExportModel :: Theme.buttonGroupFirst) [ text "📥" ]
                , div (onClick ImportModel :: Theme.buttonGroupLast) [ text "📤" ]
                ]
            ]
        ]


viewSelectedTags : List String -> Html Msg
viewSelectedTags selectedTags =
    if List.isEmpty selectedTags then
        text ""

    else
        div Theme.selectedTagsContainer
            (List.map viewTagChip selectedTags ++ [ viewClearAllButton ])


viewTagChip : String -> Html Msg
viewTagChip tag =
    div Theme.tagChip
        [ text ("@" ++ tag)
        , span
            (onClick (RemoveSelectedTag tag) :: Theme.tagChipClose)
            [ text "×" ]
        ]


viewClearAllButton : Html Msg
viewClearAllButton =
    div
        (onClick ClearAllSelectedTags :: Theme.button)
        [ text "Clear all" ]



-- DECODERS


inputDecoder : Decode.Decoder ( Msg, Bool )
inputDecoder =
    Decode.map2
        (\value selectionStart ->
            ( SearchQueryChanged value selectionStart, False )
        )
        (Decode.field "target" (Decode.field "value" Decode.string))
        (Decode.field "target" (Decode.field "selectionStart" Decode.int))


keydownDecoder : Bool -> Decode.Decoder ( Msg, Bool )
keydownDecoder listenKeydownEvents =
    Decode.map
        (\key ->
            let
                shouldPrevent =
                    listenKeydownEvents && (key == 13 || key == 38 || key == 40)
            in
            ( SearchKeyDown key, shouldPrevent )
        )
        (Decode.field "keyCode" Decode.int)



-- HELPERS


removeTagFromQueryWithPosition : String -> ( String, Int )
removeTagFromQueryWithPosition query =
    let
        matches =
            Regex.find tagRegex query

        -- Find the last match (most recent tag being typed)
        lastMatch =
            List.reverse matches |> List.head

        ( cleanQuery, cursorPos ) =
            case lastMatch of
                Just match ->
                    let
                        beforeMatch =
                            String.left match.index query

                        afterMatch =
                            String.dropLeft (match.index + String.length match.match) query

                        cleaned =
                            beforeMatch ++ afterMatch
                    in
                    ( cleaned, match.index )

                Nothing ->
                    ( query, String.length query )
    in
    ( cleanQuery
        |> String.trim
        |> Regex.replace whitespaceRegex (\_ -> " ")
    , cursorPos
    )


resetUpdatedCursorPosition : Model -> Model
resetUpdatedCursorPosition model =
    { model | updatedCursorPosition = Nothing }
