module Main exposing (..)

import Api exposing (Path, Entry(..))
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE


type Model
    = Fetching Path
    | DisplayingDirectory Path (List Entry)
    | DisplayingFile String Path


type Msg
    = DirectoryFetchSucceeded Path (List Entry)
    | DirectoryFetchFailed
    | FileFetchSucceeded Path String
    | FileFetchFailed
    | DirectoryClicked Path
    | FileClicked Path


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
    ( Fetching "/", listDirectory "/" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DirectoryFetchFailed ->
            ( model, Cmd.none )

        DirectoryFetchSucceeded path entries ->
            ( DisplayingDirectory path entries, Cmd.none )

        FileFetchFailed ->
            ( model, Cmd.none )

        FileFetchSucceeded path content ->
            ( DisplayingFile path content, Cmd.none )

        DirectoryClicked path ->
            ( Fetching path, listDirectory path )

        FileClicked path ->
            ( Fetching path, fetchFile path )


listDirectory : String -> Cmd Msg
listDirectory path =
    Api.listDirectory (always DirectoryFetchFailed) (DirectoryFetchSucceeded path) path


fetchFile : String -> Cmd Msg
fetchFile path =
    Api.fetchFile (always FileFetchFailed) (FileFetchSucceeded path) path


view : Model -> Html Msg
view model =
    case model of
        Fetching path ->
            layout path
                [ H.div
                    [ HA.class "progress" ]
                    [ H.div [ HA.class "indeterminate" ] [] ]
                ]

        DisplayingFile path content ->
            layout path
                [ H.pre [] [ H.text content ] ]

        DisplayingDirectory path entries ->
            layout path
                [ viewDirectory entries ]


layout : Path -> List (Html Msg) -> Html Msg
layout path body =
    let
        nav =
            H.nav
                [ HA.class "blue-grey" ]
                [ H.div
                    [ HA.class "nav-wrapper" ]
                    [ H.span [] [ H.text path ]
                    ]
                ]
    in
        H.div [] (nav :: body)


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
