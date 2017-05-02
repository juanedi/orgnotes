module Routes exposing (Route(..), routesParser, navigate)

import Navigation
import UrlParser exposing (oneOf, map, s, string, stringParam, top, (<?>))


type Route
    = DirectoryRoute String
    | FileRoute String


routesParser : Navigation.Location -> Route
routesParser location =
    let
        parseCmd location =
            -- Hack :)
            -- Build a location with same query but fixed-size path to parse only query
            UrlParser.parsePath
                (map (\_ cmd -> Maybe.withDefault "ls" cmd) (string <?> stringParam "cmd"))
                { location | pathname = "." }

        pathRoute cmd =
            if cmd == "cat" then
                FileRoute location.pathname
            else
                DirectoryRoute location.pathname
    in
        location
            |> parseCmd
            |> Maybe.map pathRoute
            |> Maybe.withDefault (DirectoryRoute "/")


navigate : Route -> Cmd msg
navigate route =
    Navigation.newUrl <| routeToPath route


routeToPath : Route -> String
routeToPath route =
    case route of
        DirectoryRoute path ->
            path

        FileRoute path ->
            path ++ "?cmd=cat"
