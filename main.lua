
local Importer = ...

local _ENV = (getgenv or getrenv or getfenv)()

local Packages, Settings = {}, {}
local Cache, Errors = {}, _ENV.ERRORS or {} do
    _ENV.ERRORS = Errors
end

local Session = os.clock() do
    _ENV.Session = Session
    _ENV.Settings = Settings
end

local Owner = "vita8it"
local Respoitory = "Turbopack"

local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local PlaceId = game.PlaceId
local JobId = game.JobId

local LocalPlayer = Players.LocalPlayer

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped

local KeyboardEnabled = UserInputService.KeyboardEnabled
local TouchEnabled = UserInputService.TouchEnabled

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

function NewPackage(Name, Module)
    do Packages[Name] = Module()
        return Packages[Name]
    end
end 

function TableToString(Value, Indent, Seen)
    Indent = Indent or 0
    Seen = Seen or {}

    if type(Value) ~= "table" then
        if typeof(Value) == "Instance" then
            return Value:GetFullName()
        elseif type(Value) == "string" then
            return string.format("%q", Value)
        end

        return tostring(Value)
    end

    if Seen[Value] then
        return "<recursive>"
    end

    Seen[Value] = true

    local Space = string.rep("    ", Indent)
    local Result = {"{\n"}

    for Key, Object in next, Value do
        table.insert(Result,
            string.format(
                "%s    [%s] = %s,\n",
                Space,
                TableToString(Key, 0, Seen),
                TableToString(Object, Indent + 1, Seen)
            )
        )
    end

    table.insert(Result, Space .. "}")
    return table.concat(Result)
end

NewPackage("Importer", function()
    return Importer
end)

NewPackage("Connectors", function()
    local Connectors = {}

    local Connections = _ENV.Connections or {} do
        _ENV.Connections = Connections

        for i = 1, #Connections do
            Connections[i]:Disconnect()
        end

        table.clear(Connections)
    end

    function Connections.Connect(Instance, Callback)
        local Connection = Instance:Connect(Callback)
        table.insert(Connections, Connection) do
            return Connection 
        end
    end

    return Connections
end)

NewPackage("Configurators", function()
    local Configurators = {}
    Configurators.__index = Configurators

    local Operators = {
        "makefolder", "writefile", "getcustomasset",
        "isfolder", "readfile", "isfile", "setclipboard"
    }

    for _, Operator in Operators do
        Cache[Operator] = _ENV[Operator]
    end

    function Configurators:Folder()
        local Pathable = self.Paths

        for i = 1, #Pathable do
            local Path = Pathable[i]

            if not Cache.isfolder(Path) then
                Cache.makefolder(Path)
            end
        end
    end

    function Configurators:Default(Index, Value)
        if rawget(self.Data, Index) == nil then
            rawset(self.Data, Index, Value); self:Save()
        end
    end

    function Configurators:Save(Index, Value)
        if Index ~= nil then
            rawset(self.Data, Index, Value)
        end

        self:Folder()

        local Json = HttpService:JSONEncode(self.Data) do
            return Cache.writefile(self.Json, Json) 
        end
    end

    function Configurators:Load()
        if not Cache.isfile(self.Json) then
            self:Save()
        end

        local Success, Result = pcall(function()
            return HttpService:JSONDecode(
                Cache.readfile(self.Json)
            )
        end)

        if Success and typeof(Result) == "table" then
            table.clear(self.Data)

            for Index, Value in Result do
                self.Data[Index] = Value
            end
        end
    end

    function Configurators.new(Folder)
        local self = setmetatable({}, Configurators)

        Folder = Folder or "Unknown"

        self.Files = Folder
        self.Settings = `{Folder}/settings`

        self.Json = `{self.Settings}/{PlaceId}.json`
        self.Paths = { self.Files, self.Settings }

        self.Data = {}

        self:Folder() do
            self:Load()
            self:Default("Success", true) 
        end

        Settings = setmetatable({}, {
            __index = function(_, Index)
                return self.Data[Index]
            end,
            __newindex = function(_, Index, Value)
                if self.Data[Index] ~= Value then
                    self.Data[Index] = Value; self:Save()
                end
            end
        })

        _ENV.Settings = Settings

        return self
    end

    return Configurators
end)

