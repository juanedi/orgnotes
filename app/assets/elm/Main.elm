module Main exposing (..)

import Api exposing (Path, Entry(..))
import Html as H exposing (Html)
import Html.Events as HE


type Model
    = FetchingDirectory Path
    | FetchingFile Path
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
    ( FetchingDirectory "/", listDirectory "/" )


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
            ( FetchingDirectory path, listDirectory path )

        FileClicked path ->
            ( FetchingFile path, fetchFile path )


listDirectory : String -> Cmd Msg
listDirectory path =
    Api.listDirectory (always DirectoryFetchFailed) (DirectoryFetchSucceeded path) path


fetchFile : String -> Cmd Msg
fetchFile path =
    Api.fetchFile (always FileFetchFailed) (FileFetchSucceeded path) path


view : Model -> Html Msg
view model =
    case model of
        FetchingDirectory _ ->
            H.p [] [ H.text "..." ]

        FetchingFile _ ->
            H.p [] [ H.text "..." ]

        DisplayingFile path content ->
            H.pre
                []
                [ H.text content ]

        DisplayingDirectory path entries ->
            H.div
                []
                [ H.h1 [] [ H.text path ]
                , H.ul
                    []
                    (List.map viewEntry entries)
                ]


viewEntry : Entry -> Html Msg
viewEntry entry =
    case entry of
        Folder metadata ->
            H.li
                [ HE.onClick (DirectoryClicked metadata.pathLower) ]
                [ H.text metadata.name ]

        File metadata ->
            H.li
                [ HE.onClick (FileClicked metadata.pathLower) ]
                [ H.text metadata.name ]
