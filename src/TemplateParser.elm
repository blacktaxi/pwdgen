module TemplateParser where

import Generator exposing (..)
import Blueshift exposing (..)
import String

inCurlyBraces : Parser String
inCurlyBraces =
    char '{' `annotate` "a '{'"
    `andThen` \_ -> many (inCurlyBraces `or` (String.fromChar `map` notAnyOf "{}"))
    `andThen` \r -> char '}' `annotate` "a '}'"
    `combine` (String.concat `map` succeed r)


    -- char '{' `annotate` "a '{'"
    -- `andThen` \_ -> many (notChar '}')
    -- `andThen` \r -> char '}' `annotate` "a '}'"
    -- `combine` (String.fromList `map` succeed r)


-- pWordTemplate : Parser
--
-- pTemplatePart : Parser TemplatePart
-- pTemplatePart =
