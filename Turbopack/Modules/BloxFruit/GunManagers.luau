local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Stepped = RunService.Stepped

local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator = Remotes:WaitForChild("Validator2")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

local HitboxLimbs = {
    "RightLowerArm", "RightUpperArm", "LeftLowerArm",
    "LeftUpperArm", "RightHand", "LeftHand"
}

local HumanoidsCache do
    local COUNT_NEWINDEX = 0
    local Metatable = {
        __newindex = function(self, index, value)
            if COUNT_NEWINDEX >= 50 then
                for key, cache in self do
                    if typeof(cache) == "Instance" and not cache:IsDescendantOf(game) then
                        rawset(self, key, nil)
                    end
                end
                COUNT_NEWINDEX = 0
            end

            COUNT_NEWINDEX += 1
            return rawset(self, index, value)
        end
    }
    Metatable.__index = function(self, Character)
        local Humanoid = Character:FindFirstChild(
            if Character.Parent == SeaBeasts then "Health" else "Humanoid"
        )
        if Humanoid then
            self[Character] = Humanoid
            return Humanoid
        end
    end

    HumanoidsCache = setmetatable({}, Metatable)
end

local function GetHumanoidHealth(Humanoid)
    return Humanoid[if Humanoid.ClassName == "Humanoid" then "Health" else "Value"]
end

local function IsAlive(Character, _Humanoid)
    if _Humanoid then
        return GetHumanoidHealth(_Humanoid) > 0
    elseif Character then
        local Humanoid = HumanoidsCache[Character]
        if Humanoid then
            return GetHumanoidHealth(Humanoid) > 0
        else
            return Character.Parent == Boats
        end
    end
end

local function DistanceFromCharacter(Value)
    return Player:DistanceFromCharacter(Value.Position)
end

local function GetRandomHitboxLimb(Character)
    return Character:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)])
end

local function CheckPlayerAlly(Target)
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

