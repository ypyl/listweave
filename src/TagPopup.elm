module TagPopup exposing
    ( Model
    , Msg(..)
    , getHighlightedTag
    , getTags
    , init
    , isVisible
    , setTags
    , update
    , view
    )

import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import TagsUtils



-- MODEL


type alias Model =
    { position : Maybe ( Int, Int, Int ) -- top, left, width
    , tags : Maybe (List String)
    , highlightedTag : Maybe String
    }


init : Model
init =
    { position = Nothing
    , tags = Nothing
    , highlightedTag = Nothing
    }



-- UPDATE


type Msg
    = Show ( Int, Int, Int ) (List String)
    | Hide
    | NavigateUp
    | NavigateDown
    | HighlightTag String
    | NoOp


update : Msg -> Model -> Model
update msg model =
    case msg of
        Show position tags ->
            let
                selectedTag =
                    case tags of
                        t :: _ ->
                            Just t

                        [] ->
                            Nothing
            in
            { model
                | position = Just position
                , tags = Just tags
                , highlightedTag = selectedTag
            }

        Hide ->
            { model
                | position = Nothing
                , tags = Nothing
                , highlightedTag = Nothing
            }

        NavigateUp ->
            case ( model.tags, model.highlightedTag ) of
                ( Just tags, Just current ) ->
                    case TagsUtils.findPrev tags current of
                        Just prev ->
                            { model | highlightedTag = Just prev }

                        Nothing ->
                            model

                ( Just tags, Nothing ) ->
                    case List.head tags of
                        Just firstTag ->
                            { model | highlightedTag = Just firstTag }

                        Nothing ->
                            model

                _ ->
                    model

        NavigateDown ->
            case ( model.tags, model.highlightedTag ) of
                ( Just tags, Just current ) ->
                    case TagsUtils.findNext tags current of
                        Just next ->
                            { model | highlightedTag = Just next }

                        Nothing ->
                            model

                ( Just tags, Nothing ) ->
                    case List.head tags of
                        Just firstTag ->
                            { model | highlightedTag = Just firstTag }

                        Nothing ->
                            model

                _ ->
                    model

        HighlightTag tag ->
            { model | highlightedTag = Just tag }

        NoOp ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    case ( model.position, model.tags ) of
        ( Just ( top, left, width ), Just matchingTags ) ->
            if List.isEmpty matchingTags then
                text ""

            else
                div
                    [ Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "top" (String.fromInt top ++ "px")
                    , Html.Attributes.style "left" (String.fromInt left ++ "px")
                    , Html.Attributes.style "width" (String.fromInt width ++ "px")
                    , Html.Attributes.style "background" "#f5f5f5"
                    , Html.Attributes.style "border" "1px solid #ccc"
                    , Html.Attributes.style "border-radius" "4px"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "flex-direction" "column"
                    , Html.Attributes.style "gap" "2px"
                    , Html.Attributes.style "padding" "4px"
                    , Html.Attributes.style "overflow-y" "auto"
                    , Html.Attributes.style "font-size" "12px"
                    , stopPropagationOn "click" (D.succeed ( NoOp, True ))
                    ]
                    (List.map (viewPopupTag model.highlightedTag) matchingTags)

        _ ->
            text ""


viewPopupTag : Maybe String -> String -> Html Msg
viewPopupTag currentHighlightedTag tag =
    div
        [ onClick (HighlightTag tag)
        , Html.Attributes.style "cursor" "pointer"
        , Html.Attributes.style "user-select" "none"
        , Html.Attributes.style "background"
            (if Just tag == currentHighlightedTag then
                "#e3f2fd"

             else
                "transparent"
            )
        , Html.Attributes.style "color" "inherit"
        , Html.Attributes.style "padding" "4px 8px"
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "font-size" "12px"
        ]
        [ text tag ]



-- PUBLIC HELPERS


setTags : List String -> Model -> Model
setTags tags model =
    { model | tags = Just tags }


isVisible : Model -> Bool
isVisible model =
    case ( model.position, model.tags ) of
        ( Just _, Just tags ) ->
            not (List.isEmpty tags)

        _ ->
            False


getHighlightedTag : Model -> Maybe String
getHighlightedTag model =
    model.highlightedTag


getTags : Model -> Maybe (List String)
getTags model =
    model.tags
