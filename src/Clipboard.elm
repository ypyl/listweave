module Clipboard exposing (Model, Msg(..), init, update, hasItem, encode, decode)

import ListItem exposing (ListItem, findItemPosition, insertClipboardItemAfter, removeItemCompletely, restoreItemAtPosition)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time exposing (Posix)

-- MODEL


type alias Model =
    { clipboard : Maybe ListItem
    , clipboardOriginalPosition : Maybe ( Maybe Int, Int )
    }


init : Model
init =
    { clipboard = Nothing
    , clipboardOriginalPosition = Nothing
    }


encode : Model -> Encode.Value
encode model =
    Encode.object
        [ ( "clipboard"
          , Maybe.map ListItem.encode model.clipboard
                |> Maybe.withDefault Encode.null
          )
        , ( "clipboardOriginalPosition"
          , Maybe.map (\( a, b ) -> Encode.list identity [ Maybe.map Encode.int a |> Maybe.withDefault Encode.null, Encode.int b ]) model.clipboardOriginalPosition
                |> Maybe.withDefault Encode.null
          )
        ]


decode : Decoder Model
decode =
    Decode.map2 Model
        (Decode.field "clipboard" (Decode.nullable ListItem.decode))
        (Decode.field "clipboardOriginalPosition" (Decode.nullable clipboardPositionDecoder))


-- Helper decoder for the clipboard position tuple (Maybe Int, Int)
clipboardPositionDecoder : Decoder ( Maybe Int, Int )
clipboardPositionDecoder =
    Decode.list (Decode.nullable Decode.int)
        |> Decode.andThen
            (\list ->
                case list of
                    [ maybeIntValue, Just intB ] ->
                        let
                            maybeIntA = Maybe.withDefault Nothing (Maybe.map Just maybeIntValue)
                        in
                        Decode.succeed ( maybeIntA, intB )

                    _ ->
                        Decode.fail "ClipboardOriginalPosition list must have exactly 2 elements: [Maybe Int, Int]"
            )

-- UPDATE


type Msg
    = CutItem ListItem (List ListItem)
    | CopyItem ListItem (List ListItem) Posix
    | PasteItem ListItem (List ListItem)
    | RestoreCutItem (List ListItem)


update : Msg -> Model -> ( Model, List ListItem, Maybe ( Int, Int ) )
update msg model =
    case msg of
        CopyItem item items currentTime ->
            -- For copy, create a deep copy immediately and store it
            let
                nextId = ListItem.getNextId items
                copiedItem = ListItem.deepCopyItem currentTime nextId item
            in
            ( { model | clipboard = Just copiedItem, clipboardOriginalPosition = Nothing }, items, Nothing )

        CutItem item items ->
            let
                -- If clipboard not empty, restore previous cut item first
                ( modelAfterRestore, itemsAfterRestore ) =
                    case model.clipboard of
                        Just _ ->
                            case update (RestoreCutItem items) model of
                                ( restoredModel, restoredItems, _ ) ->
                                    ( restoredModel, restoredItems )

                        Nothing ->
                            ( model, items )

                originalPosition =
                    findItemPosition item itemsAfterRestore

                newItems =
                    removeItemCompletely item itemsAfterRestore
            in
            ( { modelAfterRestore
                | clipboard = Just item
                , clipboardOriginalPosition = originalPosition
              }
            , newItems
            , Nothing
            )

        PasteItem targetItem items ->
            case model.clipboard of
                Just clipboardItem ->
                    let
                        newItems =
                            insertClipboardItemAfter targetItem clipboardItem items
                    in
                    ( { model
                        | clipboard = Nothing
                        , clipboardOriginalPosition = Nothing
                      }
                    , newItems
                    , Just ( ListItem.getId targetItem, 0 )
                    )

                Nothing ->
                    ( model, items, Nothing )

        RestoreCutItem items ->
            case ( model.clipboard, model.clipboardOriginalPosition ) of
                ( Just clipboardItem, Just ( parentId, childIndex ) ) ->
                    let
                        newItems =
                            restoreItemAtPosition clipboardItem parentId childIndex items
                    in
                    ( { model
                        | clipboard = Nothing
                        , clipboardOriginalPosition = Nothing
                      }
                    , newItems
                    , Nothing
                    )

                _ ->
                    ( model, items, Nothing )


-- HELPERS


hasItem : Model -> Bool
hasItem model =
    model.clipboard /= Nothing
