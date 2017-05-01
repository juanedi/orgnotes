module Api exposing (Path, Entry(..), listDirectory, fetchFile)

import Http
import Json.Decode as Decode exposing (field, list, dict, int, float, string, nullable)


type alias Path =
    String


type Entry
    = File EntryMetadata
    | Folder EntryMetadata


type alias EntryMetadata =
    { name : String
    , pathLower : String
    , pathDisplay : String
    }


type alias RawEntry =
    { tag : String
    , name : String
    , pathLower : String
    , pathDisplay : String
    }


listDirectory : (Http.Error -> msg) -> (List Entry -> msg) -> String -> Cmd msg
listDirectory errorTagger okTagger path =
    let
        decoder =
            Decode.list entryDecoder
    in
        Http.get ("/api/dropbox" ++ path ++ "?cmd=ls") decoder
            |> send errorTagger okTagger


fetchFile : (Http.Error -> msg) -> (String -> msg) -> String -> Cmd msg
fetchFile errorTagger okTagger path =
    Http.getString ("/api/dropbox" ++ path ++ "?cmd=cat")
        |> send errorTagger okTagger


entryDecoder =
    let
        rawEntryDecoder =
            Decode.map4 RawEntry
                (field ".tag" string)
                (field "name" string)
                (field "path_lower" string)
                (field "path_display" string)

        toEntry { tag, name, pathLower, pathDisplay } =
            if tag == "folder" then
                Folder { name = name, pathLower = pathLower, pathDisplay = pathDisplay }
            else
                File { name = name, pathLower = pathLower, pathDisplay = pathDisplay }
    in
        Decode.map toEntry rawEntryDecoder


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
