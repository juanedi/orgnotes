module Main exposing (..)

import Api
import Data exposing (Entry, EntryType(..), Resource)
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed
import Navigation
import Port exposing (Request(..))


type alias Path =
    String


type alias Model =
    { path : Path
    , loading : Bool
    , errorMessage : Maybe String
    , content : DisplayModel
    , typeHint : Maybe EntryType
    }


type DisplayModel
    = Initializing
    | DirectoryContent Data.Directory
    | FileContent String


type Msg
    = UrlChange Path
    | Navigate Entry
    | NavigateBack
    | DismissError
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
    ( { path = location.pathname
      , loading = True
      , errorMessage = Nothing
      , content = Initializing
      , typeHint = Nothing
      }
    , fetchResource Nothing location.pathname
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange path ->
            ( { model
                | loading = True
                , errorMessage = Nothing
                , typeHint = Nothing
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
            ( { model | errorMessage = Nothing }, Cmd.none )

        RemoteFetchDone resource ->
            -- TODO: DRY this up
            case resource of
                Data.NoteResource note ->
                    ( { model
                        | path = note.path
                        , loading = False
                        , content = FileContent note.path
                      }
                    , Cmd.batch
                        [ Port.send (Render note.content)
                        , Port.send (Store resource)
                        ]
                    )

                Data.DirectoryResource directory ->
                    ( { model
                        | path = directory.path
                        , loading = False
                        , content = DirectoryContent directory
                      }
                    , Port.send (Store resource)
                    )

        RemoteFetchFailed ->
            ( { model
                | loading = False
                , errorMessage = Just "Couldn't fetch the entry"
              }
            , Cmd.none
            )

        LocalFetchFailed ->
            ( model, Cmd.none )

        LocalFetchDone resource ->
            ( model, Cmd.none )


fetchResource : Maybe EntryType -> String -> Cmd Msg
fetchResource typeHint path =
    Cmd.batch
        [ Api.fetchResource (always RemoteFetchFailed) RemoteFetchDone typeHint path
        , Port.send (Fetch path)
        ]


view : Model -> Html Msg
view model =
    H.div []
        [ viewNav model.path
        , viewProgressIndicator model.loading
        , viewErrorMessage model.errorMessage
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
            Initializing ->
                []

            FileContent path ->
                [ ( "note-content" ++ toString path
                  , H.div [ HA.id "note-content" ] []
                  )
                ]

            DirectoryContent directory ->
                [ ( "directory-content"
                  , viewDirectory directory
                  )
                ]


viewErrorMessage : Maybe String -> Html Msg
viewErrorMessage maybeError =
    case maybeError of
        Nothing ->
            H.div [] []

        Just msg ->
            H.div
                [ HA.id "error-message"
                , HA.class "card blue-grey darken-1"
                ]
                [ H.div
                    [ HA.class "card-content white-text" ]
                    [ H.span [ HA.class "card-title" ] [ H.text msg ]
                    , H.p [] [ H.text "Sorry about that. Maybe reloading helps :-(" ]
                    ]
                , H.div
                    [ HA.class "card-action" ]
                    [ H.a [ HA.attribute "onClick" "event.preventDefault(); window.location.reload(true)" ] [ H.text "Reload" ]
                    , H.a [ HE.onClick DismissError ] [ H.text "Dismiss" ]
                    ]
                ]


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
