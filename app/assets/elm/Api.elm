module Api exposing (fetchResource)

import Data exposing (EntryType(..), Resource(..))
import Http
import Json.Decode as Decode


fetchResource : (Http.Error -> msg) -> (Decode.Value -> msg) -> Maybe EntryType -> String -> Cmd msg
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
        , expect = Http.expectJson Decode.value
        , timeout = Nothing
        , withCredentials = False
        }
        |> send errorTagger okTagger


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
