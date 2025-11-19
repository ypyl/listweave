module ListItem exposing (..)

import Actions exposing (SortOrder(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Regex
import Set
import TagsUtils exposing (isTagRegex, processContent)
import Time exposing (Month(..), Posix, millisToPosix, posixToMillis, toDay, toMonth, toYear)


type ListItem
    = ListItem
        { id : Int
        , content : List String
        , tags : List String
        , children : List ListItem
        , collapsed : Bool
        , editing : Bool
        , created : Posix
        , updated : Posix
        }


encode : ListItem -> Encode.Value
encode (ListItem item) =
    -- Destructure the custom type
    Encode.object
        [ ( "id", Encode.int item.id )
        , ( "content", Encode.list Encode.string item.content )
        , ( "tags", Encode.list Encode.string item.tags )
        , ( "children", Encode.list encode item.children ) -- `encoder` handles the custom type
        , ( "collapsed", Encode.bool item.collapsed )
        , ( "editing", Encode.bool item.editing )
        , ( "created", Encode.float (toFloat (Time.posixToMillis item.created)) )
        , ( "updated", Encode.float (toFloat (Time.posixToMillis item.updated)) )
        ]


decode : Decoder ListItem
decode =
    Decode.map ListItem
        -- Map the *record* to the *custom type constructor*
        (Decode.map8
            (\id content tags children collapsed editing created updated ->
                { id = id
                , content = content
                , tags = tags
                , children = children
                , collapsed = collapsed
                , editing = editing
                , created = created
                , updated = updated
                }
            )
            (Decode.field "id" Decode.int)
            (Decode.field "content" (Decode.list Decode.string))
            (Decode.field "tags" (Decode.list Decode.string))
            (Decode.field "children" (Decode.list (Decode.lazy (\_ -> decode))))
            -- Use lazy here
            (Decode.field "collapsed" Decode.bool)
            (Decode.field "editing" Decode.bool)
            (Decode.field "created" posixDecoder)
            (Decode.field "updated" posixDecoder)
        )


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


formatDateToMDY : Posix -> String
formatDateToMDY posix =
    let
        zone =
            Time.utc

        month =
            Time.toMonth zone posix |> monthToInt

        day =
            Time.toDay zone posix

        year =
            Time.toYear zone posix
    in
    String.padLeft 2 '0' (String.fromInt month) ++ "/" ++ String.padLeft 2 '0' (String.fromInt day) ++ "/" ++ String.fromInt year


posixDecoder : Decoder Posix
posixDecoder =
    Decode.float
        |> Decode.map (\millis -> Time.millisToPosix (round millis))


sortItemsByDate : SortOrder -> List ListItem -> List ListItem
sortItemsByDate sortOrder items =
    let
        fn =
            case sortOrder of
                ByCreatedDate ->
                    getCreated

                ByUpdatedDate ->
                    getUpdated

        sortByDate item =
            Time.posixToMillis (fn item)

        sortedItems =
            List.sortBy sortByDate items |> List.reverse
    in
    List.map
        (\item ->
            let
                (ListItem record) =
                    item
            in
            ListItem { record | children = sortItemsByDate sortOrder record.children }
        )
        sortedItems


moveItem : (ListItem -> ListItem -> Bool) -> List ListItem -> List ListItem
moveItem predicate items =
    let
        -- Build the result in-order; when predicate x y is True we swap x and y and return the rest
        move processed remaining =
            case remaining of
                [] ->
                    processed

                x :: [] ->
                    processed ++ [ x ]

                x :: y :: ys ->
                    if predicate x y then
                        -- swap x and y and append the rest unchanged
                        processed ++ [ y, x ] ++ ys

                    else
                        move (processed ++ [ x ]) (y :: ys)
    in
    move [] items


moveItemUp : ListItem -> List ListItem -> List ListItem
moveItemUp target items =
    moveItem (\_ y -> y == target) items


moveItemDown : ListItem -> List ListItem -> List ListItem
moveItemDown target items =
    moveItem (\x _ -> x == target) items


getAllTags : List ListItem -> List String
getAllTags items =
    let
        collectTags : ListItem -> List String
        collectTags ((ListItem item) as listItem) =
            item.tags ++ List.concatMap collectTags (getChildren listItem)
    in
    items
        |> List.concatMap collectTags
        |> List.map String.trim
        |> List.filter (not << String.isEmpty)
        |> Set.fromList
        |> Set.toList


isCollapsed : ListItem -> Bool
isCollapsed (ListItem item) =
    item.collapsed


getChildren : ListItem -> List ListItem
getChildren (ListItem item) =
    item.children


isEditing : ListItem -> Bool
isEditing (ListItem item) =
    item.editing


getId : ListItem -> Int
getId (ListItem item) =
    item.id


newEmptyListItem : Posix -> Int -> ListItem
newEmptyListItem posix id =
    let
        autoTags =
            [ "created:" ++ formatDateToMDY posix
            , "updated:" ++ formatDateToMDY posix
            ]
    in
    ListItem { id = id, content = [], tags = autoTags, children = [], collapsed = True, editing = False, created = posix, updated = posix }


newListItem : { a | id : Int, content : List String, tags : List String, children : List ListItem, collapsed : Bool, editing : Bool, created : Posix, updated : Posix } -> ListItem
newListItem item =
    ListItem { id = item.id, content = item.content, tags = item.tags, children = item.children, collapsed = item.collapsed, editing = item.editing, created = item.created, updated = item.updated }


getContent : ListItem -> List String
getContent (ListItem record) =
    record.content


{-| Parse innerHTML from a contentEditable element into the same
    representation used by the app: a list of lines. The parser handles:

    - <br>, <br/> and <br /> as line separators
    - <pre><code>...</code></pre> code blocks: the inner code is inserted
      as raw lines and wrapped with lines containing "```" before and after
    - <span>...</span> and other inline tags: tags are stripped and inner
      text is preserved

    This is intentionally forgiving (simple string scanning) to avoid
    pulling in an HTML parser dependency.
-}
parseInnerHtml : String -> List String
parseInnerHtml html =
    let
        -- normalize a couple of HTML entities and common BR variants
        normalizedNbsp = String.replace "&nbsp;" " " html
        normalizedBr =
            normalizedNbsp
                |> String.replace "<br/>" "\n"
                |> String.replace "<br />" "\n"
                |> String.replace "<br>" "\n"

        -- temporarily mark code blocks so we don't strip their tags
        withCodeMarkers =
            let
                prefix = "<pre><code"
                -- Replace <pre><code...> sequence with ||CODE_START||
                replacePreCode s =
                    case String.indexes prefix s of
                        [] -> s
                        idx :: _ ->
                            let
                                before = String.slice 0 idx s
                                rest = String.slice (idx + String.length prefix) (String.length s) s
                            in
                            case String.indexes ">" rest of
                                [] -> s
                                closeIdx :: _ ->
                                    let
                                        after = String.slice (closeIdx + 1) (String.length rest) rest
                                    in
                                    replacePreCode (before ++ "||CODE_START||" ++ after)
            in
            normalizedBr
                |> replacePreCode
                |> String.replace "</code></pre>" "||CODE_END||"

        -- strip any HTML tag like <span ...> or </span> but preserve inner text
        stripTags : String -> String
        stripTags s =
            case String.indexes "<" s of
                [] ->
                    s

                i :: _ ->
                    let
                        before = String.slice 0 i s
                        rest = String.slice i (String.length s) s
                    in
                    case String.indexes ">" rest of
                        [] ->
                            -- malformed tag: return what we have
                            before

                        j :: _ ->
                            let
                                after = String.slice (j + 1) (String.length rest) rest
                            in
                            -- recurse to remove more tags
                            stripTags (before ++ after)

        -- process normal (non-code) HTML: strip tags then split on newlines
        processNormal : String -> List String
        processNormal s =
            s
                |> stripTags
                |> String.split "\n"
                |> List.map String.trim

        startMarker = "||CODE_START||"
        endMarker = "||CODE_END||"
        lenStart = String.length startMarker
        lenEnd = String.length endMarker

        -- recursive helper that walks the string and expands code blocks
        helper : String -> List String
        helper s =
            case String.indexes startMarker s of
                [] ->
                    processNormal s

                idx :: _ ->
                    let
                        prefix = String.slice 0 idx s
                        afterStart = String.slice (idx + lenStart) (String.length s) s
                    in
                    case String.indexes endMarker afterStart of
                        [] ->
                            -- no matching end marker: treat whole text as normal
                            processNormal s

                        endIdx :: _ ->
                            let
                                codeContent = String.slice 0 endIdx afterStart
                                rest = String.slice (endIdx + lenEnd) (String.length afterStart) afterStart
                                codeLines = String.lines codeContent
                                codeBlock = "```" :: (codeLines ++ [ "```" ])
                            in
                            (processNormal prefix) ++ codeBlock ++ (helper rest)
    in
    helper withCodeMarkers


getTags : ListItem -> List String
getTags (ListItem record) =
    record.tags


getUpdated : ListItem -> Posix
getUpdated (ListItem record) =
    record.updated


getCreated : ListItem -> Posix
getCreated (ListItem record) =
    record.created


deleteItem : ListItem -> List ListItem -> List ListItem
deleteItem (ListItem item) list =
    let
        deleteItemRecursive : Int -> List ListItem -> List ListItem
        deleteItemRecursive innerId innerList =
            let
                loop processed remaining =
                    case remaining of
                        [] ->
                            List.reverse processed

                        current :: rest ->
                            let
                                (ListItem record) =
                                    current
                            in
                            if record.id == innerId then
                                case processed of
                                    [] ->
                                        -- If there is no previous item, move children up
                                        loop processed (record.children ++ rest)

                                    prev :: processedTail ->
                                        let
                                            (ListItem prevRecord) =
                                                prev

                                            newPrev =
                                                ListItem { prevRecord | children = prevRecord.children ++ record.children }
                                        in
                                        loop (newPrev :: processedTail) rest

                            else
                                let
                                    newChildren =
                                        deleteItemRecursive innerId record.children

                                    newItem =
                                        ListItem { record | children = newChildren }
                                in
                                loop (newItem :: processed) rest
            in
            loop [] innerList
    in
    deleteItemRecursive item.id list


removeItemCompletely : ListItem -> List ListItem -> List ListItem
removeItemCompletely (ListItem item) list =
    let
        removeRecursive : Int -> List ListItem -> List ListItem
        removeRecursive innerId innerList =
            List.filterMap
                (\current ->
                    let
                        (ListItem record) =
                            current
                    in
                    if record.id == innerId then
                        Nothing

                    else
                        Just (ListItem { record | children = removeRecursive innerId record.children })
                )
                innerList
    in
    removeRecursive item.id list



-- Outdent an item: move it to be a sibling of its parent (opposite of indent)


outdentItem : ListItem -> List ListItem -> List ListItem
outdentItem item list =
    let
        -- Try to remove the item from children and insert it after the parent in the outer list
        removeAndLift acc remaining =
            case remaining of
                [] ->
                    ( List.reverse acc, False )

                current :: rest ->
                    let
                        (ListItem record) =
                            current
                    in
                    -- If the target is a direct child of current, remove it from current.children and insert after current
                    case List.partition (\r -> r == item) record.children of
                        ( [], _ ) ->
                            -- Not a direct child, recurse into children
                            let
                                ( newChildren, innerFound ) =
                                    removeAndLift [] record.children

                                newCurrent =
                                    ListItem { record | children = newChildren }

                                ( processed, done ) =
                                    if innerFound then
                                        ( List.reverse (newCurrent :: acc) ++ rest, True )

                                    else
                                        removeAndLift (newCurrent :: acc) rest
                            in
                            if done then
                                ( processed, True )

                            else
                                ( processed, False )

                        ( matched, remainingChildren ) ->
                            case matched of
                                [] ->
                                    removeAndLift (current :: acc) rest

                                m :: _ ->
                                    -- Lift matched item to be sibling after current
                                    let
                                        newCurrent =
                                            ListItem { record | children = remainingChildren }

                                        newAcc =
                                            List.reverse (newCurrent :: acc) ++ (m :: rest)
                                    in
                                    ( newAcc, True )

        ( result, found ) =
            removeAndLift [] list
    in
    if found then
        result

    else
        -- recurse into children if not found at this level
        List.map (\(ListItem record) -> ListItem { record | children = outdentItem item record.children }) list


indentItem : ListItem -> List ListItem -> List ListItem
indentItem item list =
    let
        loop acc remaining =
            case remaining of
                [] ->
                    List.reverse acc

                current :: rest ->
                    if current == item then
                        case acc of
                            (ListItem prevRecord) :: accRest ->
                                let
                                    newPrev =
                                        ListItem { prevRecord | collapsed = False, children = prevRecord.children ++ [ current ] }
                                in
                                List.reverse (newPrev :: accRest) ++ rest

                            [] ->
                                List.reverse acc ++ remaining

                    else
                        loop (current :: acc) rest

        result =
            loop [] list
    in
    if result == list then
        List.map
            (\(ListItem record) -> ListItem { record | children = indentItem item record.children })
            list

    else
        result


insertItemAfter : ListItem -> Int -> List ListItem -> Posix -> List ListItem
insertItemAfter ((ListItem afterItem) as after) newId list currentTime =
    case list of
        [] ->
            []

        item :: rest ->
            let
                (ListItem record) =
                    item
            in
            if record.id == afterItem.id then
                item :: newEmptyListItem currentTime newId :: rest

            else
                ListItem { record | children = insertItemAfter after newId record.children currentTime } :: insertItemAfter after newId rest currentTime


mapItem : (ListItem -> ListItem) -> List ListItem -> List ListItem
mapItem fn list =
    List.map
        (\item ->
            let
                (ListItem record) =
                    fn item
            in
            ListItem { record | children = mapItem fn record.children }
        )
        list


findById : Int -> ListItem -> Maybe ListItem
findById targetId (ListItem record) =
    if record.id == targetId then
        Just (ListItem record)

    else
        record.children
            |> List.foldl
                (\child acc ->
                    case acc of
                        Just _ ->
                            acc

                        Nothing ->
                            findById targetId child
                )
                Nothing


findInForest : Int -> List ListItem -> Maybe ListItem
findInForest targetId items =
    items
        |> List.foldl
            (\item acc ->
                case acc of
                    Just _ ->
                        acc

                    Nothing ->
                        findById targetId item
            )
            Nothing


toggleCollapseFn : ListItem -> ListItem -> ListItem
toggleCollapseFn (ListItem current) (ListItem item) =
    if item.id == current.id then
        ListItem { item | collapsed = not item.collapsed }

    else
        ListItem item


editItemFn : Int -> ListItem -> ListItem
editItemFn id (ListItem item) =
    if item.id == id then
        ListItem { item | editing = True }

    else
        ListItem { item | editing = False }


updateItemContentFn : ListItem -> List String -> Posix -> ListItem -> ListItem
updateItemContentFn (ListItem current) lines currentTime (ListItem item) =
    if item == current then
        let
            finalLines =
                if List.all String.isEmpty lines then
                    []

                else
                    lines

            userTags =
                extractTags lines

            hasCodeBlock =
                TagsUtils.processContent lines
                    |> List.any (\( isCode, _ ) -> isCode)

            autoTags =
                [ "created:" ++ formatDateToMDY item.created
                , "updated:" ++ formatDateToMDY currentTime
                ]
                    ++ (if hasCodeBlock then
                            [ "code" ]

                        else
                            []
                       )

            allTags =
                Set.fromList (userTags ++ autoTags) |> Set.toList
        in
        ListItem { item | content = finalLines, tags = allTags, updated = currentTime }

    else
        ListItem item


extractTags : List String -> List String
extractTags lines =
    let
        blocks =
            TagsUtils.processContent lines

        -- Only extract tags from non-code blocks
        textBlocks =
            blocks
                |> List.filter (\( isCode, _ ) -> not isCode)
                |> List.concatMap (\( _, blockLines ) -> blockLines)
                |> String.join "\n"
    in
    Regex.find isTagRegex textBlocks
        |> List.filterMap
            (\m ->
                case m.submatches of
                    (Just tag) :: _ ->
                        Just tag

                    _ ->
                        Nothing
            )


saveItemFn : ListItem -> ListItem -> ListItem
saveItemFn (ListItem current) (ListItem item) =
    if item == current then
        ListItem { item | editing = False }

    else
        ListItem item


containsItem : Int -> ListItem -> Bool
containsItem id (ListItem item) =
    if item.id == id then
        True

    else
        List.any (containsItem id) item.children


expandToItem : Int -> List ListItem -> List ListItem
expandToItem id =
    List.map
        (\item ->
            let
                (ListItem record) =
                    item
            in
            if containsItem id item then
                ListItem { record | collapsed = False, children = expandToItem id record.children }

            else
                item
        )


findNextTagItemId : ListItem -> String -> List ListItem -> Maybe Int
findNextTagItemId (ListItem current) tag items =
    let
        flat =
            flattenItems items

        tagged =
            List.filter (\(ListItem i) -> List.member tag i.tags) flat

        ids =
            List.map (\(ListItem i) -> i.id) tagged

        len =
            List.length ids

        idx =
            elemIndex current.id ids
    in
    case ( ids, idx ) of
        ( [], _ ) ->
            Nothing

        ( _, Nothing ) ->
            List.head ids

        -- if currentId not found, return first
        ( _, Just i ) ->
            let
                nextIdx =
                    Basics.modBy len (i + 1)
            in
            List.head (List.drop nextIdx ids)



-- Flatten all items into a list (preorder)


flattenItems : List ListItem -> List ListItem
flattenItems items =
    List.concatMap
        (\item ->
            item
                :: flattenItems
                    (let
                        (ListItem i) =
                            item
                     in
                     i.children
                    )
        )
        items


elemIndex : a -> List a -> Maybe Int
elemIndex x xs =
    let
        helper idx rest =
            case rest of
                [] ->
                    Nothing

                y :: ys ->
                    if x == y then
                        Just idx

                    else
                        helper (idx + 1) ys
    in
    helper 0 xs


flattenVisibleItems : List ListItem -> List ListItem
flattenVisibleItems items =
    List.concatMap
        (\item ->
            let
                (ListItem record) =
                    item
            in
            if record.collapsed then
                [ item ]

            else
                item :: flattenVisibleItems record.children
        )
        items


findPreviousItem : ListItem -> List ListItem -> Maybe ListItem
findPreviousItem target items =
    let
        visibleItems =
            flattenVisibleItems items
    in
    elemIndex target visibleItems
        |> Maybe.andThen
            (\index ->
                if index > 0 then
                    List.head (List.drop (index - 1) visibleItems)

                else
                    Nothing
            )


findNextItem : ListItem -> List ListItem -> Maybe ListItem
findNextItem target items =
    let
        visibleItems =
            flattenVisibleItems items
    in
    elemIndex target visibleItems
        |> Maybe.andThen
            (\index ->
                List.head (List.drop (index + 1) visibleItems)
            )


setAllCollapsed : Bool -> List ListItem -> List ListItem
setAllCollapsed collapsedFlag items =
    List.map
        (\(ListItem item) ->
            ListItem { item | collapsed = collapsedFlag, children = setAllCollapsed collapsedFlag item.children }
        )
        items



-- CLIPBOARD OPERATIONS


findItemPosition : ListItem -> List ListItem -> Maybe ( Maybe Int, Int )
findItemPosition target items =
    let
        findInList parentId list =
            case List.indexedMap Tuple.pair list of
                [] ->
                    Nothing

                indexedItems ->
                    List.foldl
                        (\( index, item ) acc ->
                            case acc of
                                Just _ ->
                                    acc

                                Nothing ->
                                    if item == target then
                                        Just ( parentId, index )

                                    else
                                        case item of
                                            ListItem data ->
                                                findInList (Just (getId item)) data.children
                        )
                        Nothing
                        indexedItems
    in
    findInList Nothing items


splitAt : Int -> List a -> ( List a, List a )
splitAt n list =
    ( List.take n list, List.drop n list )


restoreItemAtPosition : ListItem -> Maybe Int -> Int -> List ListItem -> List ListItem
restoreItemAtPosition item parentId childIndex items =
    case parentId of
        Nothing ->
            let
                ( before, after ) =
                    splitAt childIndex items
            in
            before ++ (item :: after)

        Just pid ->
            List.map
                (\currentItem ->
                    case currentItem of
                        ListItem data ->
                            if data.id == pid then
                                let
                                    ( before, after ) =
                                        splitAt childIndex data.children
                                in
                                ListItem { data | children = before ++ (item :: after) }

                            else
                                ListItem { data | children = restoreItemAtPosition item parentId childIndex data.children }
                )
                items


deepCopyItem : Posix -> Int -> ListItem -> ListItem
deepCopyItem currentTime nextIdBase (ListItem item) =
    let
        copyChildren : Int -> List ListItem -> ( List ListItem, Int )
        copyChildren idOffset children =
            List.foldl
                (\child ( acc, offset ) ->
                    let
                        newChild = deepCopyItem currentTime (nextIdBase + offset) child
                        childrenCount = countTotalItems child
                    in
                    ( acc ++ [ newChild ], offset + childrenCount )
                )
                ( [], idOffset + 1 )
                children

        ( newChildren, _ ) = copyChildren 0 item.children

        autoTags =
            [ "created:" ++ formatDateToMDY currentTime
            , "updated:" ++ formatDateToMDY currentTime
            ]

        userTags =
            List.filter (\tag -> not (String.startsWith "created:" tag) && not (String.startsWith "updated:" tag)) item.tags
    in
    ListItem
        { id = nextIdBase
        , content = item.content
        , tags = userTags ++ autoTags
        , children = newChildren
        , collapsed = item.collapsed
        , editing = False
        , created = currentTime
        , updated = currentTime
        }

countTotalItems : ListItem -> Int
countTotalItems (ListItem item) =
    1 + List.sum (List.map countTotalItems item.children)

insertClipboardItemAfter : ListItem -> ListItem -> List ListItem -> List ListItem
insertClipboardItemAfter targetItem clipboardItem items =
    let
        insertInList list =
            case list of
                [] ->
                    []

                item :: rest ->
                    if item == targetItem then
                        item :: clipboardItem :: rest
                    else
                        case item of
                            ListItem data ->
                                ListItem { data | children = insertInList data.children } :: insertInList rest
    in
    insertInList items


getNextId : List ListItem -> Int
getNextId items =
    let
        getMaxId : ListItem -> Int
        getMaxId (ListItem item) =
            List.foldl max item.id (List.map getMaxId item.children)
    in
    case List.map getMaxId items of
        [] ->
            1

        maxIds ->
            List.foldl max 0 maxIds + 1


moveItemInTree : (ListItem -> List ListItem -> List ListItem) -> ListItem -> List ListItem -> List ListItem
moveItemInTree moveFn target items =
    let
        applyMove list =
            if List.any (\item -> item == target) list then
                moveFn target list

            else
                List.map
                    (\item ->
                        case item of
                            ListItem data ->
                                ListItem { data | children = applyMove data.children }
                    )
                    list
    in
    applyMove items


filterItems : String -> List String -> List ListItem -> List ListItem
filterItems query selectedTags items =
    if String.isEmpty query && List.isEmpty selectedTags then
        items

    else
        let
            searchWords =
                String.words (String.toLower query)

            containsQuery item =
                let
                    matches words text =
                        if List.isEmpty words then
                            True

                        else
                            List.any (\word -> String.contains word text) words

                    itemContent =
                        String.toLower (String.join " " (getContent item))

                    itemTags =
                        String.toLower (String.join " " (getTags item))

                    contentMatches =
                        matches searchWords itemContent

                    tagMatches =
                        matches searchWords itemTags

                    selectedTagsMatch =
                        if List.isEmpty selectedTags then
                            True

                        else
                            List.all (\selectedTag -> List.member selectedTag (getTags item)) selectedTags
                in
                (contentMatches || tagMatches) && selectedTagsMatch

            filterItemAndChildren item =
                case item of
                    ListItem data ->
                        if containsQuery item || data.editing then
                            Just (ListItem { data | children = List.filterMap filterItemAndChildren data.children })

                        else
                            case List.filterMap filterItemAndChildren data.children of
                                [] ->
                                    Nothing

                                filteredChildren ->
                                    Just (ListItem { data | children = filteredChildren })

            filtered =
                List.filterMap filterItemAndChildren items
        in
        filtered


findEditingItem : List ListItem -> Maybe ( ListItem, Int )
findEditingItem items =
    let
        findInList itemList =
            case itemList of
                [] ->
                    Nothing

                item :: rest ->
                    if isEditing item then
                        -- For now, return cursor position 0 - this could be enhanced to track actual cursor position
                        Just ( item, 0 )

                    else
                        case findInList (getChildren item) of
                            Just found ->
                                Just found

                            Nothing ->
                                findInList rest
    in
    findInList items
