module Main exposing (..)

import Api
import Data exposing (Entry, EntryType(..), Resource(..))
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed
import Navigation
import Port exposing (Request(..))


type alias Path =
    String


type alias Model =
    { content : DisplayModel
    , typeHint : Maybe EntryType
    , errorState : ErrorState
    }


type ErrorState
    = Clear
    | OnError String
    | PermanentDismiss


type DisplayModel
    = Initializing String
    | Displaying (Cacheable Resource)
    | LoadingOther (Cacheable Resource)


type Cacheable r
    = Cached r
    | Fetched r


type Msg
    = UrlChange Path
    | Navigate Entry
    | NavigateBack
    | DismissError
    | PermanentDismissError
    | RemoteFetchDone Resource
    | RemoteFetchFailed
    | LocalFetchFailed
    | LocalFetchDone Resource


main : Program Never Model Msg
main =
    Navigation.program
        (.pathname >> UrlChange)
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
    ( { content = Initializing location.pathname
      , typeHint = Nothing
      , errorState = Clear
      }
    , fetchResource Nothing location.pathname
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange path ->
            ( { model
                | typeHint = Nothing
                , content = setLoading model.content
              }
            , fetchResource model.typeHint path
            )

        Navigate metadata ->
            ( { model | typeHint = Just metadata.type_ }
            , Navigation.newUrl metadata.pathLower
            )

        NavigateBack ->
            ( { model | typeHint = Just DirectoryEntry }
            , Navigation.back 1
            )

        DismissError ->
            ( { model | errorState = Clear }, Cmd.none )

        PermanentDismissError ->
            ( { model | errorState = PermanentDismiss }, Cmd.none )

        RemoteFetchDone resource ->
            ( { model
                | content = Displaying (Fetched resource)
              }
            , Cmd.batch (Port.send (Store resource) :: renderingEffects resource)
            )

        LocalFetchDone resource ->
            ( { model
                | content =
                    case model.content of
                        Initializing _ ->
                            Displaying (Cached resource)

                        LoadingOther _ ->
                            Displaying (Cached resource)

                        Displaying (Fetched _) ->
                            -- cache took longer than the real thing. the world is a strange place.
                            model.content

                        Displaying (Cached _) ->
                            -- NOTE: could this happen?
                            model.content
              }
            , Cmd.none
            )

        RemoteFetchFailed ->
            ( { model
                | content = cancelLoading model.content
                , errorState =
                    case model.errorState of
                        PermanentDismiss ->
                            PermanentDismiss

                        _ ->
                            OnError "Couldn't fetch the entry"
              }
            , Cmd.none
            )

        LocalFetchFailed ->
            ( model, Cmd.none )


current : Cacheable a -> a
current cacheable =
    case cacheable of
        Cached a ->
            a

        Fetched a ->
            a


renderingEffects : Resource -> List (Cmd Msg)
renderingEffects resource =
    case resource of
        Data.NoteResource note ->
            [ Port.send (Render note.content) ]

        Data.DirectoryResource _ ->
            []


setLoading : DisplayModel -> DisplayModel
setLoading model =
    case model of
        Initializing _ ->
            model

        Displaying resource ->
            LoadingOther resource

        LoadingOther resource ->
            model


cancelLoading : DisplayModel -> DisplayModel
cancelLoading model =
    case model of
        Initializing _ ->
            model

        Displaying resource ->
            model

        LoadingOther resource ->
            Displaying resource


isLoading : DisplayModel -> Bool
isLoading model =
    case model of
        Initializing _ ->
            True

        Displaying resource ->
            False

        LoadingOther resource ->
            True


currentPath : DisplayModel -> String
currentPath model =
    case model of
        Initializing path ->
            path

        Displaying resource ->
            Data.path (current resource)

        LoadingOther resource ->
            Data.path (current resource)


fetchResource : Maybe EntryType -> String -> Cmd Msg
fetchResource typeHint path =
    Cmd.batch
        [ Api.fetchResource (always RemoteFetchFailed) RemoteFetchDone typeHint path
        , Port.send (Fetch path)
        ]


view : Model -> Html Msg
view model =
    H.div []
        [ viewNav (currentPath model.content)
        , viewProgressIndicator (isLoading model.content)
        , viewErrorMessage model.errorState
        , viewContent model.content
        ]


viewNav : Path -> Html Msg
viewNav path =
    let
        navButton =
            case path of
                "/" ->
                    H.i [ HA.class "material-icons" ] [ H.text "folder" ]

                _ ->
                    H.i [ HE.onClick NavigateBack, HA.class "material-icons" ] [ H.text "arrow_back" ]
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
                [ H.text path ]
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


viewContent : DisplayModel -> Html Msg
viewContent content =
    Html.Keyed.node "div" [] <|
        case content of
            Initializing _ ->
                []

            Displaying resource ->
                viewResource (current resource)

            LoadingOther resource ->
                viewResource (current resource)


viewResource : Resource -> List ( String, Html Msg )
viewResource resource =
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
        [ HA.class "collection-item"
        , HE.onClick (Navigate entry)
        ]
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
