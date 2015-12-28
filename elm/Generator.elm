module Generator where

import Task exposing (Task)
import Dict exposing (Dict)
import Array exposing (Array)
import String

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
  let
    getPosDict pos =
      case pos of
        Noun -> .nouns
        Adjective -> .adjectives
        Verb -> .verbs
        Adverb -> .adverbs

    choose arr =
      SecureRandom.int 0 (Array.length arr)
      |> Task.mapError toString
      |> Task.map (\i ->
        Array.get i arr
        |> Maybe.withDefault "Failed to get word from dictionary")

    generateOne part =
      case part of
        Verbatim x -> Task.succeed x
        Number -> SecureRandom.int 0 9 |> Task.mapError toString |> Task.map toString
        Word pos ->
          getPosDict pos dictionary
          |> choose

  in
    template
    |> List.map generateOne
    |> Task.sequence
    |> Task.map String.concat
