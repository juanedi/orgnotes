module Routes exposing (Route(..), routesParser)

import Navigation
import UrlParser exposing (oneOf, map, s, string, stringParam, top, (<?>))


type Route
    = DirectoryRoute String
    | FileRoute String
    | NotFoundRoute


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
            |> Maybe.withDefault NotFoundRoute
