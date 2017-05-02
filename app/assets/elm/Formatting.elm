port module Formatting exposing (NoteMarkup, format, results)


type alias NoteSource =
    String


type alias NoteMarkup =
    String


port format_ : ( String, NoteSource ) -> Cmd msg


port results_ : (( String, NoteMarkup ) -> msg) -> Sub msg


format : String -> NoteSource -> Cmd msg
format path source =
    format_ ( path, source )


results : (String -> NoteMarkup -> msg) -> Sub msg
results tagger =
    results_ (\( s1, s2 ) -> tagger s1 s2)
