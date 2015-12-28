module Pwdgen where

import Effects exposing (Effects)
import Signal exposing (Signal, Address)
import Task exposing (Task)
import StartApp
import Html exposing (Html)
import Http
import Json.Decode as J

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
    loadDictionary () =
      let
        decodeField name = (J.at [ name ] (J.array J.string))

        decodeDict =
          J.object4 Generator.Dictionary
            (decodeField "nouns")
            (decodeField "adjectives")
            (decodeField "verbs")
            (decodeField "adverbs")

      in
        Http.get decodeDict "/dictionary.json"
        |> Task.mapError toString

    generate dictionary =
      model.passwordTemplateInput
      |> Maybe.map Ok |> Maybe.withDefault (Err "Password template is empty")
      |> (flip Result.andThen)
        (TemplateParser.parse
          >> Result.formatError ((++) "Could not parse password template: "))
      |> Task.fromResult
      |> (flip Task.andThen) (\template ->
        Generator.generate dictionary template)

  in
    case action of
      PasswordTemplateInput newPasswordTemplate ->
        ({ model | passwordTemplateInput = Just newPasswordTemplate }, Effects.none)

      GenerateButtonClicked ->
        let
          work () =
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

        in
          case model.generatorOutput of
            NotStarted -> work ()
            Finished _ -> work ()

            _ -> (model, Effects.none)

      DictionaryLoadingFinished result ->
        { model |
            generatorDictionary = Just result
          , generatorOutput = NotStarted
        }
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
