local Packages, Settings = ...

assert(Packages, "Packages timed out.")
assert(Settings, "Settings timed out.")

local _ENV = (getgenv or getrenv or getfenv)()

local Module, Cache = {}, {} do
    Cache.Equipped = nil
    Cache.Enemies = {}
    Cache.Bring = {}
end

local Connectors = Packages.Connectors
local Importer = Packages.Importer

local Connect = Connectors.Connect

function NewModule(Name, Function)
    do Module[Name] = Function(Module)
        return Module[Name]
    end
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local ChestModels = workspace:WaitForChild("ChestModels")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local NPCs = workspace:WaitForChild("NPCs")
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Effect = ReplicatedStorage:WaitForChild('Effect')

local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild("CommE")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped

local KeyboardEnabled = UserInputService.KeyboardEnabled
local TouchEnabled = UserInputService.TouchEnabled

local getnamecallmethod = getnamecallmethod or (function( ... ) return ... end)
local hookmetamethod = hookmetamethod or (function( ... ) return ... end)
local hookfunction = hookfunction or (function( ... ) return ... end)

local sethiddenproperty = sethiddenproperty or (function( ... ) return ... end)
local restorefunction = restorefunction or (function( ... ) return ... end)
local getsenv = getsenv or (function( ... ) return ... end)

local ServerOwnerId = ReplicatedStorage:FindFirstChild("PrivateServerOwnerId")
local IsPrivateServer = ServerOwnerId and ServerOwnerId.Value ~= 0 or true

local KILLAURA_TAG = _ENV.TAGS_KILLABLE or tostring(math.random(120, 2e4))
local BRING_TAG = _ENV.TAGS_BRINGABLE or tostring(math.random(80, 2e4))

local HIDDEN_SETTINGS = {} do
    _ENV.TAGS_KILLABLE = KILLAURA_TAG
    _ENV.TAGS_BRINGABLE = BRING_TAG
    
    HIDDEN_SETTINGS.WATER_Y = 120
end

local function GetEnemyName(strings)
    return (strings:find("Lv. ") and strings:gsub(" %pLv. %d+%p", "") or strings):gsub(" %pBoss%p", "")
end

local function CreateDictionary(Array, Value)
    local Dictionary = {}

    for _, strings in Array do
        Dictionary[ strings ] = type(Value) == "table" and {} or Value
    end

    return Dictionary
end

local function ValidData(Filter, Enemy)
    if Filter == nil then return true end

    if type(Filter) == "table" then
        return table.find(Filter, Enemy.Name) ~= nil
    end

    if type(Filter) == "string" then
        return Enemy.Name == Filter
    end

    return false
end

Module.PirateRaid = 0 do
    Module.IsSuperBring = false

    Module.EnemyLocations = {}
    Module.SpawnLocations = {}

    Module.IsPrivateService = IsPrivateServer
    Module.IsMobile = TouchEnabled and not KeyboardEnabled and true or false

    Module.SeaName = { "Main", "Dressrosa", "Zou" }
    Module.Sea = tonumber(workspace:GetAttribute("MAP"):match("^Sea(%d+)$") ) or 1
end

NewModule("SkillManagers", function()
    return Importer("Modules/SkillManagers")(
        Module, Settings, Connect
    )
end)

NewModule("RaidList", function()
    local Success, RaidModule = pcall(require, ReplicatedStorage:WaitForChild("Raids"))

    if not Success or type(RaidModule) ~= "table" then
        return {
            "Phoenix", "Dough", "Flame", "Ice", "Quake", "Light",
            "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand",
        }
    end

    local AdvancedRaids = RaidModule.advancedRaids or {}
    local NormalRaids = RaidModule.raids or {}

    local RaidList = {}

    for i = 1, #AdvancedRaids do table.insert(RaidList, AdvancedRaids[i]) end
    for i = 1, #NormalRaids do table.insert(RaidList, NormalRaids[i]) end

    return RaidList
end)

NewModule("GoodSignal", function()
    local Signal = {}
    local Connection = {}

    Connection.__index = Connection
    Signal.__index = Signal

    function Connection:Disconnect()
        if not self.Connected then
            return
        end

        local find = table.find(self.Signal._connections, self)

        if find then
            table.remove(self.Signal._connections, find)
        end

        self.Function = nil
        self.Connected = false
    end

    function Connection:Fire(...)
        if self.Function then
            task.spawn(self.Function, ...)
        end
    end

    function Signal.new()
        return setmetatable({
            _connections = {}
        }, Signal)
    end

    function Signal:Connect(fn)
        local connection = setmetatable({
            Signal = self,
            Function = fn,
            Connected = true
        }, Connection)

        table.insert(self._connections, connection)
        return connection
    end

    function Signal:Fire(...)
        for _, connection in ipairs(self._connections) do
            connection:Fire(...)
        end
    end

    return Signal
end)

NewModule("HumanoidManager", function()
    local HumanoidManager = {}

    HumanoidManager.HumanoidsCache = (function()
        local HumanoidsCache = {} do
            HIDDEN_SETTINGS.COUNT_NEWINDEX = 0
            HIDDEN_SETTINGS.MAX_NEWINDEX = 50
        end

        HumanoidsCache.__newindex = function(self, Index, Value)
            if HIDDEN_SETTINGS.COUNT_NEWINDEX >= HIDDEN_SETTINGS.MAX_NEWINDEX then
                for Index, Cache in pairs(self) do
                    if typeof(Cache) ~= 'Instance' then
                        continue
                    end

                    if not Cache:IsDescendantOf(game) then
                        rawset(self, Index, nil)
                    end
                end

                HIDDEN_SETTINGS.COUNT_NEWINDEX = 0
            end

            HIDDEN_SETTINGS.COUNT_NEWINDEX += 1
            return rawset(self, Index, Value)
        end

        HumanoidsCache.__index = function(self, Character)
            local Property = Character.Parent == SeaBeasts and "Health" or "Humanoid"
            local Humanoid = Character:FindFirstChild(Property)

            if Humanoid then
                rawset(self, Character, Humanoid)
            end

            return Humanoid
        end

        return setmetatable({}, HumanoidsCache)
    end)()

    function HumanoidManager:GetHumanoidHealth(Humanoid)
        return Humanoid[ Humanoid.ClassName == "Humanoid" and "Health" or "Value" ]
    end

    function Module:IsAlive(Character)
        Character = Character or Player.Character

        local Humanoid = HumanoidManager.HumanoidsCache[ Character ]

        if Humanoid then
            return HumanoidManager:GetHumanoidHealth(Humanoid) > 0
        end

        return Character.Parent == Boats
    end

    function Module:IsAlly(Target)
        if Target.Parent == Characters then
            Target = Players:GetPlayerFromCharacter(Target)
        end

        if not Target then return false end

        if tostring(Target.Team) == "Marines" and Target.Team == Player.Team then
            return false
        elseif Target:HasTag(`Ally{Player.Name}`) or Player:HasTag(`Ally{Target.Name}`) then
            return false
        end

        return true
    end

    return HumanoidManager
end)

NewModule("CalculateManager", function()
    local Calculates = {}

    Calculates.Handlers = (function()
        local Handlers = {}

        Handlers.CFrame = function(Coordinate)
            return Coordinate.Position
        end

        Handlers.Vector3 = function(Position)
            return Position
        end

        Handlers.Instance = function(Object)
            if Object:IsA("Model") then
                return Object:GetPivot().Position
            elseif Object:IsA("BasePart") then
                return Object.Position
            elseif Object:IsA("Attachment") then
                return Object.WorldPosition
            end

            error(("Unsupported instance type: %s"):format(Object.ClassName))
        end

        return Handlers
    end)()

    Calculates.Positions = setmetatable({}, {
        __index = function(self, Value)
            local Type = typeof(Value)
            local Handler = Calculates.Handlers[ Type ]

            assert(Handler, ("Unsupported type: %s"):format(Type))

            return Handler(Value)
        end,
    })

    function Module:ToDistance(Value)
        Value = Calculates.Positions[ Value ]
        return Player:DistanceFromCharacter(Value)
    end

    function Module:ToUnit(Value)
        local Character = Player.Character

        if not Character then return end

        local Current = Character:GetPivot().Position
        local Result = Calculates.Positions[ Value ]

        return (Result - Current).Unit
    end
    
    function Module:FormatCommas(Number)
        if typeof(Number) == 'string' then return Number end

        local Formatted = tostring(Number)
        local Left, Num, Right = string.match(
            Formatted, '^([^%d]*%d)(%d*)(.-)$'
        )

        Num = Num:reverse():gsub('(%d%d%d)', '%1,'):reverse()
        Num = Num:gsub('^,', '')

        return Left, Num, Right
    end

    function Module:MatchString(v1, v2)
        local String = tostring(v1)

        if type(v2) == "string" then
            return String:find(v2, 1, true) ~= nil
        end

        for _, v in v2 do
            if String:find(v, 1, true) ~= nil then
                return true
            end
        end
    end
    
    function Module:DiffVector(Offset)
        return {
            Vector3.new(0, 0, Offset),
            Vector3.new(0, 0, -Offset),
            Vector3.new(Offset, 0, 0),
            Vector3.new(-Offset, 0, 0)
        }
    end
end)

