module CSV where

import Blueshift exposing (..)
import String

{- A CSV file contains 0 or more lines, each of which is terminated
   by the end-of-line character (eol). -}
csvFile : Parser (List (List String))
csvFile =
    many line
    `andThen` \r -> end
    `andThen` \_ -> succeed r

-- Each line contains 1 or more cells, separated by a comma
line : Parser (List String)
line =
    cells
    `andThen` \r -> eol
    `andThen` \_ -> succeed r

-- Build up a list of cells.  Try to parse the first cell, then figure out
-- what ends the cell.
cells : Parser (List String)
cells =
    cellContent `andThen` \first ->
    remainingCells `andThen` \next ->
    succeed (first :: next)

-- The cell either ends with a comma, indicating that 1 or more cells follow,
-- or it doesn't, indicating that we're at the end of the cells for this line
remainingCells : Parser (List String)
remainingCells =
    (char ',' `followedBy` cells)            -- Found comma?  More cells coming
    `or` (succeed [])                -- No comma?  Return [], no more cells

-- Each cell contains 0 or more characters, which must not be a comma or
-- EOL
cellContent : Parser String
cellContent =
    String.fromList `map` many (notAnyOf ",\n")

-- The end of line character is \n
eol : Parser Char
eol = char '\n'

parseCSV : String -> Result String (List (List String))
parseCSV input = parse csvFile input


-- @TODO
--     parsec:
--         ghci> parseCSV "hi"
--         Left "(unknown)" (line 1, column 3):
--         unexpected end of input
--         expecting "," or "\n"
--
--     this thing:
--         > CSV.parseCSV "hi"
--         Err ("expected end of input at or near 'hi'")
--             : Result.Result String (List (List String))
