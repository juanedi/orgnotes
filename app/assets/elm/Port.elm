port module Port exposing (Request(..), send)

import Json.Encode as Encode


type Request
    = Render String
    | Store String String
    | Fetch String


port sendRequest : Encode.Value -> Cmd msg


send : Request -> Cmd msg
send =
    encodeRequest >> sendRequest


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
                , ( "path", Encode.string path )
                , ( "path", Encode.string contents )
                ]

        Fetch path ->
            Encode.object
                [ ( "type", Encode.string "fetch" )
                , ( "path", Encode.string path )
                ]