NewModule("NetworkManager", function()
    local NetworkManager = {}
    local Net = require(Modules:WaitForChild("Net"))

    function Module:Send(IsEvent, Name, ...)
        local Remote = Cache[Name]

        if not Remote then
            if IsEvent then
                Remote = Net:RemoteEvent(Name)
            else
                Remote = Net:RemoteFunction(Name)
            end

            Cache[Name] = Remote
        end

        if IsEvent then
            return Remote:FireServer(...)
        end

        return Remote:InvokeServer(...)
    end
    
    function Module:TravelTo(Sea)
        self:ComF(`Travel{self.SeaName[Sea]}`)
    end

    function Module:ComF(...)
        return CommF:InvokeServer(...)
    end

    function Module:ComE(...)
        return CommE:FireServer(...)
    end

    return NetworkManager
end)

NewModule("FastAttack", function()
    local FastAttack = {} do
        FastAttack.Cooldown = 0.5
        FastAttack.Distance = 50

        FastAttack.ThreadId = (function()
            local UserId = tostring(Player.UserId)
            local Coroutine = tostring( coroutine.running() )

            return `{UserId:sub(2, 4)}{Coroutine:sub(11, 15)}`
        end)()

        FastAttack.Guns = Importer('Modules/GunManagers')()
    end

    local CurrentBladeHits = {} do
        Module.Closest = nil
        Module.LocalPosition = nil 
    end

    local HitboxLimbs = {
        "RightLowerArm", "RightUpperArm", "LeftLowerArm",
        "LeftUpperArm", "RightHand", "LeftHand"
    }

    function FastAttack:GetRandomHitboxLimb(Character)
        return Character:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)])
    end

    function FastAttack:ProcessHits(Folder, Distance)
        local Character = Player.Character
        local Targets = Folder:GetChildren()

        for i = 1, #Targets do
            local Enemy = Targets[i]

            if Enemy == Character then continue end

            if not Module:IsAlive(Enemy) then continue end

            if Enemy:GetAttribute("IsBoat") then continue end

            local PrimaryPart = Enemy.PrimaryPart
            local IsAlly = Enemy.Parent ~= Characters or Module:IsAlly(Enemy)

            if PrimaryPart and IsAlly then
                local Hitbox = self:GetRandomHitboxLimb(Enemy) or PrimaryPart

                if Hitbox and Module:ToDistance(PrimaryPart.Position) <= Distance then
                    table.insert(CurrentBladeHits, { Enemy, Hitbox })
                end
            end
        end
    end

    function FastAttack:UpdateBladeHits(Distance)
        Distance = Distance or self.Distance
        CurrentBladeHits = {}

        self:ProcessHits(Enemies, Distance)
        
        if Settings['Attack Players'] then
            self:ProcessHits(Characters, Distance) 
        end

        return true
    end

    function FastAttack:GetClosest(Distance)
        Distance = Distance or self.Distance

        local Distance, Closest = math.huge, nil

        for i = 1, #CurrentBladeHits do
            local Enemy = CurrentBladeHits[i]

            local Position = Enemy[2].Position
            local Absolute = Closest and (Closest.Position - Position)
            local Magnitude = Absolute and Absolute.Magnitude or Distance

            if Magnitude <= Distance then
                Distance, Closest = Magnitude, Enemy[2]
            end
        end

        Module.Closest = Closest
        return Closest
    end

    function FastAttack:SendHits(Closest, Targets)
        Module:Send(true, "RegisterAttack", 0.5)

        if self.HIT_FUNCTION then
            self.HIT_FUNCTION(Closest, Targets, nil, self.ThreadId)
        else
            Module:Send(true, "RegisterHit", Closest, Targets, nil, self.ThreadId)
        end
    end

    function FastAttack:SendSlash(Equipped, Closest)
        local LeftClick = Equipped:FindFirstChild("LeftClickRemote")

        if not LeftClick then return end

        LeftClick:FireServer(false)
        LeftClick:FireServer(Module:ToUnit(Closest), 2)
    end

    Connect(Stepped, function()
        local self = FastAttack

        if not Settings['Fast Attack'] then return end
        if not Module:IsAlive() then return end

        local Character = Player.Character
        if not Character then return end

        local Equipped = Character and Character:FindFirstChildOfClass("Tool")
        if not Equipped then return end

        Module.LocalPosition = Character:GetPivot().Position

        local ToolTip = Equipped.ToolTip
        local Name = Equipped.Name

        if ToolTip == 'Gun' then 
            return self.Guns:FireTarget(Equipped, Character)
        end

        self:UpdateBladeHits()

        local Closest = self:GetClosest()
        if not Closest then return end

        if Name == 'Ice-Ice' or Name == 'Light-Light' then
            return self:SendHits(Closest, CurrentBladeHits)
        elseif ToolTip == 'Blox Fruit' then
            return self:SendSlash(Equipped, Closest)
        else
            self:SendHits(Closest, CurrentBladeHits)
        end
    end)

    task.defer(pcall, function()
        local PlayerScripts = Player.PlayerScripts
        local LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")

        while not LocalScript do
            PlayerScripts.ChildAdded:Wait()
            LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")
        end

        local Success, Environtment = pcall(getsenv, LocalScript)

        if Success and Environtment then
            if Environtment._G.SendHitsToServer then
                FastAttack.HIT_FUNCTION = Environtment._G.SendHitsToServer
            end
        end
    end)

    return FastAttack
end)

NewModule("DataManagers", function()
    local DataManagers = Importer('Modules/DataModule')(Module.Sea)
    local Currently = DataManagers.Currently

    function DataManagers:GetByMaterial(Material)
        return Currently.Materials[Material] or {}
    end

    local function NewData(Instancer)
        if not Instancer.ClassName:find('Value') then
            return false
        end
        
        local Name = Instancer.Name
        if not DataManagers[Name] then
            DataManagers[Name] = Instancer.Value

            Connect(Instancer:GetPropertyChangedSignal('Value'), function()
                DataManagers[Name] = Instancer.Value
            end)
        end
    end

    for _, Instance in Player.Data:GetChildren() do NewData(Instance) end
    Connect(Player.Data.ChildAdded, NewData)

    return DataManagers
end)

