module SearchToolbar exposing (Model, Msg, getSearchQuery, getUpdatedCursorPosition, init, resetUpdatedCursorPosition, update, view)

import Actions exposing (SearchToolbarAction(..))
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (id, placeholder, type_, value)
import Html.Events exposing (onClick, preventDefaultOn)
import Json.Decode as D
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
    }


getUpdatedCursorPosition : Model -> Maybe Int
getUpdatedCursorPosition model =
    model.updatedCursorPosition


init : Model
init =
    { searchQuery = ""
    , updatedCursorPosition = Nothing
    }



-- UPDATE


type Msg
    = SearchQueryChanged String Int
    | CollapseAllClicked
    | ExpandAllClicked
    | SearchKeyDown Int


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



-- VIEW


view : Model -> Bool -> Html Msg
view model listenKeydownEvents =
    div Theme.searchToolbar
        [ div
            (onClick CollapseAllClicked :: Theme.button)
            [ text "Collapse All" ]
        , div
            (onClick ExpandAllClicked :: Theme.button)
            [ text "Expand All" ]
        , input
            ([ type_ "text"
            , id "search-input"
            , placeholder "Search... (type @tag to filter by tags)"
            , value model.searchQuery
            , preventDefaultOn "input" inputDecoder
            , preventDefaultOn "keydown" (keydownDecoder listenKeydownEvents)
            ] ++ Theme.searchInput)
            []
        ]



-- DECODERS


inputDecoder : D.Decoder ( Msg, Bool )
inputDecoder =
    D.map2
        (\value selectionStart ->
            ( SearchQueryChanged value selectionStart, False )
        )
        (D.field "target" (D.field "value" D.string))
        (D.field "target" (D.field "selectionStart" D.int))


keydownDecoder : Bool -> D.Decoder ( Msg, Bool )
keydownDecoder listenKeydownEvents =
    D.map
        (\key ->
            let
                shouldPrevent =
                    listenKeydownEvents && (key == 13 || key == 38 || key == 40)
            in
            ( SearchKeyDown key, shouldPrevent )
        )
        (D.field "keyCode" D.int)



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


getSearchQuery : Model -> String
getSearchQuery model =
    model.searchQuery


resetUpdatedCursorPosition : Model -> Model
resetUpdatedCursorPosition model =
    { model | updatedCursorPosition = Nothing }
