module Data exposing (..)

import Json.Decode as Decode exposing (dict, field, float, int, list, nullable, string)
import Json.Encode as Encode


type Resource
    = NoteResource Note
    | DirectoryResource Directory


type alias Note =
    { path : String
    , content : String
    }


type alias Directory =
    { path : String
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


path : Resource -> String
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
            (field "path" string)
            (field "content" string)


directoryDecoder : Decode.Decoder Resource
directoryDecoder =
    Decode.map DirectoryResource
        (Decode.map2 Directory
            (field "path" Decode.string)
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


encodeResource : Resource -> Encode.Value
encodeResource resource =
    case resource of
        NoteResource note ->
            encodeNote note

        DirectoryResource entries ->
            encodeDirectory entries


encodeNote : Note -> Encode.Value
encodeNote note =
    Encode.object
        [ ( "type", Encode.string "note" )
        , ( "path", Encode.string note.path )
        , ( "content", Encode.string note.path )
        ]


encodeDirectory : Directory -> Encode.Value
encodeDirectory directory =
    Encode.object
        [ ( "type", Encode.string "directory" )
        , ( "path", Encode.string directory.path )
        , ( "entries", Encode.list (List.map encodeEntry directory.entries) )
        ]


encodeEntry : Entry -> Encode.Value
encodeEntry entry =
    Encode.object
        [ ( "kind"
          , Encode.string
                (case entry.type_ of
                    NoteEntry ->
                        "file"

                    DirectoryEntry ->
                        "folder"
                )
          )
        , ( "name", Encode.string entry.name )
        , ( "path_lower", Encode.string entry.pathLower )
        , ( "path_display", Encode.string entry.pathDisplay )
        ]
