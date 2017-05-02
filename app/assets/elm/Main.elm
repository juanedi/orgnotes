module Main exposing (..)

import Api exposing (Entry(..))
import Formatting
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Markdown
import Navigation
import Routes exposing (Route(..))


type DisplayModel
    = DirectoryContent (List Entry)
    | FileContent Formatting.NoteMarkup


type alias Path =
    String


type alias Model =
    { path : Path
    , loading : Bool
    , content : Maybe DisplayModel
    }


type Msg
    = UrlChange Route
    | Navigate Route
    | NavigateBack
    | DirectoryFetchSucceeded Path (List Entry)
    | DirectoryFetchFailed
    | FileFetchSucceeded Path String
    | FileFormattingDone Path Formatting.NoteMarkup
    | FileFetchFailed


main : Program Never Model Msg
main =
    Navigation.program
        (Routes.routesParser >> UrlChange)
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    location
        |> Routes.routesParser
        |> loadPage location.pathname Nothing


{-| Begins loading a page.

A base path and content are required, which will be displayed until the content
arrives. This is so thag, when navigating to an item, the previous filename and
contents are shown while loading.
-}
loadPage : Path -> Maybe DisplayModel -> Route -> ( Model, Cmd Msg )
loadPage basePath baseContent route =
    case route of
        DirectoryRoute path ->
            ( { path = basePath, loading = True, content = baseContent }, listDirectory path )

        FileRoute path ->
            ( { path = basePath, loading = True, content = baseContent }, fetchFile path )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange route ->
            loadPage model.path model.content route

        Navigate route ->
            ( model, Routes.navigate route )

        NavigateBack ->
            ( model, Navigation.back 1 )

        DirectoryFetchFailed ->
            ( model, Cmd.none )

        DirectoryFetchSucceeded path entries ->
            ( { path = path
              , loading = False
              , content = Just (DirectoryContent entries)
              }
            , Cmd.none
            )

        FileFetchFailed ->
            ( model, Cmd.none )

        FileFetchSucceeded path content ->
            ( model, Formatting.format path content )

        FileFormattingDone path markup ->
            ( { model
                | path = path
                , loading = False
                , content = Just (FileContent markup)
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Formatting.results FileFormattingDone


listDirectory : String -> Cmd Msg
listDirectory path =
    Api.listDirectory (always DirectoryFetchFailed) (DirectoryFetchSucceeded path) path


fetchFile : String -> Cmd Msg
fetchFile path =
    Api.fetchFile (always FileFetchFailed) (FileFetchSucceeded path) path


view : Model -> Html Msg
view model =
    let
        loadingBar =
            if model.loading then
                H.div
                    [ HA.id "app-progress", HA.class "progress" ]
                    [ H.div [ HA.class "indeterminate" ] [] ]
            else
                H.div
                    [ HA.id "app-progress" ]
                    []

        navButton =
            case model.path of
                "/" ->
                    -- TODO: menu
                    H.i [ HA.class "material-icons" ] [ H.text "menu" ]

                _ ->
                    H.i [ HE.onClick NavigateBack, HA.class "material-icons" ] [ H.text "arrow_back" ]

        nav =
            H.nav
                [ HA.class "blue-grey" ]
                [ H.div
                    [ HA.class "nav-wrapper" ]
                    [ H.div
                        [ HA.class "nav-button left" ]
                        [ navButton ]
                    , H.span
                        [ HA.class "nav-path" ]
                        [ H.text model.path ]
                    ]
                ]

        body =
            case model.content of
                Nothing ->
                    []

                Just (FileContent m) ->
                    [ Markdown.toHtml [ HA.id "note-content" ] m ]

                Just (DirectoryContent entries) ->
                    [ viewDirectory entries ]
    in
        H.div [] (nav :: loadingBar :: body)


viewDirectory : List Entry -> Html Msg
viewDirectory entries =
    H.div
        [ HA.id "directory-entries"
        , HA.class "collection"
        ]
        (List.map viewEntry entries)


viewEntry : Entry -> Html Msg
viewEntry entry =
    let
        ( title, onClick, icon ) =
            case entry of
                Folder metadata ->
                    ( metadata.name, Navigate (DirectoryRoute metadata.pathLower), "folder" )

                File metadata ->
                    ( metadata.name, Navigate (FileRoute metadata.pathLower), "insert_drive_file" )
    in
        H.a
            [ HA.class "collection-item"
            , HE.onClick onClick
            ]
            [ H.i [ HA.class "material-icons" ] [ H.text icon ]
            , H.text title
            ]
