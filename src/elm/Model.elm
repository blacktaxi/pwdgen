module Model where

import Generator

type ProgressStatus
  = NotStarted
  | InProgress (Maybe Int)

type Future a
  = NotReady ProgressStatus
  | Ready (Result String a)

type alias Model =
  { passwordTemplateInput : Maybe String
  , generatorDictionary : Future Generator.Dictionary
  , generatorOutput : Future String
  }

type Action
  = PasswordTemplateInput String
  | DictionaryUpdated (Future Generator.Dictionary)
  | GenerationFinished (Result String String)
  | GenerateButtonClicked