NewModule("InventoryModule", function()
    local InventoryModule = {} do
        InventoryModule.Requirements = {}
        InventoryModule.Unlocked = {}
        InventoryModule.Mastery = {}
        InventoryModule.Items = {}
        InventoryModule.Count = {}
    end
    
    function InventoryModule:HasFruit(Container)
        if not Container then return false end
        
        local Objects = Container:GetChildren()
        
        for i = 1, #Objects do
            local Object = Objects[i]
            
            if Object.Name:find("Fruit") then
                return true
            end
        end
    end

    function InventoryModule:HaveFruit(Character, Backpack)
        Character = Character or Player.Character
        Backpack = Backpack or Player:FindFirstChildOfClass("Backpack")

        return self:HasFruit(Character) or self:HasFruit(Backpack)
    end

    function InventoryModule:GetFruits(IsHigh)
        local Collects, Threshold = {}, 999999
        local Fruits = Module:ComF("GetFruits")
        
        for i = 1, #Fruits do
            local Fruit = Fruits[i]
            
            local Price = Fruit.Price or 0
            local Name = Fruit.Name or "Unknow"
            
            if (Price >= Threshold) == IsHigh then
                Collects[ Name ] = Price
            end
        end

        return Collects
    end 

    function InventoryModule:GetFruit(IsHigh)
        local Target, Lowest = nil, math.huge
        local Fruits = self:GetFruits(IsHigh)

        for _, Item in Module:ComF("getInventory") do
            local Value = Item.Type == "Blox Fruit" and Fruits[ Item.Name ]

            if Value and Value < Lowest then
                Lowest, Target = Value, Item.Name
            end
        end

        return Target
    end

    function InventoryModule:LoadFruit(IsHigh)
        if self:HaveFruit() then return  end

        local Fruit = self:GetFruit(IsHigh)
        if not Fruit then return end

        return Module:ComF("LoadFruit", Fruit)
    end

    function InventoryModule:UpdateItem(Item)
        if type(Item) == "table" then
            if Item.Type == "Wear" then
                Item.Type = "Accessory"
            end

            local Name = Item.Name do
                self.Items[Name] = Item
            end

            if not self.Unlocked[Name] then
                self.Unlocked[Name] = true
            end
            
            if Item.Count then
                self.Count[Name] = Item.Count
            end
            
            if Item.Mastery then
                self.Mastery[Name] = Item.Mastery
            end
            
            if Item.MasteryRequirements then
                self.Requirements[Name] = Item.MasteryRequirements
            end
        end
    end
    
    function InventoryModule:CanUseGate()
        return Module.Sea ~= 3 or self.Unlocked['Valkyrie Helm']
    end

    function InventoryModule:RemoveItem(ItemName)
        if type(ItemName) == "string" then
            self.Unlocked[ItemName] = nil
            self.Mastery[ItemName] = nil
            self.Count[ItemName] = nil
            self.Items[ItemName] = nil
        end
    end
    
    function InventoryModule:HaveItem(Name, Character, Backpack)
        if self.Unlocked[Name] then
            return true
        end

        Character = Character or Player.Character
        Backpack = Backpack or Player:FindFirstChildOfClass("Backpack")

        if not Character or not Backpack then
            return false
        end

        return Character:FindFirstChild(Name) or Backpack:FindFirstChild(Name)
    end

    local function OnClientEvent(Method, ...)
        if Method == "ItemChanged" then
            InventoryModule:UpdateItem(...)
        elseif Method == "ItemAdded" then
            InventoryModule:UpdateItem(...)
        elseif Method == "ItemRemoved" then
            InventoryModule:RemoveItem(...)
        end
    end

    task.spawn(function()
        Connect(CommE.OnClientEvent, OnClientEvent)

        local InventoryItems = nil

        repeat
            task.wait(1)
            InventoryItems = Module:ComF("getInventory")
        until type(InventoryItems) == "table"

        for index = 1, #InventoryItems do
            InventoryModule:UpdateItem(InventoryItems[index])
        end
    end)

    return InventoryModule
end)

NewModule("StockManager", function()
    return setmetatable({}, {
        __call = function(self, IsAdvanced)
            if not self.Cached then
                self.Cached = require(ReplicatedStorage.Controllers.UI.FruitShop)
            end
            
            return self.Cached.Open(self.Cached, IsAdvanced and "AdvancedFruitDealer")
        end
    })
end)

NewModule("CodeManager", function()
    return setmetatable({}, {
        __call = function()
            local Codes = Importer('Modules/CodesModule')()

            for Code, Text in Codes do
                Remotes.Redeem:InvokeServer(Code)
                warn(Code, Text);
            end
        end,
    })
end)

NewModule("RemoveEffect", function()
    return setmetatable({}, {
        __call = function(self, Value)
            local Container = Effect.Container

            if not self.Death then
                self.Death = require(Container.Death)
            end

            if not self.Respawn then
                self.Respawn = require(Container.Respawn)
            end

            if Value then
                pcall(hookfunction, self.Death, function( ... )
                    return ( ... )
                end)

                pcall(hookfunction, self.Respawn, function( ... )
                    return ( ... )
                end)
            else
                pcall(restorefunction, self.Death)
                pcall(restorefunction, self.Respawn)
            end
        end,
    })
end)

NewModule("EnemiesModule", function()
    local EnemiesModule = CreateDictionary({
        "__CakePrince", "__PirateRaid", "__RaidBoss", "__TyrantSkies", "__Bones", "__Elite", "__Others", 
    }, {})

    local SeaCastle = CFrame.new(-5556, 314, -2988) do
        Cache.Enemies = {}
        Cache.Bring =  {}
    end

    local TagsMobs = {
        __Elite = CreateDictionary({ "Deandre", "Diablo", "Urban", "Tyrant of the skies" }, true),
        __Bones = CreateDictionary({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }, true),
        __CakePrince = CreateDictionary({ "Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter" }, true),
        __TyrantSkies = CreateDictionary({ "Sun-kissed Warrior", "Skull Slayer", "Isle Champion", "Serpent Hunter" }, true)
    }

    local Attachment = Instance.new("Attachment") do
        local AlignPosition = Instance.new("AlignPosition")
        AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPosition.Position = Vector3.new(0, 20, 0)
        AlignPosition.Responsiveness = 200
        AlignPosition.MaxForce = math.huge
        AlignPosition.Parent = Attachment
        AlignPosition.Attachment0 = Attachment
    end

    local function New(list, NewEnemy)
        if table.find(list, NewEnemy) then return end

        local Humanoid = NewEnemy:WaitForChild("Humanoid")

        if Humanoid and Humanoid.Health > 0 then
            table.insert(list, NewEnemy)
            Humanoid.Died:Wait()
            local index = table.find(list, NewEnemy)
            if index then table.remove(list, index) end
        end
    end

    local function IsFromPiratesSea(Enemy)
        if not Enemy:WaitForChild("Humanoid") or Enemy.Humanoid.Health <= 0 then return end

        local HumanoidRootPart = Enemy:WaitForChild("HumanoidRootPart")

        if HumanoidRootPart and (Enemy.Name ~= "rip_indra True Form" and Enemy.Name ~= "Blank Buddy") then
            if (HumanoidRootPart.Position - SeaCastle.Position).Magnitude <= 750 then
                task.spawn(New, EnemiesModule.__PirateRaid, Enemy)
                Module.PirateRaid = tick()
            end
        end
    end

    local function NewEnemyAdded(Enemy)
        local EnemyName = Enemy.Name
        local Others = EnemiesModule.__Others

        Others[EnemyName] = Others[EnemyName] or {}
        task.spawn(New, Others[EnemyName], Enemy)

        if Module.Sea == 3 then
            task.spawn(IsFromPiratesSea, Enemy)
        end

        if Enemy:GetAttribute("RaidBoss") then
            task.spawn(New, EnemiesModule.__RaidBoss, Enemy)
        elseif EnemiesModule["__" .. EnemyName] then
            task.spawn(New, EnemiesModule["__" .. EnemyName], Enemy)
        else
            for Tag, Mobs in pairs(TagsMobs) do
                if Mobs[EnemyName] then
                    task.spawn(New, EnemiesModule[Tag], Enemy)
                    break
                end
            end
        end
    end

    function EnemiesModule:IsSpawned(EnemyName)
        local Cached = Module.SpawnLocations[EnemyName]

        if Cached and Cached.Parent then
            return (Cached:GetAttribute("Active") or EnemiesModule:GetEnemyByTag(EnemyName)) and true or false
        end

        return EnemiesModule:GetEnemyByTag(EnemyName) and true or false
    end

    function EnemiesModule:GetTagged(TagName)
        return self["__" .. TagName] or self.__Others[TagName]
    end

    function EnemiesModule:GetEnemyByTag(TagName)
        local CachedEnemy = Cache.Enemies[TagName]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Enemies = self:GetTagged(TagName)

        if Enemies and #Enemies > 0 then
            for i = 1, #Enemies do
                local Enemy = Enemies[i]

                if Module:IsAlive(Enemy) then
                    Cache.Enemies[TagName] = Enemy
                    return Enemy
                end
            end
        end
    end

    function EnemiesModule:GetClosest(Enemies)
        local SpecialTag = table.concat(Enemies, ".")
        local CachedEnemy = Cache.Enemies[SpecialTag]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Distance, Nearest = math.huge, nil

        for i = 1, #Enemies do
            local Enemy = self:GetClosestByTag(Enemies[i])
            local Magnitude = Enemy and Module:ToDistance(Enemy)

            if Enemy and Magnitude <= Distance then
                Distance, Nearest = Magnitude, Enemy
            end
        end

        if Nearest then
            Cache.Enemies[SpecialTag] = Nearest
            return Nearest
        end
    end

    function EnemiesModule:GetClosestByTag(TagName)
        local CachedEnemy = Cache.Enemies[TagName]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Enemies = self:GetTagged(TagName)

        if Enemies and #Enemies > 0 then
            local Distance, Nearest = math.huge, nil

            for i = 1, #Enemies do
                local Enemy = Enemies[i]
                local PrimaryPart = Enemy.PrimaryPart

                if PrimaryPart and Module:IsAlive(Enemy) then
                    local Magnitude = Module:ToDistance(PrimaryPart)

                    if Magnitude <= 15 then
                        Cache.Enemies[TagName] = Enemy
                        return Enemy
                    elseif Magnitude <= Distance then
                        Distance, Nearest = Magnitude, Enemy
                    end
                end
            end

            if Nearest then
                Cache.Enemies[TagName] = Nearest
                return Nearest
            end
        end
    end

    function EnemiesModule:GetEnemies(Range, Names)
        local Distance, Nearest = Range or math.huge, nil
        local EnemiesList = Enemies:GetChildren()

        for i = 1, #EnemiesList do
            local Enemy = EnemiesList[i]

            if not Enemy.PrimaryPart then continue end
            if not ValidData(Names, Enemy) then continue end
            if not Module:IsAlive(Enemy) then continue end

            local Magnitude = Module:ToDistance(Enemy)

            if Magnitude < Distance then
                Distance = Magnitude
                Nearest = Enemy
            end
        end

        return Nearest
    end

    local function Bring(Enemy)
        local RootPart = Enemy:WaitForChild("HumanoidRootPart")
        local Humanoid = Enemy:WaitForChild("Humanoid")
        local EnemyName = Enemy.Name

        local CloneAttachment = Attachment:Clone()
        local AlignPosition = CloneAttachment.AlignPosition
        CloneAttachment.Parent = RootPart

        while Enemy and Enemy.Parent == Enemies and Enemy:HasTag(BRING_TAG) do
            if not Humanoid or Humanoid.Health <= 0 then break end
            if not RootPart or RootPart.Parent ~= Enemy then break end

            local Target = Cache.Bring[ Module.IsSuperBring and "ALL_MOBS" or EnemyName ]

            if Target and (Target.Position - RootPart.Position).Magnitude <= Settings["Bring Distance"] then
                if AlignPosition.Position ~= Target.Position then
                    AlignPosition.Position = Target.Position
                end
            else
                break
            end;task.wait()
        end

        if Enemy and Enemy:HasTag(BRING_TAG) then Enemy:RemoveTag(BRING_TAG) end
        if CloneAttachment then CloneAttachment:Destroy() end
    end

    local function KillAura(Enemy)
        local Humanoid = Enemy:FindFirstChild("Humanoid")
        local RootPart = Enemy:FindFirstChild("HumanoidRootPart")

        pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

        if Humanoid and RootPart then
            RootPart.CanCollide = false
            RootPart.Size = Vector3.new(60, 60, 60)
            Humanoid:ChangeState(15)
            Humanoid.Health = 0
            task.wait()
            Enemy:RemoveTag(KILLAURA_TAG)
        end
    end

    for _, Enemy in CollectionService:GetTagged("BasicMob") do NewEnemyAdded(Enemy) end
    Connect(CollectionService:GetInstanceAddedSignal("BasicMob"), NewEnemyAdded)
    Connect(CollectionService:GetInstanceAddedSignal(KILLAURA_TAG), KillAura)
    Connect(CollectionService:GetInstanceAddedSignal(BRING_TAG), Bring)

    return EnemiesModule
end)

