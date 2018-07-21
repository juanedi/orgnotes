module Content
    exposing
        ( Content
        , cancelLoading
        , current
        , currentPath
        , init
        , isLoading
        , setLoading
        , updateFromCache
        , updateFromServer
        )

import Data exposing (Entry, EntryType(..), Resource(..))


type alias Path =
    String


type Content
    = Initializing Path
    | Displaying (Cacheable Resource)
    | LoadingOther Path (Cacheable Resource)


type Cacheable r
    = Cached r
    | Fetched r


init : Path -> Content
init path =
    Initializing path


setLoading : Path -> Content -> Content
setLoading newPath model =
    case model of
        Initializing _ ->
            model

        Displaying resource ->
            LoadingOther newPath resource

        LoadingOther _ resource ->
            model


cancelLoading : Content -> Content
cancelLoading model =
    case model of
        Initializing _ ->
            model

        Displaying resource ->
            model

        LoadingOther _ resource ->
            Displaying resource


isLoading : Content -> Bool
isLoading model =
    case model of
        Initializing _ ->
            True

        Displaying resource ->
            False

        LoadingOther _ resource ->
            True


currentPath : Content -> Path
currentPath model =
    case model of
        Initializing path ->
            path

        Displaying resource ->
            Data.path (fromCacheable resource)

        LoadingOther _ resource ->
            Data.path (fromCacheable resource)


updateFromServer : Resource -> Content -> Content
updateFromServer resource model =
    case model of
        Initializing _ ->
            Displaying (Fetched resource)

        LoadingOther loadingPath _ ->
            -- if network is slow, we may have navigated to
            -- another local resource before the server's
            -- response arrives
            if loadingPath == Data.path resource then
                Displaying (Fetched resource)
            else
                model

        Displaying (Cached cachedResource) ->
            -- if network is slow, we may have navigated to
            -- another local resource before the server's
            -- response arrives
            if Data.path resource == Data.path cachedResource then
                Displaying (Fetched resource)
            else
                model

        Displaying (Fetched _) ->
            -- NOTE: should not happen
            model


updateFromCache : Resource -> Content -> Content
updateFromCache resource model =
    case model of
        Initializing _ ->
            Displaying (Cached resource)

        LoadingOther loadingPath _ ->
            -- if network is slow, we may have navigated to
            -- another local resource before the server's
            -- response arrives
            if loadingPath == Data.path resource then
                Displaying (Cached resource)
            else
                model

        Displaying (Fetched _) ->
            -- cache took longer than the real thing. the world is a strange place.
            model

        Displaying (Cached _) ->
            -- NOTE: should not happen
            model


current : Content -> Maybe Resource
current content =
    case content of
        Initializing _ ->
            Nothing

        Displaying cacheable ->
            Just (fromCacheable cacheable)

        LoadingOther _ cacheable ->
            Just (fromCacheable cacheable)


fromCacheable : Cacheable r -> r
fromCacheable cacheable =
    case cacheable of
        Cached r ->
            r

        Fetched r ->
            r
