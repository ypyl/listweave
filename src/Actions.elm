module Actions exposing (..)


type SortOrder
    = ByCreatedDate
    | ByUpdatedDate


type SearchToolbarAction
    = KeyArrowUp
    | KeyArrowDown
    | KeyEnter
    | CollapseAll
    | ExpandAll
    | QueryChanged String Int
    | SetSortOrder SortOrder


type TagPopupAction
    = HighlightTag String
