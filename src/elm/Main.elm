module Pwdgen where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Effects exposing (Effects)
import Signal exposing (Signal, Address)
import Task
import StartApp

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

initModel : Model
initModel =
  { passwordTemplateInput = Nothing
  , generatorDictionary = NotReady NotStarted
  , generatorOutput = NotReady NotStarted
  }

init : (Model, Effects Action)
init = (initModel, Effects.none)

type Action
  = PasswordTemplateInput String
  | DictionaryUpdated (Future Generator.Dictionary)
  | GenerationFinished (Result String String)
  | GenerateButtonPressed

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

view : Address Action -> Model -> Html
view address model =
  text "Hello."

app : StartApp.App Model
app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = []
    }

main : Signal Html
main = app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks
