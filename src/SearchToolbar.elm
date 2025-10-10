module SearchToolbar exposing (Model, Msg(..), UpdateResult, init, update, view, getSearchQuery)

import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (id, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput, preventDefaultOn)
import Json.Decode as D
import ListItem exposing (ListItem, getAllTags, setAllCollapsed)
import Regex
import TagsUtils exposing (isInsideTagBrackets, isTagRegex)


-- MODEL


type alias Model =
    { searchQuery : String
    , showingTagPopup : Bool
    }


init : Model
init =
    { searchQuery = ""
    , showingTagPopup = False
    }


-- UPDATE


type Msg
    = SearchQueryChanged String Int
    | CollapseAllClicked
    | ExpandAllClicked
    | SearchKeyDown Int String Int
    | HideTagPopup
    | RemoveTagFromSearch String


type alias UpdateResult =
    { model : Model
    , items : List ListItem
    , tagPopupTags : Maybe (List String)
    , extractedTags : List String
    , cursorPosition : Maybe Int
    }


update : Msg -> Model -> List ListItem -> UpdateResult
update msg model items =
    case msg of
        SearchQueryChanged query cursorPos ->
            let
                tagPopupTags =
                    isInsideTagBrackets cursorPos query
                        |> Maybe.map (\( tagSearchPrefix, _ ) ->
                            getAllTags items
                                |> List.filter (String.startsWith tagSearchPrefix)
                        )
            in
            { model = { model | searchQuery = query, showingTagPopup = tagPopupTags /= Nothing }
            , items = items
            , tagPopupTags = tagPopupTags
            , extractedTags = []
            , cursorPosition = Nothing
            }

        CollapseAllClicked ->
            { model = model, items = setAllCollapsed True items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

        ExpandAllClicked ->
            { model = model, items = setAllCollapsed False items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

        SearchKeyDown key query cursorPos ->
            case key of
                13 -> -- Enter key
                    { model = model, items = items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

                38 -> -- Up arrow
                    { model = model, items = items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

                40 -> -- Down arrow
                    { model = model, items = items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

                _ ->
                    { model = model, items = items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

        HideTagPopup ->
            { model = { model | showingTagPopup = False }, items = items, tagPopupTags = Nothing, extractedTags = [], cursorPosition = Nothing }

        RemoveTagFromSearch selectedTag ->
            let
                ( cleanQuery, cursorPos ) = removeTagFromQueryWithPosition model.searchQuery selectedTag
            in
            { model = { model | searchQuery = cleanQuery, showingTagPopup = False }
            , items = items
            , tagPopupTags = Nothing
            , extractedTags = []
            , cursorPosition = Just cursorPos
            }


removeTagFromQueryWithPosition : String -> String -> ( String, Int )
removeTagFromQueryWithPosition query selectedTag =
    let
        -- Find all @tag patterns in the query
        tagRegex =
            Regex.fromString "@[a-zA-Z0-9-_]*"
                |> Maybe.withDefault Regex.never

        matches = Regex.find tagRegex query

        -- Find the last match (most recent tag being typed)
        lastMatch = List.reverse matches |> List.head

        ( cleanQuery, cursorPos ) =
            case lastMatch of
                Just match ->
                    let
                        beforeMatch = String.left match.index query
                        afterMatch = String.dropLeft (match.index + String.length match.match) query
                        cleaned = beforeMatch ++ afterMatch
                    in
                    ( cleaned, match.index )

                Nothing ->
                    ( query, String.length query )
    in
    ( cleanQuery
        |> String.trim
        |> Regex.replace (Regex.fromString "\\s+" |> Maybe.withDefault Regex.never) (\_ -> " ")
    , cursorPos
    )


-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "margin-bottom" "16px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "gap" "8px"
        ]
        [ div
            [ onClick CollapseAllClicked
            , style "background" "#f5f5f5"
            , style "border" "1px solid #ccc"
            , style "border-radius" "4px"
            , style "padding" "4px 8px"
            , style "cursor" "pointer"
            , style "font-size" "12px"
            , style "user-select" "none"
            ]
            [ text "Collapse All" ]
        , div
            [ onClick ExpandAllClicked
            , style "background" "#f5f5f5"
            , style "border" "1px solid #ccc"
            , style "border-radius" "4px"
            , style "padding" "4px 8px"
            , style "cursor" "pointer"
            , style "font-size" "12px"
            , style "user-select" "none"
            ]
            [ text "Expand All" ]
        , input
            [ type_ "text"
            , id "search-input"
            , placeholder "Search... (type @tag to filter by tags)"
            , value model.searchQuery
            , preventDefaultOn "input"
                (D.map2
                    (\value selectionStart ->
                        ( SearchQueryChanged value selectionStart, False )
                    )
                    (D.field "target" (D.field "value" D.string))
                    (D.field "target" (D.field "selectionStart" D.int))
                )
            , preventDefaultOn "keydown"
                (D.map4
                    (\key value selectionStart showingPopup ->
                        let
                            shouldPrevent = showingPopup && (key == 13 || key == 38 || key == 40)
                        in
                        ( SearchKeyDown key value selectionStart, shouldPrevent )
                    )
                    (D.field "keyCode" D.int)
                    (D.field "target" (D.field "value" D.string))
                    (D.field "target" (D.field "selectionStart" D.int))
                    (D.succeed model.showingTagPopup)
                )
            , style "background" "#f5f5f5"
            , style "border" "1px solid #ccc"
            , style "border-radius" "4px"
            , style "padding" "4px 8px"
            , style "font-size" "12px"
            , style "flex-grow" "1"
            ]
            []
        ]


-- HELPERS


getSearchQuery : Model -> String
getSearchQuery model =
    model.searchQuery
