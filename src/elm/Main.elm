module Pwdgen where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Effects exposing (Effects)
import Signal exposing (Signal, Address)
import Task
import StartApp

type alias Model =
  {
  }

initModel : Model
initModel =
  {
  }

init : (Model, Effects Action)
init = (initModel, Effects.none)

type Action
  = NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp -> (model, Effects.none)

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
