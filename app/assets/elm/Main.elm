port module Main exposing (..)

import Api exposing (Entry(..))
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed
import Navigation
import Route exposing (Route(..))


type alias Path =
    String


type alias Model =
    { path : Path
    , loading : Bool
    , errorMessage : Maybe String
    , content : DisplayModel
    }


type DisplayModel
    = Initializing
    | DirectoryContent (List Entry)
    | FileContent String


type Msg
    = UrlChange Route
    | Navigate Route
    | NavigateBack
    | DismissError
    | DirectoryFetchSucceeded Path (List Entry)
    | DirectoryFetchFailed
    | FileFetchSucceeded Path String
    | FileFetchFailed


port renderNote : String -> Cmd msg


main : Program Never Model Msg
main =
    Navigation.program
        (Route.parse >> UrlChange)
        { init = init
        , update = update
        , view = view
        , subscriptions = \model -> Sub.none
        }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    location
        |> Route.parse
        |> loadPage location.pathname Initializing


{-| Begins loading a page.

A base path and content are required, which will be displayed until the content
arrives. This is so thag, when navigating to an item, the previous filename and
contents are shown while loading.

-}
loadPage : Path -> DisplayModel -> Route -> ( Model, Cmd Msg )
loadPage basePath baseContent route =
    let
        action =
            case route of
                DirectoryRoute path ->
                    listDirectory path

                FileRoute path ->
                    fetchFile path
    in
    ( { path = basePath
      , loading = True
      , errorMessage = Nothing
      , content = baseContent
      }
    , action
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange route ->
            loadPage model.path model.content route

        Navigate route ->
            ( model, Navigation.newUrl (Route.toPath route) )

        NavigateBack ->
            ( model, Navigation.back 1 )

        DismissError ->
            ( { model | errorMessage = Nothing }, Cmd.none )

        DirectoryFetchFailed ->
            ( { model
                | loading = False
                , errorMessage = Just "Couldn't fetch directory"
              }
            , Cmd.none
            )

        DirectoryFetchSucceeded path entries ->
            ( { model
                | path = path
                , loading = False
                , content = DirectoryContent entries
              }
            , Cmd.none
            )

        FileFetchFailed ->
            ( { model
                | loading = False
                , errorMessage = Just "Couldn't fetch file"
              }
            , Cmd.none
            )

        FileFetchSucceeded path content ->
            ( { model
                | path = path
                , loading = False
                , content = FileContent path
              }
            , renderNote content
            )


listDirectory : String -> Cmd Msg
listDirectory path =
    Api.listDirectory (always DirectoryFetchFailed) (DirectoryFetchSucceeded path) path


fetchFile : String -> Cmd Msg
fetchFile path =
    Api.fetchFile (always FileFetchFailed) (FileFetchSucceeded path) path


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

            DirectoryContent entries ->
                [ ( "directory-content"
                  , viewDirectory entries
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


viewDirectory : List Entry -> Html Msg
viewDirectory entries =
    if List.isEmpty entries then
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
