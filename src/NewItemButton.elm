module NewItemButton exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events exposing (onClick)


view : msg -> Html msg
view onClickMsg =
    div
        [ onClick onClickMsg
        , Html.Attributes.style "cursor" "pointer"
        , Html.Attributes.style "user-select" "none"
        , Html.Attributes.style "width" "20px"
        , Html.Attributes.style "min-width" "20px"
        , Html.Attributes.style "margin-left" "20px"
        , Html.Attributes.style "display" "inline-flex"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "justify-content" "center"
        ]
        [ text "+" ]