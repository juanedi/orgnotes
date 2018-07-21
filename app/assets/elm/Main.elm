module Main exposing (..)

import Api
import Content exposing (Content)
import Data exposing (Entry, EntryType(..), Resource(..))
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed
import Json.Decode as Decode
import Navigation
import Path exposing (Path)
import Port exposing (Request(..))


type alias Model =
    { content : Content
    , typeHint : Maybe EntryType
    , errorState : ErrorState
    }


type ErrorState
    = Clear
    | OnError String
    | PermanentDismiss


type Msg
    = UrlChange Path
    | Navigate (Maybe EntryType) Path
    | DismissError
    | PermanentDismissError
    | RemoteFetchDone Decode.Value
    | RemoteFetchFailed
    | LocalFetchFailed
    | LocalFetchDone Decode.Value


main : Program Never Model Msg
main =
    Navigation.program
        (.pathname >> Path.fromString >> UrlChange)
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Port.responses
        (\response ->
            case response of
                Port.FetchDone resource ->
                    LocalFetchDone resource

                Port.FetchFailed ->
                    LocalFetchFailed
        )


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        path =
            Path.fromString location.pathname
    in
    ( { content = Content.init path
      , typeHint = Nothing
      , errorState = Clear
      }
    , fetchResource Nothing path
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange path ->
            ( { model
                | typeHint = Nothing
                , content = Content.setLoading path model.content
              }
            , fetchResource model.typeHint path
            )

        Navigate typeHint path ->
            ( { model | typeHint = typeHint }
            , Navigation.newUrl (Path.toString path)
            )

        DismissError ->
            ( { model | errorState = Clear }, Cmd.none )

        PermanentDismissError ->
            ( { model | errorState = PermanentDismiss }, Cmd.none )

        RemoteFetchDone value ->
            case decodeResource value of
                Ok resource ->
                    ( { model | content = Content.updateFromServer resource model.content }
                    , Cmd.batch (Port.send (Store value) :: renderingEffects resource)
                    )

                Err _ ->
                    ( userError model, Cmd.none )

        LocalFetchDone value ->
            case decodeResource value of
                Ok resource ->
                    ( { model | content = Content.updateFromCache resource model.content }
                    , Cmd.batch (renderingEffects resource)
                    )

                Err _ ->
                    ( model, Cmd.none )

        RemoteFetchFailed ->
            ( userError model, Cmd.none )

        LocalFetchFailed ->
            ( model, Cmd.none )


decodeResource : Decode.Value -> Result String Resource
decodeResource =
    Decode.decodeValue Data.resourceDecoder


userError : Model -> Model
userError model =
    { model
        | content = Content.cancelLoading model.content
        , errorState =
            case model.errorState of
                PermanentDismiss ->
                    PermanentDismiss

                _ ->
                    OnError "Couldn't fetch the entry"
    }


renderingEffects : Resource -> List (Cmd Msg)
renderingEffects resource =
    case resource of
        Data.NoteResource note ->
            [ Port.send (Render note.content) ]

        Data.DirectoryResource _ ->
            []


fetchResource : Maybe EntryType -> Path -> Cmd Msg
fetchResource typeHint path =
    Cmd.batch
        [ Api.fetchResource (always RemoteFetchFailed) RemoteFetchDone typeHint path
        , Port.send (Fetch path)
        ]


view : Model -> Html Msg
view model =
    H.div []
        [ viewNav (Content.currentPath model.content)
        , viewProgressIndicator (Content.isLoading model.content)
        , viewErrorMessage model.errorState
        , model.content
            |> Content.current
            |> Maybe.map viewResource
            |> Maybe.withDefault (H.text "")
        ]


viewNav : Path -> Html Msg
viewNav path =
    let
        navButton =
            case Path.parent path of
                Nothing ->
                    H.i [ HA.class "material-icons" ] [ H.text "folder" ]

                Just parentPath ->
                    H.a
                        (spaLink
                            (Path.toString parentPath)
                            (Navigate (Just DirectoryEntry) parentPath)
                        )
                        [ H.i
                            [ HA.class "material-icons"
                            ]
                            [ H.text "arrow_back" ]
                        ]
    in
    H.nav
        [ HA.class "blue-grey" ]
        [ H.div
            [ HA.class "nav-wrapper" ]
            [ H.div
                [ HA.class "nav-button left" ]
                [ navButton ]
            , H.span
                [ HA.class "nav-path" ]
                [ H.text (Path.toString path) ]
            ]
        ]


viewProgressIndicator : Bool -> Html Msg
viewProgressIndicator loading =
    if loading then
        H.div
            [ HA.id "app-progress", HA.class "progress" ]
            [ H.div [ HA.class "indeterminate" ] [] ]
    else
        H.div
            [ HA.id "app-progress" ]
            []


viewResource : Resource -> Html Msg
viewResource resource =
    Html.Keyed.node "div" [] <|
        case resource of
            NoteResource note ->
                [ ( "note-content" ++ toString note.path
                  , H.div [ HA.id "note-content" ] []
                  )
                ]

            DirectoryResource directory ->
                [ ( "directory-content"
                  , viewDirectory directory
                  )
                ]


viewErrorMessage : ErrorState -> Html Msg
viewErrorMessage errorState =
    case errorState of
        OnError msg ->
            H.div
                [ HA.id "error-message"
                , HA.class "card blue-grey darken-1"
                ]
                [ H.div
                    [ HA.class "card-content white-text" ]
                    -- TODO: if viewing a cached version, show a better error message
                    [ H.span [ HA.class "card-title" ] [ H.text msg ]
                    , H.p [] [ H.text "Sorry about that. Maybe reloading helps :-(" ]
                    ]
                , H.div
                    [ HA.class "card-action" ]
                    [ H.a [ HA.attribute "onClick" "event.preventDefault(); window.location.reload(true)" ] [ H.text "Reload" ]
                    , H.a [ HE.onClick DismissError ] [ H.text "Hide" ]
                    , H.a [ HE.onClick PermanentDismissError ] [ H.text "Dismiss permanently" ]
                    ]
                ]

        Clear ->
            H.div [] []

        PermanentDismiss ->
            H.div [] []


viewDirectory : Data.Directory -> Html Msg
viewDirectory directory =
    if List.isEmpty directory.entries then
        H.div
            [ HA.class "empty-directory valign-wrapper center-align" ]
            [ H.div
                [ HA.class "center-align" ]
                [ H.p [ HA.class "shrug" ] [ H.text "¯\\_(ツ)_/¯" ]
                , H.p [] [ H.text "Nothing here!" ]
                ]
            ]
    else
        H.div
            [ HA.id "directory-entries"
            , HA.class "collection"
            ]
            (List.map viewEntry directory.entries)


viewEntry : Entry -> Html Msg
viewEntry entry =
    H.a
        (HA.class "collection-item"
            :: spaLink
                entry.pathLower
                (Navigate (Just entry.type_) (Path.fromString entry.pathLower))
        )
        [ H.i [ HA.class "material-icons" ]
            [ H.text <|
                case entry.type_ of
                    DirectoryEntry ->
                        "folder"

                    NoteEntry ->
                        "insert_drive_file"
            ]
        , H.text entry.name
        ]


spaLink : String -> msg -> List (H.Attribute msg)
spaLink href onClickMsg =
    let
        isSpecialClick : Decode.Decoder Bool
        isSpecialClick =
            Decode.map2
                (\isCtrl isMeta -> isCtrl || isMeta)
                (Decode.field "ctrlKey" Decode.bool)
                (Decode.field "metaKey" Decode.bool)

        succeedIfFalse : a -> Bool -> Decode.Decoder a
        succeedIfFalse msg preventDefault =
            case preventDefault of
                False ->
                    Decode.succeed msg

                True ->
                    Decode.fail "succeedIfFalse: condition was True"
    in
    [ HE.onWithOptions "click"
        { stopPropagation = False
        , preventDefault = True
        }
        (isSpecialClick
            |> Decode.andThen (succeedIfFalse onClickMsg)
        )
    , HA.href href
    ]