NewPackage("Queueable", function()
    local Queueable = {}
    Queueable.__index = Queueable

    function Queueable:Error(Message)
        _ENV.OnFarm = false

        local Option = _ENV.RunningOption or "Unknow"
        local Text = (`error [ { Option } ] { Message }`)

        if not Errors[Option] then
            Errors[Option] = {}
        end

        if _ENV.Error then
            _ENV.Error.Text ..= `\n\n{ Text }`
        else
            local Error = Instance.new("Message") do
                Error.Parent = workspace
                Error.Text = Text
            end

            _ENV.Error = Error
        end

        table.insert(Errors[Option], Message)
    end

    function Queueable:ResetQueue()
        local Fallback = self.Fallback

        local Option = _ENV.RunningOption
        local Error = _ENV.Error

        if Error then
            Error.Text = "Start Refresh Options."

            task.wait(2)


            if Option and Fallback[Option] then
                Fallback[Option]:SetValue(false)
                Error.Text = `Disabled : {Option}`
            end

            task.wait(2)

            Error:Destroy()
            _ENV.Error = nil

            self:RunQueue()
        end
    end

    function Queueable:GetQueue()
        for _, Option in self.FarmFunctions do
            _ENV.RunningOption = Option.Name

            local Method = Option.Function()

            if Method then
                if type(Method) == "string" then
                    _ENV.RunningMethod = Method
                end

                return Method
            end
        end

        _ENV.RunningOption, _ENV.RunningMethod = nil, nil
    end

    function Queueable:RunQueue()
        local Success, Error = pcall(function()
            while task.wait(0) do
                if _ENV.Session ~= Session then
                    _ENV.RunningOption, _ENV.RunningMethod = nil, nil
                    _ENV.OnFarm = false

                    warn("Breakable", Session); break
                end

                _ENV.OnFarm = self:GetQueue() and true or false
            end
        end)

        if not Success then
            self:Error(Error)
            task.delay(3, function()
                self:ResetQueue(Error)
            end)
        end
    end

    function Queueable:UpdateOptions()
        table.clear(self.FarmFunctions)

        for Index, Value in self.NewValues do
            self.Cloneables[ Index ] = Value or nil
            self.NewValues[ Index ] = nil
        end

        for i = 1, #self.Functions do
            local Function = self.Functions[i]

            if self.Cloneables[Function.Name] then
                table.insert(self.FarmFunctions, Function)
            end
        end
    end

    function Queueable:While(Value, Interval, Callback, Break)
        while Value do
            local Tick = tick()

            if Callback then Callback() end
            if Break and Break() then break end

            repeat
                RunService.Heartbeat:Wait()
            until tick() - Tick >= (Interval or 0.1)
        end
    end

    function Queueable:NewOption(Flag, Function, Interval)
        if Interval then
            self.Threads[Flag] = function(Value)
                self:While(Value, Interval or 0.1, Function, function()
                    return not Value or _ENV.Session ~= Session
                end)
            end
        else
            self.Indexable[Flag] = Function
            table.insert(self.Functions, { 
                ["Name"] = Flag,
                ["Function"] = Function
            })
        end
    end

    function Queueable.Build(Running)
        local self = setmetatable({}, Queueable)

        self.Fallback = {}

        self.NewValues = {}
        self.Cloneables = {}

        self.Functions = _ENV.Functions or {}
        self.FarmFunctions = _ENV.FarmFunctions or {}

        self.Enableds = _ENV.Enableds or setmetatable({}, {
            __newindex = function(_, Index, Value)
                self.NewValues[Index] = Value or false
                self:UpdateOptions()
            end,
            __index = self.Cloneables
        })

        self.Threads = {}
        self.Indexable = {} do
            _ENV.FarmFunctions = self.FarmFunctions
            _ENV.Functions = self.Functions
            _ENV.Enableds = self.Enableds

            if Running then
                task.spawn(self.RunQueue, self) 
            end

            table.clear(self.Functions)
        end

        return self
    end

    return Queueable
end)

