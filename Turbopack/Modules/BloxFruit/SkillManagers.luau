local Module, Settings, Connect = ...

local _ENV = (getgenv or getrenv or getfenv)()

local SkillManagers = {}

local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui, Backpack, Character, Humanoid, Skills

local CurrentTool = nil

local LastSkillUse = 0
local LastSimple = 0

local IsReloading = false
local OnFirstTime = true

local function UpdateReferences()
    Player = Players.LocalPlayer

    if not Player then return false end

    PlayerGui = Player:FindFirstChild("PlayerGui")
    Backpack = Player:FindFirstChildOfClass("Backpack")
    Character = Player.Character

    if not Character and Player.CharacterAdded then
        Character = Player.CharacterAdded:Wait()
    end

    Humanoid = Character and Character:FindFirstChild("Humanoid") or nil
    Skills = PlayerGui and PlayerGui:FindFirstChild("Main") and PlayerGui.Main:FindFirstChild("Skills") or nil

    return true
end

function SkillManagers:GetEnabledSkills()
    return {
        ['Melee'] = Settings['Melee'] or { "Z", "X", "C" },
        ['Sword'] = Settings['Sword'] or { "Z", "X" },
        ['Gun'] = Settings['Gun'] or { "Z", "X" },
        ['Blox Fruit'] = Settings['Blox Fruit'] or { "Z", "X", "C" }
    }
end

function SkillManagers:GetEnabledList(ToolName)
    if not (Backpack or Character) then return {} end

    local Tool = (Backpack and Backpack:FindFirstChild(ToolName)) or (Character and Character:FindFirstChild(ToolName))

    return Tool and self:GetEnabledSkills()[Tool.ToolTip] or {}
end

function SkillManagers:IsToolValid(ToolFrame)
    if not ToolFrame or not ToolFrame:IsA("Frame") then return false end

    local Tool = (Backpack and Backpack:FindFirstChild(ToolFrame.Name)) or (Character and Character:FindFirstChild(ToolFrame.Name))
    if not Tool then return false end

    local EnabledList = self:GetEnabledSkills()[Tool.ToolTip]

    return EnabledList and #EnabledList > 0
end

function SkillManagers:IsSkillUnlocked(Skill)
    if not Skill then return false end
    local Title = Skill:FindFirstChild("Title")

    return Title and Title.TextColor3 == Color3.fromRGB(255, 255, 255)
end

function SkillManagers:IsSkillOnCooldown(Skill)
    if not Skill then return false end
    local Cooldown = Skill:FindFirstChild("Cooldown")

    return Cooldown and Cooldown.Size.X.Scale > 0
end

function SkillManagers:IsSkillReady(Skill, ToolName)
    return table.find(self:GetEnabledList(ToolName), Skill.Name) and self:IsSkillUnlocked(Skill) and not self:IsSkillOnCooldown(Skill)
end

function SkillManagers:FindReadySkill(ToolContainer, ToolName)
    if not ToolContainer then return nil end
    for _, Skill in ToolContainer:GetChildren() do
        if not Skill:IsA("Frame") or Skill.Name == "Template" then continue end

        if self:IsSkillReady(Skill, ToolName) then
            return Skill.Name
        end
    end
end

function SkillManagers:FindLowestCooldownSkill(ToolContainer, ToolName)
    local SelectedSkill, LowestCooldown = nil, math.huge
    local EnabledList = self:GetEnabledList(ToolName)

    if not ToolContainer then return nil end

    for _, Skill in ToolContainer:GetChildren() do
        if not Skill:IsA("Frame") or Skill.Name == "Template" then continue end

        if not self:IsSkillUnlocked(Skill) or not table.find(EnabledList, Skill.Name) then continue end

        local Cooldown = Skill:FindFirstChild("Cooldown")

        if not Cooldown or Cooldown.Size.X.Scale >= LowestCooldown then continue end

        LowestCooldown, SelectedSkill = Cooldown.Size.X.Scale, Skill.Name
    end

    return SelectedSkill
end

function SkillManagers:GetBestSkill(CurrentToolName)
    if not Skills then return nil, nil end

    if CurrentToolName then
        local ToolContainer = Skills:FindFirstChild(CurrentToolName)

        if ToolContainer and self:IsToolValid(ToolContainer) then
            local SkillName = self:FindReadySkill(ToolContainer, CurrentToolName)

            if SkillName then
                return CurrentToolName, SkillName
            end
        end
    end

    local BestTool, BestSkill, LowestCooldown = nil, nil, math.huge

    for _, Tool in pairs(Skills:GetChildren()) do
        if not Tool:IsA("Frame") or Tool.Name == "Container" then continue end

        if not self:IsToolValid(Tool) then continue end

        if Tool.Name == CurrentToolName then continue end

        local SkillName = self:FindReadySkill(Tool, Tool.Name)

        if SkillName then return Tool.Name, SkillName end

        local LowestSkill = self:FindLowestCooldownSkill(Tool, Tool.Name)

        if not LowestSkill then continue end

        local SkillFrame = Tool:FindFirstChild(LowestSkill)
        local Cooldown = SkillFrame and SkillFrame:FindFirstChild("Cooldown")

        if not Cooldown or Cooldown.Size.X.Scale >= LowestCooldown then continue end

        LowestCooldown, BestTool, BestSkill = Cooldown.Size.X.Scale, Tool.Name, LowestSkill
    end

    if not BestTool and CurrentToolName then
        local ToolContainer = Skills:FindFirstChild(CurrentToolName)

        if ToolContainer and self:IsToolValid(ToolContainer) then
            local LowestSkill = self:FindLowestCooldownSkill(ToolContainer, CurrentToolName)

            if LowestSkill then
                return CurrentToolName, LowestSkill
            end
        end
    end

    return BestTool, BestSkill
