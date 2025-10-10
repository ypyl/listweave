module NewItemButton exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events exposing (onClick)


view : msg -> Html msg
view onClickMsg =
    div
        [ onClick onClickMsg
        , Html.Attributes.style "background" "#f5f5f5"
        , Html.Attributes.style "border" "1px solid #ccc"
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "padding" "4px 8px"
        , Html.Attributes.style "cursor" "pointer"
        , Html.Attributes.style "font-size" "12px"
        , Html.Attributes.style "user-select" "none"
        , Html.Attributes.style "margin-left" "20px"
        , Html.Attributes.style "display" "inline-flex"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "justify-content" "center"
        ]
        [ text "+ Add Item" ]