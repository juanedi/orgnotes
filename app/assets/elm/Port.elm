port module Port exposing (Request(..), Response(..), responses, send)

import Json.Decode as Decode
import Json.Encode as Encode


port toJs : Encode.Value -> Cmd msg


port fromJs : (Encode.Value -> msg) -> Sub msg


type Request
    = Render String
    | Store String String
    | Fetch String


type Response
    = FetchDone Note
    | FetchFailed


type alias Note =
    { path : String
    , content : String
    }


send : Request -> Cmd msg
send =
    encodeRequest >> toJs


responses : (Response -> msg) -> Sub msg
responses toMsg =
    fromJs
        (\value ->
            case Decode.decodeValue decodeResponse value of
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

        Store path contents ->
            Encode.object
                [ ( "type", Encode.string "store" )
                , ( "note"
                  , Encode.object
                        [ ( "path", Encode.string path )
                        , ( "content", Encode.string contents )
                        ]
                  )
                ]

        Fetch path ->
            Encode.object
                [ ( "type", Encode.string "fetch" )
                , ( "path", Encode.string path )
                ]


decodeResponse : Decode.Decoder Note
decodeResponse =
    Decode.map2 Note
        (Decode.field "path" Decode.string)
        (Decode.field "content" Decode.string)
