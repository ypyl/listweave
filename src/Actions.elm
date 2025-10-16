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
    | ExportModel
    | ImportModel


type TagPopupAction
    = HighlightTag String
