module Generator where

import Task exposing (Task)
import Dict exposing (Dict)
import Array exposing (Array)

type PartOfSpeech = Noun | Adjective | Verb | Adverb

type TemplatePart
    = Verbatim String
    | Number
    | Word PartOfSpeech

type alias Template = List TemplatePart

type alias Dictionary = Dict PartOfSpeech (Array String)

generate : Dictionary -> Template -> Task String String
generate _ _ =
  Task.fail "error"
