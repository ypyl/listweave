module Actions exposing (..)


type SearchToolbarAction
    = KeyArrowUp
    | KeyArrowDown
    | KeyEnter
    | CollapseAll
    | ExpandAll
    | QueryChanged String Int

type TagPopupAction
    = HighlightTag String
