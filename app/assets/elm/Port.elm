port module Port exposing (Request(..), Response(..), responses, send)

import Data exposing (Note)
import Json.Decode as Decode
import Json.Encode as Encode


port toJs : Encode.Value -> Cmd msg


port fromJs : (Encode.Value -> msg) -> Sub msg


type Request
    = Render String
    | Store Note
    | Fetch String


type Response
    = FetchDone Note
    | FetchFailed


send : Request -> Cmd msg
send =
    encodeRequest >> toJs


responses : (Response -> msg) -> Sub msg
responses toMsg =
    fromJs
        (\value ->
            case Decode.decodeValue decodeNote value of
                Ok note ->
                    toMsg (FetchDone note)

                Err _ ->
                    toMsg FetchFailed
        )


encodeRequest : Request -> Encode.Value
encodeRequest request =
    case request of
        Render contents ->
            Encode.object
                [ ( "type", Encode.string "render" )
                , ( "content", Encode.string contents )
                ]

        Store note ->
            Encode.object
                [ ( "type", Encode.string "store" )
                , ( "note", encodeNote note )
                ]

        Fetch path ->
            Encode.object
                [ ( "type", Encode.string "fetch" )
                , ( "path", Encode.string path )
                ]


encodeNote : Note -> Encode.Value
encodeNote note =
    Encode.object
        [ ( "path", Encode.string note.path )
        , ( "content", Encode.string note.path )
        ]


decodeNote : Decode.Decoder Note
decodeNote =
    Decode.map2 Note
        (Decode.field "path" Decode.string)
        (Decode.field "content" Decode.string)
