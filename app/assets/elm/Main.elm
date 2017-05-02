module Main exposing (..)

import Api exposing (Path, Entry(..))
import Formatting
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Process
import Task


type DisplayModel
    = DirectoryContent (List Entry)
    | FileCanvas String
    | FileContent String


type alias Model =
    { path : Path
    , loading : Bool
    , content : Maybe DisplayModel
    }


type Msg
    = DirectoryFetchSucceeded Path (List Entry)
    | DirectoryFetchFailed
    | FileFetchSucceeded Path String
    | FileFetchFailed
    | DirectoryClicked Path
    | FileClicked Path
    | CanvasReady


main : Program Never Model Msg
main =
    H.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }


init : ( Model, Cmd Msg )
init =
    ( { path = "/", loading = True, content = Nothing }, listDirectory "/" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DirectoryClicked path ->
            ( { model | loading = True }, listDirectory path )

        FileClicked path ->
            ( { model | loading = True }, fetchFile path )

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
            ( { path = path
              , loading = True
              , content = Just (FileCanvas content)
              }
            , Task.perform (always CanvasReady) (Process.sleep 100)
            )

        CanvasReady ->
            case model.content of
                Just (FileCanvas content) ->
                    ( { model | loading = False, content = Just (FileContent content) }
                    , Formatting.format content
                    )

                _ ->
                    ( model, Cmd.none )


listDirectory : String -> Cmd Msg
listDirectory path =
    Api.listDirectory (always DirectoryFetchFailed) (DirectoryFetchSucceeded path) path


fetchFile : String -> Cmd Msg
fetchFile path =
    Api.fetchFile (always FileFetchFailed) (FileFetchSucceeded path) path


view : Model -> Html Msg
view model =
    let
        nav =
            H.nav
                [ HA.class "blue-grey" ]
                [ H.div
                    [ HA.class "nav-wrapper" ]
                    [ H.span [] [ H.text model.path ]
                    ]
                ]

        loadingBar =
            H.div
                [ HA.id "app-progress", HA.classList [ ( "progress", True ), ( "inactive", not model.loading ) ] ]
                [ H.div [ HA.class "indeterminate" ] [] ]

        body =
            case model.content of
                Nothing ->
                    []

                Just (FileCanvas content) ->
                    [ H.div [ HA.id "formatted-code" ] [] ]

                Just (FileContent content) ->
                    [ H.div [ HA.id "formatted-code" ] [] ]

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
                    ( metadata.name, DirectoryClicked metadata.pathLower, "folder" )

                File metadata ->
                    ( metadata.name, FileClicked metadata.pathLower, "insert_drive_file" )
    in
        H.a
            [ HA.class "collection-item"
            , HA.href "#"
            , HE.onClick onClick
            ]
            [ H.i [ HA.class "material-icons" ] [ H.text icon ]
            , H.text title
            ]
