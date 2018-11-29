module Main exposing (main)

import Api
import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Content exposing (Content(..))
import Data exposing (Entry, EntryType(..), Resource(..))
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed
import Json.Decode as Decode
import Org
import Path exposing (Path)
import Port exposing (Request(..))
import Url exposing (Url)


type alias Model =
    { key : Nav.Key
    , content : Content
    , typeHint : Maybe EntryType
    , popup : PopupState
    }


type ErrorState
    = AllGood
    | MayBeOldContent
    | Fatal


type NoContentSign
    = EmptyDirectory
    | SomethingWentWrong


type PopupState
    = NoPopup
    | InfoPopup
    | OfflinePopup


type alias Popup msg =
    { title : String
    , content : List (Html msg)
    , actions : List (Html msg)
    }


type Msg
    = ClickedLink UrlRequest
    | UrlChange Url
    | RemoteFetchDone Decode.Value
    | RemoteFetchFailed
    | LocalFetchFailed
    | LocalFetchDone Decode.Value
    | ShowInfo
    | ShowOfflineWarning
    | HidePopup


type alias Flags =
    ()


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = UrlChange
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


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        path =
            Path.fromUrl url
    in
    ( { key = key
      , content = Content.init path
      , typeHint = Nothing
      , popup = NoPopup
      }
    , fetchResource Nothing path
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChange url ->
            let
                path =
                    Path.fromUrl url
            in
            ( { model
                | typeHint = Nothing
                , content = Content.setLoading path model.content
              }
            , fetchResource Nothing path
            )

        RemoteFetchDone value ->
            case decodeResource value of
                Ok resource ->
                    ( { model | content = Content.updateFromServer resource model.content }
                    , Port.send (Store value)
                    )

                Err _ ->
                    ( { model | content = Content.serverFailed model.content }, Cmd.none )

        LocalFetchDone value ->
            case decodeResource value of
                Ok resource ->
                    ( { model | content = Content.updateFromCache resource model.content }, Cmd.none )

                Err _ ->
                    ( { model | content = Content.cacheFailed model.content }, Cmd.none )

        RemoteFetchFailed ->
            ( { model | content = Content.serverFailed model.content }, Cmd.none )

        LocalFetchFailed ->
            ( { model | content = Content.cacheFailed model.content }, Cmd.none )

        ShowInfo ->
            ( { model | popup = InfoPopup }, Cmd.none )

        ShowOfflineWarning ->
            ( { model | popup = OfflinePopup }, Cmd.none )

        HidePopup ->
            ( { model | popup = NoPopup }, Cmd.none )


decodeResource : Decode.Value -> Result Decode.Error Resource
decodeResource =
    Decode.decodeValue Data.resourceDecoder


fetchResource : Maybe EntryType -> Path -> Cmd Msg
fetchResource typeHint path =
    Cmd.batch
        [ Api.fetchResource (always RemoteFetchFailed) RemoteFetchDone typeHint path
        , Port.send (Fetch path)
        ]


view : Model -> Document Msg
view model =
    { title = "Orgnotes"
    , body =
        [ viewNav model.content
        , viewProgressIndicator (Content.isLoading model.content)
        , viewContent model.content
        , maybeViewPopup model.popup
        ]
    }


viewNav : Content -> Html Msg
viewNav content =
    let
        path =
            Content.currentPath content

        navButton =
            case Path.parent path of
                Nothing ->
                    icon "folder"

                Just parentPath ->
                    H.a
                        [ HA.href (Path.toString parentPath) ]
                        [ icon "arrow_back" ]
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
            , case error content of
                AllGood ->
                    H.button
                        [ HE.onClick ShowInfo ]
                        [ icon "info" ]

                MayBeOldContent ->
                    H.button
                        [ HE.onClick ShowOfflineWarning ]
                        [ icon "warning" ]

                Fatal ->
                    H.span [] [ icon "error" ]
            ]
        ]


viewContent : Content -> Html Msg
viewContent content =
    case content of
        Loading { displayedResource } ->
            case displayedResource of
                Nothing ->
                    H.text ""

                Just resource ->
                    viewResource resource

        CachedVersion { resource } ->
            viewResource resource

        ServerVersion resource ->
            viewResource resource

        Failure _ ->
            viewNoContent SomethingWentWrong


