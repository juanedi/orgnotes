module Path exposing
    ( Path
    , decode
    , encode
    , fromString
    , parent
    , toString
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Path
    = Path (List Component)


type alias Component =
    String


fromString : String -> Path
fromString str =
    str
        |> String.split "/"
        |> List.filter (not << String.isEmpty)
        |> Path


toString : Path -> String
toString (Path components) =
    "/" ++ String.join "/" components


decode : Decoder Path
decode =
    Decode.map
        fromString
        Decode.string


encode : Path -> Encode.Value
encode path =
    path
        |> toString
        |> Encode.string


parent : Path -> Maybe Path
parent (Path components) =
    case List.tail (List.reverse components) of
        Nothing ->
            Nothing

        Just reversed ->
            Just (Path (List.reverse reversed))