NewModule("QuestManager", function()
    local EnemiesModule = Module.EnemiesModule
    local DataManagers = Module.DataManagers

    local Currently = DataManagers.Currently

    local QuestManager = {} do
        QuestManager.Blacklist = { "BartiloQuest", "MarineQuest", "CitizenQuest", "ImpelQuest" }
        QuestManager.GuideModule = require(ReplicatedStorage:WaitForChild('GuideModule'))
        QuestManager.Quests = require(ReplicatedStorage:WaitForChild('Quests')) 
    end

    function QuestManager:Pack(Data, Levels)
        return Data[ tostring(math.max(unpack(Levels))) ]
    end

    function QuestManager:GetMonster(CurrentLevel)
        local Data, Levels = {}, {}
        local Maximum = ({ {0, 700}, {700, 1500}, {1500, math.huge} })[ Module.Sea ]

        for Name, Task in self.Quests do
            if table.find(self.Blacklist, Name) then continue end

            for Number, Mission in Task do
                local Level = Mission.LevelReq
                local Monster, Value = next(Mission.Task)

                if Level >= Maximum[1] and Level < Maximum[2] and CurrentLevel >= Level and Value > 1 then
                    table.insert(Levels, Level)

                    Data[ tostring(Level) ] = {
                        Name = Mission.Name,
                        Level = Number,
                        Monster = Monster,
                    }
                end
            end
        end

        if #Levels == 0 then return nil end

        return self:Pack(Data, Levels)
    end

    function QuestManager:NPCsData(CurrentLevel)
        local Data, Levels = {}, {}

        for _, Npcs in self.GuideModule.Data.NPCList do
            if not Npcs.InternalQuestName then continue end

            if not table.find(self.Blacklist, Npcs.InternalQuestName) then
                local Level = Npcs.Levels[1]

                if CurrentLevel >= Level then
                    table.insert(Levels, Level)
                    Data[ tostring(Level) ] = {
                        Position = Npcs.Position,
                        Quest = Npcs.InternalQuestName,
                    }
                end 
            end
        end

        if #Levels == 0 then return nil end

        return self:Pack(Data, Levels)
    end

    function QuestManager:GetBossData(CurrentLevel)
        local BestBoss, BestLevel = nil, -math.huge

        for Name, Data in Currently.Bosses do
            local Level = Data.Level
            local Quest = Data.Quest

            if Level <= CurrentLevel and Level > BestLevel then
                BestLevel = Level

                BestBoss = {
                    Name = Name,
                    Monster = Name,
                    Quest = Quest[1],
                    Position = Quest[2],
                    Level = Quest[3] or 3
                }
            end
        end

        if BestBoss and EnemiesModule:GetClosestByTag(BestBoss.Monster) then
            return BestBoss
        end
    end

    function QuestManager:GetQuest()
        local Level = DataManagers.Level

        if Level == 1 and Level <= 9 then
            if tostring(Player.Team) == "Marines" then
                return {
                    Name = "Trainees",
                    Monster = "Trainee",
                    Level = 1,
                    Quest = "MarineQuest",
                    Position = CFrame.new(-2711, 24, 2104),
                }
            elseif tostring(Player.Team) == "Pirates" then
                return {
                    Name = "Bandits",
                    Monster = "Bandit",
                    Level = 1,
                    Quest = "BanditQuest1",
                    Position = CFrame.new(1059, 15, 1550),
                }
            end
        else
            local BossData = self:GetBossData(Level)
            if BossData then return BossData end

            local Data = self:GetMonster(Level)
            if not Data then return end

            local NPCsData = self:NPCsData(Level)
            if not NPCsData then return end

            Data.Quest = NPCsData.Quest
            Data.Position = CFrame.new(NPCsData.Position)

            return Data
        end
    end

    return QuestManager
end)

