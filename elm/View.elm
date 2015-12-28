module View where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Effects exposing (Effects)
import Signal exposing (Signal, Address)

import Model exposing (..)

view : Address Action -> Model -> Html
view addr model =
  div
    []
    [ button
        [ onClick addr GenerateButtonClicked ]
        [ text "Generate" ]
    , div
        []
        [ text <|
            case model.generatorOutput of
              NotStarted -> "click the button to start generating..."
              LoadingDictionary progress -> "Loading dictionary, " ++ (toString progress) ++ "% complete..."
              Generating -> "generating..."
              Finished (Ok x) -> x
              Finished (Err err) -> "Error: " ++ err
        ]
    , input
        [ placeholder "password template goes here"
        , on "input" targetValue (\x -> Signal.message addr (PasswordTemplateInput x))
        , value <| Maybe.withDefault "" model.passwordTemplateInput
        ]
        []
    ]
