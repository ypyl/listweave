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
    , encode
    , decode
    )

import Actions exposing (TagPopupAction)
import Html exposing (Html, div, text)
import Html.Attributes exposing (id)
import Html.Events exposing (onClick, stopPropagationOn)
import TagsUtils
import Theme
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


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



encode : Model -> Encode.Value
encode model =
    Encode.object
        [ ( "position"
          , Maybe.map (\( a, b, c ) -> Encode.list Encode.int [ a, b, c ]) model.position
                |> Maybe.withDefault Encode.null
          )
        , ( "tags"
          , Maybe.map (Encode.list Encode.string) model.tags
                |> Maybe.withDefault Encode.null
          )
        , ( "highlightedTag"
          , Maybe.map Encode.string model.highlightedTag
                |> Maybe.withDefault Encode.null
          )
        , ( "source"
          , Maybe.map sourceEncoder model.source
                |> Maybe.withDefault Encode.null
          )
        ]


decode : Decoder Model
decode =
    Decode.map4 Model
        (Decode.field "position" (Decode.nullable positionDecoder))
        (Decode.field "tags" (Decode.nullable (Decode.list Decode.string)))
        (Decode.field "highlightedTag" (Decode.nullable Decode.string))
        (Decode.field "source" (Decode.nullable sourceDecoder))


-- Helper decoder for the position tuple (Int, Int, Int)
positionDecoder : Decoder ( Int, Int, Int )
positionDecoder =
    Decode.list Decode.int
        |> Decode.andThen
            (\list ->
                case list of
                    [ a, b, c ] ->
                        Decode.succeed ( a, b, c )

                    _ ->
                        Decode.fail "Position list must have exactly 3 elements (top, left, width)"
            )


-- Encoder for the Source custom type
sourceEncoder : Source -> Encode.Value
sourceEncoder source =
    case source of
        FromSearchToolbar ->
            Encode.string "FromSearchToolbar"

        FromItem ->
            Encode.string "FromItem"


-- Decoder for the Source custom type
sourceDecoder : Decoder Source
sourceDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "FromSearchToolbar" ->
                        Decode.succeed FromSearchToolbar

                    "FromItem" ->
                        Decode.succeed FromItem

                    _ ->
                        Decode.fail ("Unexpected source value: " ++ str)
            )


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
                    (stopPropagationOn "click" (Decode.succeed ( NoOp, True )) :: Theme.positionStyle top left width ++ Theme.popup)
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