viewNoContent : NoContentSign -> Html Msg
viewNoContent sign =
    let
        ( message, ascii ) =
            case sign of
                EmptyDirectory ->
                    ( "Nothing here!"
                    , "¯\\_(ツ)_/¯"
                    )

                SomethingWentWrong ->
                    ( "Something went wrong!"
                    , "༼ つ ◕_◕ ༽つ"
                    )
    in
    H.div
        [ HA.class "no-content valign-wrapper center-align" ]
        [ H.div
            [ HA.class "center-align" ]
            [ H.p [ HA.class "shrug" ] [ H.text ascii ]
            , H.p [] [ H.text message ]
            ]
        ]


error : Content -> ErrorState
error content =
    case content of
        Loading _ ->
            AllGood

        CachedVersion { waitingForServer } ->
            if waitingForServer then
                AllGood

            else
                MayBeOldContent

        ServerVersion resource ->
            AllGood

        Failure _ ->
            Fatal


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
                [ ( "note-content" ++ Path.toString note.path
                  , Org.view [] note.content
                  )
                ]

            DirectoryResource directory ->
                [ ( "directory-content"
                  , viewDirectory directory
                  )
                ]


maybeViewPopup : PopupState -> Html Msg
maybeViewPopup popup =
    case popup of
        NoPopup ->
            H.text ""

        InfoPopup ->
            viewPopup infoPopup

        OfflinePopup ->
            viewPopup offlinePopup


viewPopup : Popup Msg -> Html Msg
viewPopup config =
    H.div
        [ HA.id "app-popup"
        , HA.class "card blue-grey darken-1"
        ]
        [ H.div
            [ HA.class "card-content white-text" ]
            [ H.span [ HA.class "card-title" ] [ H.text config.title ]
            , H.div [] config.content
            ]
        , H.div
            [ HA.class "card-action" ]
            config.actions
        ]


infoPopup : Popup Msg
infoPopup =
    { title = "OrgNotes"
    , content =
        [ H.p []
            [ H.text "Developed by Juan Edi. Source code available on "
            , H.a [ HA.href "http://github.com/juanedi/orgnotes", HA.title "Github" ] [ H.text "Github" ]
            , H.text "."
            ]
        , H.br [] []
        , H.p []
            [ H.text "Icons made by "
            , H.a [ HA.href "https://www.flaticon.com/authors/smashicons", HA.title "Smashicons" ] [ H.text "Smashicons" ]
            , H.text " from "
            , H.a [ HA.href "https://www.flaticon.com/", HA.title "Flaticon" ] [ H.text "www.flaticon.com" ]
            , H.text " is licensed by "
            , H.a [ HA.href "http://creativecommons.org/licenses/by/3.0/", HA.title "Creative Commons BY 3.0" ] [ H.text "CC 3.0 BY" ]
            , H.text "."
            ]
        ]
    , actions =
        [ H.a [ HE.onClick HidePopup ] [ H.text "Hide" ]
        ]
    }


offlinePopup : Popup Msg
offlinePopup =
    { title = "Offline mode"
    , content = [ H.p [] [ H.text "You're looking at a cached version, which may be old. Maybe reloading helps :-(" ] ]
    , actions =
        [ H.a [ HE.onClick HidePopup ] [ H.text "Hide" ]
        , H.a [ HA.attribute "onClick" "event.preventDefault(); window.location.reload(true)" ] [ H.text "Reload" ]
        ]
    }


viewDirectory : Data.Directory -> Html Msg
viewDirectory directory =
    if List.isEmpty directory.entries then
        viewNoContent EmptyDirectory

    else
        -- NOTE: Html.Keyed is here to prevent hover style bugs on mobile
        Html.Keyed.node "div"
            [ HA.id "directory-entries"
            , HA.class "collection"
            ]
            (List.map
                (\entry -> ( entry.name, viewEntry entry ))
                directory.entries
            )


viewEntry : Entry -> Html Msg
viewEntry entry =
    H.a
        [ HA.class "collection-item"
        , HA.href entry.pathLower
        ]
        [ case entry.type_ of
            DirectoryEntry ->
                icon "folder"

            NoteEntry ->
                icon "insert_drive_file"
        , H.text entry.name
        ]


icon : String -> Html msg
icon iconId =
    H.i [ HA.class "material-icons" ]
        [ H.text iconId
        ]
