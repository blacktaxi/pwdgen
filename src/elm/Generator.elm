module Generator where

import Task exposing (Task)
import Dict exposing (Dict)
import Array exposing (Array)

import SecureRandom

type PartOfSpeech = Noun | Adjective | Verb | Adverb

type TemplatePart
    = Verbatim String
    | Number
    | Word PartOfSpeech

type alias Template = List TemplatePart

type alias Dictionary =
  { nouns : Array String
  , adjectives : Array String
  , verbs : Array String
  , adverbs : Array String
  }

generate : Dictionary -> Template -> Task String String
generate dictionary template =
  (SecureRandom.int 0 10 |> Task.mapError toString)
  `Task.andThen` \x ->
    Task.succeed <| "hohooo: " ++ (toString x)
