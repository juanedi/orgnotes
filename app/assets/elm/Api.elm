module Api exposing (fetchResource)

import Data exposing (Entry, EntryType(..), Resource(..))
import Http
import Json.Decode as Decode exposing (dict, field, float, int, list, nullable, string)


fetchResource : (Http.Error -> msg) -> (Resource -> msg) -> Maybe EntryType -> String -> Cmd msg
fetchResource errorTagger okTagger typeHint path =
    let
        headers =
            case typeHint of
                Nothing ->
                    []

                Just NoteEntry ->
                    [ Http.header "ORGNOTES_ENTRY_TYPE" "file" ]

                Just DirectoryEntry ->
                    [ Http.header "ORGNOTES_ENTRY_TYPE" "directory" ]
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = "/api/dropbox" ++ path
        , body = Http.emptyBody
        , expect = Http.expectJson resourceDecoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> send errorTagger okTagger


resourceDecoder : Decode.Decoder Resource
resourceDecoder =
    Decode.andThen
        (\entryType ->
            case entryType of
                "note" ->
                    noteDecoder

                "directory" ->
                    directoryDecoder

                _ ->
                    Decode.fail ("Unexpected resource type: " ++ entryType)
        )
        (field "type" string)


noteDecoder : Decode.Decoder Resource
noteDecoder =
    Decode.map NoteResource <|
        Decode.map2 Data.Note
            (field "path" string)
            (field "content" string)


directoryDecoder : Decode.Decoder Resource
directoryDecoder =
    Decode.map DirectoryResource (field "entries" (Decode.list entryDecoder))


entryDecoder : Decode.Decoder Entry
entryDecoder =
    Decode.map4 Entry
        (field "kind" resourceTypeDecoder)
        (field "name" string)
        (field "path_lower" string)
        (field "path_display" string)


resourceTypeDecoder : Decode.Decoder EntryType
resourceTypeDecoder =
    Decode.andThen
        (\typeLabel ->
            case typeLabel of
                "folder" ->
                    Decode.succeed DirectoryEntry

                "file" ->
                    Decode.succeed NoteEntry

                _ ->
                    Decode.fail ("Unexpected entry type: " ++ typeLabel)
        )
        string


send : (Http.Error -> msg) -> (a -> msg) -> Http.Request a -> Cmd msg
send errorTagger okTagger request =
    Http.send (unpackResult errorTagger okTagger) request


unpackResult : (x -> r) -> (a -> r) -> Result x a -> r
unpackResult onError onSuccess result =
    case result of
        Ok x ->
            onSuccess x

        Err y ->
            onError y
