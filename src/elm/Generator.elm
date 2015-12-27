module Generator where

-- import String

type PartOfSpeech = Noun | Adjective | Verb | Adverb

type TemplatePart
    = Verbatim String
    | Number
    | Word PartOfSpeech

type alias Template = List TemplatePart

