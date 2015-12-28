module Model where

import Generator

type GenerationStatus
  = NotStarted
  | LoadingDictionary Int
  | Generating
  | Finished (Result String String)

type alias Model =
  { passwordTemplateInput : Maybe String
  , generatorDictionary : Maybe Generator.Dictionary
  , generatorOutput : GenerationStatus
  }

type Action
  = PasswordTemplateInput String
  | GenerateButtonClicked
  | DictionaryLoadingFinished Generator.Dictionary
  | GenerationFinished (Result String String)
