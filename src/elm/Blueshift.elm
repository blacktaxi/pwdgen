module Blueshift where

import String

type Parser a =
    Parser (String -> Result String (a, String))

-- type Parser a =
--     Parser (State -> Success a b -> Failure b -> Success a b -> Failure b -> Parser)

-- type alias Success a b = (a -> State -> Errors -> Parser b)
-- type alias Failure a = (Errors -> Parser a)
--
-- type alias Errors = {
--     errors : List String
-- }
--
-- type alias State = {
--     input : String,
--     position : Int
-- }

runParser : Parser a -> String -> Result String (a, String)
runParser (Parser run) inp = run inp

parse : Parser a -> String -> Result String a
parse p inp =
    case runParser p inp of
        Ok (x, _) -> Ok x
        Err err -> Err err

succeed : a -> Parser a
succeed x = Parser <| \inp -> Ok (x, inp)

fail : String -> Parser a
fail err = Parser <| \_ -> Err err

map : (a -> b) -> Parser a -> Parser b
map f p = Parser <| \inp ->
    case runParser p inp of
        Ok (x, more) -> Ok (f x, more)
        Err err -> Err err

(<$>) : (a -> b) -> Parser a -> Parser b
(<$>) = map

andThen : Parser a -> (a -> Parser b) -> Parser b
andThen p f = Parser <| \inp ->
    case runParser p inp of
        Ok (x, more) -> runParser (f x) more
        Err err -> Err err

(>>=) : (a -> Parser b) -> Parser a -> Parser b
(>>=) = flip andThen

followedBy : Parser a -> Parser b -> Parser b
followedBy p q = p `andThen` \_ -> q

combine : Parser a -> Parser b -> Parser b
combine q w = q `andThen` (always w)

or : Parser a -> Parser a -> Parser a
or q w = Parser <| \inp ->
    case runParser q inp of
        Ok _ as ok -> ok
        Err _ -> runParser w inp

-- try : Parser a -> Parser a
-- try p = Parser <| \inp ->


apply : Parser (a -> b) -> Parser a -> Parser b
apply a p = a `andThen` \f -> p `andThen` \a -> succeed (f a)

errMsgExpected : String -> String -> String
errMsgExpected label inp =
    "expected " ++ label ++ " at or near '" ++ (String.left 5 inp) ++ "'"

end : Parser ()
end = Parser <| \inp ->
    case inp of
        "" -> Ok ((), "")
        _ -> Err <| errMsgExpected "end of input" inp

anyChar : Parser Char
anyChar = Parser <| \inp ->
    case String.uncons inp of
        Just (c, tail) -> Ok (c, tail)
        Nothing -> Err <| errMsgExpected "any character" inp

satisfy : (Char -> Bool) -> Parser Char
satisfy pred =
    anyChar `andThen` \c ->
        if pred c
            then succeed c
            else fail ("no sat for " ++ String.fromChar c)

char : Char -> Parser Char
char c = satisfy ((==) c) `annotate` ("'" ++ String.fromChar c ++ "'")

notChar : Char -> Parser Char
notChar c = satisfy ((/=) c)

many : Parser a -> Parser (List a)
many p = (some p) `or` (succeed [])

some : Parser a -> Parser (List a)
some p = p `andThen` \v -> many p `andThen` \vs -> succeed (v :: vs)

annotate : Parser a -> String -> Parser a
annotate p label = Parser <| \inp ->
    case runParser p inp of
        Ok _ as ok -> ok
        Err _ -> Err <| errMsgExpected label inp

string : String -> Parser String
string s =
    let p = Parser <| \inp ->
        if String.left (String.length s) inp == s
            then Ok (s, String.dropLeft (String.length s) inp)
            else Err ""
    in p `annotate` ("'" ++ s ++ "'")

-- anyString : Parser String
-- anyString = Parser <| \inp ->

anyOf : String -> Parser Char
anyOf s = satisfy (\x -> String.fromChar x `String.contains` s)

-- @TODO called `noneOf` in parsec
notAnyOf : String -> Parser Char
notAnyOf s = satisfy (\x -> not <| String.fromChar x `String.contains` s)






