module Blueshift where

import String

type Parser a = Parser (String -> Result String (a, String))

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

-- (<$>) : (a -> b) -> Parser a -> Parser b
-- (<$>) = map

andThen : Parser a -> (a -> Parser b) -> Parser b
andThen p f = Parser <| \inp ->
    case runParser p inp of
        Ok (x, more) -> runParser (f x) more
        Err err -> Err err

-- (>>=) : (a -> Parser b) -> Parser a -> Parser b
-- (>>=) = andThen

combine : Parser a -> Parser b -> Parser b
combine q w = q `andThen` (always w)

-- (>>) : Parser a -> Parser b -> Parser b
-- (>>) = combine

or : Parser a -> Parser a -> Parser a
or q w = Parser <| \inp ->
    case runParser q inp of
        Ok _ as ok -> ok
        Err _ -> runParser w inp

apply : Parser (a -> b) -> Parser a -> Parser b
apply a p = a `andThen` \f -> p `andThen` \a -> succeed (f a)

end : Parser ()
end = Parser <| \inp ->
    case inp of
        "" -> Ok ((), "")
        _ -> Err "expected end of input"

anyChar : Parser Char
anyChar = Parser <| \inp ->
    case String.uncons inp of
        Just (c, tail) -> Ok (c, tail)
        Nothing -> Err "expected any character, instead got empty input"

satisfy : (Char -> Bool) -> Parser Char
satisfy pred =
    anyChar `andThen` \c ->
        if pred c
            then succeed c
            else fail ("no sat for " ++ String.fromChar c)

char : Char -> Parser Char
char c = satisfy ((==) c)

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
        Err _ -> Err ("expected " ++ label ++ " at or near " ++ (String.left 5 inp) ++ "...")

string : String -> Parser String
string s =
    let p = Parser <| \inp ->
        if String.left (String.length s) inp == s
            then Ok (s, String.dropLeft (String.length s) inp)
            else Err ""
    in p `annotate` ("'" ++ s ++ "'")

anyOf : String -> Parser Char
anyOf s = satisfy (\x -> String.fromChar x `String.contains` s)

notAnyOf : String -> Parser Char
notAnyOf s = satisfy (\x -> not <| String.fromChar x `String.contains` s)






