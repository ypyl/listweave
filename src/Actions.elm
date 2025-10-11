module Actions exposing (..)


type Action
    = SearchToolbarKeyArrowUp
    | SearchToolbarKeyArrowDown
    | SearchToolbarKeyEnter
    | SearchToolbarCollapseAll
    | SearchToolbarExpandAll
    | SearchToolbarQueryChanged String Int
