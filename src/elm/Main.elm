module Pwdgen where

import Effects exposing (Effects)
import Signal exposing (Signal, Address)
import Task exposing (Task)
import StartApp
import Html exposing (Html)

import Generator
import TemplateParser
import View
import Model exposing (..)

initModel : Model
initModel =
  { passwordTemplateInput = Nothing
  , generatorDictionary = Nothing
  , generatorOutput = NotStarted
  }

initAction : (Model, Effects Action)
initAction = (initModel, Effects.none)

update : Action -> Model -> (Model, Effects Action)
update action model =
  let
    loadDictionary () = Task.fail "dummy!"

    generate dictionary =
      model.passwordTemplateInput
      |> Maybe.map Ok |> Maybe.withDefault (Err "Password template is empty")
      |> (flip Result.andThen) TemplateParser.parse
      |> Task.fromResult
      |> (flip Task.andThen) (\template ->
        Generator.generate dictionary template)

  in
    case action of
      PasswordTemplateInput newPasswordTemplate ->
        ({ model | passwordTemplateInput = Just newPasswordTemplate }, Effects.none)

      GenerateButtonClicked ->
        case model.generatorOutput of
          NotStarted ->
            case model.generatorDictionary of
              Just dictionary ->
                ( { model | generatorOutput = Generating }
                , generate dictionary
                  |> Task.toResult
                  |> Task.map GenerationFinished
                  |> Effects.task
                )

              Nothing ->
                ( { model | generatorOutput = LoadingDictionary 0 }
                , loadDictionary ()
                  |> Task.toResult
                  |> Task.map (\result ->
                    case result of
                      Ok d -> DictionaryLoadingFinished d
                      Err err -> GenerationFinished (Err err))
                  |> Effects.task
                )

          _ -> (model, Effects.none)

      DictionaryLoadingFinished result ->
        { model | generatorDictionary = Just result }
        |> update GenerateButtonClicked

      GenerationFinished result ->
        ({ model | generatorOutput = Finished result }, Effects.none)

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
