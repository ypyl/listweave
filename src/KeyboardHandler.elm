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
    | Escape
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

        _ ->
            Other code


onKeyDown :
    { tagPopup : TagPopup.Model
    , clipboard : Clipboard.Model
    , onMoveItemUp : Int -> ListItem -> msg
    , onMoveItemDown : Int -> ListItem -> msg
    , onCutItem : ListItem -> msg
    , onPasteItem : ListItem -> msg
    , onDeleteItem : ListItem -> msg
    , onInsertSelectedTag : ListItem -> String -> Int -> msg
    , onSaveAndCreateAfter : ListItem -> msg
    , onIndentItem : Int -> ListItem -> msg
    , onOutdentItem : Int -> ListItem -> msg
    , onTagPopupMsg : TagPopup.Msg -> msg
    , onNavigateToPreviousWithColumn : ListItem -> Int -> msg
    , onNavigateToNextWithColumn : ListItem -> Int -> msg
    , onRestoreCutItem : msg
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

        cursorPosDecoder =
            D.field "target" (D.field "selectionStart" D.int)

        valueDecoder =
            D.field "target" (D.field "value" D.string)
    in
    preventDefaultOn "keydown"
        (D.map5
            (\key alt shift cursorPos value ->
                if alt then
                    case key of
                        Up ->
                            ( config.onMoveItemUp cursorPos item, True )

                        Down ->
                            ( config.onMoveItemDown cursorPos item, True )

                        Other 88 ->
                            ( config.onCutItem item, True )

                        Other 86 ->
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
                                    ( config.onInsertSelectedTag item tag cursorPos, True )

                                ( True, _, _ ) ->
                                    ( config.onNoOp, False )

                                _ ->
                                    ( config.onSaveAndCreateAfter item, True )

                        Other 9 ->
                            if shift then
                                ( config.onOutdentItem cursorPos item, True )

                            else
                                ( config.onIndentItem cursorPos item, True )

                        Left ->
                            case TagsUtils.focusedTag cursorPos value of
                                Just _ ->
                                    ( config.onNoOp, False )

                                Nothing ->
                                    ( config.onTagPopupMsg TagPopup.Hide, False )

                        Right ->
                            case TagsUtils.focusedTag cursorPos value of
                                Just _ ->
                                    ( config.onNoOp, False )

                                Nothing ->
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
                                let
                                    lines =
                                        String.lines value

                                    totalLines =
                                        List.length lines

                                    currentLineIndex =
                                        String.left cursorPos value
                                            |> String.lines
                                            |> List.length
                                            |> (\n -> n - 1)
                                in
                                if currentLineIndex >= totalLines - 1 then
                                    let
                                        currentLine =
                                            String.left cursorPos value |> String.lines |> List.reverse |> List.head |> Maybe.withDefault ""

                                        columnPos =
                                            String.length currentLine
                                    in
                                    ( config.onNavigateToNextWithColumn item columnPos, True )

                                else
                                    ( config.onNoOp, False )

                        Up ->
                            if TagPopup.isVisible config.tagPopup then
                                ( config.onTagPopupMsg TagPopup.NavigateUp, True )

                            else
                                let
                                    currentLineIndex =
                                        String.left cursorPos value
                                            |> String.lines
                                            |> List.length
                                            |> (\n -> n - 1)
                                in
                                if currentLineIndex <= 0 then
                                    let
                                        currentLine =
                                            String.left cursorPos value |> String.lines |> List.reverse |> List.head |> Maybe.withDefault ""

                                        columnPos =
                                            String.length currentLine
                                    in
                                    ( config.onNavigateToPreviousWithColumn item columnPos, True )

                                else
                                    ( config.onNoOp, False )

                        Other _ ->
                            ( config.onNoOp, False )
            )
            keyDecoder
            altKeyDecoder
            shiftKeyDecoder
            cursorPosDecoder
            valueDecoder
        )
