module ContentBlock exposing (ContentBlock(..), contentBlocksToLines, linesToContentBlocks)


type ContentBlock
    = TextBlock String
    | CodeBlock String


contentBlocksToLines : List ContentBlock -> List String
contentBlocksToLines blocks =
    List.concatMap
        (\block ->
            case block of
                TextBlock text ->
                    String.split "\n" text

                CodeBlock code ->
                    String.split "\n" code
        )
        blocks


linesToContentBlocks : List String -> List ContentBlock
linesToContentBlocks lines =
    let
        helper remaining acc inCode codeAcc =
            case remaining of
                [] ->
                    if inCode then
                        List.reverse (CodeBlock (String.join "\n" (List.reverse codeAcc)) :: acc)

                    else if List.isEmpty acc then
                        []

                    else
                        List.reverse acc

                line :: rest ->
                    if String.startsWith "```" line then
                        if inCode then
                            helper rest (CodeBlock (String.join "\n" (List.reverse codeAcc)) :: acc) False []

                        else
                            helper rest acc True []

                    else if inCode then
                        helper rest acc True (line :: codeAcc)

                    else
                        case acc of
                            (TextBlock text) :: accRest ->
                                helper rest (TextBlock (text ++ "\n" ++ line) :: accRest) False []

                            _ ->
                                helper rest (TextBlock line :: acc) False []
    in
    helper lines [] False []
