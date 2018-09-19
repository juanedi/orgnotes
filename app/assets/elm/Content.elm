module Content exposing
    ( Content(..)
    , cacheFailed
    , currentPath
    , init
    , isLoading
    , serverFailed
    , setLoading
    , updateFromCache
    , updateFromServer
    )

import Data exposing (Entry, EntryType(..), Resource(..))
import Path exposing (Path)


type Content
    = Loading
        { pathToLoad : Path
        , displayedResource : Maybe Resource
        , status : LoadingStatus
        }
    | CachedVersion
        { resource : Resource
        , waitingForServer : Bool
        }
    | ServerVersion Resource
    | Failure Path


type LoadingStatus
    = WaitingForBoth
    | ServerFailed
    | CacheFailed


init : Path -> Content
init path =
    Loading
        { pathToLoad = path
        , displayedResource = Nothing
        , status = WaitingForBoth
        }


currentPath : Content -> Path
currentPath content =
    case content of
        Loading { pathToLoad } ->
            pathToLoad

        CachedVersion { resource } ->
            Data.path resource

        ServerVersion resource ->
            Data.path resource

        Failure path ->
            path


isLoading : Content -> Bool
isLoading content =
    case content of
        Loading _ ->
            True

        CachedVersion _ ->
            False

        ServerVersion _ ->
            False

        Failure _ ->
            False


setLoading : Path -> Content -> Content
setLoading newPath content =
    case content of
        Loading _ ->
            content

        CachedVersion { resource } ->
            Loading
                { pathToLoad = newPath
                , displayedResource = Just resource
                , status = WaitingForBoth
                }

        ServerVersion resource ->
            Loading
                { pathToLoad = newPath
                , displayedResource = Just resource
                , status = WaitingForBoth
                }

        Failure _ ->
            Loading
                { pathToLoad = newPath
                , displayedResource = Nothing
                , status = WaitingForBoth
                }


updateFromCache : Resource -> Content -> Content
updateFromCache resource content =
    if Data.path resource /= currentPath content then
        content

    else
        case content of
            Loading loading ->
                -- if network is slow, we may have navigated to
                -- another local resource before the server's
                -- response arrives
                CachedVersion
                    { resource = resource
                    , waitingForServer = loading.status /= ServerFailed
                    }

            CachedVersion _ ->
                -- should not happen
                content

            ServerVersion _ ->
                -- cache took longer than the real thing. the world is a strange place.
                content

            Failure path ->
                CachedVersion { resource = resource, waitingForServer = True }


updateFromServer : Resource -> Content -> Content
updateFromServer resource content =
    -- if network is slow, we may have navigated to
    -- another local resource before the server's
    -- response arrives
    if Data.path resource /= currentPath content then
        content

    else
        case content of
            Loading { pathToLoad } ->
                ServerVersion resource

            CachedVersion cached ->
                ServerVersion resource

            ServerVersion _ ->
                -- should not happen
                content

            Failure path ->
                ServerVersion resource


serverFailed : Content -> Content
serverFailed content =
    case content of
        Loading loading ->
            case loading.status of
                CacheFailed ->
                    Failure loading.pathToLoad

                _ ->
                    -- no server version, but the cache might still succeed
                    Loading { loading | status = ServerFailed }

        CachedVersion cached ->
            CachedVersion { cached | waitingForServer = False }

        ServerVersion resource ->
            -- should not happen
            content

        Failure path ->
            -- should not happen
            content


cacheFailed : Content -> Content
cacheFailed content =
    case content of
        Loading loading ->
            case loading.status of
                ServerFailed ->
                    Failure loading.pathToLoad

                _ ->
                    -- no cached version, but the server might still succeed
                    Loading { loading | status = CacheFailed }

        CachedVersion cached ->
            -- should not happen
            content

        ServerVersion resource ->
            -- we don't care
            content

        Failure path ->
            -- should not happen
            content