NewModule("PlayerManagers", function()
    local PlayerManagers = {}
    
    function Module:EquipTool(ToolName, ByType)
        ByType = ToolName and true or ByType
        ToolName = ToolName or Settings.FarmTool

        if not self:IsAlive(Player.Character) then
            return nil
        end

        local Equipped = Cache.Equipped

        if Equipped and Equipped.Parent and Equipped[ ByType and "ToolTip" or "Name" ] == ToolName then
            if Equipped:GetAttribute("Locks") then
                Equipped:SetAttribute("Locks", nil)
            end

            if Equipped.Parent == Player.Character then
                return nil
            elseif Equipped.Parent == Player.Backpack then
                Player.Character.Humanoid:EquipTool(Equipped)
                return nil
            end
        end

        if ToolName and not ByType then
            local BackpackTool = Player.Backpack:FindFirstChild(ToolName)

            if BackpackTool then
                Cache.Equipped = BackpackTool
                Player.Character.Humanoid:EquipTool(BackpackTool)
            end
        else
            for _, Tool in Player.Backpack:GetChildren() do
                if Tool:IsA("Tool") and Tool.ToolTip == ToolName then
                    Cache.Equipped = Tool
                    Player.Character.Humanoid:EquipTool(Tool)
                    return nil
                end
            end
        end
    end
    
    function Module:BringEnemies(ToEnemy, SuperBring, CustomCFrame, Distance)
        if not self:IsAlive(ToEnemy) or not ToEnemy.PrimaryPart then
            return nil
        end

        pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

        if Distance or Settings['Enabled Bring'] then
            self.IsSuperBring = SuperBring and true or false

            local Name = ToEnemy.Name
            local BringPositionTag = SuperBring and "ALL_MOBS" or Name
            local Target = CustomCFrame or ToEnemy.PrimaryPart.CFrame
            local MaxDistance = Distance or Settings['Bring Distance']

            if not Cache.Bring[BringPositionTag] or (Target.Position - Cache.Bring[BringPositionTag].Position).Magnitude > 25 then
                Cache.Bring[BringPositionTag] = Target
            end

            local EnemyList = (not SuperBring and self.EnemiesModule:GetTagged(Name)) or Enemies:GetChildren()

            for i = 1, #EnemyList do
                local Enemy = EnemyList[i]

                if (SuperBring or Enemy.Name == Name)
                    and Enemy.Parent == Enemies
                    and not Enemy:HasTag(BRING_TAG)
                    and Enemy:FindFirstChild("CharacterReady") then

                    local PrimaryPart = Enemy.PrimaryPart

                    if Module:IsAlive(Enemy) and PrimaryPart then
                        if Module:ToDistance(PrimaryPart) < MaxDistance then
                            Enemy.Humanoid.WalkSpeed = 0
                            Enemy.Humanoid.JumpPower = 0
                            Enemy:AddTag(BRING_TAG)
                        end
                    end
                end
            end
        else
            if not Cache.Bring[ToEnemy] then
                Cache.Bring[ToEnemy] = ToEnemy.PrimaryPart.CFrame
            end

            ToEnemy.PrimaryPart.CFrame = Cache.Bring[ToEnemy]
        end
    end
    
    return PlayerManagers
end)

