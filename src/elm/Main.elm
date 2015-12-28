module Pwdgen where

import Effects exposing (Effects)
import Signal exposing (Signal, Address)
import Task exposing (Task)
import StartApp
import Html exposing (Html)

import Generator
import View
import Model exposing (..)

initModel : Model
initModel =
  { passwordTemplateInput = Nothing
  , generatorDictionary = NotReady NotStarted
  , generatorOutput = NotReady NotStarted
  }

initAction : (Model, Effects Action)
initAction = (initModel, Effects.none)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    PasswordTemplateInput newPasswordTemplate ->
      ({ model | passwordTemplateInput = Just newPasswordTemplate }, Effects.none)

    DictionaryUpdated newState ->
      ({ model | generatorDictionary = newState }, Effects.none)

    GenerationFinished result ->
      ({ model | generatorOutput = Ready result }, Effects.none)

    GenerateButtonPressed ->
      ( { model | generatorOutput = NotReady (InProgress Nothing) }
      , Task.fail "dummy"
        |> Task.toResult
        |> Task.map (GenerationFinished)
        |> Effects.task)

app : StartApp.App Model
app =
  StartApp.start
    { init = initAction
    , update = update
    , view = View.view
    , inputs = []
    }

main : Signal Html
main = app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks
