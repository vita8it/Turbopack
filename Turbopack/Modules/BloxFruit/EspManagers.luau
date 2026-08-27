local Module, Settings = ...

local _ENV = (getgenv or gerenv or getfenv)()

local EspManager = {}
EspManager.__index = EspManager

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local CoreGui = game:GetService('CoreGui')

EspManager.__newindex = function(self, index, value)
    if index == "Enabled" then
        task.spawn(self.ToggleEsp, self, value)
    else
        rawset(self, index, value)
    end
end

local CoreGuiEspFolder = Instance.new("Folder", CoreGui) do
    CoreGuiEspFolder.Name = "XYN-EspFolder"

    local _EspFolder = CoreGui:FindFirstChild(CoreGuiEspFolder.Name)

    if _EspFolder and _EspFolder ~= CoreGuiEspFolder then
        _EspFolder:Destroy()
    end
end

local EspTemplate = Instance.new("BoxHandleAdornment") do
    local BoxHandleAdornment = EspTemplate
    BoxHandleAdornment.Size = Vector3.new(1, 0, 1, 0)
    BoxHandleAdornment.AlwaysOnTop = true
    BoxHandleAdornment.ZIndex = 10
    BoxHandleAdornment.Transparency = 0

    local BillboardGui = Instance.new("BillboardGui", BoxHandleAdornment)
    BillboardGui.Size = UDim2.new(0, 100, 0, 150)
    BillboardGui.StudsOffset = Vector3.new(0, 2, 0)
    BillboardGui.AlwaysOnTop = true

    local TextLabel = Instance.new("TextLabel", BillboardGui)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0, 0, 0, -50)
    TextLabel.Size = UDim2.new(0, 100, 0, 100)
    TextLabel.TextSize = 10
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    TextLabel.Text = "..."
    TextLabel.ZIndex = 15
    TextLabel.RichText = true
end

local DefaultEspColor = Color3.fromRGB(255, 255, 255)
local HumHealth = "%s<font color='rgb(160, 160, 160)'> [ %im ]</font>\n<font color='rgb(25, 240, 25)'>[%i/%i]</font>"
local CreatedEsps = {}

local function GetBasePart(Instance)
    if Instance:IsA("BasePart") then
        return Instance
    elseif Instance:IsA("Model") then
        return Instance.PrimaryPart or Instance:GetPivot()
    elseif Instance.Parent:IsA("Model") then
        return Instance.Parent.PrimaryPart or Instance.Parent:GetPivot()
    end
end

function EspManager:SetCustomEspDisplay(Action)
    self.CustomEspDisplay = Action
    return self
end

function EspManager:SetObjects(Objects)
    self.GetObjectsAction = Objects
    return self
end

function EspManager:GetInstance(Action)
    self.OnlyOneInstanceAction = Action
    return self
end

function EspManager:SetInstanceName(Instance, Name)
    self.EspsNames[Instance] = Name
    return self
end

function EspManager:SetAllInstancesName(Name)
    self.CustomInstanceName = Name
    return self
end

function EspManager:WaitChildsAdded()
    self._WaitChildsAdded = true
    return self
end

function EspManager:SetEspColor(Action)
    self.EspColor = Action
    return self
end

function EspManager:SetAlwaysValidate()
    self.AlwaysValidateInstance = true
    return self
end

function EspManager:Validator(Action)
    self.ValidateInstance = Action
    return self
end

function EspManager:ChangeEspSize(Size)
    self.EspSize = Size

    for i = 1, #CreatedEsps do
        for _, Esp in pairs(CreatedEsps[i].EspObjects) do
            Esp.BoxHandleAdornment.BillboardGui.TextLabel.TextSize = Size
        end
    end

    return self
end

local BaseESP = "%s<font color='rgb(160, 160, 160)'> [ %im ]</font>"

