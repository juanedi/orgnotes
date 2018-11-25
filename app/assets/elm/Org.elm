module Org exposing (Org, decode, view)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Json.Decode as Decode exposing (Decoder)
import Path exposing (Path)


type Org
    = Org String


decode : Decoder Org
decode =
    Decode.map Org Decode.string


view : List (Attribute msg) -> Org -> Html msg
view attrs (Org source) =
    Html.node "org-note"
        (Attr.attribute "value" source :: attrs)
        []
