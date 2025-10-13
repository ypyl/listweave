module Theme exposing (..)

import Html
import Html.Attributes exposing (style)


-- COLORS

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

spacing =
    { xs = "4px"
    , sm = "8px"
    , md = "12px"
    , lg = "16px"
    , xl = "20px"
    , xxl = "24px"
    }


-- TYPOGRAPHY

typography =
    { fontSize = "12px"
    , lineHeight = "1.8"
    , fontFamily = "inherit"
    , fontFamilyMono = "monospace"
    }


-- LAYOUT

layout =
    { maxWidth = "800px"
    , borderRadius = "4px"
    , borderRadiusLarge = "12px"
    }


-- COMPONENT STYLES

container =
    [ style "max-width" layout.maxWidth
    , style "margin" "0 auto"
    , style "padding" spacing.xl
    ]

button =
    [ style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "cursor" "pointer"
    , style "font-size" typography.fontSize
    , style "user-select" "none"
    ]

input =
    [ style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "font-size" typography.fontSize
    ]

listItem =
    [ style "margin-bottom" "5px"
    , style "background" colors.background
    , style "border" ("1px solid " ++ colors.border)
    , style "border-radius" layout.borderRadius
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "font-size" typography.fontSize
    ]

listItemRow =
    [ style "display" "flex"
    , style "align-items" "flex-start"
    , style "max-width" "80%"
    ]

listItemRowWithChildren =
    listItemRow ++ [ style "margin-bottom" "5px" ]

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

arrowEmpty =
    [ style "width" spacing.xl
    , style "display" "inline-block"
    , style "line-height" typography.lineHeight
    ]

bullet =
    [ style "width" spacing.xl
    , style "min-width" spacing.xl
    , style "display" "inline-flex"
    , style "align-items" "center"
    , style "justify-content" "center"
    , style "user-select" "none"
    , style "line-height" typography.lineHeight
    ]

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

content =
    [ style "white-space" "pre-wrap"
    , style "line-height" typography.lineHeight
    ]

contentEmpty =
    [ style "color" colors.textPlaceholder
    , style "line-height" typography.lineHeight
    ]

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

tag =
    [ style "color" colors.link
    , style "cursor" "pointer"
    , style "user-select" "none"
    , style "white-space" "nowrap"
    ]

tagSelected =
    tag ++
    [ style "background" colors.highlight
    , style "color" colors.text
    , style "font-weight" "bold"
    ]

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

tagChipClose =
    [ style "cursor" "pointer"
    , style "color" colors.textMuted
    , style "font-weight" "bold"
    , style "user-select" "none"
    ]

selectedTagsContainer =
    [ style "margin-bottom" spacing.md
    , style "display" "flex"
    , style "flex-wrap" "wrap"
    , style "gap" "6px"
    , style "align-items" "center"
    ]

searchToolbar =
    [ style "margin-bottom" spacing.lg
    , style "display" "flex"
    , style "align-items" "center"
    , style "gap" spacing.sm
    ]

searchInput =
    input ++
    [ style "flex-grow" "1"
    ]

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

popupItem =
    [ style "cursor" "pointer"
    , style "user-select" "none"
    , style "color" "inherit"
    , style "padding" (spacing.xs ++ " " ++ spacing.sm)
    , style "border-radius" layout.borderRadius
    , style "font-size" typography.fontSize
    ]

popupItemHighlighted =
    popupItem ++ [ style "background" colors.tagBackground ]

popupItemNormal =
    popupItem ++ [ style "background" "transparent" ]

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