NewModule("IndicatorHandler", function()
    local IndicatorHandler = {}
    
    IndicatorHandler.EspHandlers = {}
    Cache.RealFruits = {}
    
    local GearColor = BrickColor.new("Pastel Blue")
    local EspManagers = Importer('Modules/EspManagers')(Module, Settings)
    
    IndicatorHandler.Flowers = {
        Flower1 = "Blue Flower",
        Flower2 = "Red Flower",
    }
    
    IndicatorHandler.Islands = {
        PrehistoricIsland = "Prehistoric Island",
        KitsuneIsland = "Kitsune Island",
        MysticIsland = "Mirage Island",
        FrozenDimension = "Frozen Dimension"
    }

    IndicatorHandler.Berries = {
        "Pink Pig Berry", "Purple Jelly Berry", "Red Cherry Berry",
        "Blue Icicle Berry", "Green Toad Berry", "Orange Berry",
        "White Cloud Berry", "Yellow Star Berry",
    }
    
    IndicatorHandler.RealFruits = {
        "AppleSpawner", "PineappleSpawner", "BananaSpawner"
    }
    
    function IndicatorHandler:Text(Text, Distance)
        if not Settings["Distance Indicator"] then
            return Text
        end

        return string.format(
            "%s<font color='rgb(160, 160, 160)'> [ %im ]</font>",
            Text, Distance
        )
    end

    function IndicatorHandler:ToBerry(Bush)
        local Bushs = Bush:GetAttributes()
        
        for i = 1, #Bushs do
            local Bush = Bushs[i]
            
            if type(Bush) ~= 'string' then continue end
            if table.find(self.Berries, Bush) then
                return Bush
            end
        end

        return "Unknown Berry"
    end

    function IndicatorHandler:ToBloxFruit(Fruit)
        local Current = Fruit.Name
        if not Fruit:IsA('Model') then return Current end

        local Idle = Fruit:FindFirstChild('Idle', true)
        if not Idle then return Current end

        local Id = tostring(Idle.AnimationId)
        if not Id then return Current end

        local Name = Module.FruitsId[Id]
        if not Name then return Current end

        return Name .. " [ Spawned ]"
    end
    
    function IndicatorHandler.NewChests()
        local Collects = {}
        local Chests = CollectionService:GetTagged("_ChestTagged")
        
        for i = 1, #Chests do
            if not Chests[i]:GetAttribute("IsDisabled") then
                Collects[#Collects + 1] = Chests[i]
            end
        end
        
        return Collects
    end
    
    function IndicatorHandler.NewBerries()
        local Collects = {}
        local Berries = CollectionService:GetTagged("BerryBush")

        for i = 1, #Berries do
            if next(Berries[i]:GetAttributes()) then
                Collects[#Collects + 1] = Berries[i]
            end
        end

        return Collects
    end
    
    function IndicatorHandler.NewFruits()
        local Collects = {}

        for _, Name in IndicatorHandler.RealFruits do
            local Folder = Cache.RealFruits[Name]

            if not Folder then
                Folder = workspace:FindFirstChild(Name)
                Cache.RealFruits[Name] = Folder
            end

            if not Folder then continue end

            for _, Fruit in Folder:GetChildren() do
                if Fruit:IsA("Tool") then
                    Collects[#Collects + 1] = Fruit
                end
            end
        end

        return Collects
    end

    function IndicatorHandler.NewGear()
        local Mirage = Map:FindFirstChild("MysticIsland")
        if not Mirage then return {} end

        local Cached = Cache.Gear

        if Cached and Cached[1] and Cached[1]:IsDescendantOf(Mirage) then
            return Cached
        end

        local Collects = {}
        local Objects = Mirage:GetChildren()

        for i = 1, #Objects do
            local Object = Objects[i]

            if Object:IsA("MeshPart") and Object.BrickColor == GearColor then
                Collects[#Collects + 1] = Object
            end
        end

        Cache.Gear = Collects
        return Collects
    end
    
    function IndicatorHandler:AddEsp(Flag, Custom) self.EspHandlers[Flag] = Custom end do
        IndicatorHandler:AddEsp("Spacial Island", {
            Colors = Color3.fromRGB(255, 0, 127),
            Folder = Map,

            Valid = function(Island)
                return IndicatorHandler.Islands[Island.Name] ~= nil
            end,

            CustomName = function(Island, Distance)
                return IndicatorHandler:Text(
                    IndicatorHandler.Islands[Island.Name] or Island.Name,
                    Distance
                )
            end,
        })

        IndicatorHandler:AddEsp("Devil Fruits", {
            Colors = Color3.fromRGB(255, 0, 0),
            Folder = workspace,

            Valid = function(Fruit)
                return Fruit.Name:find("Fruit") ~= nil
            end,

            CustomName = function(Fruit, Distance)
                return IndicatorHandler:Text(
                    IndicatorHandler:ToBloxFruit(Fruit),
                    Distance
                )
            end,
        })

        IndicatorHandler:AddEsp("Sea Beast", {
            Colors = Color3.fromRGB(0, 85, 127),

            Folder = function()
                return SeaBeasts:GetChildren()
            end,

            Valid = function(SeaBeast)
                if not SeaBeast:IsA("Model") then
                    return false
                end

                local Health = SeaBeast:FindFirstChild("Health")
                return Health and Health.Value > 0
            end,

            CustomName = function(SeaBeast, Distance)
                local Health = SeaBeast:FindFirstChild("Health")

                return IndicatorHandler:Text(
                    Health and string.format("Sea Beast [ %i ]", Health.Value) or "Sea Beast",
                    Distance
                )
            end,
        })

        IndicatorHandler:AddEsp("Flowers", {
            Colors = Color3.fromRGB(255, 170, 255),
            Folder = workspace,

            Valid = function(Flower)
                return Flower.Name:find("Flower") ~= nil
            end,

            CustomName = function(Flower, Distance)
                return IndicatorHandler:Text(
                    IndicatorHandler.Flowers[Flower.Name] or Flower.Name,
                    Distance
                )
            end,
        })

        IndicatorHandler:AddEsp("Players", {
            Colors = Color3.fromRGB(255, 255, 255),
            Folder = Characters,

            Valid = function(Character)
                local Target = Players:GetPlayerFromCharacter(Character)
                return Target and Target ~= Player
            end,
        })

        IndicatorHandler:AddEsp("Chest", {
            Colors = Color3.fromRGB(255, 255, 127),
            Folder = IndicatorHandler.NewChests,

            Valid = function(Chest)
                return not Chest:GetAttribute("IsDisabled")
            end,

            CustomName = function(_, Distance)
                return IndicatorHandler:Text("Chest", Distance)
            end,
        })

        IndicatorHandler:AddEsp("Berries", {
            Colors = Color3.fromRGB(101, 104, 255),
            Folder = IndicatorHandler.NewBerry,

            Valid = function(Bush)
                return next(Bush:GetAttributes()) ~= nil
            end,

            CustomName = function(Bush, Distance)
                return IndicatorHandler:Text(
                    IndicatorHandler:GetBerryName(Bush),
                    Distance
                )
            end,
        })

        IndicatorHandler:AddEsp("Fruits", {
            Colors = Color3.fromRGB(0, 255, 127),
            Folder = IndicatorHandler.NewFruits,

            Valid = function(Fruit)
                return Fruit:IsA("Tool") and Fruit.Parent ~= nil
            end,

            CustomName = function(Fruit, Distance)
                return IndicatorHandler:Text(Fruit.Name, Distance)
            end,
        })

        IndicatorHandler:AddEsp("Gear", {
            Colors = Color3.fromRGB(85, 255, 255),
            Folder = IndicatorHandler.NewGear,

            Valid = function(Gear)
                return Gear:IsA("MeshPart") and Gear.Parent ~= nil
            end,

            CustomName = function(_, Distance)
                return IndicatorHandler:Text("Gear", Distance)
            end,
        })

        IndicatorHandler:AddEsp("Ship", {
            Colors = Color3.fromRGB(115, 169, 255),
            Folder = Boats,

            Valid = function(Ship)
                return Ship.Parent ~= nil
            end,

            CustomName = function(Ship, Distance)
                local Owner = Ship:FindFirstChild("Owner")

                if Owner and Owner.Value then
                    return IndicatorHandler:Text(
                        string.format("%s [ %s ]", Ship.Name, Owner.Value),
                        Distance
                    )
                end

                return IndicatorHandler:Text(Ship.Name, Distance)
            end,
        })
    end

    IndicatorHandler.EspInstaller = {} do
        for Name, Data in IndicatorHandler.EspHandlers do
            local Handler = EspManagers.new(Name)
            
            if type(Data.Folder) == "function" then
                Handler:SetObjects(Data.Folder)
            else
                Handler:SetObjects(function()
                    return Data.Folder:GetChildren()
                end)
            end
            
            if Data.Valid then
                Handler:Validator(Data.Valid)
                Handler:SetAlwaysValidate()
            end

            if Data.CustomName then
                Handler:SetCustomEspDisplay(Data.CustomName)
            end

            IndicatorHandler.EspInstaller[Name] = Handler
        end
    end

    IndicatorHandler.OnToggle = function(Value, Select)
        for Name, Handler in IndicatorHandler.EspInstaller do
            Handler.Enabled = Value and table.find(Select, Name) ~= nil
        end
    end

    return IndicatorHandler
end)

NewModule("ObjectModule", function()
    local ObjectModule = {}
    
    local FruitSpawners = {
        "AppleSpawner", "PineappleSpawner", "BananaSpawner",
    }
    
    local WaterBase = Map:WaitForChild("WaterBase-Plane")
    local HalfSize = _ENV.HalfSize or WaterBase.Size * 0.5 do
        _ENV.HalfSize = HalfSize
    end
    
    function ObjectModule:WalkOnWater(Value)
        if Value then
            WaterBase.Size = Vector3.new(1000, HIDDEN_SETTINGS.WATER_Y, 1000)
        else
            WaterBase.Size = Vector3.new(1000, 80, 1000)
        end
    end
    
    function ObjectModule:IsOnSafeZone(Position)
        for _, Object in WorldOrigin.SafeZones:GetChildren() do
            if not Object:IsA("BasePart") then continue end

            local Mesh = Object:FindFirstChildOfClass("SpecialMesh")
            
            local Radius = (Mesh and Object.Size.X or Object.Size.X * Mesh.Scale.X) / 2
            local Distance = (Position - Object.Position).Magnitude

            if Distance <= Radius then
                return true
            end
        end
    end
    
    function ObjectModule:IsOwnerShip(Model)
        local Owner = Model:FindFirstChild("Owner")

        if not Owner or not Owner:IsA("ObjectValue") then
            return false
        end

        if tostring(Owner.Value) ~= Player.Name then
            return false
        end

        return true
    end

    function ObjectModule:IsOnWater(Position)
        Position = typeof(Position) == "Instance" and Position.Position or Position
        local Offset = Position - WaterBase.Position
        
        return math.abs(Offset.X) <= HalfSize.X and
            math.abs(Offset.Z) <= HalfSize.Z and Offset.Y <= 2
    end
    
    function ObjectModule:RemoveBoatCollision(Boat)
        local Objects = Boat:GetDescendants()

        for i = 1, #Objects do
            local BasePart = Objects[i]

            if BasePart:IsA("BasePart") and BasePart.CanCollide then
                BasePart.CanCollide = false
            end
        end
    end

    ObjectModule.RealFruits = setmetatable({}, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent then
                return Cached
            end

            self.Spawners = self.Spawners or {}
            for i = 1, #FruitSpawners do
                local Spawner = self.Spawners[i]

                if not Spawner then
                    Spawner = workspace:FindFirstChild(FruitSpawners[i])
                    self.Spawners[i] = Spawner
                end

                if Spawner then continue end
                local Fruits = Spawner:GetChildren()
                
                for Tool = 1, #Fruits do
                    local Fruit = Fruits[Tool]
                    if not Fruit:IsA("Tool") then continue end

                    local Handle = Fruit:FindFirstChild("Handle")
                    if not Handle then continue end

                    self.Cached = Handle
                    return Handle
                end
            end
        end,
    })
    
    ObjectModule.DevilFruits = setmetatable({}, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent and Cached.Parent == workspace then
                local Handle = Cached:FindFirstChild("Handle")

                if Handle and not ObjectModule:IsOnWater(Handle.Position) then
                    return Handle
                end
            end

            if self.Debounce and tick() < self.Debounce then
                return nil
            end

            local Nearest, Distance = nil, math.huge
            local Objects = workspace:GetChildren()

            for i = 1, #Objects do
                local Fruit = Objects[i]

                if not Fruit.Name:find("Fruit") then continue end

                local Handle = Fruit:FindFirstChild("Handle")
                if not Handle then continue end

                if ObjectModule:IsOnWater(Handle.Position) then continue end

                local Magnitude = Module:ToDistance(Handle)

                if Magnitude < Distance then
                    Distance = Magnitude
                    Nearest = Fruit
                end
            end

            self.Cached = Nearest
            self.Debounce = tick() + 0.2

            return Nearest and Nearest.Handle
        end,
    })
    
    ObjectModule.Players = setmetatable({}, {
        __call = function(self, CustomCondition)
            local Cached = self.Cached
            local Debouce = self.Debounce
            local Position = self.Position
            
            if Cached and Position and Debouce and Module:IsAlive(Cached) then
                if Module:ToDistance(Position) < 5 and tick() < Debouce then
                    return Cached
                end
            end

            local Nearest, Distance = nil, math.huge
            local PlayerList = Players:GetPlayers()

            for i = 1, #PlayerList do
                local Player = PlayerList[i]
                if Players.LocalPlayer == Player then continue end

                if Player:GetAttribute("PvpDisabled") then continue end
                if Player:GetAttribute("IslandRaiding") then continue end

                if CustomCondition and not CustomCondition(Player) then continue end

                local Character = Player.Character
                if not Character or not Module:IsAlive(Character) then continue end

                local PrimaryPart = Character.PrimaryPart
                if not PrimaryPart then continue end
                
                if ObjectModule:IsOnSafeZone(PrimaryPart.Position) then continue end
                local Magnitude = Module:ToDistance(PrimaryPart)

                if Magnitude < Distance then
                    Nearest, Distance = Character, Magnitude
                end
            end

            if Nearest then
                self.Cached = Nearest
                self.Position = Nearest:GetPivot().Position
            else
                self.Cached = nil
                self.Position = nil
            end

            self.Debounce = tick() + 0.1

            return Nearest
        end,
    })

    ObjectModule.Chests = setmetatable({}, {
        __call = function(self, SelectedIsland)
            local CachedChest = self.Cached

            if CachedChest and not CachedChest:GetAttribute("IsDisabled") then
                if not SelectedIsland or CachedChest:IsDescendantOf(SelectedIsland) then
                    return CachedChest
                end
            end

            if self.Debounce and (tick() - self.Debounce) < 0.5 then
                return nil
            end

            local Chests = CollectionService:GetTagged("_ChestTagged")
            local Distance, Nearest = math.huge, nil

            for i = 1, #Chests do
                local Chest = Chests[i]
                local Magnitude = Module:ToDistance(Chest)

                if not SelectedIsland or Chest:IsDescendantOf(SelectedIsland) then
                    if not Chest:GetAttribute("IsDisabled") and Magnitude < Distance then
                        Distance, Nearest = Magnitude, Chest
                    end
                end
            end

            self.Debounce = tick()
            self.Cached = Nearest
            
            return Nearest
        end
    })
    
    ObjectModule.Berries = setmetatable({}, {
        __call = function(self, BerryArray)
            local CachedBush = self.Cached

            if CachedBush and CachedBush:IsDescendantOf(Map) then
                for Tag, CFrame in pairs(CachedBush:GetAttributes()) do
                    return CachedBush
                end
            end

            if self.Debounce and (tick() - self.Debounce) < 0.5 then
                return nil
            end

            local BerryBush = CollectionService:GetTagged("BerryBush")
            local Distance, Nearest = math.huge, nil

            for i = 1, #BerryBush do
                local Bush = BerryBush[i]

                for AttributeName, BerryName in pairs(Bush:GetAttributes()) do
                    if not BerryArray or table.find(BerryArray, BerryName) then
                        local Magnitude = Module:ToDistance(Bush.Parent)

                        if Magnitude < Distance then
                            Nearest, Distance = Bush, Magnitude
                        end
                    end
                end
            end

            self.Debounce = tick()
            self.Cached = Nearest
            
            return Nearest
        end
    })
    
    ObjectModule.LavaRocks = setmetatable({}, {
        __call = function(self, VolcanoRocks)
            local Cached = self.LavaRock

            if Cached and Cached.Parent == VolcanoRocks then
                local LavaEffect = Cached:FindFirstChild("At1Beam", true)

                if LavaEffect and LavaEffect.Enabled then
                    return Cached
                end
            end
            
            if self.Debounce and (tick() - self.Debounce) < 0.25 then
                return nil
            end

            local Distance, Nearest = math.huge, nil
            local Rocks = VolcanoRocks:GetChildren()

            for i = 1, #Rocks do
                local Rock = Rocks[i]
                if not Rock:IsA("Model") then continue end

                local LavaEffect = Rock:FindFirstChild("At1Beam", true)
                if not LavaEffect or not LavaEffect.Enabled then continue end

                local Magnitude = Module:ToDistance(Rock)

                if Magnitude < Distance then
                    Nearest, Distance = Rock, Magnitude
                end
            end
            
            self.Debounce = tick()
            self.LavaRock = Nearest
            
            return Nearest
        end,
    })
    
    ObjectModule.TreeEagles = setmetatable({}, {
        __call = function(self, EagleBossArena)
            local Cached = self.Cached

            if Cached and Cached.Parent == EagleBossArena and Cached.PrimaryPart then
                return Cached
            end

            if self.Debounce and (tick() - self.Debounce) < 0.25 then
                return nil
            end

            local Nearest, Distance = math.huge, nil
            local Objects = EagleBossArena:GetChildren()

            for i = 1, #Objects do
                local Object = Objects[i]
                
                if Object.Name ~= "Tree" then continue end
                if not Object:IsA("Model") then continue end

                local PrimaryPart = Object.PrimaryPart
                if not PrimaryPart then continue end

                local Magnitude = Module:ToDistance(PrimaryPart)

                if Magnitude < Distance then
                    Nearest, Distance = Object, Magnitude
                end
            end
            
            self.Debounce = tick()
            self.Cached = Nearest
            
            return Nearest
        end,
    })
    
    ObjectModule.Gifts = setmetatable({}, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent == WorldOrigin then
                local Value = Cached:FindFirstChild("Value", true)

                if Value and tostring(Value.Value) == Player.Name then
                    return Cached
                end
            end

            if self.Debounce and (tick() - self.Debounce) < 0.25 then
                return nil
            end

            local Objects = WorldOrigin:GetChildren()

            for i = 1, #Objects do
                local Object = Objects[i]
                if Object.Name ~= "Present" then continue end

                local Value = Object:FindFirstChild("Value", true)
                if not Value then continue end

                if tostring(Value.Value) == Player.Name then
                    self.Debounce = tick()
                    self.Cached = Object
                    
                    return Object
                end
            end

            self.Cached = nil
        end,
    })
    
    ObjectModule.Raids = setmetatable({}, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent == Locations and Module:ToDistance(Cached) < 3500 then
                return Cached
            end

            if self.Debounce and (tick() - self.Debounce) < 0.25 then
                return nil
            end

            local Islands = {}
            local Children = Locations:GetChildren()

            for i = 1, #Children do
                local Island = Children[i]
                Islands[Island.Name] = Island
            end

            for i = 5, 1, -1 do
                local Island = Islands["Island " .. i]

                if Island and Module:ToDistance(Island) < 3500 then
                    self.Cached = Island
                    self.Debounce = tick()
                    
                    return Island
                end
            end

            self.Cached = nil
        end,
    })
    
    ObjectModule.SeaBeasts = setmetatable({}, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent == SeaBeasts and Module:IsAlive(Cached) then
                return Cached
            end

            if self.Debounce and tick() < self.Debounce then
                return nil
            end

            local Nearest, Distance = nil, 5000
            local Beasts = SeaBeasts:GetChildren()

            for i = 1, #Beasts do
                local SeaBeast = Beasts[i]

                if not SeaBeast:IsA("Model") then continue  end
                if not Module:IsAlive(SeaBeast) then continue end

                local RootPart = SeaBeast:FindFirstChild("HumanoidRootPart")
                if not RootPart then continue end

                local Magnitude = Module:ToDistance(RootPart)

                if Magnitude < Distance then
                    Nearest, Distance = SeaBeast, Magnitude
                end
            end

            self.Cached = Nearest
            self.Debounce = tick() + (Nearest and 0.25 or 0.05)

            return Nearest
        end,
    })
    
    ObjectModule.MyShips = setmetatable({}, {
        __call = function(self, Name)
            self.Cached = self.Cached or {}
            self.Debounces = self.Debounces or {}

            local Cached = self.Cached[Name]

            if Cached and Cached.Parent == Boats then
                if Cached:GetAttribute("IsBoat") and ObjectModule:IsOwnerShip(Cached) then
                    local Humanoid = Cached:FindFirstChild("Humanoid")

                    if Humanoid and Humanoid.Value > 0 then
                        return Cached
                    end 
                end
            end

            local Debounce = self.Debounces[Name]

            if Debounce and tick() < Debounce then
                return nil
            end

            local Nearest, Distance = nil, 5000
            local Ships = Boats:GetChildren()

            for i = 1, #Ships do
                local Ship = Ships[i]
                
                if Ship.Name ~= Name then continue end
                if not ObjectModule:IsOwnerShip(Ship) then continue end
                
                if not Module:IsAlive(Ship) then continue end
                if not Ship:GetAttribute("IsBoat") then continue end

                local Magnitude = Module:ToDistance(Ship)

                if Magnitude < Distance then
                    Nearest, Distance = Ship, Magnitude
                end
            end

            self.Cached[Name] = Nearest
            self.Debounces[Name] = tick() + (Nearest and 0.25 or 0.05)

            return Nearest
        end,
    })
    
    ObjectModule.EnemyShips = setmetatable({}, {
        __call = function(self, Names)
            self.Cached = self.Cached or {}
            self.Debounces = self.Debounces or {}

            local Key = table.concat(Names, "|")
            local Cached = self.Cached[Key]

            if Cached and Cached.Parent == Enemies then
                return Cached
            end
            
            if Module:IsAlive(Cached) and Cached:FindFirstChild("Seat", true) then
                return Cached
            end

            local Debounce = self.Debounces[Key]
            
            if Debounce and tick() < Debounce then
                return nil
            end

            local Nearest, Distance = nil, 5000
            local EnemyShips = Enemies:GetChildren()

            for i = 1, #EnemyShips do
                local Ship = EnemyShips[i]
                if not table.find(Names, Ship.Name) then continue end

                if not Module:IsAlive(Ship) then continue end
                if not Ship:FindFirstChild("Seat", true) then continue end

                local Magnitude = Module:ToDistance(Ship)

                if Magnitude < Distance then
                    Nearest, Distance = Ship, Magnitude
                end
            end

            self.Cached[Key] = Nearest
            self.Debounces[Key] = tick() + (Nearest and 0.25 or 0.05)

            return Nearest
        end,
    })
    
    ObjectModule.BlazeEmbers = setmetatable({}, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent then
                return Cached
            end

            if self.Debounce and tick() < self.Debounce then
                return nil
            end

            local Nearest, Distance = nil, math.huge
            local Objects = workspace:GetChildren()

            for i = 1, #Objects do
                local Ember = Objects[i]
                if Ember.Name ~= "EmberTemplate" then continue end

                local Part = Ember:FindFirstChild("Part")
                if not Part then continue end

                local Magnitude = Module:ToDistance(Part)

                if Magnitude < Distance then
                    Nearest, Distance = Part, Magnitude
                end
            end

            self.Cached = Nearest
            self.Debounce = tick() + 0.2

            return Nearest
        end,
    })
    
    return ObjectModule