NewPackage("EachOthers", function()
    local EachOthers = {}

    function EachOthers:Join(Id)
        return TeleportService:TeleportToPlaceInstance(PlaceId, Id, LocalPlayer)
    end

    function EachOthers:Reversed(Cursor)
        local Url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&limit=100`

        if Cursor then Url ..= `&cursor={Cursor}` end

        local Result = game:HttpGet(Url)

        return HttpService:JSONDecode(Result)
    end

    function EachOthers:Rejoin()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining");wait()

            return TeleportService:Teleport(PlaceId, LocalPlayer)
        end

        return self:Join(JobId)
    end

    function EachOthers:Change()
        local Server, Next

        repeat
            local Servers = self:Reversed(Next)

            Server = Servers and Servers.data and Servers.data[1]
            Next = Servers and Servers.nextPageCursor
        until Server

        if not Server or not Server.id then return end
        return self:Join(Server.id)
    end

    function EachOthers:Set3d(value)
        RunService:Set3dRenderingEnabled(if value then false else true)
    end

    function EachOthers:Low()
        local Terrain = workspace:FindFirstChildOfClass('Terrain') do
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0

            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9

            settings().Rendering.QualityLevel = 1
        end
    end

    return EachOthers
end)

NewPackage("Plugins", function()
    local Plugins = {}

    local Nodes = Importer("Components/Library")()
    local Lucides = Importer("Components/Lucide")()

    local Configurators = Packages.Configurators
    local EachOthers = Packages.EachOthers

    local Configable = Configurators.new(Respoitory)

    Plugins.ParagraphTypes = {
        Icon = function(Paragraph, Value)
            return Paragraph:Icon(type(Value) == 'string' and Lucides[Value] or Value)
        end,
        Text = function(Paragraph, Value)
            return Paragraph:Typography(Value)
        end,
        Status = function(Paragraph, Value)
            return Paragraph:Status(Value)
        end,
    }

    function Plugins:Default(...)
        Configable:Default(...)
    end

    function Plugins:NewProxy(Tab)
        local Proxy = {}

        function Proxy:Section(Name, Callback)
            local Element = Tab[Name]

            if not Element then
                Element = Tab:Section(Name)
                rawset(Tab, Name, Element)
            end

            if Callback then
                Callback(Element)
            end

            return Element
        end

        setmetatable(Proxy, {
            __index = function(self, Index)
                return Tab[Index]
            end,
            __newindex = function(self, Index, Value)
                rawset(Tab, Index, Value)
            end,
        })

        return Proxy
    end

    function Plugins:Window(Queueable)
        self.Nodes = Nodes

        self.Enableds = Queueable.Enableds
        self.Fallback = Queueable.Fallback
        self.Threads = Queueable.Threads

        self.Library = Nodes.Application("Next.js", {
            Title = "Next.js",
            Footer = "Client Framework.",
            Logo = 130970470497096,
        })

        return self.Library
    end

    function Plugins:Notify(Args, Duration)
        return self.Library:Notification({
            Title = Args[1],
            Description = Args[2],
            Icon = Args[3] or 107131709546324,
            Duration = Duration or 5
        })
    end

    function Plugins:Dialog(Args, Callback)
        return self.Library:Dialog({
            Title = Args[1],
            Description = "Are you sure?",
            Content = Args[2],
            Icon = Args[3] or 107131709546324,
            Callback = function(State)
                if State then
                    task.spawn(pcall, Callback)
                end
            end,

        })
    end

    function Plugins:MakeTab(Args, Select)
        local NewTab = self.Library:MakeTab({
            Title = Args[1],
            Description = Args[2] or "Automatically",
            Icon = type(Args[3]) == 'string' and Lucides[ Args[3] ] or Args[3],
            Selected = self.Library.FirstTab,
        })

        self.Library.FirstTab = false
        return self:NewProxy(NewTab)
    end


    function Plugins:Paragraph(Section, Args, Types)
        local Paragraph = Section:Paragraph({
            Title = Args[1],
            Description = Args[2],
        })

        if not Types then
            return Paragraph
        end

        local Handler = Plugins.ParagraphTypes[Types[1]]

        if Handler then
            return Handler(Paragraph, Types[2])
        end

        return Paragraph
    end

    function Plugins:Button(Section, Args, Callback)
        return Section:Button({
            Title = Args[1],
            Description = Args[2],
            Type = Args[3] or "Primary",
            Callback = Callback,
        })
    end

    function Plugins:Toggle(Section, Args, Flag, Callback)
        local Thread = nil

        self.Fallback[ Flag ] = Section:Toggle({
            Title = Args[1],
            Description = Args[2],
            Value = Settings[Flag],
            Callback = function(_, Value)
                Settings[ Flag ] = Value
                self.Enableds[ Flag ] = Value

                if Value and self.Threads[ Flag ] ~= nil then
                    Thread = task.spawn(self.Threads[ Flag ], Value)
                else
                    if Thread then task.cancel(Thread) end
                end

                if Callback then Callback(Value) end
            end
        })

        return self.Fallback[Flag]
    end

    function Plugins:Slider(Section, Args, Values, Flag, Callback)
        return Section:Slider({
            Title = Args[1],
            Description = Args[2],
            Min = Values[1],
            Max = Values[2],
            Rounding = Values[3],
            Value = Settings[Flag],
            Callback = function(self, Value)
                Settings[ Flag ] = Value
                if Callback then Callback(Value) end
            end
        })
    end

    function Plugins:Dropdown(Section, Title, List, Flag, Callback)
        return Section:Dropdown({
            Title = Title,
            Value = Settings[Flag] or "None",
            List = List,
            Callback = function(Value)
                Settings[Flag] = Value
                if Callback then Callback(Value) end
            end
        })
    end

    function Plugins:Textbox(Section, Args, Flag, Callback)
        return Section:Textbox({
            Title = Args[1],
            Description = Args[2],
            Value = Settings[Flag] or "None",
            Callback = function(Value)
                Settings[Flag] = Value
                if Callback then Callback(Value) end
            end,
        })
    end

    function Plugins:Community()
        local Community = self:MakeTab({
            "Community", "Integration", 115960025411300
        }) do
            Community:Section("Community", function(self)
                Plugins:Button(self, {
                    "Discord",
                    "Join our community."
                }, function()
                    pcall(Cache.setclipboard, "https://discord.gg/Q2jyDsT9yv")

                    Plugins:Notify({
                        "Copy Discord", "Copy success.", 116378866141355
                    })
                end)
            end)
        end
    end

    function Plugins:Managers()
        local Managers = self:MakeTab({
            "Managers", "Extension", 127866486547434
        }) do
            Managers:Section("Developing", function(self)
                Plugins:Button(self, {
                    "Copy Error",
                    "Copy all errors that have occurred.",
                    "Secondary"
                }, function()
                    pcall(Cache.setclipboard, TableToString(Errors))

                    Plugins:Notify({
                        "Copy Error", "Copy success.", 116378866141355
                    })
                end)

                Plugins:Button(self, {
                    "Remove Worksapce",
                    "Reset save setting file to default value.",
                    "Danger"
                }, function()
                    local Json = Configable.Json

                    if Json and Cache.isfile(Json) then
                        pcall(Cache.delfile, Json)
                    end
                end)
            end)

            Managers:Section("Server", function(self)
                Configable:Default("JobId", JobId)

                Plugins:Textbox(self, { 
                    "JobId",
                    "Put the job id."
                }, 'JobId')

                Plugins:Button(self, {
                    "Join",
                    "Connect to the server using the provided JobId.",
                }, function()
                    EachOthers:Join(Settings.JobId)
                end)

                Plugins:Button(self, {
                    "Change",
                    "Teleport to a different public server instance.",
                    "Secondary"
                }, function()
                    task.spawn(function()
                        Plugins:Notify({
                            "Server", "Wait for hopping .", 105706502741449
                        })

                        EachOthers:Change()
                    end)
                end)

                Plugins:Button(self, {
                    "Rejoin",
                    "Reconnect to the current server instance.",
                    "Secondary"
                }, function()
                    EachOthers:Rejoin()
                end)
            end)

            Managers:Section("Optimize", function(self)
                Plugins:Toggle(self, {
                    "White Screen",
                    "Disabled 3D Rendering to improve performance."
                }, "White Screen", function(value)
                    EachOthers:Set3d(value)
                end)

                Plugins:Button(self, { 
                    "Fast Mode",
                    "Set graphics quality to low."
                }, function()
                    EachOthers:Low()
                    Plugins:Notify({
                        "Fast Mode", "Has been enabled.", 140109651313859
                    })
                end)
            end)
        end
    end

    return Plugins
end)

NewPackage("TweenManager", function()
    local TweenManager = {}
    TweenManager.__index = TweenManager

    local Tweens = {}
    local EasingStyle = Enum.EasingStyle.Linear

    function TweenManager.new(Object, Time, Property, Value)
        local self = setmetatable({}, TweenManager)

        self.Value = Value
        self.Object = Object

        self.Info = TweenInfo.new(Time, EasingStyle)
        self.Tween = TweenService:Create(Object, self.Info, {
            [ Property ] = Value
        })

        self.Tween:Play()

        if Tweens[ Object ] then
            Tweens[ Object ]:Destroy()
        end

        Tweens[ Object ] = self

        return self
    end

    function TweenManager:Destroy()
        self.Tween:Pause()
        self.Tween:Destroy()

        Tweens[ self.Object ] = nil
        setmetatable(self, nil)
    end

    function TweenManager:StopTween(Object)
        if Object and Tweens[ Object ] then
            Tweens[ Object ]:Destroy()
        end
    end

    return TweenManager
end)

NewPackage("BodyVelocity", function()
    local Connectors = Packages.Connectors

    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character and Character:WaitForChild('Humanoid', 10)
    local HumanoidRootPart = Character and Character:WaitForChild('HumanoidRootPart', 10)

    local BodyVelocity = Instance.new("BodyVelocity") do
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVelocity.P = 1000
    end

    local Highlight = Instance.new("Highlight") do
        Highlight.FillColor = Color3.fromRGB(255, 255, 255)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = 0.3
    end

    if _ENV.tween_bodyvelocity then
        _ENV.tween_bodyvelocity:Destroy()
    end

    if _ENV.highlight then
        _ENV.highlight:Destroy()
    end

    _ENV.highlight = Highlight
    _ENV.tween_bodyvelocity = BodyVelocity

    local CanCollideObjects = {}

    local function AddObjectToBaseParts(Object)
        if Object:IsA("BasePart") and Object.CanCollide then
            table.insert(CanCollideObjects, Object)
        end
    end

    local function RemoveObjectsFromBaseParts(BasePart)
        local index = table.find(CanCollideObjects, BasePart)

        if index then
            table.remove(CanCollideObjects, index)
        end
    end

    local function NewCharacter(Character)
        table.clear(CanCollideObjects)

        for _, Object in Character:GetDescendants() do AddObjectToBaseParts(Object) end
        Character.DescendantAdded:Connect(AddObjectToBaseParts)
        Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
    end

    Connectors.Connect(LocalPlayer.CharacterAdded, NewCharacter)
    task.spawn(NewCharacter, Character)

    local function NoClipOnStepped(Character)
        if _ENV.OnFarm then
            for i = 1, #CanCollideObjects do
                CanCollideObjects[i].CanCollide = false
            end
        elseif Character.PrimaryPart and not Character.PrimaryPart.CanCollide then
            for i = 1, #CanCollideObjects do
                CanCollideObjects[i].CanCollide = true
            end
        end
    end

    local function IsAlive()
        if not Character then return end
        if not Humanoid then return end
        if not HumanoidRootPart then return end

        return (Humanoid and Humanoid.Health > 0) or HumanoidRootPart ~= nil
    end

    local function UpdateVelocityOnStepped(Character)
        local BasePart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")

        local BodyVelocity = _ENV.tween_bodyvelocity
        local Highlight = _ENV.highlight

        if _ENV.OnFarm and BasePart and Humanoid and Humanoid.Health > 0 then
            if BodyVelocity.Parent ~= BasePart then
                BodyVelocity.Parent = BasePart
            end

            if Highlight.Parent ~= Character then
                Highlight.Parent = Character
            end
        elseif BodyVelocity.Parent then
            BodyVelocity.Parent = nil
            Highlight.Parent = nil
        end

        if BodyVelocity.Velocity ~= Vector3.zero and (not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm) then
            BodyVelocity.Velocity = Vector3.zero
            Highlight.Parent = nil
        end
    end

    Connectors.Connect(RenderStepped, function()
        if IsAlive() then
            UpdateVelocityOnStepped(Character)
            NoClipOnStepped(Character)
        end
    end)

    Connectors.Connect(LocalPlayer.CharacterAdded, function(v)
        Character = v
        Humanoid = v:WaitForChild("Humanoid", 10)
        HumanoidRootPart = v:WaitForChild("HumanoidRootPart", 10)
    end)

    return BodyVelocity
end)

return Packages, Settings
