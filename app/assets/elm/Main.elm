module Main exposing (..)

import Api
import Content exposing (Content)
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
    ( { content = Content.init location.pathname
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
                , content = Content.setLoading path model.content
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
            ( { model | content = Content.updateFromServer resource model.content }
            , Cmd.batch (Port.send (Store resource) :: renderingEffects resource)
            )

        LocalFetchDone resource ->
            ( { model | content = Content.updateFromCache resource model.content }
            , Cmd.batch (renderingEffects resource)
            )

        RemoteFetchFailed ->
            ( { model
                | content = Content.cancelLoading model.content
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
