port module Port exposing (Request(..), Response(..), responses, send)

import Data exposing (Resource(..))
import Json.Decode as Decode
import Json.Encode as Encode


port toJs : Encode.Value -> Cmd msg


port fromJs : (Encode.Value -> msg) -> Sub msg


type Request
    = Render String
    | Store Decode.Value
    | Fetch String


type Response
    = FetchDone Decode.Value
    | FetchFailed


send : Request -> Cmd msg
send =
    encodeRequest >> toJs


responses : (Response -> msg) -> Sub msg
responses toMsg =
    fromJs (toMsg << FetchDone)


encodeRequest : Request -> Encode.Value
encodeRequest request =
    case request of
        Render contents ->
            Encode.object
                [ ( "type", Encode.string "render" )
                , ( "content", Encode.string contents )
                ]

        Store resource ->
            Encode.object
                [ ( "type", Encode.string "store" )
                , ( "resource", resource )
                ]

        Fetch path ->
            Encode.object
                [ ( "type", Encode.string "fetch" )
                , ( "path", Encode.string path )
                ]
