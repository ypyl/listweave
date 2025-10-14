module Theme exposing (..)

import Html
import Html.Attributes exposing (style)



-- COLORS


colors : { background : String, border : String, borderSelected : String, text : String, textMuted : String, textPlaceholder : String, link : String, highlight : String, tagBackground : String, codeBackground : String }
colors =
    { background = "#f5f5f5"
    , border = "#ccc"
    , borderSelected = "#90caf9"
    , text = "#000"
    , textMuted = "#666"
    , textPlaceholder = "#aaa"
    , link = "#007acc"
    , highlight = "#ffeb3b"
    , tagBackground = "#e3f2fd"
    , codeBackground = "#f5f5f5"
    }



-- SPACING


spacing : { xs : String, sm : String, md : String, lg : String, xl : String, xxl : String }
spacing =
    { xs = "4px"
    , sm = "8px"
    , md = "12px"
    , lg = "16px"
    , xl = "20px"
    , xxl = "24px"
    }



-- TYPOGRAPHY


typography : { fontSize : String, lineHeight : String, fontFamily : String, fontFamilyMono : String }
typography =
    { fontSize = "12px"
    , lineHeight = "1.8"
    , fontFamily = "inherit"
    , fontFamilyMono = "monospace"
    }



-- LAYOUT


layout : { maxWidth : String, borderRadius : String, borderRadiusLarge : String }
layout =
    { maxWidth = "800px"
    , borderRadius = "4px"
    , borderRadiusLarge = "12px"
    }



-- COMPONENT STYLES


container : List (Html.Attribute msg)
container =
    [ style "max-width" layout.maxWidth
    , style "margin" "0 auto"
    , style "padding" spacing.xl
    ]


button : List (Html.Attribute msg)
button =
    [ style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "cursor" "pointer"
    , style "font-size" typography.fontSize
    , style "user-select" "none"
    ]


buttonGroup : List (Html.Attribute msg)
buttonGroup =
    [ style "padding" "0"
    , style "cursor" "pointer"
    , style "font-size" typography.fontSize
    , style "user-select" "none"
    , style "display" "flex"
    , style "align-items" "center"
    ]



-- Base style for buttons *inside* a group (no radius yet)


buttonGroupBase : List (Html.Attribute msg)
buttonGroupBase =
    [ style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "cursor" "pointer"
    , style "font-size" typography.fontSize
    , style "user-select" "none"
    , style "border-right" "none" -- Remove the inner border
    ]



-- Style for the left-most (first) button


buttonGroupFirst : List (Html.Attribute msg)
buttonGroupFirst =
    buttonGroupBase
        ++ [ style "border-radius" (layout.borderRadius ++ " 0 0 " ++ layout.borderRadius) -- Radius only on the left
           ]



-- Style for the right-most (last) button


buttonGroupLast : List (Html.Attribute msg)
buttonGroupLast =
    buttonGroupBase
        ++ [ style "border-right" ("1px solid " ++ colors.border) -- Re-add the border that 'buttonGroupBase' removed
           , style "border-radius" ("0 " ++ layout.borderRadius ++ " " ++ layout.borderRadius ++ " 0") -- Radius only on the right
           ]



-- Style for middle buttons (if any)


buttonGroupMiddle : List (Html.Attribute msg)
buttonGroupMiddle =
    buttonGroupBase


select : List (Html.Attribute msg)
select =
    [ style "display" "flex"
    , style "gap" spacing.xs
    , style "font-size" typography.fontSize
    , style "user-select" "none"
    , style "align-items" "center"
    , style "align-self" "flex-end"
    , style "margin-left" "auto"
    ]


input : List (Html.Attribute msg)
input =
    [ style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "font-size" typography.fontSize
    ]


listItem : List (Html.Attribute msg)
listItem =
    [ style "margin-bottom" "5px"
    , style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "font-size" typography.fontSize
    ]


listItemRow : List (Html.Attribute msg)
listItemRow =
    [ style "display" "flex"
    , style "align-items" "flex-start"
    , style "max-width" "80%"
    ]


listItemRowWithChildren : List (Html.Attribute msg)
listItemRowWithChildren =
    listItemRow ++ [ style "margin-bottom" "5px" ]


arrow : List (Html.Attribute msg)
arrow =
    [ style "cursor" "pointer"
    , style "user-select" "none"
    , style "width" spacing.xl
    , style "min-width" spacing.xl
    , style "display" "inline-flex"
    , style "align-items" "center"
    , style "justify-content" "center"
    , style "line-height" typography.lineHeight
    ]


