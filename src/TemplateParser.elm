module TemplateParser where

import Generator exposing (..)
import Blueshift exposing (..)
import String

inCurlyBraces : Parser a -> Parser a
inCurlyBraces p =
    -- char '{' `annotate` "a '{'"
    -- `andThen` \_ ->
    --     many (inCurlyBraces `or` (String.fromChar `map` notAnyOf "{}"))
    -- `andThen` \r -> char '}' `annotate` "a '}'"
    -- `combine` (String.concat `map` succeed r)

    char '{' `annotate` "a '{'"
    `andThen` \_ -> p
    `andThen` \r -> char '}' `annotate` "a '}'"
    `combine` (succeed r)

    -- char '{' `annotate` "a '{'"
    -- `andThen` \_ -> many (notChar '}')
    -- `andThen` \r -> char '}' `annotate` "a '}'"
    -- `combine` (String.fromList `map` succeed r)

partOfSpeech : Parser PartOfSpeech
partOfSpeech =
    (string "noun" `combine` (succeed Noun))
    `or` (string "adj" `combine` (succeed Adjective))
    `or` (string "verb" `combine` (succeed Verb))
    `or` (string "adv" `combine` (succeed Adverb))
    `annotate` "a part of speech"

word : Parser TemplatePart
word = Word `map` (inCurlyBraces partOfSpeech)

number : Parser TemplatePart
number = (always Number) `map` (string "\\d")

verbatimString : Parser TemplatePart
verbatimString =
    (List.map String.fromChar >> String.concat >> Verbatim)
    `map` some (notChar '{')

templatePart : Parser TemplatePart
templatePart =
    word
    `or` number
    `or` verbatimString

template : Parser Template
template =
    many templatePart
    `andThen` \r -> end
    `andThen` \_ -> succeed r