local GunClient = (function()
    local GunClient = {
        Distance = 50,
        attackMobs = true,
        attackPlayers = true,
        Equipped = nil,
        Debounce = 0,
        ShootDebounce = 0,

        Overheat = {
            ["Dragonstorm"] = {
                MaxOverheat = 3,
                Cooldown = 0,
                TotalOverheat = 0,
                Distance = 400,
                Shooting = false
            }
        },
        ShootsPerTarget = {
            ["Dual Flintlock"] = 2
        },
        SpecialShoots = {
            ["Skull Guitar"] = "TAP",
            ["Bazooka"] = "Position",
            ["Cannon"] = "Position",
            ["Dragonstorm"] = "Overheat"
        }
    }

    local RE_ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")

    local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
        return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
    end)

    GunClient.ShootsFunctions = {
        ["Skull Guitar"] = function(self, Equipped, Position)
            Equipped.RemoteEvent:FireServer("TAP", Position)
        end
    }

    local CurrentBladeHits = {}
    local MyRootPartPosition = nil

    local function CanChangeGunTarget(Target, Enemy)
        if Enemy.Parent == SeaBeasts then
            return true
        elseif Target.Parent ~= SeaBeasts and Enemy:GetAttribute("IsBoat") then
            return true
        end
        return false
    end

    local function ConvertToGunHits()
        local Target, Hitbox
        local MinDist = math.huge

        for index = 1, #CurrentBladeHits do
            local Hit = CurrentBladeHits[index]
            local Dist = (MyRootPartPosition - Hit[2].Position).Magnitude

            if Dist < MinDist then
                MinDist = Dist
                Hitbox, Target = Hit[2], Hit[1]
            end
        end

        CurrentBladeHits = { Hitbox, math.random() }
        return Hitbox.Position, Hitbox
    end

    local function ProcessSeaEventsHits(Distance)
        for _, SeaBeast in SeaBeasts:GetChildren() do
            local BasePart = SeaBeast:FindFirstChildOfClass("MeshPart")
            if IsAlive(SeaBeast) and BasePart and (MyRootPartPosition - BasePart.Position).Magnitude < Distance then
                table.insert(CurrentBladeHits, { SeaBeast, BasePart })
            end
        end

        for _, Boat in Enemies:GetChildren() do
            if not Boat:GetAttribute("IsBoat") then continue end
            local BasePart = Boat:FindFirstChildOfClass("MeshPart")
            if IsAlive(Boat) and BasePart and (MyRootPartPosition - BasePart.Position).Magnitude < Distance then
                table.insert(CurrentBladeHits, { Boat, BasePart })
            end
        end
    end

    local function ProcessHits(List, Distance)
        local MyCharacter = Player.Character
        local Targets = List:GetChildren()

        for i = 1, #Targets do
            local Character = Targets[i]
            if Character == MyCharacter or Character:GetAttribute("IsBoat") or not IsAlive(Character) then continue end
            local RootPart = Character.PrimaryPart

            if RootPart and (Character.Parent ~= Characters or CheckPlayerAlly(Character)) then
                local Hitbox = GetRandomHitboxLimb(Character) or RootPart
                if Hitbox and (MyRootPartPosition - RootPart.Position).Magnitude <= Distance then
                    table.insert(CurrentBladeHits, { Character, Hitbox })
                end
            end
        end
    end

    function GunClient:UpdateBladeHits(Distance, SeasEvents)
        Distance = Distance or self.Distance
        CurrentBladeHits = {}

        if self.attackMobs then ProcessHits(Enemies, Distance) end
        if self.attackPlayers then ProcessHits(Characters, Distance) end
        if SeasEvents then ProcessSeaEventsHits(Distance) end
    end

    function GunClient:GetClosestEnemy(Distance)
        self:UpdateBladeHits(Distance, true)

        local MinDist, Closest = math.huge

        for i = 1, #CurrentBladeHits do
            local Magnitude = (MyRootPartPosition - CurrentBladeHits[i][2].Position).Magnitude
            if Magnitude <= MinDist then
                MinDist, Closest = Magnitude, CurrentBladeHits[i][2]
            end
        end

        return Closest
    end

    function GunClient:GetValidator2()
        local v1 = getupvalue(SHOOT_FUNCTION, 15)
        local v2 = getupvalue(SHOOT_FUNCTION, 13)
        local v3 = getupvalue(SHOOT_FUNCTION, 16)
        local v4 = getupvalue(SHOOT_FUNCTION, 17)
        local v5 = getupvalue(SHOOT_FUNCTION, 14)
        local v6 = getupvalue(SHOOT_FUNCTION, 12)
        local v7 = getupvalue(SHOOT_FUNCTION, 18)

        local v8 = v6 * v2
        local v9 = (v5 * v2 + v6 * v1) % v3

        v9 = (v9 * v3 + v8) % v4
        v5 = math.floor(v9 / v3)
        v6 = v9 - v5 * v3
        v7 = v7 + 1

        setupvalue(SHOOT_FUNCTION, 15, v1)
        setupvalue(SHOOT_FUNCTION, 13, v2)
        setupvalue(SHOOT_FUNCTION, 16, v3)
        setupvalue(SHOOT_FUNCTION, 17, v4)
        setupvalue(SHOOT_FUNCTION, 14, v5)
        setupvalue(SHOOT_FUNCTION, 12, v6)
        setupvalue(SHOOT_FUNCTION, 18, v7)

        local r1, r2 = math.floor(v9 / v4 * 16777215), v7

        return r1, r2
    end

    function GunClient:ShootInTarget(TargetPosition)
        local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")

        if Equipped and Equipped.ToolTip == "Gun" then
            if Equipped:FindFirstChild("Cooldown") and (tick() - self.ShootDebounce) >= Equipped.Cooldown.Value then
                if self.ShootsFunctions[Equipped.Name] then
                    return self.ShootsFunctions[Equipped.Name](self, Equipped, TargetPosition)
                end

                if SUCCESS_SHOOT and SHOOT_FUNCTION then
                    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"

                    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
                        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                        GunValidator:FireServer(self:GetValidator2())

                        if ShootType == "TAP" then
                            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
                        else
                            RE_ShootGunEvent:FireServer(TargetPosition)
                        end

                        self.ShootDebounce = tick()
                    end
                else
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1); task.wait(0.05)
                    self.ShootDebounce = tick()
                end
            end
        end
    end

    function GunClient:UseGunShoot(Character, Equipped)
        if not Equipped.Enabled then
            return
        end

        local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"

        if ShootType == "Normal" or ShootType == "Overheat" then
            local Distance = if ShootType == "Overheat" then self.Overheat[Equipped.Name].Distance else 200
            self:UpdateBladeHits(Distance, true)

            if #CurrentBladeHits == 0 then
                return nil
            end

            local Position, PrimaryPart = ConvertToGunHits()
            local PrimaryTarget = PrimaryPart.Parent

            if ShootType == "Overheat" then
                self.Debounce = tick() + 9e9

                while PrimaryTarget.Parent and IsAlive(PrimaryTarget) and Equipped and Equipped.Parent == Player.Character do
                    if PrimaryPart.Parent ~= PrimaryTarget or DistanceFromCharacter(PrimaryPart) > Distance then
                        break
                    end

                    Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                    GunValidator:FireServer(self:GetValidator2())
                    RE_ShootGunEvent:FireServer(Position, CurrentBladeHits)
                    task.wait()
                end

                self.Debounce = 0
            elseif PrimaryTarget then
                local shoots = self.ShootsPerTarget[Equipped.Name] or 1

                Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                GunValidator:FireServer(self:GetValidator2())

                for i = 1, shoots do
                    RE_ShootGunEvent:FireServer(Position, CurrentBladeHits)
                end
            end

        elseif ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
            local Target = self:GetClosestEnemy(200)

            if Target then
                if self.ShootsFunctions[Equipped.Name] then
                    return self.ShootsFunctions[Equipped.Name](self, Equipped, Target.Position)
                end

                Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                GunValidator:FireServer(self:GetValidator2())

                if ShootType == "TAP" then
                    Equipped.RemoteEvent:FireServer("TAP", Target.Position)
                else
                    RE_ShootGunEvent:FireServer(Target.Position)
                end
            end
        end
    end

    function GunClient:FireTarget(Equipped, Character)
        if not Character then return end

        local Cooldown = Equipped:FindFirstChild("Cooldown")
        local Current = Cooldown and Cooldown.Value or 0.3

        if (tick() - self.Debounce) >= Current then
            self.Equipped = Equipped
            self.Debounce = tick()

            MyRootPartPosition = Character:GetPivot().Position

            if SUCCESS_SHOOT and SHOOT_FUNCTION then
                self:UseGunShoot(Character, Equipped)
            end
        end
    end

    return GunClient
end)()

return GunClient