end)

NewModule("SeaEventManagers", function()
    local SeaEventManagers = {} do
        SeaEventManagers.LastShip = nil
    end
    
    local TweenManagers = Packages.TweenManager
    
    SeaEventManagers.ZoneCoordinates = {
        ['Infinite - ∞'] = {-9999999, 9999999},
        ['Low - 1'] = {-21227, 4047},
        ['Meduim - 2'] = {-24237, 6381},
        ['High - 3'] = {-27105, 8959},
        ['Extreme - 4'] = {-29350, 11744},
        ['Crazy - 5'] = {-32404, 16208},
        ['??? - 6'] = {-35611, 20548},
    }

    SeaEventManagers.SeaBeastAnims = {
        "rbxassetid://8708225668",
        "rbxassetid://8708223619",
        "rbxassetid://8708222938"
    }
    
    function SeaEventManagers:Zone(Zone)
        local Coords = self.ZoneCoordinates[Zone]

        if Coords then
            return CFrame.new(Coords[1], 100, Coords[2])
        end

        return CFrame.new(-9999999, 100, 9999999)
    end
    
    function SeaEventManagers:IsSeaBeastHiding(Animator)
        for _, Track in Animator:GetPlayingAnimationTracks() do
            if self.SeaBeastAnims[Track.Animation.AnimationId] then
                return true
            end
        end
    end
    
    function SeaEventManagers:DriveStopped()
        local Ship = self.LastShip

        if Ship and Ship.Parent then
            TweenManagers:StopTween(Ship:FindFirstChild("VehicleSeat"))
        end

        self.LastShip = nil
    end
    
    function SeaEventManagers:Drive(Ship, Target, High)
        High = High or 100

        self.LastShip = Ship

        local VehicleSeat = Ship:FindFirstChild("VehicleSeat")
        if not VehicleSeat then return end

        local BodyPosition = VehicleSeat:FindFirstChild("BodyPosition")
        local BodyVelocity = VehicleSeat:FindFirstChild("BodyVelocity")

        if not BodyPosition or not BodyVelocity then return end

        local Origin = VehicleSeat.Position
        local Distance = (Target.Position - Ship:GetPivot().Position).Magnitude

        BodyVelocity.P = 0
        BodyPosition.MaxForce = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        VehicleSeat.CFrame = CFrame.new(Origin.X, High, Origin.Z)
        TweenManagers.new(VehicleSeat, Distance / 250, "CFrame", Target)
    end
    
    return SeaEventManagers
end)

