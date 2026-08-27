local _ENV = (getgenv or getrenv or getfenv)()

local Importer, Inserter = ...

local HIDDEN_SETTINGS = {

}

local Owner = "vita8it"
local Respoitory = "Turbopack"

if type(Importer) ~= 'function' then
    Importer = function(Path)
        local Github = 'https://raw.githubusercontent.com/%s'
        local Direct = `{Owner}/{Respoitory}/main/{Path}.lua`

        local Formater = Github:format(Direct)
        local Result = game:HttpGet(Formater)

        return loadstring(Result)
    end 
end

local Packages, Settings = Importer('Package')(Importer)

local Configurators = Packages.Configurators
local EachOthers = Packages.EachOthers
local Connectors = Packages.Connectors
local Queueable =  Packages.Queueable
local Plugins = Packages.Plugins

local Options = Queueable.Build()
local Folder = gethui and gethui()

for _, Object in Folder:GetChildren() do
    if Object.Name:find('Next.js') then
        Object:Destroy()
    end
end

local Window = Plugins:Window(Options) do
    Plugins:Community() 
end

do
    Options:NewOption("Test While", function()
        print(_ENV.Session, "While Loop")
    end, 1)

    Options:NewOption("Test Queue", function()
        print(_ENV.Session, "Queue Loop")
        return true -- stop and farm
    end)
end

local Tab = Plugins:MakeTab({
    "Example", "Automatically", 115960025411300
}) do
    Tab:Section("Looping", function(Section)
        Plugins:Toggle(Section, {
            "Test Queue"
        }, "Test Queue")

        Plugins:Toggle(Section, {
            "Test While"
        }, "Test While")
    end)
end

Plugins:Managers()
Options:RunQueue()