local HttpService = game:GetService('HttpService')

local GameIds = {
    [ 994732206 ] = '1a767c2043c5faa3c80ab469820fcf649cb790f0067dec3adc688903b0792ad6'
}

local Owner = "vita8it"
local Respoitory = "Turbopack"

local CacheFolder = `{Respoitory}/Cached`
local ManifestPath = `{CacheFolder}/Manifest.json`

local RawUrl = "https://raw.githubusercontent.com/%s/%s/main/%s.lua"
local TreeUrl = "https://api.github.com/repos/%s/%s/git/trees/main?recursive=1"

local Manifest = {}

local function ReadManifest()
    if isfile(ManifestPath) then
        Manifest = HttpService:JSONDecode(readfile(ManifestPath))
    else
        Manifest = {}
    end
end

local function SaveManifest()
    writefile(ManifestPath, HttpService:JSONEncode(Manifest))
end

local function UpdateManifest()
    local Result = game:HttpGet(TreeUrl:format(Owner, Respoitory))
    local Data = HttpService:JSONDecode(Result)

    Manifest = {}

    for _, Object in Data.tree do
        if Object.type == "blob" and Object.path:sub(-4) == ".lua" then
            Manifest[Object.path:sub(1, -5)] = Object.sha
        end
    end

    SaveManifest()
end

local function EnsureManifest()
    if not isfolder(CacheFolder) then
        makefolder(CacheFolder)
    end

    ReadManifest()

    if next(Manifest) == nil then
        UpdateManifest()
    end
end

EnsureManifest()

local function Importer(Path)
    local CachedPath = `{CacheFolder}/{Path}.lua`
    local CurrentSha = Manifest[Path]

    if isfile(CachedPath) then
        local ShaPath = `{CachedPath}.sha`

        if isfile(ShaPath) and readfile(ShaPath) == CurrentSha then
            return loadstring(readfile(CachedPath))
        end
    end

    local Source = game:HttpGet(
        RawUrl:format(Owner, Respoitory, Path)
    )

    local Folder = CachedPath:match("(.+)/[^/]+$")

    if Folder and not isfolder(Folder) then
        makefolder(Folder)
    end

    writefile(CachedPath, Source)
    writefile(`{CachedPath}.sha`, CurrentSha or "")

    return loadstring(Source)
end

local Junkie = "https://api.jnkie.com/api/v1/luascripts/public/%s/download"
local Game = GameIds[ game.GameId ]

loadstring(game:HttpGet(Junkie:format(game)))(Importer)