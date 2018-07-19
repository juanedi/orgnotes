module Data exposing (..)


type Resource
    = NoteResource Note
    | DirectoryResource (List Entry)


type alias Note =
    { path : String
    , content : String
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
