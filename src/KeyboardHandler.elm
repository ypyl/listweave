module KeyboardHandler exposing (onKeyDown)

import Clipboard
import Html
import Html.Events exposing (preventDefaultOn)
import Json.Decode as D
import ListItem exposing (ListItem, getContent)
import TagPopup
import TagsUtils


type Key
    = Backspace
    | Enter
    | Left
    | Right
    | Up
    | Down
    | X
    | V
    | C
    | Escape
    | Tab
    | Other Int


keyFromCode : Int -> Key
keyFromCode code =
    case code of
        8 ->
            Backspace

        13 ->
            Enter

        27 ->
            Escape

        37 ->
            Left

        38 ->
            Up

        39 ->
            Right

        40 ->
            Down

        88 ->
            X

        86 ->
            V

        67 ->
            C

        9 ->
            Tab

        _ ->
            Other code


onKeyDown :
    { tagPopup : TagPopup.Model
    , clipboard : Clipboard.Model
    , onMoveItemUpAfter : ListItem -> msg
    , onMoveItemDownAfter : ListItem -> msg
    , onCutItem : ListItem -> msg
    , onCopyItem : ListItem -> msg
    , onPasteItem : ListItem -> msg
    , onDeleteItem : ListItem -> msg
    , onInsertSelectedTagAfter : ListItem -> String -> msg
    , onSaveAndCreateAfter : ListItem -> String -> msg
    , onIndentItemAfter : ListItem -> msg
    , onOutdentItemAfter : ListItem -> msg
    , onTagPopupMsg : TagPopup.Msg -> msg
    , onNavigateToPreviousAfter : ListItem -> msg
    , onNavigateToNextAfter : ListItem -> msg
    , onRestoreCutItem : msg
    , onAddNewLineAfter : ListItem -> msg
    , onNoOp : msg
    }
    -> ListItem
    -> Html.Attribute msg
onKeyDown config item =
    let
        keyDecoder : D.Decoder Key
        keyDecoder =
            D.map keyFromCode (D.field "keyCode" D.int)

        altKeyDecoder =
            D.field "altKey" D.bool

        shiftKeyDecoder =
            D.field "shiftKey" D.bool

        innerHtml =
            D.at ["target", "innerHTML"] (D.string)
    in
    preventDefaultOn "keydown"
        (D.map4
            (\key alt shift innerHtmlValue ->
                if alt then
                    case key of
                        Up ->
                            ( config.onMoveItemUpAfter item, True )

                        Down ->
                            ( config.onMoveItemDownAfter item, True )

                        X ->
                            ( config.onCutItem item, True )

                        C ->
                            ( config.onCopyItem item, True )

                        V ->
                            ( config.onPasteItem item, True )

                        _ ->
                            ( config.onNoOp, False )

                else
                    case key of
                        Backspace ->
                            if List.isEmpty (getContent item) || getContent item == [ "" ] then
                                ( config.onDeleteItem item, True )

                            else
                                ( config.onNoOp, False )

                        Enter ->
                            case ( shift, TagPopup.isVisible config.tagPopup, TagPopup.getHighlightedTag config.tagPopup ) of
                                ( False, True, Just tag ) ->
                                    ( config.onInsertSelectedTagAfter item tag, True )

                                ( True, _, _ ) ->
                                    ( config.onAddNewLineAfter item, True )

                                _ ->
                                    ( config.onSaveAndCreateAfter item innerHtmlValue, True )

                        Tab ->
                            if shift then
                                ( config.onOutdentItemAfter item, True )

                            else
                                ( config.onIndentItemAfter item, True )

                        Left ->
                            ( config.onTagPopupMsg TagPopup.Hide, False )

                        Right ->
                            ( config.onTagPopupMsg TagPopup.Hide, False )

                        Escape ->
                            case ( Clipboard.hasItem config.clipboard, TagPopup.isVisible config.tagPopup ) of
                                ( True, _ ) ->
                                    ( config.onRestoreCutItem, True )

                                ( False, True ) ->
                                    ( config.onTagPopupMsg TagPopup.Hide, True )

                                ( False, False ) ->
                                    ( config.onNoOp, False )

                        Down ->
                            if TagPopup.isVisible config.tagPopup then
                                ( config.onTagPopupMsg TagPopup.NavigateDown, True )
                            else
                                ( config.onNavigateToNextAfter item, True )

                        Up ->
                            if TagPopup.isVisible config.tagPopup then
                                ( config.onTagPopupMsg TagPopup.NavigateUp, True )
                            else
                                ( config.onNavigateToPreviousAfter item, True )

                        _ ->
                            ( config.onNoOp, False )
            )
            keyDecoder
            altKeyDecoder
            shiftKeyDecoder
            innerHtml
        )