NewModule("HookManagers", function()
    local Reference = {}

    local HookManagers = {} do
        _ENV.Target = Vector3.zero
    end

    function HookManagers:IsReference()
        for _, Flag in Reference do
            if _ENV.Settings[Flag] == true then
                return true 
            end 
        end 
    end
    
    function HookManagers:Import(Name)
        if not Reference[Name] then
            table.insert(Reference, Name)
        end
    end
    
    function HookManagers:SetTarget(Vector)
        _ENV.Target = (typeof(Vector) == 'CFrame' and Vector.Position) or Vector
    end
    
    if not _ENV.Original then
        task.defer(function()
            local Original; Original = hookmetamethod(game, "__namecall", function(self, ...)
                local Method = getnamecallmethod()
                
                if Method == "Emit" and self:IsA("ParticleEmitter") then
                    return Original(self, 1)
                end

                if tostring(self) == "PlayerGui" and Method == "Destroy" then
                    return warn("Override PlayerGui:", Method)
                end

                if Method == "FireServer" or Method == "InvokeServer" then
                    local v1, v2 = ...

                    if Method == "InvokeServer" and v1 == 'X' and typeof(v2) == 'Vector3' and self.Name == "" then
                        if HookManagers:IsReference() then
                            return Original(self, v1, _ENV.Target)
                        end
                    end

                    if Method == "FireServer" and self.Name == "RemoteEvent" and typeof(v1) == "Vector3" and v2 == nil then
                        if HookManagers:IsReference() then
                            return Original(self, _ENV.Target)
                        end
                    end
                end
                
                return Original(self, ...)
            end)
            
            _ENV.Original = Original
        end)
    end
    
    return HookManagers
end)

NewModule("WaitEnemiesModule", function()
    local WaitEnemiesModule = {}
    
    local SpawnLocations = Module.SpawnLocations
    local EnemyLocations = Module.EnemyLocations
    local EnemiesModule = Module.EnemiesModule
    
    function WaitEnemiesModule:ShouldStop(Breake)
        return not _ENV.OnFarm or not Module:IsAlive() or (Breake and Breake())
    end

    function WaitEnemiesModule:AnyEnemyFound(Names)
        for _, Name in Names do
            if EnemiesModule:GetClosestByTag(Name) then
                return true
            end
        end
    end

    function WaitEnemiesModule:BuildSpawnPoints(Names)
        local Points = {}

        for _, Name in Names do
            local Location = EnemyLocations[Name]
            if not Location then continue end
            
            for _, Spawner in Location do
                Points[#Points + 1] = Spawner
            end
        end

        return Points
    end

    function WaitEnemiesModule:WaitAtSpawnPoints(Names, SpawnPoints, Breake, Teleport)
        if self:ShouldStop(Breake) then return end
        if self:AnyEnemyFound(Names) then return end

        local WaitDelay = Settings['Wait Enemies Delay'] or 0.75

        for _, SpawnCFrame in SpawnPoints do
            if self:ShouldStop(Breake) then return end
            if self:AnyEnemyFound(Names) then return end
            
            Teleport(SpawnCFrame)

            local WaitStart = tick()

            while tick() - WaitStart < WaitDelay do
                if self:ShouldStop(Breake) then return end
                if self:AnyEnemyFound(Names) then return end
                
                task.wait(0.1)
            end
        end

        if not self:ShouldStop(Breake) and not self:AnyEnemyFound(Names) then
            self:WaitAtSpawnPoints(Names, SpawnPoints, Breake, Teleport)
        end
    end
    
    task.spawn(function()
        local function NewIslandAdded(Island)
            if Island.Name:find("Island") then
                Cache.RaidIsland = nil
            end
        end

        local function NewSpawn(Part)
            local EnemyName = GetEnemyName(Part.Name)
            EnemyLocations[EnemyName] = EnemyLocations[EnemyName] or {}

            local EnemySpawn = Part.CFrame + Vector3.new(0, 25, 0)
            SpawnLocations[EnemyName] = Part

            if not table.find(EnemyLocations[EnemyName], EnemySpawn) then
                table.insert(EnemyLocations[EnemyName], EnemySpawn)
            end
        end

        for _, Spawn in EnemySpawns:GetChildren() do NewSpawn(Spawn) end

        Connect(EnemySpawns.ChildAdded, NewSpawn)
        Connect(Locations.ChildAdded, NewIslandAdded)

        Connect(Player.Idled, function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    
    return function(Names, Breake)
        Names = type(Names) == "table" and Names or { Names }
        
        if not _ENV.TELEPORTER then return end
        if WaitEnemiesModule:ShouldStop(Breake) then return end
        if WaitEnemiesModule:AnyEnemyFound(Names) then return end

        local SpawnPoints = WaitEnemiesModule:BuildSpawnPoints(Names)

        if #SpawnPoints > 0 then
            WaitEnemiesModule:WaitAtSpawnPoints(
                Names, SpawnPoints, Breake, _ENV.TELEPORTER
            )
        end
    end
end)

return Module, Cache