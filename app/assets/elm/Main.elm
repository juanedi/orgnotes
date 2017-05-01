module Main exposing (..)

import Html exposing (Html)


type alias Model =
    ()


type alias Msg =
    ()


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }


init : ( Model, Cmd Msg )
init =
    ( (), Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    init


view : Model -> Html Msg
view model =
    Html.p [] [ Html.text "fooooooo" ]