arrowEmpty : List (Html.Attribute msg)
arrowEmpty =
    [ style "width" spacing.xl
    , style "display" "inline-block"
    , style "line-height" typography.lineHeight
    ]


bullet : List (Html.Attribute msg)
bullet =
    [ style "width" spacing.xl
    , style "min-width" spacing.xl
    , style "display" "inline-flex"
    , style "align-items" "center"
    , style "justify-content" "center"
    , style "user-select" "none"
    , style "line-height" typography.lineHeight
    ]


textarea : List (Html.Attribute msg)
textarea =
    [ style "box-sizing" "border-box"
    , style "overflow-y" "hidden"
    , style "resize" "none"
    , style "border" "none"
    , style "outline" "none"
    , style "background" "transparent"
    , style "width" "100%"
    , style "font-family" typography.fontFamily
    , style "font-size" typography.fontSize
    , style "padding" "0"
    , style "margin" "0"
    , style "display" "block"
    , style "line-height" typography.lineHeight
    ]


content : List (Html.Attribute msg)
content =
    [ style "white-space" "pre-wrap"
    , style "line-height" typography.lineHeight
    ]


contentEmpty : List (Html.Attribute msg)
contentEmpty =
    [ style "color" colors.textPlaceholder
    , style "line-height" typography.lineHeight
    ]


codeBlock : List (Html.Attribute msg)
codeBlock =
    [ style "display" "block"
    , style "white-space" "pre-wrap"
    , style "line-height" typography.lineHeight
    , style "background" colors.codeBackground
    , style "padding" spacing.sm
    , style "border-radius" layout.borderRadius
    , style "margin" (spacing.xs ++ " 0")
    , style "font-family" typography.fontFamilyMono
    ]


tag : List (Html.Attribute msg)
tag =
    [ style "color" colors.link
    , style "cursor" "pointer"
    , style "user-select" "none"
    , style "white-space" "nowrap"
    ]


tagSelected : List (Html.Attribute msg)
tagSelected =
    tag
        ++ [ style "background" colors.highlight
           , style "color" colors.text
           , style "font-weight" "bold"
           ]


tagChip : List (Html.Attribute msg)
tagChip =
    [ style "background" colors.tagBackground
    , style "border" ("1px solid " ++ colors.borderSelected)
    , style "border-radius" layout.borderRadiusLarge
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "display" "flex"
    , style "align-items" "center"
    , style "gap" spacing.xs
    , style "font-size" typography.fontSize
    ]


tagChipClose : List (Html.Attribute msg)
tagChipClose =
    [ style "cursor" "pointer"
    , style "color" colors.textMuted
    , style "font-weight" "bold"
    , style "user-select" "none"
    ]


selectedTagsContainer : List (Html.Attribute msg)
selectedTagsContainer =
    [ style "display" "flex"
    , style "flex-wrap" "wrap"
    , style "gap" "6px"
    , style "align-items" "center"
    ]


searchToolbar : List (Html.Attribute msg)
searchToolbar =
    [ style "margin-bottom" spacing.lg
    , style "display" "flex"
    , style "align-items" "center"
    , style "gap" spacing.sm
    ]


searchInput : List (Html.Attribute msg)
searchInput =
    input
        ++ [ style "flex-grow" "1"
           ]


popup : List (Html.Attribute msg)
popup =
    [ style "position" "absolute"
    , style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "display" "flex"
    , style "flex-direction" "column"
    , style "gap" "2px"
    , style "padding" spacing.xs
    , style "overflow-y" "auto"
    , style "font-size" typography.fontSize
    ]


popupItem : List (Html.Attribute msg)
popupItem =
    [ style "cursor" "pointer"
    , style "user-select" "none"
    , style "color" "inherit"
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "border-radius" layout.borderRadius
    , style "font-size" typography.fontSize
    ]


popupItemHighlighted : List (Html.Attribute msg)
popupItemHighlighted =
    popupItem ++ [ style "background" colors.tagBackground ]


popupItemNormal : List (Html.Attribute msg)
popupItemNormal =
    popupItem ++ [ style "background" "transparent" ]


flexGrow : List (Html.Attribute msg)
flexGrow =
    [ style "flex-grow" "1" ]



-- HELPER FUNCTIONS


indentStyle : Int -> List (Html.Attribute msg)
indentStyle level =
    [ style "margin-left" (String.fromInt (level * 24) ++ "px") ]


positionStyle : Int -> Int -> Int -> List (Html.Attribute msg)
positionStyle top left width =
    [ style "top" (String.fromInt top ++ "px")
    , style "left" (String.fromInt left ++ "px")
    , style "width" (String.fromInt width ++ "px")
    ]
