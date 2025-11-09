module TagsUtils exposing (..)

import Regex


type alias FocusedTag =
    { tag : String
    , position : Int
    }


tagPrefix : String
tagPrefix =
    "@"


tagPostfix : String
tagPostfix =
    ""


type Change
    = Insertion Int String -- position, inserted char
    | Deletion Int String -- position, deleted char
    | NoChange


findCurrentWord : String -> String -> Int -> String -> String
findCurrentWord before after pos text =
    let
        wordStart =
            case List.reverse (String.indexes " " before) |> List.head of
                Just i ->
                    i + 1

                Nothing ->
                    0

        wordEnd =
            case String.indexes " " after |> List.head of
                Just i ->
                    pos + i

                Nothing ->
                    String.length text
    in
    String.slice wordStart wordEnd text


isInsideTagBrackets : Int -> String -> Maybe ( String, String )
isInsideTagBrackets cursorPos content =
    if isInsideCodeBlock cursorPos content then
        Nothing
    else
        focusedTag cursorPos content
            |> Maybe.map
                (\{ tag, position } ->
                    ( String.left position tag, tag )
                )


isTagRegex : Regex.Regex
isTagRegex =
    Regex.fromString (tagPrefix ++ "([a-zA-Z0-9-_]*)" ++ tagPostfix)
        |> Maybe.withDefault Regex.never


focusedTag : Int -> String -> Maybe FocusedTag
focusedTag idx content =
    Regex.find isTagRegex content
        |> List.filter
            (\m ->
                let
                    start =
                        m.index

                    end =
                        m.index + String.length m.match
                in
                idx >= start && idx <= end
            )
        |> List.head
        |> Maybe.map
            (\match ->
                case List.head match.submatches of
                    Just (Just submatch) ->
                        { tag = submatch
                        , position = idx - (match.index + String.length tagPrefix)
                        }

                    _ ->
                        { tag = ""
                        , position = idx - match.index - String.length tagPrefix
                        }
            )

findNext : List String -> String -> Maybe String
findNext list current =
    case list of
        [] -> Nothing
        x :: xs ->
            if x == current then
                case xs of
                    [] -> List.head list  -- wrap around to first
                    next :: _ -> Just next
            else
                findNext xs current

findPrev : List String -> String -> Maybe String
findPrev list current =
    case list of
        [] -> Nothing
        [x] ->
            if x == current then
                List.reverse list |> List.head  -- wrap around to last
            else
                Nothing
        x :: y :: rest ->
            if y == current then
                Just x
            else
                findPrev (y :: rest) current


processContent : List String -> List ( Bool, List String )
processContent content =
    let
        isCodeBlock line =
            String.startsWith "```" line

        processLines =
            List.foldl
                (\line ( currentLines, inCode, acc ) ->
                    if isCodeBlock line then
                        if inCode then
                            -- End of code block, finalize the code block and reset
                            ( [], False, acc ++ [ ( True, currentLines ) ] )
                        else
                            -- Start of code block, save previous lines as text block if any
                            ( []
                            , True
                            , if List.isEmpty currentLines then
                                acc
                              else
                                acc ++ [ ( False, currentLines ) ]
                            )
                    else if inCode then
                        -- Inside code block, collect the line
                        ( currentLines ++ [ line ], inCode, acc )
                    else
                        -- Regular text
                        ( currentLines ++ [ line ], inCode, acc )
                )
                ( [], False, [] )
                content
    in
    case processLines of
        ( remainingLines, _, blocks ) ->
            if List.isEmpty remainingLines then
                blocks
            else
                blocks ++ [ ( False, remainingLines ) ]


isInsideCodeBlock : Int -> String -> Bool
isInsideCodeBlock cursorPos content =
    let
        lines =
            String.lines content

        findBlock ( inCode, pos ) line =
            let
                lineEnd =
                    pos + String.length line

                isCursorInLine =
                    cursorPos >= pos && cursorPos <= lineEnd
            in
            if isCursorInLine then
                -- Cursor is in this line. Return current `inCode` state and a flag to stop.
                ( inCode, -1 )

            else if String.startsWith "```" line then
                -- This line is a fence, it flips the state for the *next* line.
                ( not inCode, pos + String.length line + 1 )

            else
                -- Cursor not in this line, continue.
                ( inCode, pos + String.length line + 1 )

        ( wasInCode, finalPos ) =
            List.foldl
                (\line acc ->
                    let
                        ( currentInCode, currentPos ) =
                            acc
                    in
                    if currentPos == -1 then
                        acc

                    else
                        findBlock acc line
                )
                ( False, 0 )
                lines
    in
    if finalPos == -1 then
        wasInCode

    else
        False


insertTagAtCursor : String -> String -> Int -> ( String, Int )
insertTagAtCursor content tag cursorPos =
    let
        before = String.left cursorPos content
        after = String.dropLeft cursorPos content

        tagStart =
            String.reverse before
                |> String.indexes tagPrefix
                |> List.head
                |> Maybe.map (\i -> cursorPos - i - 1)
                |> Maybe.withDefault cursorPos

        newContent =
            String.left tagStart content
                ++ tagPrefix
                ++ tag
                ++ after

        newCaretPos =
            tagStart + String.length tagPrefix + String.length tag
    in
    ( newContent, newCaretPos )
