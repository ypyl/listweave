module TagPopup exposing
    ( Model
    , Msg
    , Source(..)
    , currentSource
    , getHighlightedTag
    , getTags
    , hidePopup
    , hidePopupMsg
    , init
    , isVisible
    , navigateDown
    , navigateDownMsg
    , navigateUp
    , navigateUpMsg
    , setTags
    , update
    , view
    , showPopup
    )

import Actions exposing (TagPopupAction)
import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import TagsUtils



-- MODEL


type Source
    = FromSearchToolbar
    | FromItem


type alias Model =
    { position : Maybe ( Int, Int, Int ) -- top, left, width
    , tags : Maybe (List String)
    , highlightedTag : Maybe String
    , source : Maybe Source
    }


currentSource : Model -> Maybe Source
currentSource model =
    model.source


navigateUp : Model -> Model
navigateUp model =
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


navigateDown : Model -> Model
navigateDown model =
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


init : Model
init =
    { position = Nothing
    , tags = Nothing
    , highlightedTag = Nothing
    , source = Nothing
    }



-- UPDATE


type Msg
    = Hide
    | NavigateUp
    | NavigateDown
    | HighlightTag String
    | NoOp


hidePopupMsg : Msg
hidePopupMsg =
    Hide


navigateDownMsg : Msg
navigateDownMsg =
    NavigateDown


navigateUpMsg : Msg
navigateUpMsg =
    NavigateUp


update : Msg -> Model -> ( Model, Maybe TagPopupAction )
update msg model =
    case msg of
        Hide ->
            ( hidePopup model
            , Nothing
            )

        NavigateUp ->
            ( navigateUp model, Nothing )

        NavigateDown ->
            ( navigateDown model, Nothing )

        HighlightTag tag ->
            let
                hidenPopup =
                    hidePopup model
            in
            ( { hidenPopup
                | highlightedTag = Just tag
              }
            , Just (Actions.HighlightTag tag)
            )

        NoOp ->
            ( model, Nothing )


hidePopup : Model -> Model
hidePopup model =
    { model
        | position = Nothing
        , tags = Nothing
        , highlightedTag = Nothing
        , source = Nothing
    }


showPopup : ( Int, Int, Int ) -> List String -> Model -> Model
showPopup position tags model =
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


setTags : ( List String, Source ) -> Model -> Model
setTags ( tags, source ) model =
    { model | tags = Just tags, source = Just source }


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
