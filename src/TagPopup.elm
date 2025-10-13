module TagPopup exposing
    ( Model
    , Msg(..)
    , Source(..)
    , currentSource
    , getHighlightedTag
    , getTags
    , hidePopup
    , init
    , isVisible
    , navigateDown
    , navigateUp
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
import Theme



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
                    (stopPropagationOn "click" (D.succeed ( NoOp, True )) :: Theme.positionStyle top left width ++ Theme.popup)
                    (List.map (viewPopupTag model.highlightedTag) matchingTags)

        _ ->
            text ""


viewPopupTag : Maybe String -> String -> Html Msg
viewPopupTag currentHighlightedTag tag =
    let
        styles =
            if Just tag == currentHighlightedTag then
                Theme.popupItemHighlighted
            else
                Theme.popupItemNormal
    in
    div
        (onClick (HighlightTag tag) :: styles)
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
