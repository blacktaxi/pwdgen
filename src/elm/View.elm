module View where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Effects exposing (Effects)
import Signal exposing (Signal, Address)

import Model exposing (..)

view : Address Action -> Model -> Html
view address model =
  text "Hello."
