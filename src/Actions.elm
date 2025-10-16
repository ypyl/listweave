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
    | AddNewItem


type TagPopupAction
    = HighlightTag String