function EspManager:StartRunningEsp(Esp)
    local Instance = Esp.Instance
    local BoxHandleAdornment = Esp.BoxHandleAdornment
    local TextLabel = BoxHandleAdornment.BillboardGui.TextLabel
    local Folder = self.EspFolder
    local IsModel = Instance:IsA("Model")
    local CachedBasePart = nil

    while task.wait(Settings.SmoothMode and 0.25 or 0) do
        if not BoxHandleAdornment or not BoxHandleAdornment.Parent then
            return self:Clear(Esp)
        elseif self.AlwaysValidateInstance and not self.ValidateInstance(Instance) then
            return self:Clear(Esp)
        elseif not Instance:IsDescendantOf(workspace) and not Instance:IsDescendantOf(ReplicatedStorage) then
            return self:Clear(Esp)
        end

        CachedBasePart = CachedBasePart or GetBasePart(Instance)

        if not CachedBasePart then
            return self:Clear(Esp)
        end

        local DistanceValue = math.floor((Module:ToDistance(CachedBasePart)) / 5)
        local Humanoider = IsModel and Instance:FindFirstChildOfClass("Humanoid")

        if Humanoider then
            TextLabel.Text = HumHealth:format(Instance.Name, DistanceValue, math.floor(Humanoider.Health), math.floor(Humanoider.MaxHealth))
        elseif self.CustomEspDisplay then
            TextLabel.Text = self.CustomEspDisplay(Instance, DistanceValue)
        else
            local Name = self.CustomInstanceName or self.EspsNames[Instance] or Instance.Name
            TextLabel.Text = BaseESP:format(Name, DistanceValue)
        end
    end
end

function EspManager:Create(Instance)
    if self.EspObjects[Instance] then return end

    local Esp = {
        Instance = Instance,
        BoxHandleAdornment = nil
    }

    local BoxHandleAdornment = EspTemplate:Clone()
    local BillboardGui = BoxHandleAdornment.BillboardGui
    local TextLabel = BillboardGui.TextLabel

    BillboardGui.Adornee = (Instance:IsA("BasePart") or Instance:IsA("Model")) and Instance or Instance.Parent
    TextLabel.TextColor3 = type(self.EspColor) == "function" and self.EspColor(Instance) or self.EspColor or DefaultEspColor
    TextLabel.Text = self.CustomInstanceName or "..."
    TextLabel.TextSize = self.EspSize or TextLabel.TextSize
    BoxHandleAdornment.Parent = self.EspFolder

    self.EspObjects[Instance] = Esp
    Esp.BoxHandleAdornment = BoxHandleAdornment

    task.spawn(self.StartRunningEsp, self, Esp)

    return Esp
end

function EspManager:Clear(Esp)
    if Esp then
        self.EspObjects[Esp.Instance] = nil
        if Esp.BoxHandleAdornment then Esp.BoxHandleAdornment:Destroy() end
    else
        table.clear(self.EspObjects)
        self.EspFolder:ClearAllChildren()
    end
end

function EspManager:ToggleEsp(Value)
    local Environment = "Xyn_Esp_" .. self.SpecialTag
    _ENV[Environment] = Value

    if not Value then
        return self:Clear()
    end

    while _ENV[Environment] do
        local ObjectsAction = self.GetObjectsAction
        local CreatedNew = false

        if self.OnlyOneInstanceAction then
            local Instance = self.OnlyOneInstanceAction()

            if Instance then
                self:Create(Instance)
            end
        elseif ObjectsAction then
            local Instances

            if typeof(ObjectsAction) == "function" then
                Instances = ObjectsAction()
            elseif typeof(ObjectsAction) == "Instance" then
                Instances = ObjectsAction:GetChildren()
            else
                Instances = ObjectsAction
            end

            local Validate = self.ValidateInstance
            local CreatedEsps = self.EspObjects

            for i = 1, #Instances do
                local Instance = Instances[i]

                if not CreatedEsps[Instance] and (not Validate or Validate(Instance)) then
                    CreatedNew = true
                    self:Create(Instance)
                end
            end
        end

        if not CreatedNew and self._WaitChildsAdded then
            ObjectsAction.ChildAdded:Wait()
        end

        task.wait(0.25)
    end
end

function EspManager.new(Tag)
    local EspFolder = Instance.new("Folder", CoreGuiEspFolder)
    EspFolder.Name = Tag

    local self = setmetatable({
        SpecialTag = Tag,
        EspObjects = {},
        EspsNames = {},
        EspFolder = EspFolder
    }, EspManager)

    table.insert(CreatedEsps, self)

    return self
end

return EspManager