end

function SkillManagers:EquipTool(ToolName)
    if not Module or not Module.IsAlive or not Module:IsAlive() then return false end
    if not (Backpack and Character and Humanoid) then return false end

    local Tool = Backpack:FindFirstChild(ToolName)

    if not Tool then return false end

    if Tool:GetAttribute("Locks") then
        Tool:SetAttribute("Locks", nil)
    end

    if not Character:FindFirstChild(ToolName) then
        Humanoid:EquipTool(Tool)

        local Timeout = tick() + 1

        while not Character:FindFirstChild(ToolName) and tick() < Timeout do
            task.wait()
        end
    end

    return Character and Character:FindFirstChild(ToolName) ~= nil
end

function SkillManagers:GetUnCooldownSkill(Name, Select)
    if not Skills then return nil end
    local ToolContainer = Skills:FindFirstChild(Name)
    if not ToolContainer then return nil end

    for _, KeyName in ipairs(Select) do
        local Skill = ToolContainer:FindFirstChild(KeyName)

        if not Skill or not Skill:IsA("Frame") then continue end

        if not self:IsSkillUnlocked(Skill) then continue end

        if self:IsSkillOnCooldown(Skill) then continue end

        return KeyName
    end

    return nil
end

function SkillManagers:OnToolAdded(Tool)
    if not Tool or not Tool:IsA("Tool") then return end

    local EnabledSkills = self:GetEnabledSkills()

    if not EnabledSkills[Tool.ToolTip] then return end

    if not Skills then return end
    if Skills:FindFirstChild(Tool.Name) then return end

    IsReloading = true

    task.wait(0.5)

    if Humanoid then Humanoid:UnequipTools() end

    CurrentTool = nil

    Module:EquipTool(Tool.ToolTip, true)

    if Humanoid then Humanoid:UnequipTools() end

    IsReloading = false
end

function SkillManagers:BindBackpack()
    if not Backpack then return end
    if _ENV.Reload then _ENV.Reload:Disconnect() end
    _ENV.Reload = Connect(Backpack.ChildAdded, function(child) return self:OnToolAdded(child) end)
end

function SkillManagers:Use()
    UpdateReferences()
    if not (Character and Humanoid and Skills) then return end

    if OnFirstTime then
        OnFirstTime = false do
            return Module:EquipTool("Melee", true)
        end
    end

    if IsReloading then return end
    if tick() - LastSkillUse < 0.2 then return end

    local ToolName, SkillName = self:GetBestSkill(CurrentTool)

    if not ToolName or not SkillName then return end

    if CurrentTool ~= ToolName then
        if not self:EquipTool(ToolName) then
            if Humanoid then Humanoid:UnequipTools() end
            task.wait(0.25)

            for _, ToolType in pairs({"Melee", "Sword", "Gun", "Blox Fruit"}) do
                Module:EquipTool(ToolType, true)
                task.wait(0.15)
            end

            return
        end

        CurrentTool = ToolName
        task.wait(0.15)
    end

    if not (Character and Character:FindFirstChild(ToolName)) then
        CurrentTool = nil
        return
    end

    LastSkillUse = tick()

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[SkillName], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[SkillName], false, game)
end

function SkillManagers:Skill(Select)
    UpdateReferences()
    if not (Character and Skills) then return end
    if not Select or #Select == 0 then return end
    if tick() - LastSimple < 0.2 then return end

    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped then return end

    local Skill = self:GetUnCooldownSkill(Equipped.Name, Select)
    if not Skill then return end

    LastSimple = tick()

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[Skill], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[Skill], false, game)
end

task.spawn(function()
    if UpdateReferences() then
        SkillManagers:BindBackpack()
    end

    if Player and Player.CharacterAdded then
        Connect(Player.CharacterAdded, function(NewCharacter)
            Character = NewCharacter

            Humanoid = NewCharacter:WaitForChild("Humanoid", 10)
            Backpack = Player:FindFirstChildOfClass('Backpack')

            CurrentTool = nil
            IsReloading = false

            SkillManagers:BindBackpack()
        end)
    end
end)

return SkillManagers