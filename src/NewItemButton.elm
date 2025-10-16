module NewItemButton exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events exposing (onClick)
import Theme


view : msg -> Html msg
view onClickMsg =
    div
        (onClick onClickMsg :: Html.Attributes.style "margin-left" "10px" :: Html.Attributes.style "display" "inline-flex" :: Html.Attributes.style "align-items" "center" :: Html.Attributes.style "justify-content" "center" :: Theme.button)
        [ text "+ Add Item" ]
