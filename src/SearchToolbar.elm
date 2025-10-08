module SearchToolbar exposing (Model, Msg, init, update, view, getSearchQuery)

import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import ListItem exposing (ListItem, setAllCollapsed)


-- MODEL


type alias Model =
    { searchQuery : String
    }


init : Model
init =
    { searchQuery = ""
    }


-- UPDATE


type Msg
    = SearchQueryChanged String
    | CollapseAllClicked
    | ExpandAllClicked


update : Msg -> Model -> List ListItem -> ( Model, List ListItem )
update msg model items =
    case msg of
        SearchQueryChanged query ->
            ( { model | searchQuery = query }, items )

        CollapseAllClicked ->
            ( model, setAllCollapsed True items )

        ExpandAllClicked ->
            ( model, setAllCollapsed False items )


-- VIEW


view : Model -> Html Msg
view model =
    div 
        [ style "margin-bottom" "16px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "gap" "8px"
        ]
        [ button [ onClick CollapseAllClicked ] [ text "Collapse All" ]
        , button [ onClick ExpandAllClicked ] [ text "Expand All" ]
        , input
            [ type_ "text"
            , placeholder "Search..."
            , value model.searchQuery
            , onInput SearchQueryChanged
            , style "padding" "4px 8px"
            , style "border" "1px solid #ccc"
            , style "border-radius" "4px"
            ]
            []
        ]


-- HELPERS


getSearchQuery : Model -> String
getSearchQuery model =
    model.searchQuery