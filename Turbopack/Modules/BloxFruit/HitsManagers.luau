-- Made by @vita8it

local _ENV = (getgenv or getrenv or getfenv)()

local HIDDEN_SETTINGS = {
    FAST_ATTACK = true
}

local Module = {}
local Cache = {} do
    Cache.RemoteId = nil
    Cache.Remote = nil

    Cache.SeedIdMultiple = nil
    Cache.SeedResult = nil
    Cache.SeedId = nil
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService('Lighting')
local Players = game:GetService("Players")
local CoreGui = game:GetService('CoreGui')

local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local ChestModels = workspace:WaitForChild("ChestModels")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local NPCs = workspace:WaitForChild('NPCs')
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local NetModule = Modules:WaitForChild('Net')
local Seed = NetModule:WaitForChild('seed')

local Player = Players.LocalPlayer

Module.HumanoidManager = (function()
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
end)()

Module.CalculateManager = (function()
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
end)()

Module.Injection = (function()
    local Injection = {}
    local Folders = {
        "Util", "Common","FX",
        "Remotes", "Assets"
    }

    local SeedId, Success = Seed:InvokeServer() do
        Cache.SeedIdMultiple = SeedId * 2
        Cache.SeedResult = Success
        Cache.SeedId = SeedId

        Seed.OnClientInvoke = function(Result, Id)
            Cache.SeedIdMultiple = Id * 2
            Cache.SeedResult = Result
            Cache.SeedId = Id
        end
    end

    function Injection.RegisterRemote(Object)
        if Object:IsA("RemoteEvent") and Object:GetAttribute("Id") then
            Cache.Remote = Object
            Cache.RemoteId = Object:GetAttribute("Id") + 909090
        end
    end

    function Injection:NewRemoteProxy(Folder)
        local Instancer = ReplicatedStorage[Folder]

        for _, Remote in Instancer:GetChildren() do
            self.RegisterRemote(Remote)
        end

        Instancer.ChildAdded:Connect(Injection.RegisterRemote)
    end

    function Injection:EncryptRemote(Name)
        return string.gsub(Name, ".", function(c)
            return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
        end)
    end

    for _, Folder in Folders do Injection:NewRemoteProxy(Folder) end

    return Injection
end)()

Module.FastAttack = (function()
    local Injection = Module.Injection

    local FastAttack = {} do
        FastAttack.Cooldown = 0.5
        FastAttack.Distance = 50
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
        self:ProcessHits(Characters, Distance)
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
        NetModule["RE/RegisterAttack"]:FireServer(0.5)

        local Encrypted = Injection:EncryptRemote("RE/RegisterHit")
        local XorId = bit32.bxor(Cache.RemoteId, Cache.SeedIdMultiple)

        Cache.Remote:FireServer(Encrypted, XorId, Closest, Targets)
    end

    HIDDEN_SETTINGS.FAST_ATTACK = true
    RunService.Stepped:Connect(function()
        local self = FastAttack

        if not HIDDEN_SETTINGS.FAST_ATTACK then return end
        if not Module:IsAlive() then return end

        local Character = Player.Character
        if not Character then return end

        local Equipped = Character and Character:FindFirstChildOfClass("Tool")
        if not Equipped then return end

        self:UpdateBladeHits()

        local Closest = self:GetClosest()
        if not Closest then return end

        Module.LocalPosition = Character:GetPivot().Position

        local ToolTip = Equipped.ToolTip
        local Name = Equipped.Name

        if Name == 'Ice-Ice' or Name == 'Light-Light' then
            return self:SendHits(Closest, CurrentBladeHits)
        elseif ToolTip == 'Melee' or ToolTip == 'Sword' then
            return self:SendHits(Closest, CurrentBladeHits)
        end
    end)

    return FastAttack
end)()