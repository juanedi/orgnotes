port module Formatting exposing (NoteMarkup, format, results)


type alias NoteSource =
    String


type alias NoteMarkup =
    String


port format : ( String, NoteSource ) -> Cmd msg


port render : NoteMarkup -> Cmd msg


port results : (( String, NoteMarkup ) -> msg) -> Sub msg
