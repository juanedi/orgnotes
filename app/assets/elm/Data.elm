module Data exposing (..)

import Json.Decode as Decode exposing (dict, field, float, int, list, nullable, string)
import Path exposing (Path)


type Resource
    = NoteResource Note
    | DirectoryResource Directory


type alias Note =
    { path : Path
    , content : String
    }


type alias Directory =
    { path : Path
    , entries : List Entry
    }


type alias Entry =
    { type_ : EntryType
    , name : String
    , pathLower : String
    , pathDisplay : String
    }


type EntryType
    = NoteEntry
    | DirectoryEntry


path : Resource -> Path
path resource =
    -- TODO: maybe move "path" to top level field and nest the rest?
    case resource of
        NoteResource note ->
            note.path

        DirectoryResource directory ->
            directory.path


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
        Decode.map2 Note
            (field "path" Path.decode)
            (field "content" string)


directoryDecoder : Decode.Decoder Resource
directoryDecoder =
    Decode.map DirectoryResource
        (Decode.map2 Directory
            (field "path" Path.decode)
            (field "entries" (Decode.list entryDecoder))
        )


entryDecoder : Decode.Decoder Entry
entryDecoder =
    Decode.map4 Entry
        (field "kind" entryTypeDecoder)
        (field "name" string)
        (field "path_lower" string)
        (field "path_display" string)


entryTypeDecoder : Decode.Decoder EntryType
entryTypeDecoder =
    -- TODO: make this consistent with resource type
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
