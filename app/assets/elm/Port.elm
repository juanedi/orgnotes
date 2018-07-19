port module Port exposing (Request(..), Response(..), responses, send)

import Api
import Data exposing (Resource(..))
import Json.Decode as Decode
import Json.Encode as Encode


port toJs : Encode.Value -> Cmd msg


port fromJs : (Encode.Value -> msg) -> Sub msg


type Request
    = Render String
    | Store Resource
    | Fetch String


type Response
    = FetchDone Resource
    | FetchFailed


send : Request -> Cmd msg
send =
    encodeRequest >> toJs


responses : (Response -> msg) -> Sub msg
responses toMsg =
    fromJs
        (\value ->
            case Decode.decodeValue Data.resourceDecoder value of
                Ok resource ->
                    toMsg (FetchDone resource)

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

        Store resource ->
            Encode.object
                [ ( "type", Encode.string "store" )
                , ( "resource", Data.encodeResource resource )
                ]

        Fetch path ->
            Encode.object
                [ ( "type", Encode.string "fetch" )
                , ( "path", Encode.string path )
                ]
