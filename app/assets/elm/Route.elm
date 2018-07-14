module Route exposing (Route(..), parse, toPath)

import Navigation
import UrlParser exposing ((<?>), map, oneOf, s, string, stringParam, top)


type Route
    = DirectoryRoute String
    | FileRoute String


parse : Navigation.Location -> Route
parse location =
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


toPath : Route -> String
toPath route =
    case route of
        DirectoryRoute path ->
            path

        FileRoute path ->
            path ++ "?cmd=cat"
