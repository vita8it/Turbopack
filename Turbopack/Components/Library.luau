local _ENV = (getgenv or getrenv or getfenv)()

local Framework = {}
local Types = {}

local clonefunction = clonefunction or function( ... ) return ... end
local cloneref = cloneref or function( ... ) return ... end

local Nodes, Cached = {}, {} do
    Nodes.Game = cloneref(game)
    Nodes.Cloner = clonefunction(Nodes.Game.GetService)

    Nodes.Service = setmetatable({
        Reference = {}, Inference = {}
    }, {
        __index = function(self, Service)
            local Inference = self.Inference
            local Reference = self.Reference

            if Reference[Service] then
                return Reference[Service]
            elseif Inference[Service] then
                return Inference[Service]
            end

            Inference[Service] = Nodes.Cloner(Nodes.Game, Service)
            Reference[Service] = cloneref(Inference[Service])

            return Reference[Service]
        end,
    }):: Types.Service
end

local Service = Nodes.Service

local UserInputService = Service.UserInputService
local TweenService = Service.TweenService
local HttpService = Service.HttpService
local RunService = Service.RunService
local GuiService = Service.GuiService
local Players = Service.Players
local CoreGui = Service.CoreGui

local CurrentCamera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local UserInputState = Enum.UserInputState
local UserInputType = Enum.UserInputType

local EasingDirection = Enum.EasingDirection
local EasingStyle = Enum.EasingStyle

local HorizontalAlignment = Enum.HorizontalAlignment
local VerticalAlignment = Enum.VerticalAlignment
local TextXAlignment = Enum.TextXAlignment
local TextTruncate = Enum.TextTruncate

local UIFlexAlignment = Enum.UIFlexAlignment
local FillDirection = Enum.FillDirection

local ZIndexBehavior = Enum.ZIndexBehavior
local AutomaticSize = Enum.AutomaticSize
local ScreenInsets = Enum.ScreenInsets

local ScaleType = Enum.ScaleType
local SortOrder= Enum.SortOrder

local FontWeight = Enum.FontWeight
local FontStyle = Enum.FontStyle

Nodes.TextLabels = {}
Nodes.ButtonColorsMap = {
    ['Primary'] = {
        Title = Color3.fromRGB(0, 0, 0),
        Background = Color3.fromRGB(234, 234, 234)
    },
    ['Secondary'] = {
        Title = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(45, 45, 45)
    },
    ['Disabled'] = {
        Title = Color3.fromRGB(100, 100, 100),
        Background = Color3.fromRGB(30, 30, 30)
    },
    ['Danger'] = {
        Title = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(255, 47, 47)
    },
}

Nodes.Parent = (function()
    if not RunService:IsStudio() then
        return (gethui and gethui()) or CoreGui
    end

    return PlayerGui
end)()

Nodes.IsMobile = (function()
    local TouchEnabled = UserInputService.TouchEnabled
    local KeyboardEnabled = UserInputService.KeyboardEnabled

    return TouchEnabled and not KeyboardEnabled and true
end)()

Nodes.WaitForPortSize = (function()
    repeat task.wait()
    until CurrentCamera.ViewportSize.X > 1 and CurrentCamera.ViewportSize.Y > 1
end)()

Nodes.FontMedium = (function()
    return Font.new(
        "rbxasset://fonts/families/GothamSSm.json",
        FontWeight.Medium,
        FontStyle.Normal
    )
end)()

Nodes.FontRegular = (function()
    return Font.new(
        "rbxasset://fonts/families/GothamSSm.json",
        FontWeight.Regular,
        FontStyle.Normal
    )
end)()

Nodes.FontSemi = (function()
    return Font.new(
        "rbxasset://fonts/families/GothamSSm.json",
        FontWeight.SemiBold,
        FontStyle.Normal
    )
end)()

Nodes.IsThaiCharacter = function(Text)
    return Text:find("[ก-ฮ]")
end

Nodes.New = function(Class: Types.GuiClass, Properties: { [ string ]: any }): GuiObject
    local Creations: TextLabel = Instance.new(Class)

    for Property, Value in Properties do
        Creations[Property] = Value
    end

    if Class == "Frame" then
        Creations.BorderSizePixel = 0
    end

    if Class == 'TextLabel' then
        Nodes.TextLabels[Creations] = Creations.Text

        if Nodes.IsThaiCharacter(Creations.Text) and Creations.TextSize < 14 then
            Creations.TextSize = 14
        end
    end

    return Creations
end

Nodes.Button = function(Parent: GuiObject): TextButton
    return Nodes.New('TextButton', {
        Name = "Click",
        Parent = Parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = Parent.ZIndex + 3
    })
end

Nodes.Tween = function(Object: Instance, Info: Types.TweenInfoData)
    return TweenService:Create(
        Object,
        TweenInfo.new(
            Info.Time,
            EasingStyle[Info.Style],
            EasingDirection[Info.Direction]
        ),
        Info.Goal
    )
end

Nodes.MultiTweens = function(Object, Tweens)
    for Property, Data in Tweens do
        Nodes.Tween(Object, {
            Time = Data.Time,
            Style = "Linear",
            Direction = "Out",
            Goal = {
                [ Property ] = Data.Goal,
            },
        }):Play()
    end
end

Nodes.Asset = function(Id: number | string)
    if type(Id) == 'number' then
        return `rbxassetid://{Id}`
    elseif type(Id) == 'string' and Id:find('rbxassetid://') then
        return Id
    end

    return Id
end

Nodes.Highlight = function(Original, Search)
    local Escaped = Search:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    local Lower = Original:lower()
    local SearchLower = Escaped:lower()

    local Start, End = Lower:find(SearchLower, 1, true)
    if not Start then return Original end

    return Original:sub(1, Start - 1) 
        .. '<font color="#00AAFF">' 
        .. Original:sub(Start, End) 
        .. '</font>' 
        .. Original:sub(End + 1)
end

Nodes.ToDictionary = function(List, Value)
    local NewList = {}

    for _, Name in List do
        NewList[Name] = Value
    end

    return NewList
end

Nodes.ToArray = function(List)
    local NewList = {}

    for Index, _ in List do
        table.insert(NewList, Index)
    end

    return NewList
end

Nodes.Draggable = setmetatable({
    Enumeration = {
        Began = {
            [ UserInputType.MouseButton1 ] = true,
            [ UserInputType.Touch ] = true,
        },
        Changed = {
            [ UserInputType.MouseMovement ] = true,
            [ UserInputType.Touch ] = true,
        },
        State = {
            [ UserInputState.End ] = true,
        },
    },

    Acceleration = 0.1,
    States = {},

    Update = function(self, Frame, Input)
        local State = self.States[Frame]
        if not State then return end

        local Delta = Input.Position - State.Start
        local NewPosition = UDim2.new(
            State.Position.X.Scale, State.Position.X.Offset + Delta.X,
            State.Position.Y.Scale, State.Position.Y.Offset + Delta.Y
        )

        Nodes.Tween(Frame, {
            Time = self.Acceleration,
            Style = "Linear",
            Direction = "Out",
            Goal = { Position = NewPosition },
        }):Play()
    end
}, {
    __call = function(self, Frame, IsResizing)
        local State = self.States[Frame]

        if not State then
            State = {
                IsDragging = false,
                Start = nil,
                Input = nil,
                Position = nil,
            }

            self.States[Frame] = State
        end

        Frame.InputBegan:Connect(function(Input)
            if IsResizing() then return end

            if self.Enumeration.Began[Input.UserInputType] then
                State.IsDragging = true
                State.Start = Input.Position
                State.Position = Frame.Position

                Input.Changed:Connect(function()
                    if self.Enumeration.State[Input.UserInputState] then
                        State.IsDragging = false
                    end
                end)
            end
        end)

        Frame.InputChanged:Connect(function(Input)
            if self.Enumeration.Changed[Input.UserInputType] then
                State.Input = Input
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if Input == State.Input and State.IsDragging then
                if IsResizing() then return end
                self:Update(Frame, Input)
            end
        end)
    end,
})

Nodes.Resizing = setmetatable({
    Cached = {},
    States = {},
    SideSize = UDim2.new(0, 20, 0, 20),

    UDimToVector = function(self, UDim, Parent)
        local ViewportSize = CurrentCamera.ViewportSize
        local ParentSize = Parent and Parent.AbsoluteSize or Vector2.new(ViewportSize.X, ViewportSize.Y)

        return Vector2.new(
            UDim.X.Scale * ParentSize.X + UDim.X.Offset,
            UDim.Y.Scale * ParentSize.Y + UDim.Y.Offset
        )
    end,

    GetMaximize = function()
        local ViewportSize = CurrentCamera.ViewportSize
        return UDim2.new(0, ViewportSize.X * 0.8, 0, ViewportSize.Y * 0.95)
    end,
}, {
    __call = function(self, Frame, Minimize, Maximize)
        if self.Cached[Frame] then return end

        local State = self.States[Frame]

        local SideSize = self.SideSize
        local SideOffset = SideSize.X.Offset

        if not State then
            State = {
                IsResizing = false,
                Start = nil,
                Size = nil,
                Position = nil,
            }
            self.States[Frame] = State
        end

        local function MakeResizable(Handle, Direction)
            local ResizeStart, StartSize, StartPos, StartUDim = nil, nil, nil, nil

            Handle.ZIndex = 999

            Nodes.New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Handle
            })

            Handle.InputBegan:Connect(function(Input)
                if Cached.IsFullScreen then return end

                if Input.UserInputType ~= UserInputType.MouseButton1
                    and Input.UserInputType ~= UserInputType.Touch then
                    return
                end

                Nodes.Tween(Handle, {
                    Time = 0.15,
                    Style = "Linear",
                    Direction = "Out",
                    Goal = {
                        BackgroundTransparency = 0.5
                    }
                }):Play()

                Cached.IsResizing = true

                ResizeStart = Input.Position
                StartSize = Frame.AbsoluteSize
                StartUDim = Frame.Position

                local Inset = GuiService:GetGuiInset()
                StartPos = Vector2.new(
                    Frame.AbsolutePosition.X + Frame.AbsoluteSize.X / 2,
                    Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y / 2 + Inset.Y
                )

                Input.Changed:Connect(function()
                    if Input.UserInputState == UserInputState.End then
                        Cached.IsResizing = false
                        ResizeStart = nil
                        StartSize = nil
                        StartPos = nil
                        StartUDim = nil

                        Nodes.Tween(Handle, {
                            Time = 0.15,
                            Style = "Linear",
                            Direction = "Out",
                            Goal = {
                                BackgroundTransparency = 1
                            }
                        }):Play()
                    end
                end)
            end)

            UserInputService.InputChanged:Connect(function(Input)
                if Cached.IsFullScreen then return end

                if not ResizeStart or not StartSize or not StartPos or not StartUDim then return end
                if Input.UserInputType ~= UserInputType.MouseMovement and Input.UserInputType ~= UserInputType.Touch then return end

                local MaximizeUDim = Maximize or self:GetMaximize()
                local Delta = Input.Position - ResizeStart

                local MinVec = self:UDimToVector(Minimize)
                local MaxVec = self:UDimToVector(MaximizeUDim)

                local NewWidth = StartSize.X
                local NewHeight = StartSize.Y
                local NewX = StartPos.X
                local NewY = StartPos.Y

                if Direction == "Right" or Direction == "TopRight" or Direction == "BottomRight" then
                    NewWidth = math.clamp(StartSize.X + Delta.X, MinVec.X, MaxVec.X)
                    NewX = StartPos.X + (NewWidth - StartSize.X) / 2
                elseif Direction == "Left" or Direction == "TopLeft" or Direction == "BottomLeft" then
                    NewWidth = math.clamp(StartSize.X - Delta.X, MinVec.X, MaxVec.X)
                    NewX = StartPos.X - (NewWidth - StartSize.X) / 2
                end

                if Direction == "Lower" or Direction == "BottomLeft" or Direction == "BottomRight" then
                    NewHeight = math.clamp(StartSize.Y + Delta.Y, MinVec.Y, MaxVec.Y)
                    NewY = StartPos.Y + (NewHeight - StartSize.Y) / 2
                elseif Direction == "Upper" or Direction == "TopLeft" or Direction == "TopRight" then
                    NewHeight = math.clamp(StartSize.Y - Delta.Y, MinVec.Y, MaxVec.Y)
                    NewY = StartPos.Y - (NewHeight - StartSize.Y) / 2
                end

                local ViewportSize = CurrentCamera.ViewportSize
                local ScaleX = StartUDim.X.Scale
                local ScaleY = StartUDim.Y.Scale
                local OffsetX = NewX - ScaleX * ViewportSize.X
                local OffsetY = NewY - ScaleY * ViewportSize.Y

                Frame.Size = UDim2.new(0, NewWidth, 0, NewHeight)
                Frame.Position = UDim2.new(ScaleX, OffsetX, ScaleY, OffsetY)
            end)
        end

        local Resize = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Resize",
            Parent = Frame,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
        })

        local Holder_Left = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Name = "Holder_Left",
            Parent = Resize,
            Size = UDim2.new(0, 10, 1, -SideOffset),
        })

        local Holder_Right = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Name = "Holder_Right",
            Parent = Resize,
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 10, 1, -SideOffset),
        })

        local Holder_Upper = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Name = "Holder_Upper",
            Parent = Resize,
            Size = UDim2.new(1, -SideOffset, 0, 10),
        })

        local Holder_Lower = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Name = "Holder_Lower",
            Parent = Resize,
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, -SideOffset, 0, 10),
        })

        local Holder_TopLeft = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Holder_TopLeft",
            Parent = Resize,
            Position = UDim2.new(0, 0, 0, 0),
            Size = SideSize,
        })

        local Holder_TopRight = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Holder_TopRight",
            Parent = Resize,
            Position = UDim2.new(1, 0, 0, 0),
            Size = SideSize,
        })

        local Holder_BottomLeft = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Holder_BottomLeft",
            Parent = Resize,
            Position = UDim2.new(0, 0, 1, 0),
            Size = SideSize,
        })

        local Holder_BottomRight = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Holder_BottomRight",
            Parent = Resize,
            Position = UDim2.new(1, 0, 1, 0),
            Size = SideSize,
        })

        MakeResizable(Holder_Left, "Left")
        MakeResizable(Holder_Right, "Right")
        MakeResizable(Holder_Upper, "Upper")
        MakeResizable(Holder_Lower, "Lower")
        MakeResizable(Holder_TopLeft, "TopLeft")
        MakeResizable(Holder_TopRight, "TopRight")
        MakeResizable(Holder_BottomLeft, "BottomLeft")
        MakeResizable(Holder_BottomRight, "BottomRight")

        self.Cached[Frame] = true
    end,
})

Nodes.GoodSignal = (function()
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
        for _, connection in self._connections do
            connection:Fire(...)
        end
    end

    return Signal
end)()

Nodes.UpdateLine = function(Rows)
    for Index, Row in Rows do
        if Row.Line then
            Row.Line.Visible = (Index ~= #Rows)
        end
    end
end

Nodes.ScrollTo = function(ScrollingFrame, Target)
    Nodes.Tween(ScrollingFrame, {
        Time = 1,
        Style = 'Exponential',
        Direction = "Out",
        Goal = {
            CanvasPosition = Vector2.new(
                0, Target.AbsolutePosition.Y - ScrollingFrame.AbsolutePosition.Y
            )
        }
    }):Play()
end

Nodes.NewRow = function(Parent, Args)
    local Info = {} do
        Info.Title = Args.Title
        Info.Desc = Args.Desc or nil
    end

    local RowModule = {}
    local CurrentPadding = Info.Desc and 10 or 15

    local Rows = Nodes.New("Frame", {
        AutomaticSize = AutomaticSize.Y,
        BackgroundTransparency = 1,
        Name = "Rows",
        Parent = Parent,
        Size = UDim2.new(1, 0, 0, 0),
    }) do
        Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            Name = "Line",
            Parent = Rows,
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
        })

        RowModule.Line = Rows.Line
        Rows:SetAttribute('Dropdown', Args.IsDropdown)
    end

    local Left = Nodes.New("Frame", {
        AutomaticSize = AutomaticSize.Y,
        BackgroundTransparency = 1,
        Name = "Left",
        Parent = Rows,
        Size = UDim2.new(1, 0, 0, 0),
    }) do
        Nodes.New("UIListLayout", {
            Padding = UDim.new(0, 2),
            FillDirection = FillDirection.Horizontal,
            SortOrder = SortOrder.LayoutOrder,
            VerticalAlignment = VerticalAlignment.Center,
            Parent = Left,
        })

        Nodes.New("UIPadding", {
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, CurrentPadding),
            PaddingBottom = UDim.new(0, CurrentPadding),
            Parent = Left,
        })

        local Text = Nodes.New("Frame", {
            AutomaticSize = AutomaticSize.XY,
            BackgroundTransparency = 1,
            Name = "Text",
            Parent = Left,
            Size = UDim2.new(0, 0, 0, 0),
        }) do
            local IsThai = Info.Desc and Nodes.IsThaiCharacter(Info.Desc)
            local LayoutPadding = IsThai and 0 or 2

            Nodes.New("UIListLayout", {
                Padding = UDim.new(0, LayoutPadding),
                SortOrder = SortOrder.LayoutOrder,
                VerticalAlignment = VerticalAlignment.Center,
                Parent = Text,
            })
            Nodes.New("TextLabel", {
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                Name = "Title",
                Parent = Text,
                Size = UDim2.new(0, 0, 0, 0),
                FontFace = Nodes.FontMedium,
                Text = Info.Title,
                RichText = true,
                TextWrapped = true,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = TextXAlignment.Left,
            })

            if Info.Desc then
                Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    Name = "Desc",
                    Parent = Text,
                    Size = UDim2.new(0, 0, 0, 0),
                    FontFace = Nodes.FontMedium,
                    Text = Info.Desc,
                    RichText = true,
                    TextWrapped = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextXAlignment = TextXAlignment.Left,
                }) 

                RowModule.Desc = Text.Desc
            end
        end

        RowModule.Left = Left
        RowModule.Title = Text.Title
    end

    local Right = Nodes.New("Frame", {
        BackgroundTransparency = 1,
        Name = "Right",
        Parent = Rows,
        Size = UDim2.new(1, 0, 1, 0),
    }) do
        Nodes.New("UIListLayout", {
            FillDirection = FillDirection.Horizontal,
            SortOrder = SortOrder.LayoutOrder,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
            Parent = Right,
        })
        Nodes.New("UIPadding", {
            PaddingRight = UDim.new(0, 15),
            Parent = Right,
        })
    end

    function RowModule:Padding(Side, Paddings)
        for Index, Value in Paddings do
            Rows[Side].UIPadding[Index] = UDim.new(0, Value)
        end
    end

    function RowModule:Layout(Side, Value)
        Rows[Side].UIListLayout.Padding = UDim.new(0, Value)
    end

    RowModule.Right = Right
    RowModule.self = Rows

    return RowModule
end

Nodes.BuildElements = function(App, Args)
    local Elements = {}

    local Module = {} do
        Module.Rows = {}
        Module.Section = Args.Section
        Module.Page = Args.Page
    end

    function Module:AddSearching(Row, Settings)
        table.insert(Module.Rows, Row)
        Nodes.UpdateLine(Module.Rows)

        table.insert(App.Searching, {
            Original = Module.Page,
            Section = Module.Section,
            SectionTitle = Module.Section.Header.Left.Title,
            OriginalSectionTitle = Args.Section.Header.Left.Title.Text,
            Row = Row.Line.Parent,
            RowModule = Row,
            Title = Row.Title,
            Desc = Row.Desc,
            OriginalTitle = Settings.Title,
            OriginalDesc = Settings.Description,
        })
    end

    function Elements:Paragraph(Settings)
        local Row = Nodes.NewRow(Module.Section, {
            Title = Settings.Title,
            Desc = Settings.Description,
            IsDropdown = Settings.IsDropdown or false
        })

        function Row:Typography(Text)
            local Contents = Nodes.New("TextLabel", {
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                FontFace = Nodes.FontMedium,
                Name = "Content",
                Parent = Row.Right,
                RichText = true,
                Size = UDim2.new(0, 0, 0, 0),
                Text = Text,
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = 12,
                TextXAlignment = TextXAlignment.Left,
            })

            Contents:GetAttributeChangedSignal('Text'):Connect(function()
                Row:Padding("Left", {
                    PaddingRight = Contents.AbsoluteSize.X + 25
                })
            end)

            task.defer(function()
                Row:Padding("Left", {
                    PaddingRight = Contents.AbsoluteSize.X + 25
                })
            end)

            return setmetatable({}, {
                __index = Contents,
                __newindex = function(_, Index, Value)
                    Contents[Index] = Value
                end,
            })
        end

        function Row:Icon(Id)
            local Icon = Nodes.New("ImageLabel", {
                BackgroundTransparency = 1,
                Name = "Icon",
                Parent = Row.Right,
                Size = UDim2.new(0, 20, 0, 20),
                Image = Nodes.Asset(Id),
                ImageTransparency = 0.5,
            })

            Row:Padding("Left", {
                PaddingRight = Icon.AbsoluteSize.X + 25
            })

            return setmetatable({}, {
                __index = Icon,

                __newindex = function(_, Index, Value)
                    Icon[Index] = Value
                end,
            })
        end

        function Row:Status(Value)
            local SelectColor = Value and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(255, 0, 0)

            local Active = Nodes.New("Frame", {
                BackgroundColor3 = SelectColor,
                BackgroundTransparency = 0.9,
                Name = "Active",
                Parent = Row.Right,
                Size = UDim2.new(0, 70, 0, 23),
            }) do
                Nodes.New("UICorner", {
                    Parent = Active,
                })

                Nodes.New("UIShadow", {
                    Parent = Active,
                    Transparency = 0.55,
                    BlurRadius = UDim.new(0, 5),
                })
            end

            local Title = Nodes.New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Name = "Title",
                Parent = Active,
                Position = UDim2.new(0.5, 0, 0.5, -1),
                Size = UDim2.new(1, -20, 1, 0),
                FontFace = Nodes.FontMedium,
                Text = Value and "Spawned" or "Despawn",
                TextColor3 = SelectColor,
                TextSize = 11,
            })

            local Stroke = Nodes.New("UIStroke", {
                Color = SelectColor,
                Thickness = 0.5,
                Transparency = 0.45,
                Parent = Active,
            })

            Row:Padding("Left", {
                PaddingRight = Active.AbsoluteSize.X + 25,
            })

            local Object = {}

            return setmetatable(Object, {
                __index = function(_, Index)
                    if Index == "Value" then
                        return Value
                    end

                    return Active[Index]
                end,
                __newindex = function(_, Index, NewValue)
                    if Index == "Value" then
                        Value = NewValue

                        local SelectColor = NewValue
                            and Color3.fromRGB(0, 255, 127)
                            or Color3.fromRGB(255, 0, 0)

                        Title.Text = NewValue and "Spawned" or "Despawn"
                        Title.TextColor3 = SelectColor

                        Active.BackgroundColor3 = SelectColor
                        Stroke.Color = SelectColor
                    else
                        Active[Index] = NewValue
                    end
                end,
            })
        end

        Module:AddSearching(Row, Settings)

        return setmetatable({}, {
            __index = Row,
            __newindex = function(Self, Index, Value)
                if Index == "Title" then
                    Row.Title.Text = Value
                elseif Index == "Description" then
                    Row.Desc.Text = Value
                elseif Index == "Visible" then
                    Row.Visible = Value
                else
                    rawset(Self, Index, Value)
                end
            end,
        })
    end

    function Elements:Button(Settings)
        local Paragarph = self:Paragraph(Settings)

        local Info = {
            Type = Settings.Type or "Primary",
            ButtonText = Settings.ButtonText or "Click",
            Callback = Settings.Callback or function() end
        }

        local Self = Paragarph.self
        local Right = Paragarph.Right
        local SelectType = Nodes.ButtonColorsMap[ Info.Type ]

        local Button = Nodes.New("Frame", {
            BackgroundColor3 = SelectType.Background,
            Name = "Button",
            Parent = Right,
            Size = UDim2.new(0, 75, 0, 25),
        }) do
            Nodes.New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Button,
            })

            Nodes.New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Name = "Title",
                Parent = Button,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                FontFace = Nodes.FontSemi,
                Text = Info.ButtonText,
                TextColor3 = SelectType.Title,
                TextSize = 12,
                TextTransparency = 0.3,
                TextXAlignment = TextXAlignment.Center,
            })
        end

        Nodes.New("UIShadow", {
            Parent = Button,
            Transparency = 0.5,
            BlurRadius = UDim.new(0, 5)
        })

        task.defer(function()
            Button.Size = UDim2.new(0, Button.Title.TextBounds.X + 35, 0, 25)

            Paragarph:Padding("Left", {
                PaddingRight = Button.AbsoluteSize.X + 25
            })
        end)

        Nodes.Button(Button).MouseButton1Click:Connect(function()
            if App:IsDropdownOpen() then return end
            if Info.Type == 'Disabled' then return end

            Nodes.Tween(Button.UIShadow, {
                Time = 0.15,
                Style = "Linear",
                Direction = "Out",
                Goal = {
                    BlurRadius = UDim.new(0, 1)
                }
            }):Play()

            Button.Title.TextSize = 14

            task.delay(0.1, function()
                Nodes.Tween(Button.UIShadow, {
                    Time = 0.15,
                    Style = "Linear",
                    Direction = "Out",
                    Goal = {
                        BlurRadius = UDim.new(0, 5)
                    }
                }):Play()

                Button.Title.TextSize = 12
            end)

            if Info.Type == 'Danger' then
                App:Dialog({
                    Title = Settings.Title,
                    Description = "Are you sure?",
                    Content = Settings.Description,
                    Icon = 115960025411300,
                    Callback = function(State)
                        if State then
                            task.spawn(pcall, Info.Callback)
                        end
                    end,

                })
            else
                task.spawn(pcall, Info.Callback, Paragarph)
            end
        end)

        function Paragarph:Fire()
            Info.Callback()
        end

        function Paragarph:SetType(Type)
            Info.Type = Type
            SelectType = Nodes.ButtonColorsMap[ Info.Type ]

            Button.BackgroundColor3 = SelectType.Background
            Button.Title.TextColor3 = SelectType.Title
        end


        return Paragarph
    end

    function Elements:Toggle(Settings)
        local Paragarph = self:Paragraph(Settings)

        local Info = {
            Title = Settings.Title,
            Desc = Settings.Description,
            Value = Settings.Value or false,
            Callback = Settings.Callback or function() end
        }

        local Right = Paragarph.Right

        local Toggle = Nodes.New("Frame", {
            BackgroundColor3 = Info.Value and Color3.fromRGB(42, 120, 214) or Color3.fromRGB(65, 65, 65),
            Name = "Toggle",
            Parent = Right,
            Size = UDim2.new(0, 40, 0, 23),
        }) do
            Nodes.New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Toggle,
            })

            Nodes.New("UIShadow", {
                Parent = Toggle,
                Transparency = 0.65,
                BlurRadius = UDim.new(0, 4)
            })
        end

        local Circle = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Name = "Circle",
            Parent = Toggle,
            Position = UDim2.new(0.5, Info.Value and 9 or -8, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(244, 244, 244),
            Size = UDim2.new(0, 17, 0, 17),
        }) do
            Nodes.New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Circle,
            })
        end

        local function OnChanged(Value)
            Nodes.Tween(Toggle, {
                Time = 0.15,
                Style = 'Linear',
                Direction = 'Out',
                Goal = {
                    BackgroundColor3 = Value and Color3.fromRGB(42, 120, 214) or Color3.fromRGB(65, 65, 65)
                }
            }):Play()

            Nodes.Tween(Circle, {
                Time = 0.15,
                Style = 'Exponential',
                Direction = 'Out',
                Goal = {
                    Position = UDim2.new(0.5, Value and 9 or -8, 0.5, 0)
                }
            }):Play()

            task.spawn(pcall, Info.Callback, Paragarph, Value)
        end

        function Paragarph:SetValue(Value)
            Info.Value = Value
            OnChanged(Info.Value)
        end

        Nodes.Button(Toggle).MouseButton1Click:Connect(function()
            if App:IsDropdownOpen() then return end

            Info.Value = not Info.Value
            OnChanged(Info.Value)
        end)

        Paragarph:Padding("Left", {
            PaddingRight = Toggle.AbsoluteSize.X + 25
        })

        OnChanged(Info.Value)

        return Paragarph
    end

    function Elements:Slider(Settings)
        local Paragarph = self:Paragraph(Settings)

        local Info = {
            Title = Settings.Title,
            Desc = Settings.Description,
            Min = Settings.Min or 0,
            Max = Settings.Max or 10,
            Rounding = Settings.Rounding or 0,
            Value = Settings.Value ~= nil and Settings.Value or Settings.Min or 0,
            Callback = Settings.Callback or function() end
        }

        local Right = Paragarph.Right

        local Slidable = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Name = "Slidable",
            Parent = Right,
            Size = UDim2.new(0, 100, 0, 35),
        })

        local Background = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(65, 65, 65),
            Name = "Background",
            Parent = Slidable,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -10, 0, 5),
        }) do
            Nodes.New("UICorner", {
                Parent = Background,
                CornerRadius = UDim.new(1, 0),
            })

            Nodes.New("UIShadow", {
                Parent = Background,
                Transparency = 0.65,
                BlurRadius = UDim.new(0, 4)
            })
        end

        local Color = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(42, 120, 214),
            Name = "Color",
            Parent = Background,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 1, 0),
        }) do
            Nodes.New("UICorner", {
                Parent = Color,
                CornerRadius = UDim.new(1, 0),
            })
        end

        local Circle = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Name = "Circle",
            Parent = Color,
            BackgroundColor3 = Color3.fromRGB(244, 244, 244),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 13, 0, 13),
        }) do
            Nodes.New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Circle,
            })
        end

        local TextBox = Nodes.New("TextBox", {
            AutomaticSize = AutomaticSize.X,
            BackgroundTransparency = 1,
            Name = "Value",
            Parent = Right,
            Size = UDim2.new(0, 0, 0, 20),
            FontFace = Nodes.FontMedium,
            PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
            Text = tostring(Info.Value),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 11,
            TextTransparency = 0.5,
            TextXAlignment = TextXAlignment.Right,
        })

        local function UpdatePadding()
            Paragarph:Padding("Left", {
                PaddingRight = TextBox.AbsoluteSize.X + 125
            })
        end

        local Dragging = false
        local Slide = Nodes.Button(Slidable)

        local function Round(n, decimals)
            local factor = 10 ^ decimals
            return math.floor(n * factor + 0.5) / factor
        end

        local function Update(Value)
            Value = tonumber(Value) or Info.Value

            Value = math.clamp(Value, Info.Min, Info.Max)
            Value = Round(Value, Info.Rounding)

            Info.Value = Value

            local Ratio = Info.Max == Info.Min and 0 or (Value - Info.Min) / (Info.Max - Info.Min)

            Nodes.Tween(Color, {
                Time = 0.1,
                Style = "Linear",
                Direction = "Out",
                Goal = {
                    Size = UDim2.new(math.max(Ratio, 0.1), 0, 1, 0)
                }
            }):Play()

            TextBox.Text = tostring(Value)
            task.spawn(pcall, Info.Callback, Paragarph, Value)

            return Value
        end

        local function InputValue(Input)
            local AbsX = Background.AbsolutePosition.X
            local AbsW = Background.AbsoluteSize.X

            local Ratio = math.clamp(
                (Input.Position.X - AbsX) / AbsW,
                0,
                1
            )

            return Ratio * (Info.Max - Info.Min) + Info.Min
        end

        Slide.InputBegan:Connect(function(Input)
            if App:IsDropdownOpen() then return end

            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then

                Dragging = true
                Update(InputValue(Input))
            end
        end)

        Slide.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then

                Dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if App:IsDropdownOpen() then return end
            if not Dragging then return end

            if Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch then

                Update(InputValue(Input))
            end
        end)

        TextBox.FocusLost:Connect(function()
            local Value = tonumber(TextBox.Text)

            if Value then
                Update(Value)
            else
                TextBox.Text = tostring(Info.Value)
            end

            UpdatePadding()
        end)

        function Paragarph:SetValue(Value)
            Update(Value)
        end

        Update(Info.Value, false)
        UpdatePadding()

        Paragarph:Layout("Right", 5)

        TextBox:GetPropertyChangedSignal("Text"):Connect(UpdatePadding)
        TextBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdatePadding)

        return Paragarph
    end

    function Elements:Textbox(Settings)
        local Paragarph = self:Paragraph(Settings)
        local Right = Paragarph.Right

        local Info = {
            Title = Settings.Title,
            Desc = Settings.Description,
            TypeValue = Settings.TypeOfValue or "string",
            Value = Settings.Value or "N/A",
            Callback = Settings.Callback or function() end
        }

        local Textfield = Nodes.New("Frame", {
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            Name = "Textfield",
            Parent = Right,
            Size = UDim2.new(0, 75, 0, 26),
        }) do
            Nodes.New("UICorner", {
                Parent = Textfield,
                CornerRadius = UDim.new(0, 8)
            })

            Nodes.New("UIStroke", {
                Color = Color3.fromRGB(30, 30, 30),
                Thickness = 0.75,
                BorderStrokePosition = "Outer",
                Parent = Textfield,
            })

            Paragarph:Padding("Left", {
                PaddingRight = Textfield.AbsoluteSize.X + 25
            })

            Nodes.New("UIShadow", {
                Parent = Textfield,
                Transparency = 0.65,
                BlurRadius = UDim.new(0, 4)
            })
        end

        local TextBox = Nodes.New("TextBox", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            FontFace = Nodes.FontMedium,
            Parent = Textfield,
            PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Text = tostring(Info.Value),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextTransparency = 0.5,
            TextTruncate = TextTruncate.AtEnd,
        })

        TextBox.FocusLost:Connect(function()
            local Value = TextBox.Text

            if Info.TypeValue == "number" then
                Value = tonumber(Value)

                if not Value then
                    TextBox.Text = tostring(Info.Value)
                    return
                end
            end

            Info.Value = Value
            Info.Callback(Paragarph, Value)
        end)

        return Paragarph
    end

    function Elements:Dropdown(Settings)
        local IsShowing = false
        local IsMulti = typeof(Settings.Value) == "table"

        local Paragraph = self:Paragraph({
            Title = Settings.Title,
            Description = "None",
            IsDropdown = true
        })

        local Right = Paragraph.Right
        local Icon = Paragraph:Icon(132291592681506)

        local Info = {
            Title = Settings.Title,
            List = Settings.List or {},
            Value = Settings.Value or (IsMulti and {} or "None"),
            Callback = Settings.Callback or function() end
        }

        local Button = Nodes.Button(Paragraph.self)

        local NewDropdown = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Name = "NewDropdown",
            Parent = Framework.Window,
            Position = UDim2.new(0.5, 0, 0.3, 0),
            Visible = false,
            Size = UDim2.new(0, 400, 0, 250),
        }) do
            Nodes.New("UICorner", {
                BottomLeftRadius = UDim.new(0, 16),
                BottomRightRadius = UDim.new(0, 16),
                TopLeftRadius = UDim.new(0, 5),
                TopRightRadius = UDim.new(0, 5),
                Parent = NewDropdown,
            })

            Nodes.New("UIStroke", {
                Color = Color3.fromRGB(35, 35, 35),
                BorderStrokePosition = "Inner",
                Parent = NewDropdown,
            })

            Nodes.New("UIStroke", {
                Name = "Shadow",
                BorderStrokePosition = "Outer",
                Transparency = 0.5,
                Parent = NewDropdown,
            })

            Nodes.New("UIListLayout", {
                HorizontalAlignment = HorizontalAlignment.Center,
                Parent = NewDropdown,
                SortOrder = SortOrder.LayoutOrder,
            })

            Nodes.New("UIShadow", {
                BlurRadius = UDim.new(0, 20),
                Parent = NewDropdown,
                Transparency = 0.5,
            })
        end

        local Head = Nodes.New("Frame", {
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            Name = "Head",
            Parent = NewDropdown,
            Size = UDim2.new(1, 0, 0, 50),
        }) do
            Nodes.New("UICorner", {
                BottomLeftRadius = UDim.new(0, 0),
                BottomRightRadius = UDim.new(0, 0),
                TopLeftRadius = UDim.new(0, 5),
                TopRightRadius = UDim.new(0, 5),
                Parent = Head,
            })
        end

        local HeadRight = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Name = "Right",
            Parent = Head,
            Size = UDim2.new(1, 0, 1, 0),
        }) do
            Nodes.New("UIListLayout", {
                FillDirection = FillDirection.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Center,
                Parent = HeadRight,
                SortOrder = SortOrder.LayoutOrder,
                VerticalAlignment = VerticalAlignment.Center,
            })
        end

        local Search = Nodes.New("Frame", {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Name = "Search",
            Parent = HeadRight,
            Size = UDim2.new(1, -20, 0, 30),
        }) do
            Nodes.New("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = Search,
            })

            Nodes.New("UIStroke", {
                Color = Color3.fromRGB(35, 35, 35),
                BorderStrokePosition = "Inner",
                Parent = Search,
            })

            Nodes.New("UIListLayout", {
                FillDirection = FillDirection.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = Search,
                SortOrder = SortOrder.LayoutOrder,
                VerticalAlignment = VerticalAlignment.Center,
            })

            Nodes.New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "rbxassetid://78256773704343",
                ImageTransparency = 0.5,
                LayoutOrder = 1,
                Name = "Lucide",
                Parent = Search,
                Size = UDim2.new(0, 18, 0, 18),
            })

            Nodes.New("UIPadding", {
                PaddingRight = UDim.new(0, 8),
                Parent = Search,
            })
        end

        local SearchInput = Nodes.New("TextBox", {
            BackgroundTransparency = 1,
            FontFace = Nodes.FontRegular,
            Name = "SearchBox",
            Parent = Search,
            PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
            PlaceholderText = "Search",
            Size = UDim2.new(1, -35, 1, 0),
            Text = "",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextTransparency = 0.5,
            TextXAlignment = TextXAlignment.Left,
        })

        local DropdownScale = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Name = "DropdownScale",
            Parent = NewDropdown,
            Size = UDim2.new(1, 0, 1, -60),
        })

        local DropdownScroll = Nodes.New("ScrollingFrame", {
            Active = true,
            BackgroundTransparency = 1,
            Name = "DropdownScroll",
            Parent = DropdownScale,
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
            Size = UDim2.new(1, 0, 1, 0),
        })

        local UIListLayout = Nodes.New("UIListLayout", {
            HorizontalAlignment = HorizontalAlignment.Center,
            Parent = DropdownScroll,
            SortOrder = SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
        })

        Nodes.New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 4),
            Parent = DropdownScroll,
        })

        UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            DropdownScroll.CanvasSize = UDim2.new(
                0,
                0,
                0,
                UIListLayout.AbsoluteContentSize.Y + 15
            )
        end)

        local SelectedValues = {}
        local SelectedOrder = 0

        local function IsValueInTable(Value, Table)
            if type(Table) ~= "table" then
                return false
            end

            for _, v in ipairs(Table) do
                if v == Value then
                    return true
                end
            end

            return false
        end

        local function GetText()
            if IsMulti then
                if type(Info.Value) ~= "table" or #Info.Value == 0 then
                    return "None"
                end

                return table.concat(Info.Value, ", ")
            end

            if Info.Value == nil or Info.Value == "" then
                return "None"
            end

            return tostring(Info.Value)
        end

        local function SetText()
            Paragraph.Description = GetText()
        end

        local function UpdateValue()
            if not IsMulti then
                return
            end

            local SelectedList = {}

            for Name, Order in pairs(SelectedValues) do
                table.insert(SelectedList, {
                    Name = Name,
                    Order = Order
                })
            end

            table.sort(SelectedList, function(a, b)
                return a.Order < b.Order
            end)

            local Values = {}

            for _, Data in ipairs(SelectedList) do
                table.insert(Values, Data.Name)
            end

            Info.Value = Values

            SetText()

            return Values
        end

        local function UpdateOrder()
            if not IsMulti then
                return
            end

            for _, List in ipairs(DropdownScroll:GetChildren()) do
                if List:IsA("Frame") and List.Name == "NewList" then
                    local Left = List:FindFirstChild("Left")
                    local Title = Left and Left:FindFirstChild("Title")

                    if Title then
                        local Order = SelectedValues[Title.Text]

                        if Order then
                            List.LayoutOrder = Order
                        else
                            List.LayoutOrder = table.find(Info.List, Title.Text) or 0
                        end
                    end
                end
            end
        end

        local function CloseDropdown()
            IsShowing = false
            NewDropdown.Visible = false
            NewDropdown.Position = UDim2.new(0.5, 0, 0.3, 0)
            SearchInput.Text = ""
        end

        Paragraph.CloseDropdown = CloseDropdown
        Paragraph.Lists = Paragraph.Lists or {}

        SetText()

        function Paragraph:Clear(Value)
            for _, List in ipairs(DropdownScroll:GetChildren()) do
                if List:IsA("Frame") and List.Name == "NewList" then
                    local Left = List:FindFirstChild("Left")
                    local Title = Left and Left:FindFirstChild("Title")

                    local ShouldClear =
                        Value == nil
                        or (type(Value) == "string" and Title and Title.Text == Value)
                        or (type(Value) == "table" and Title and IsValueInTable(Title.Text, Value))

                    if ShouldClear then
                        if Title then
                            SelectedValues[Title.Text] = nil
                        end

                        List:Destroy()
                    end
                end
            end

            if Value == nil then
                SelectedValues = {}
                SelectedOrder = 0
                Info.Value = IsMulti and {} or "None"
                Paragraph.Description = "None"
            else
                UpdateValue()
            end

            UpdateOrder()
        end

        function Paragraph:AddList(Name)
            if type(Name) ~= "string" then
                return
            end

            local NewList = Nodes.New("Frame", {
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                Name = "NewList",
                Parent = DropdownScroll,
                Size = UDim2.new(1, 0, 0, 40),
                LayoutOrder = table.find(Info.List, Name) or 0,
            }) do
                Nodes.New("UICorner", {
                    CornerRadius = UDim.new(0, 3),
                    Parent = NewList,
                })
            end

            local Actived = Nodes.New("Frame", {
                BackgroundColor3 = Color3.fromRGB(234, 234, 234),
                Name = "Actived",
                Parent = NewList,
                Size = UDim2.new(0, 5, 0, 0),
            })

            local Left = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Left",
                Parent = NewList,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Left,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    FontFace = Nodes.FontMedium,
                    Name = "Title",
                    Parent = Left,
                    Size = UDim2.new(0, 0, 0, 0),
                    Text = tostring(Name),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 13,
                    TextTransparency = 0.5,
                    TextXAlignment = TextXAlignment.Left,
                })

                Nodes.New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 20),
                    Parent = Left,
                })
            end

            local ListRight = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Right",
                Parent = NewList,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    HorizontalAlignment = HorizontalAlignment.Right,
                    Parent = ListRight,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    PaddingRight = UDim.new(0, 20),
                    Parent = ListRight,
                })
            end

            local Lucide = Nodes.New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "rbxassetid://93349826813564",
                ImageTransparency = 1,
                Name = "Lucide",
                Parent = ListRight,
                Size = UDim2.new(0, 20, 0, 20),
            })

            Paragraph.Lists[Name] = NewList

            local function OnValue(IsSelected)
                Nodes.Tween(NewList, {
                    Time = 0.2,
                    Style = "Linear",
                    Direction = "Out",
                    Goal = {
                        BackgroundTransparency = IsSelected and 0.85 or 1
                    }
                }):Play()

                local Title = Left:FindFirstChild("Title")

                if Title then
                    Nodes.Tween(Title, {
                        Time = 0.2,
                        Style = "Linear",
                        Direction = "Out",
                        Goal = {
                            TextTransparency = IsSelected and 0 or 0.5
                        }
                    }):Play()
                end

                Nodes.Tween(Actived, {
                    Time = 0.2,
                    Style = "Quad",
                    Direction = IsSelected and "Out" or "In",
                    Goal = {
                        Size = IsSelected
                            and UDim2.new(0, 5, 1, 0)
                            or UDim2.new(0, 5, 0, 0)
                    }
                }):Play()

                Nodes.Tween(Lucide, {
                    Time = 0.2,
                    Style = "Quad",
                    Direction = "Out",
                    Goal = {
                        ImageTransparency = IsSelected and 0 or 1
                    }
                }):Play()
            end

            local function OnSelected()
                if IsMulti then
                    if SelectedValues[Name] then
                        SelectedValues[Name] = nil
                        OnValue(false)
                    else
                        SelectedOrder += 1
                        SelectedValues[Name] = SelectedOrder
                        OnValue(true)
                    end

                    local Values = UpdateValue()

                    UpdateOrder()

                    pcall(Info.Callback, Paragraph, Values)
                else
                    for _, List in ipairs(DropdownScroll:GetChildren()) do
                        if List:IsA("Frame") and List.Name == "NewList" then
                            local Active = List:FindFirstChild("Actived")
                            local LeftFrame = List:FindFirstChild("Left")
                            local Title = LeftFrame and LeftFrame:FindFirstChild("Title")
                            local RightFrame = List:FindFirstChild("Right")
                            local ListLucide = RightFrame and RightFrame:FindFirstChild("Lucide")

                            if Title and Title.Text ~= Name then
                                Nodes.Tween(List, {
                                    Time = 0.2,
                                    Style = "Linear",
                                    Direction = "Out",
                                    Goal = {
                                        BackgroundTransparency = 1
                                    }
                                }):Play()

                                Nodes.Tween(Title, {
                                    Time = 0.2,
                                    Style = "Linear",
                                    Direction = "Out",
                                    Goal = {
                                        TextTransparency = 0.5
                                    }
                                }):Play()

                                if Active then
                                    Nodes.Tween(Active, {
                                        Time = 0.2,
                                        Style = "Quad",
                                        Direction = "In",
                                        Goal = {
                                            Size = UDim2.new(0, 5, 0, 0)
                                        }
                                    }):Play()
                                end

                                if ListLucide then
                                    Nodes.Tween(ListLucide, {
                                        Time = 0.2,
                                        Style = "Quad",
                                        Direction = "Out",
                                        Goal = {
                                            ImageTransparency = 1
                                        }
                                    }):Play()
                                end
                            end
                        end
                    end

                    Info.Value = Name

                    OnValue(true)
                    SetText()

                    pcall(Info.Callback, Paragraph, Info.Value)
                end
            end

            if IsMulti then
                if IsValueInTable(Name, Info.Value) then
                    SelectedOrder += 1
                    SelectedValues[Name] = SelectedOrder
                    OnValue(true)
                end
            elseif Name == Info.Value then
                OnValue(true)
            end

            Nodes.Button(NewList).MouseButton1Click:Connect(OnSelected)

            return NewList
        end

        SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
            local SearchText = string.lower(SearchInput.Text)

            for _, List in ipairs(DropdownScroll:GetChildren()) do
                if List:IsA("Frame") and List.Name == "NewList" then
                    local Left = List:FindFirstChild("Left")
                    local Title = Left and Left:FindFirstChild("Title")

                    if Title then
                        List.Visible =
                            SearchText == ""
                            or string.find(
                                string.lower(Title.Text),
                                SearchText,
                                1,
                                true
                            ) ~= nil
                    end
                end
            end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if not IsShowing then
                return
            end

            if Input.UserInputType ~= UserInputType.MouseButton1
                and Input.UserInputType ~= UserInputType.Touch then
                return
            end

            local Mouse = Player:GetMouse()
            local Position = NewDropdown.AbsolutePosition
            local Size = NewDropdown.AbsoluteSize

            local IsInside =
                Mouse.X >= Position.X
                and Mouse.X <= Position.X + Size.X
                and Mouse.Y >= Position.Y
                and Mouse.Y <= Position.Y + Size.Y

            if not IsInside then
                Paragraph:CloseDropdown()
            end
        end)

        Button.MouseButton1Click:Connect(function()
            if IsShowing then
                Paragraph:CloseDropdown()
                return
            end

            if App:IsDropdownOpen() then
                return
            end

            IsShowing = true
            NewDropdown.Visible = true

            Nodes.Tween(NewDropdown, {
                Time = 0.3,
                Style = "Back",
                Direction = "Out",
                Goal = {
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }
            }):Play()
        end)

        for _, Name in ipairs(Info.List) do
            Paragraph:AddList(Name)
        end

        UpdateOrder()

        return Paragraph
    end

    return Elements
end

Nodes.Application = function(Folder, Args)
    local Application = {} do
        Application.Tabs = {}
        Application.Flags = {}
        Application.Shadows = {}
        Application.Searching = {}
        Application.Callbacks = {}

        Application.SelectTab = nil
        Application.FirstTab = true
        Application.IsFirstRunning = true
        Application.IsCollapseTab = false
        Application.DropdownOpened = false
        Application.WindowToolsOpened = false
        Application.Signal = Nodes.GoodSignal.new()

        Cached.IsResizing = false
        Cached.IsFullScreen = false
    end

    local Logo = Args.Logo or "0"
    local Keybind = Args.Keybind or "LeftControl"

    local Title = Args.Title or "Window"
    local Footer = Args.Footer or "Roblox company."

    local Minimum = Args.Minimum or UDim2.new(0, 500, 0, 360)
    local Maximum = Args.Maximum or UDim2.new(0, 960,0, 700)

    local WindowSize = UDim2.new(0, 575, 0, 515)
    local Current = Nodes.IsMobile and Minimum
    local Size = Args.Size or Current or WindowSize

    function Application:NewElement(Name, Module)
        return typeof(Module) == 'function' and Module(Name)
    end

    function Application:IsDropdownOpen()
        local Dropdowns = {
            "NewDropdown", "NewDialog", "WindowTools"
        }

        for _, v in Framework.Window:GetChildren() do
            if table.find(Dropdowns, v.Name) and v.Visible then
                return true
            end
        end
    end

    function Application:CreateTool(Parent, Settings)
        local Tool = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Settings.Color,
            BackgroundTransparency = 0.94,
            Name = Settings.Name,
            Parent = Parent,
            Size = UDim2.new(1, 0, 0, 50),
        }) do
            local Right = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Right",
                Parent = Tool,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Right,
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Right,
                    PaddingRight = UDim.new(0, 15),
                })

                Nodes.New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Name = "Close",
                    Parent = Right,
                    Size = UDim2.new(0, 25, 0, 25),
                    Image = Nodes.Asset(Settings.Icon),
                    ImageColor3 = Settings.Color,
                    ImageContent = Content.fromUri(Settings.Icon),
                    ImageTransparency = 0.5,
                })
            end

            local Left = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Left",
                Parent = Tool,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIPadding", {
                    Parent = Left,
                    PaddingLeft = UDim.new(0, 15),
                })

                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Left,
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                local Text = Nodes.New("Frame", {
                    AutomaticSize = AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    Name = "Text",
                    Parent = Left,
                    Size = UDim2.new(0, 0, 0, 0),
                }) do
                    Nodes.New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        Parent = Text,
                        SortOrder = SortOrder.LayoutOrder,
                        VerticalAlignment = VerticalAlignment.Center,
                    })

                    Nodes.New("TextLabel", {
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Title",
                        Parent = Text,
                        Size = UDim2.new(0, 0, 0, 0),
                        FontFace = Nodes.FontMedium,
                        Text = Settings.Title,
                        TextColor3 = Settings.Color,
                        TextSize = 15,
                        TextXAlignment = TextXAlignment.Left,
                    })

                    Nodes.New("TextLabel", {
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Desc",
                        Parent = Text,
                        Size = UDim2.new(0, 0, 0, 0),
                        FontFace = Nodes.FontMedium,
                        Text = Settings.Description,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 12,
                        TextTransparency = 0.5,
                        TextXAlignment = TextXAlignment.Left,
                    })
                end
            end
        end

        return Tool
    end

    function Application:Dialog(Info)
        local Shows = {}
        local Hides = {}

        local DialogModule = {
            Title = Info.Title,
            Description = Info.Description,
            Content = Info.Content,
            Icon = Info.Icon,
            Callback = Info.Callback
        }

        local NewDialog = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Name = "NewDialog",
            Parent = Framework.Workspace,
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 300, 0, 200),
        }) do
            Shows[NewDialog] = { BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) }
            Hides[NewDialog] = { BackgroundTransparency = 1 }

            Nodes.New("UICorner", {
                CornerRadius = UDim.new(0, 16),
                Parent = NewDialog,
            })

            Nodes.New("UIStroke", {
                Color = Color3.fromRGB(35, 35, 35),
                Parent = NewDialog,
                Transparency = 1,
            })

            Shows[NewDialog.UIStroke] = { Transparency = 0 }
            Hides[NewDialog.UIStroke] = { Transparency = 1 }

            Nodes.New("UIListLayout", {
                Parent = NewDialog,
                SortOrder = SortOrder.LayoutOrder,
                HorizontalAlignment = HorizontalAlignment.Center,
            })

            local Header = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Header",
                Parent = NewDialog,
                Size = UDim2.new(1, 0, 0, 55),
            }) do
                local Left = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "Left",
                    Parent = Header,
                    Size = UDim2.new(1, 0, 1, 0),
                }) do
                    Nodes.New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        Parent = Left,
                        FillDirection = FillDirection.Horizontal,
                        SortOrder = SortOrder.LayoutOrder,
                        VerticalAlignment = VerticalAlignment.Center,
                    })

                    Nodes.New("UIPadding", {
                        Parent = Left,
                    })

                    local Text = Nodes.New("Frame", {
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Text",
                        Parent = Left,
                        Size = UDim2.new(0, 0, 0, 0),
                    }) do
                        Nodes.New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            Parent = Text,
                            SortOrder = SortOrder.LayoutOrder,
                            VerticalAlignment = VerticalAlignment.Center,
                        })

                        Nodes.New("TextLabel", {
                            AutomaticSize = AutomaticSize.XY,
                            BackgroundTransparency = 1,
                            Name = "Title",
                            Parent = Text,
                            Size = UDim2.new(0, 0, 0, 0),
                            FontFace = Nodes.FontMedium,
                            Text = DialogModule.Title,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = 14,
                            TextXAlignment = TextXAlignment.Left,
                            TextTransparency = 1,
                        })

                        Shows[Text.Title] = { TextTransparency = 0 }
                        Hides[Text.Title] = { TextTransparency = 1 }

                        Nodes.New("TextLabel", {
                            AutomaticSize = AutomaticSize.XY,
                            BackgroundTransparency = 1,
                            Name = "Desc",
                            Parent = Text,
                            Size = UDim2.new(0, 0, 0, 0),
                            FontFace = Nodes.FontMedium,
                            Text = DialogModule.Description,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = 12,
                            TextTransparency = 1,
                            TextXAlignment = TextXAlignment.Left,
                        })

                        Shows[Text.Desc] = { TextTransparency = 0.5 }
                        Hides[Text.Desc] = { TextTransparency = 1 }
                    end

                    local ToolsButton = Nodes.New("Frame", {
                        BackgroundTransparency = 1,
                        LayoutOrder = -5,
                        Name = "ToolsButton",
                        Parent = Left,
                        Size = UDim2.new(0, 60, 1, 0),
                    }) do
                        Nodes.New("ImageLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            Name = "Lucide",
                            Parent = ToolsButton,
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            Size = UDim2.new(0, 25, 0, 25),
                            Image = Nodes.Asset(DialogModule.Icon),
                            ImageTransparency = 1,
                        })

                        Shows[ToolsButton.Lucide] = { ImageTransparency = 0 }
                        Hides[ToolsButton.Lucide] = { ImageTransparency = 1 }
                    end
                end
            end

            Nodes.New("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                Name = "Mainline",
                Parent = NewDialog,
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundTransparency = 1,
            })

            Shows[NewDialog.Mainline] = { BackgroundTransparency = 0 }
            Hides[NewDialog.Mainline] = { BackgroundTransparency = 1 }

            local Info = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Info",
                Parent = NewDialog,
                Size = UDim2.new(1, 0, 0, 100),
            }) do
                local Scroll = Nodes.New("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Name = "Scroll",
                    Parent = Info,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasPosition = Vector2.new(0, 0),
                    ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScrollBarImageTransparency = 0.75,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 0,
                }) do
                    Shows[Scroll] = { 
                        ScrollBarImageTransparency = 0.75,
                        ScrollBarThickness = 3
                    }

                    Hides[Scroll] = { 
                        ScrollBarImageTransparency = 1,
                        ScrollBarThickness = 0
                    }

                    Nodes.New("UIListLayout", {
                        Parent = Scroll,
                        SortOrder = SortOrder.LayoutOrder,
                    })

                    Nodes.New("UIPadding", {
                        Parent = Scroll,
                        PaddingBottom = UDim.new(0, 10),
                        PaddingLeft = UDim.new(0, 15),
                        PaddingRight = UDim.new(0, 15),
                        PaddingTop = UDim.new(0, 10),
                    })

                    Nodes.New("TextLabel", {
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Context",
                        Parent = Scroll,
                        Size = UDim2.new(0, 0, 0, 0),
                        FontFace = Nodes.FontMedium,
                        Text = DialogModule.Content,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 12,
                        TextTransparency = 1,
                        TextWrapped = true,
                        TextXAlignment = TextXAlignment.Left,
                    })

                    Shows[Scroll.Context] = { TextTransparency = 0.5 }
                    Hides[Scroll.Context] = { TextTransparency = 1 }
                end
            end

            local Buttons = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Buttons",
                Parent = NewDialog,
                Size = UDim2.new(1, 0, 0, 44),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    Parent = Buttons,
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                local Cancel = Nodes.New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Name = "Cancel",
                    Parent = Buttons,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 140, 0, 30),
                }) do
                    Shows[Cancel] = { BackgroundTransparency = 0 }
                    Hides[Cancel] = { BackgroundTransparency = 1 }

                    Nodes.New("UICorner", {
                        TopRightRadius = UDim.new(0, 0),
                        BottomRightRadius = UDim.new(0, 0),
                        TopLeftRadius = UDim.new(0, 0),
                        BottomLeftRadius = UDim.new(0, 10),
                        Parent = Cancel,
                    })

                    Nodes.New("TextLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Title",
                        Parent = Cancel,
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, 0),
                        FontFace = Nodes.FontMedium,
                        Text = "Cancel",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextTransparency = 1,
                        TextXAlignment = TextXAlignment.Left,
                    })

                    Shows[Cancel.Title] = { TextTransparency = 0.3 }
                    Hides[Cancel.Title] = { TextTransparency = 1 }

                    Nodes.Button(Cancel).MouseButton1Click:Connect(function()
                        if DialogModule.Callback then
                            DialogModule.Callback(false)
                        end

                        for Object, Hide in Hides do
                            Nodes.Tween(Object, {
                                Time = 0.15,
                                Style = 'Linear',
                                Direction = 'Out',
                                Goal = Hide,
                            }):Play()
                        end

                        task.delay(0.6, function()
                            NewDialog:Destroy()
                        end)
                    end)
                end

                local Confirm = Nodes.New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(234, 234, 234),
                    Name = "Confirm",
                    Parent = Buttons,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 140, 0, 30),
                }) do
                    Shows[Confirm] = { BackgroundTransparency = 0 }
                    Hides[Confirm] = { BackgroundTransparency = 1 }

                    Nodes.New("UICorner", {
                        TopRightRadius = UDim.new(0, 0),
                        BottomRightRadius = UDim.new(0, 10),
                        TopLeftRadius = UDim.new(0, 0),
                        BottomLeftRadius = UDim.new(0, 0),
                        Parent = Confirm,
                    })

                    Nodes.New("TextLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Title",
                        Parent = Confirm,
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, 0),
                        FontFace = Nodes.FontSemi,
                        Text = "Confirm",
                        TextSize = 14,
                        TextTransparency = 1,
                        TextXAlignment = TextXAlignment.Left,
                    })

                    Shows[Confirm.Title] = { TextTransparency = 0 }
                    Hides[Confirm.Title] = { TextTransparency = 1 }

                    Nodes.Button(Confirm).MouseButton1Click:Connect(function()


                        if DialogModule.Callback then
                            DialogModule.Callback(true)
                        end

                        for Object, Hide in Hides do
                            Nodes.Tween(Object, {
                                Time = 0.15,
                                Style = 'Linear',
                                Direction = 'Out',
                                Goal = Hide,
                            }):Play()
                        end

                        task.delay(0.6, function()
                            NewDialog:Destroy()
                        end)
                    end)
                end
            end
        end

        Nodes.New("UIShadow", {
            Parent = NewDialog,
            Transparency = 1,
            BlurRadius = UDim.new(0, 20)
        })

        Shows[NewDialog.UIShadow] = { Transparency = 0.5 }
        Hides[NewDialog.UIShadow] = { Transparency = 1 }

        for Object, Show in Shows do
            Nodes.Tween(Object, {
                Time = 0.3,
                Style = 'Back',
                Direction = 'Out',
                Goal = Show,
            }):Play()
        end

        return DialogModule
    end

    Application:NewElement("@Window", function()
        local ScreenGui = Nodes.New("ScreenGui", {
            ZIndexBehavior = ZIndexBehavior.Global,
            IgnoreGuiInset = true,
            ScreenInsets = ScreenInsets.DeviceSafeInsets,
            Parent = Nodes.Parent,
            Name = Folder,
        })

        local ViewportSize = CurrentCamera.ViewportSize

        local NewSize = UDim2.new(
            0, math.max(ViewportSize.X * 0.7, 500),
            0, math.max(ViewportSize.Y * 0.8, 360)
        )

        local Window = Nodes.New("Frame", {
            BackgroundColor3 = Color3.fromRGB(24, 24, 24),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Parent = ScreenGui,
            Size = Nodes.IsMobile and NewSize or Size,
            Name = "Window",
        }) do
            Nodes.New("UIShadow", {
                Parent = Window,
                BlurRadius = UDim.new(0, 25),
                Transparency = 0.3
            })

            Nodes.New("UICorner", {
                CornerRadius = UDim.new(0, 16),
                Parent = Window
            }) 
        end

        local Workspacetable = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Parent = Window,
            Size = UDim2.new(1, 0, 1, 0),
            Name = "Workspace",
        }) do
            Nodes.New("UICorner", {
                CornerRadius = UDim.new(0, 16),
                Parent = Workspacetable
            }) 
        end

        Nodes.Draggable(Window, function()
            return Cached.IsResizing or Cached.IsFullScreen
        end)

        if not Nodes.IsMobile then
            Nodes.Resizing(Window, Minimum, Maximum)
        end

        Application.Signal:Connect(function(Type)
            if Type == 'FullScreen' then
                Cached.IsFullScreen = not Cached.IsFullScreen

                local IsFullScreen = Cached.IsFullScreen
                local Radius = IsFullScreen and 0 or 16

                if IsFullScreen then
                    Cached.WindowSize = Window.Size
                    Cached.WindowPosition = Window.Position
                end

                Framework.ScreenGui.IgnoreGuiInset = not IsFullScreen
                Window.UICorner.CornerRadius = UDim.new(0, Radius)
                Framework.HeadCorner.TopRightRadius = UDim.new(0, Radius)

                if Application.IsCollapseTab then
                    Framework.HeadCorner.TopLeftRadius = UDim.new(0, Radius)
                end

                Nodes.Tween(Window, {
                    Time = 0.15,
                    Style = 'Exponential',
                    Direction = 'Out',
                    Goal = {
                        Position = IsFullScreen and UDim2.new(0.5, 0, 0.5, 0) or Cached.WindowPosition,
                        Size = IsFullScreen and UDim2.new(1, 0, 1, 0) or Cached.WindowSize
                    }
                }):Play()
            end
        end)

        Framework.Window = Window
        Framework.ScreenGui = ScreenGui
        Framework.Workspace = Window
    end)

    Application:NewElement("@Notification", function()
        local Notification = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Name = "Notification",
            Parent = Framework.ScreenGui,
            Size = UDim2.new(1, 0, 1, 0),
        })

        local History = Nodes.New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Name = "History",
            Parent = Notification,
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 250, 1, 0),
        }) do
            Nodes.New("UIListLayout", {
                Padding = UDim.new(0, 10),
                Parent = History,
                SortOrder = SortOrder.LayoutOrder,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Bottom,
            })

            Nodes.New("UIPadding", {
                Parent = History,
                PaddingBottom = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
            })
        end

        function Application:Notification(Settings)
            local Shows, Hides = {}, {}

            local NotificationModule ={
                Title = Settings.Title or "N/A",
                Desc = Settings.Description or "Unknow message content.",
                Time = Settings.Duration or 5,
                Icon = Settings.Icon or 0
            }

            local NewNotify = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "NewNotify",
                Parent = History,
                Size = UDim2.new(1, 0, 0, 60),
            })

            local Scale = Nodes.New("Frame", {
                BackgroundColor3 = Color3.fromRGB(24, 24, 24),
                Name = "Scale",
                Parent = NewNotify,
                BackgroundTransparency = 0.05,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(1.1, 0, 0, 0)
            }) do
                Nodes.New("UICorner", {
                    Parent = Scale,
                })

                Nodes.New("UIShadow", {
                    Parent = Scale,
                    BlurRadius = UDim.new(0, 20),
                    Transparency = 0.5
                })

                Shows[Scale] = { Position = UDim2.new(0, 0, 0, 0) }
                Hides[Scale] = { Position = UDim2.new(1.1, 0, 0, 0) }
            end

            local Countdown = Nodes.New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 0.949999988079071,
                Name = "Countdown",
                Parent = Scale,
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UICorner", {
                    Parent = Countdown,
                }) 
            end

            local Left = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Left",
                Parent = Scale,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    Parent = Left,
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Left,
                })
            end

            local Text = Nodes.New("Frame", {
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                Name = "Text",
                Parent = Left,
                Size = UDim2.new(0, 0, 0, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Text,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    FontFace = Nodes.FontMedium,
                    Name = "Title",
                    Parent = Text,
                    Size = UDim2.new(0, 0, 0, 0),
                    Text = NotificationModule.Title,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = TextXAlignment.Left,
                })

                Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    FontFace = Nodes.FontMedium,
                    Name = "Desc",
                    Parent = Text,
                    Size = UDim2.new(0, 0, 0, 0),
                    Text = NotificationModule.Desc,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextXAlignment = TextXAlignment.Left,
                })
            end

            local Icon = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = -5,
                Name = "Icon",
                Parent = Left,
                Size = UDim2.new(0, 60, 1, 0),
            }) do
                Nodes.New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = Nodes.Asset(NotificationModule.Icon),
                    Name = "Lucide",
                    Parent = Icon,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 20, 0, 20),
                }) 
            end

            local Elastic = Nodes.Tween(Scale, {
                Time = 0.45,
                Style = "Quint",
                Direction = "Out",
                Goal = Shows[Scale]
            })

            Elastic.Completed:Once(function()
                local Counter = Nodes.Tween(Countdown, {
                    Time = NotificationModule.Time,
                    Style = "Linear",
                    Direction = "Out",
                    Goal = {
                        Size = UDim2.new(0, 0, 1, 0)
                    }
                })

                Countdown.UICorner:Destroy()

                Counter.Completed:Once(function()
                    Nodes.Tween(Scale, {
                        Time = 0.3,
                        Style = "Quint",
                        Direction = "In",
                        Goal = Hides[Scale]
                    }):Play()
                end)

                Counter:Play()
            end)

            Elastic:Play()
        end
    end)

    Application:NewElement("@Maintab", function()
        local Maintab = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Parent = Framework.Window,
            Size = UDim2.new(0, 200, 1, 0),
            Name = "Maintab",
        }) do
            Nodes.New("UIListLayout", {
                Parent = Maintab,
                SortOrder = SortOrder.LayoutOrder,
                HorizontalAlignment = HorizontalAlignment.Center,
            }) 
        end

        Application:NewElement("./Header", function()
            local Header = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Header",
                Parent = Maintab,
                Size = UDim2.new(1, 0, 0, 60),
            })

            local Left = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Left",
                Parent = Header,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                    Parent = Left,
                })

                Nodes.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 20),
                    Parent = Left,
                })
            end

            local Title = Nodes.New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Name = "Title",
                Parent = Left,
                Size = UDim2.new(0, 0, 0, 0),
                FontFace = Nodes.FontMedium,
                Text = Args.Title,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 15,
                TextXAlignment = TextXAlignment.Left,
            })

            local Footer = Nodes.New("TextLabel", {
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                Name = "Footer",
                Parent = Left,
                Size = UDim2.new(0, 0, 0, 0),
                FontFace = Nodes.FontMedium,
                Text = Footer,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                TextTransparency = 0.5,
                TextXAlignment = TextXAlignment.Left,
            })

            local Right = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Right",
                Parent = Header,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                    Parent = Right,
                })

                Nodes.New("UIPadding", {
                    PaddingRight = UDim.new(0, 17),
                    Parent = Right,
                })
            end
        end)

        Application:NewElement("./Search", function()
            local Search = Nodes.New("Frame", {
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                Name = "Search",
                Parent = Maintab,
                Size = UDim2.new(1, -30, 0, 30),
            }) do
                Nodes.New("UICorner", {
                    Parent = Search,
                })

                Nodes.New("UIStroke", {
                    Color = Color3.fromRGB(35, 35, 35),
                    Parent = Search,
                })

                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 6),
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                    Parent = Search,
                })

                Nodes.New("UIPadding", {
                    PaddingRight = UDim.new(0, 8),
                    Parent = Search,
                })
            end

            local Icon = Nodes.New("ImageLabel", {
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Name = "Lucide",
                Parent = Search,
                Size = UDim2.new(0, 18, 0, 18),
                Image = "rbxassetid://78256773704343",
                ImageContent = Content.fromUri("rbxassetid://78256773704343"),
                ImageTransparency = 0.5,
            })

            local Searchable = Nodes.New("TextBox", {
                BackgroundTransparency = 1,
                Parent = Search,
                Size = UDim2.new(1, -35, 1, 0),
                FontFace = Nodes.FontRegular,
                PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
                Text = "",
                PlaceholderText = "Searchable.",
                TextColor3 = Color3.fromRGB(234, 234, 234),
                TextSize = 12,
                TextTruncate = TextTruncate.AtEnd,
                TextXAlignment = TextXAlignment.Left,
            })

            local Space = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Space",
                Parent = Maintab,
                Size = UDim2.new(1, 0, 0, 15),
            }) do
                Nodes.New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Name = "Line",
                    Parent = Space,
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                })
            end

            Searchable:GetPropertyChangedSignal('Text'):Connect(function()
                Application.Signal:Fire('Searchable', {
                    Word = Searchable.Text
                })
            end)
        end)

        Application:NewElement("./Tabscrolling", function()
            local Tabscrolling = Nodes.New("ScrollingFrame", {
                BackgroundTransparency = 1,
                Name = "Tabscrolling",
                Parent = Maintab,
                Size = UDim2.new(1, 0, 1, -165),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                AutomaticCanvasSize = AutomaticSize.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0)
            }) do
                Nodes.New("UIListLayout", {
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    Parent = Tabscrolling,
                })
            end

            Framework.Tabscrolling = Tabscrolling
        end)

        Application:NewElement("./TabResult", function()
            local ResultTab = Nodes.New("Frame", {
                Name = "ResultTab",
                Parent = Framework.Tabscrolling,
                Visible = false,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 50),
            }) do
                Nodes.New("Frame", {
                    Name = "Line",
                    Parent = ResultTab,
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                })
            end

            local Left = Nodes.New("Frame", {
                Name = "Left",
                Parent = ResultTab,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Left,
                    Padding = UDim.new(0, 2),
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Left,
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 20),
                })

                Nodes.New("TextLabel", {
                    Name = "Title",
                    Parent = Left,
                    AutomaticSize = AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 100, 0, 0),
                    FontFace = Nodes.FontMedium,
                    Text = "Not Found",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 15,
                    TextTruncate = TextTruncate.AtEnd,
                    TextXAlignment = TextXAlignment.Left,
                })

                Nodes.New("TextLabel", {
                    Name = "Footer",
                    Parent = Left,
                    AutomaticSize = AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 120, 0, 0),
                    FontFace = Nodes.FontMedium,
                    Text = "No results found.",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextTruncate = TextTruncate.AtEnd,
                    TextXAlignment = TextXAlignment.Left,
                })
            end

            local Right = Nodes.New("Frame", {
                Name = "Right",
                Parent = ResultTab,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Right,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Right,
                    PaddingRight = UDim.new(0, 20),
                })
            end

            local ScaleLucide = Nodes.New("Frame", {
                Name = "ScaleLucide",
                Parent = Right,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 20, 0, 20),
            }) do
                Nodes.New("ImageLabel", {
                    Name = "Lucide",
                    Parent = ScaleLucide,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://140505896789576",
                    ImageTransparency = 0.5,
                })
            end

            Application.Signal:Connect(function(Type, Value)
                if Type == 'SetResultTab' then
                    ResultTab.Visible = Value
                end
            end)
        end)

        Application:NewElement("./Profile", function()
            local ThumbnailType = Enum.ThumbnailType
            local ThumbnailSize = Enum.ThumbnailSize

            local Profile = Nodes.New("Frame", {
                Name = "Profile",
                Parent = Maintab,
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            }) do
                Nodes.New("UICorner", {
                    Parent = Profile,
                    TopRightRadius = UDim.new(0, 0),
                    BottomRightRadius = UDim.new(0, 0),
                    TopLeftRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 16),
                })
            end

            local Line = Nodes.New("Frame", {
                Name = "Line",
                Parent = Profile,
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            })

            local Left = Nodes.New("Frame", {
                Name = "Left",
                Parent = Profile,
                Size = UDim2.new(1, 0, 1, -1),
                BackgroundTransparency = 1,
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Left,
                    Padding = UDim.new(0, 10),
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Left,
                    PaddingLeft = UDim.new(0, 12),
                })
            end

            local Avatar = Nodes.New("ImageLabel", {
                Name = "Avatar",
                Parent = Left,
                Size = UDim2.new(0, 40, 0, 40),
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            }) do
                Nodes.New("UICorner", {
                    Parent = Avatar,
                    CornerRadius = UDim.new(1, 0),
                })

                Nodes.New("UIShadow", {
                    Parent = Avatar,
                    BlurRadius = UDim.new(0, 3),
                    Transparency = 0.75,
                })
            end

            local Text = Nodes.New("Frame", {
                Name = "Text",
                Parent = Left,
                Size = UDim2.new(0, 0, 0, 0),
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Text,
                    Padding = UDim.new(0, 2),
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })
            end

            local Title = Nodes.New("TextLabel", {
                Name = "Title",
                Parent = Text,
                Size = UDim2.new(0, 0, 0, 0),
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                FontFace = Nodes.FontMedium,
                Text = "Welcome",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 15,
                TextXAlignment = TextXAlignment.Left,
            })

            local Username = Nodes.New("TextLabel", {
                Name = "Username",
                Parent = Text,
                Size = UDim2.new(0, 80, 0, 0),
                AutomaticSize = AutomaticSize.Y,
                BackgroundTransparency = 1,
                FontFace = Nodes.FontMedium,
                Text = "None",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                TextTransparency = 0.5,
                TextTruncate = TextTruncate.AtEnd,
                TextXAlignment = TextXAlignment.Left,
            })

            local Right = Nodes.New("Frame", {
                Name = "Right",
                Parent = Profile,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Right,
                    Padding = UDim.new(0, 10),
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Right,
                    PaddingRight = UDim.new(0, 10),
                })
            end

            local Outter = Nodes.New("Frame", {
                Name = "Outter",
                Parent = Right,
                Size = UDim2.new(0, 40, 0, 40),
                BackgroundTransparency = 1,
            })

            local Hidden = false
            local Icon = Nodes.New("ImageLabel", {
                Name = "Icon",
                Parent = Outter,
                Size = UDim2.new(0.5, 0, 0.5, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://106575150727113",
                ImageColor3 = Color3.fromRGB(255, 170, 0),
                ImageTransparency = 0.5,
            })

            Nodes.Button(Avatar).MouseButton1Click:Connect(function()
                Hidden = not Hidden
                Avatar.Image = Hidden and Application.RobloxProfile or Application.PlayerProfile
            end)

            task.defer(function()
                local Success, Image = pcall(
                    Players.GetUserThumbnailAsync,
                    Players, Player.UserId,
                    ThumbnailType.HeadShot,
                    ThumbnailSize.Size420x420
                )

                local Success2, Image2 = pcall(
                    Players.GetUserThumbnailAsync,
                    Players, 1,
                    ThumbnailType.HeadShot,
                    ThumbnailSize.Size420x420
                )

                if Success2 then
                    Application.RobloxProfile = Image2
                end

                if Success then
                    Application.PlayerProfile = Image
                    Avatar.Image = Image

                    Username.Text = Player.Name:gsub("[aeiouAEIOU]", function()
                        return string.char(37, 42, 35):sub(math.random(1, 3), math.random(1, 3))
                    end)
                else
                    Application:Notification({
                        Title = 'Error',
                        Description = "Avatar load failed.",
                        Icon = 80212074789397,
                        Duration = 5
                    })
                end
            end)
        end)
    end)

    Application:NewElement("@Mainpage", function()
        local Mainpage = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Name = "Mainpage",
            Parent = Framework.Window,
            Size = UDim2.new(1, 0, 1, 0),
        }) do
            Nodes.New("UIPadding", {
                Parent = Mainpage,
                PaddingLeft = UDim.new(0, 200),
            })
        end

        local Pages = Nodes.New("Frame", {
            BackgroundColor3 = Color3.fromRGB(22, 22, 22),
            Size = UDim2.new(1, 0, 1, 0),
            Name = "Pages",
            Parent = Mainpage,
        }) do
            Nodes.New("UICorner", {
                TopRightRadius = UDim.new(0, 16),
                BottomRightRadius = UDim.new(0, 16),
                TopLeftRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Pages,
            })
        end

        local Mainline = Nodes.New("Frame", {
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            Name = "Mainline",
            Parent = Pages,
            Size = UDim2.new(0, 1, 1, 0),
        })

        local __index = Nodes.New("Frame", {
            BackgroundTransparency = 1,
            Name = "__index",
            Parent = Pages,
            Size = UDim2.new(1, 0, 1, 0),
            ClipsDescendants = true,
        }) do
            Nodes.New("UIPadding", {
                Parent = __index,
                PaddingTop = UDim.new(0, 50),
            })
        end

        local PageLayout = Nodes.New("UIPageLayout", {
            EasingStyle = EasingStyle.Exponential,
            TweenTime = 0.25,
            Parent = __index,
            FillDirection = FillDirection.Vertical,
            SortOrder = SortOrder.LayoutOrder,
            GamepadInputEnabled = false,
            ScrollWheelInputEnabled = false,
            TouchInputEnabled = false,
        })

        Application:NewElement("./SearchResult", function()
            local Result = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Visible = false,
                Name = "Result",
                Parent = Pages,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIPadding", {
                    Parent = Result,
                    PaddingTop = UDim.new(0, 35),
                })

                Nodes.New("UIListLayout", {
                    Parent = Result,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Name = "Icon",
                    Parent = Result,
                    Size = UDim2.new(0, 60, 0, 60),
                    Image = "rbxassetid://140505896789576",
                    ImageContent = Content.fromUri("rbxassetid://140505896789576"),
                    ImageTransparency = 0.25,
                })
            end

            local Text = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Text",
                Parent = Result,
                Size = UDim2.new(1, 0, 0, 35),
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Text,
                    Padding = UDim.new(0, 2),
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Name = "Title",
                    Parent = Text,
                    Size = UDim2.new(1, 0, 0, 0),
                    FontFace = Nodes.FontMedium,
                    Text = "404 not found",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 18,
                    TextTruncate = TextTruncate.AtEnd,
                })

                Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Name = "Desc",
                    Parent = Text,
                    Size = UDim2.new(1, 0, 0, 0),
                    FontFace = Nodes.FontMedium,
                    RichText = true,
                    Text = "Nothing found for your search",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextTruncate = TextTruncate.AtEnd,
                })
            end

            Application.Signal:Connect(function(Type, Found)
                if Type == 'SetResultPage' then
                    Result.Visible = Found
                end
            end)
        end)

        Application:NewElement("./WindowTools", function()
            local WindowTools = Nodes.New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                Name = "WindowTools",
                Parent = Framework.Workspace,
                Position = UDim2.new(0.5, 0, 0.3, 0),
                Size = UDim2.new(0, 300, 0, 200),
                Visible = false
            }) do
                Nodes.New("UICorner", {
                    CornerRadius = UDim.new(0, 16),
                    Parent = WindowTools,
                })

                Nodes.New("UIStroke", {
                    Color = Color3.fromRGB(35, 35, 35),
                    Parent = WindowTools,
                })

                Nodes.New("UIStroke", {
                    Name = "Shadow",
                    Parent = WindowTools,
                    Transparency = 0.7,
                })

                Nodes.New("UIShadow", {
                    Parent = WindowTools,
                    BlurRadius = UDim.new(0, 40),
                    Transparency = 0.5,
                })

                Nodes.New("UIListLayout", {
                    Parent = WindowTools,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                    VerticalFlex = UIFlexAlignment.Fill,
                })

                Nodes.New("UIPadding", {
                    Parent = WindowTools,
                    PaddingBottom = UDim.new(0, 2),
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    PaddingTop = UDim.new(0, 2),
                })
            end

            local FullScreen = Application:CreateTool(WindowTools, {
                Name = "FullScreen",
                Title = "Fullscreen",
                Description = "Max size of window.",
                Color = Color3.fromRGB(40, 200, 64),
                Icon = "rbxassetid://72097270213792",
            }) do
                Nodes.New("UICorner", {
                    TopRightRadius = UDim.new(0, 16),
                    BottomRightRadius = UDim.new(0, 0),
                    TopLeftRadius = UDim.new(0, 16),
                    BottomLeftRadius = UDim.new(0, 0),
                    Parent = FullScreen,
                })

                Nodes.Button(FullScreen).MouseButton1Click:Connect(function()
                    WindowTools.Visible = false
                    Application.WindowToolsOpened = false

                    Application.Signal:Fire('FullScreen')
                end)
            end

            local Collapse = Application:CreateTool(WindowTools, {
                Name = "Collapse",
                Title = "Collapse",
                Description = "Hide the tab of window.",
                Color = Color3.fromRGB(254, 188, 46),
                Icon = "rbxassetid://122111834524820",
            }) do
                Nodes.Button(Collapse).MouseButton1Click:Connect(function()
                    WindowTools.Visible = false
                    Application.WindowToolsOpened = false

                    Application.Signal:Fire('Collapse')
                end)
            end

            local Close = Application:CreateTool(WindowTools, {
                Name = "Close",
                Title = "Destroyer",
                Description = "Destroy the window.",
                Color = Color3.fromRGB(255, 51, 51),
                Icon = "rbxassetid://80212074789397",
            }) do
                Nodes.New("UICorner", {
                    TopRightRadius = UDim.new(0, 0),
                    BottomRightRadius = UDim.new(0, 16),
                    TopLeftRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 16),
                    Parent = Close,
                })

                Nodes.Button(Close).MouseButton1Click:Connect(function()
                    WindowTools.Visible = false

                    Application:Dialog({
                        Title = "Are you sure?",
                        Description = "to close window page.",
                        Content = "If you close i will cant open it again",
                        Icon = 71601463400945,
                        Callback = function(State)
                            Application.WindowToolsOpened = false

                            if State then
                                Framework.ScreenGui:Destroy()
                            end
                        end,
                    })
                end)
            end

            UserInputService.InputBegan:Connect(function(Input)
                local Mouse = Player:GetMouse()
                local MouseX, MouseY = Mouse.X, Mouse.Y

                local Position = WindowTools.AbsolutePosition
                local Size = WindowTools.AbsoluteSize

                if Input.UserInputType == UserInputType.MouseButton1 or Input.UserInputType == UserInputType.Touch then
                    local IsInside =
                        MouseX >= Position.X
                        and MouseX <= Position.X + Size.X
                        and MouseY >= Position.Y
                        and MouseY <= Position.Y + Size.Y

                    if not IsInside then
                        Application.WindowToolsOpened = false
                        WindowTools.Visible = false
                        WindowTools.Position = UDim2.new(0.5, 0, 0.3, 0)
                    end
                end
            end)

            Application.Signal:Connect(function(Type, ToolButton)
                if Type == 'OpenTools' then
                    Application.WindowToolsOpened = true
                    WindowTools.Visible = true

                    Nodes.Tween(WindowTools, {
                        Time = 0.3,
                        Style = 'Back',
                        Direction = 'Out',
                        Goal = {
                            Position = UDim2.new(0.5, 0, 0.5, 0)
                        }
                    }):Play()
                end
            end)
        end)

        Application:NewElement("./Head", function()
            local Signal = Application.Signal

            local Head = Nodes.New("Frame", {
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                Name = "Head",
                Parent = Mainpage,
                Size = UDim2.new(1, 0, 0, 50),
            }) do
                Nodes.New("UICorner", {
                    TopRightRadius = UDim.new(0, 16),
                    BottomRightRadius = UDim.new(0, 0),
                    TopLeftRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 0),
                    Parent = Head,
                })

                Framework.HeadCorner = Head.UICorner
            end

            local Right = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Right",
                Parent = Head,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Parent = Right,
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Right,
                    PaddingRight = UDim.new(0, 15),
                })
            end

            local BackButton = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "BackButton",
                Parent = Right,
                Size = UDim2.new(0, 30, 1, 0),
            }) do
                Nodes.New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Parent = BackButton,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 25, 0, 25),
                    ImageTransparency = 0.6,
                    Image = "rbxassetid://104312702185319",
                    ImageContent = Content.fromUri("rbxassetid://104312702185319"),
                }) 

                Nodes.Button(BackButton).MouseButton1Click:Connect(function()
                    Signal:Fire("PreviousTab", {
                        Icon = BackButton.ImageLabel,
                        Function = function()
                            PageLayout:Previous()
                        end,
                    })
                end)
            end

            local NextButton = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "NextButton",
                Parent = Right,
                Size = UDim2.new(0, 30, 1, 0),
            }) do
                Nodes.New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Parent = NextButton,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 25, 0, 25),
                    Image = "rbxassetid://130050888244501",
                    ImageTransparency = 0.6,
                    ImageContent = Content.fromUri("rbxassetid://130050888244501"),
                }) 

                Nodes.Button(NextButton).MouseButton1Click:Connect(function()
                    Signal:Fire("NextTab", {
                        Icon = NextButton.ImageLabel,
                        Function = function()
                            PageLayout:Next()
                        end,
                    })
                end)
            end

            local Left = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                Name = "Left",
                Parent = Head,
                Size = UDim2.new(1, 0, 1, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Left,
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("UIPadding", {
                    Parent = Left,
                })
            end

            local Text = Nodes.New("Frame", {
                AutomaticSize = AutomaticSize.XY,
                BackgroundTransparency = 1,
                Name = "Text",
                Parent = Left,
                Size = UDim2.new(0, 0, 0, 0),
            }) do
                Nodes.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Text,
                    SortOrder = SortOrder.LayoutOrder,
                    VerticalAlignment = VerticalAlignment.Center,
                })
            end

            local Title = Nodes.New("TextLabel", {
                AutomaticSize = AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = "Title",
                Parent = Text,
                Size = UDim2.new(0, 100, 0, 0),
                TextTruncate = TextTruncate.AtEnd,
                FontFace = Nodes.FontMedium,
                Text = "Loading",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = TextXAlignment.Left,
            })

            local Desc = Nodes.New("TextLabel", {
                AutomaticSize = AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = "Desc",
                Parent = Text,
                Size = UDim2.new(0, 120, 0, 0),
                TextTruncate = TextTruncate.AtEnd,
                FontFace = Nodes.FontMedium,
                Text = "Waiting for loading tabs.",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                TextTransparency = 0.5,
                TextXAlignment = TextXAlignment.Left,
            })

            local ToolsButton = Nodes.New("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = -5,
                Name = "ToolsButton",
                Parent = Left,
                Size = UDim2.new(0, 60, 1, 0),
            }) do
                Nodes.New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Name = "Lucide",
                    Parent = ToolsButton,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 25, 0, 25),
                    Image = "rbxassetid://84570865508509",
                    ImageContent = Content.fromUri("rbxassetid://84570865508509"),
                }) 

                Nodes.Button(ToolsButton).MouseButton1Click:Connect(function()
                    Signal:Fire('OpenTools', ToolsButton)
                end)
            end

            local Search = Nodes.New("Frame", {
                Name = "Search",
                Parent = Left,
                Size = UDim2.new(1, -250, 1, 0),
                BackgroundTransparency = 1,
            }) do
                Search:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
                    Search.Visible = Search.AbsoluteSize.X > 125 and true or false
                end)
            end

            local __search = Nodes.New("Frame", {
                Name = "__search",
                Parent = Search,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -50, 0, 30),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                BackgroundTransparency = 0.35,
            }) do
                Nodes.New("UICorner", {
                    Parent = __search,
                })

                Nodes.New("UIListLayout", {
                    Parent = __search,
                    Padding = UDim.new(0, 6),
                    FillDirection = FillDirection.Horizontal,
                    SortOrder = SortOrder.LayoutOrder,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Center,
                })

                Nodes.New("ImageLabel", {
                    Name = "Lucide",
                    Parent = __search,
                    LayoutOrder = 1,
                    Size = UDim2.new(0, 18, 0, 18),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://78256773704343",
                    ImageContent = Content.fromUri("rbxassetid://78256773704343"),
                    ImageTransparency = 0.5,
                })

                Nodes.New("UIPadding", {
                    Parent = __search,
                    PaddingRight = UDim.new(0, 8),
                })

                Nodes.New("TextBox", {
                    Parent = __search,
                    Size = UDim2.new(1, -35, 1, 0),
                    BackgroundTransparency = 1,
                    CursorPosition = -1,
                    FontFace = Nodes.FontRegular,
                    PlaceholderColor3 = Color3.fromRGB(127, 127, 127),
                    PlaceholderText = "Search Option.",
                    Text = "",
                    TextColor3 = Color3.fromRGB(234, 234, 234),
                    TextSize = 12,
                    TextTruncate = TextTruncate.AtEnd,
                    TextXAlignment = TextXAlignment.Left,
                })

                __search.TextBox:GetPropertyChangedSignal('Text'):Connect(function()
                    Signal:Fire("UpdateLine")
                    Signal:Fire("OptionSearch", __search.TextBox.Text)
                end)

                Framework.MainSearch = __search.TextBox
            end

            function Application:GetOrderByIndex()
                for _, TabModule in self.Tabs do
                    if TabModule.Index == PageLayout.CurrentPage then
                        return TabModule.Order
                    end
                end
            end

            function Application:GetTargetOrder(Type)
                local CurrentOrder = self:GetOrderByIndex()

                local TotalTabs = #self.Tabs
                local TargetOrder = Type == "PreviousTab" and CurrentOrder - 1 or CurrentOrder + 1

                local CanMove = TotalTabs > 1 and TargetOrder >= 1 and TargetOrder <= TotalTabs
                if not CanMove then return end

                return TargetOrder, self.Tabs[TargetOrder]
            end

            Signal:Connect(function(Type, Info)
                if Type == "OptionSearch" and Framework.Pages then
                    local Found = false

                    local Query = string.lower(Info)
                    local CurrentPage = PageLayout.CurrentPage
                    local SectionVisible = {}

                    for _, Data in Application.Searching do
                        if not SectionVisible[Data.Section] then
                            SectionVisible[Data.Section] = {
                                Original = Data.Original,
                                Match = false,
                                Rows = {}
                            }
                        end

                        if Query == "" then
                            Data.Row.Visible = true

                            Data.Title.RichText = false
                            Data.SectionTitle.RichText = false

                            Data.Title.Text = Data.OriginalTitle
                            Data.SectionTitle.Text = Data.OriginalSectionTitle

                            if Data.Desc and not Data.Row:GetAttribute('Dropdown') then
                                Data.Desc.RichText = false
                                Data.Desc.Text = Data.OriginalDesc
                            end

                            table.insert(
                                SectionVisible[Data.Section].Rows,
                                Data.RowModule
                            )

                            SectionVisible[Data.Section].Match = true
                        else
                            local SectionTitle = string.lower(
                                Data.Section.Header.Left.Title.Text
                            )

                            local TitleText = string.lower(
                                Data.OriginalTitle
                            )

                            local DescText = Data.OriginalDesc
                                and string.lower(Data.OriginalDesc)
                                or ""

                            local Match =
                                string.find(TitleText, Query, 1, true)
                                or string.find(DescText, Query, 1, true)
                                or string.find(SectionTitle, Query, 1, true)

                            Data.Row.Visible = Match ~= nil

                            if Match then
                                Found = true

                                Data.Title.RichText = true
                                Data.Title.Text = Nodes.Highlight(
                                    Data.OriginalTitle,
                                    Info
                                )

                                if Data.Desc and not Data.Row:GetAttribute('Dropdown') then
                                    Data.Desc.RichText = true
                                    Data.Desc.Text = Nodes.Highlight(
                                        Data.OriginalDesc,
                                        Info
                                    )
                                end

                                Data.SectionTitle.RichText = true
                                Data.SectionTitle.Text = Nodes.Highlight(
                                    Data.OriginalSectionTitle,
                                    Info
                                )

                                SectionVisible[Data.Section].Match = true

                                table.insert(
                                    SectionVisible[Data.Section].Rows,
                                    Data.RowModule
                                )
                            else
                                Data.Title.RichText = false
                                Data.Title.Text = Data.OriginalTitle

                                if Data.Desc and not Data.Row:GetAttribute('Dropdown') then
                                    Data.Desc.RichText = false
                                    Data.Desc.Text = Data.OriginalDesc
                                end

                                Data.SectionTitle.RichText = false
                                Data.SectionTitle.Text = Data.OriginalSectionTitle
                            end
                        end
                    end

                    for Section, Data in SectionVisible do
                        Section.Parent = (Query == "" or Data.Match)
                            and Data.Original
                            or CurrentPage

                        Section.Visible = true

                        if Query ~= "" then
                            Section.Parent = Data.Match
                                and CurrentPage
                                or Data.Original

                            Section.Visible = Data.Match
                        end

                        Nodes.UpdateLine(Data.Rows)
                    end

                    Signal:Fire(
                        "SetResultPage",
                        Query ~= "" and not Found
                    )

                    return nil
                end

                if Type == "Collapse" then
                    Application.IsCollapseTab = not Application.IsCollapseTab

                    local IsCollapsed = Application.IsCollapseTab
                    local Visible = not IsCollapsed

                    local Radius = IsCollapsed and 16 or 0
                    local PaddingLeft = IsCollapsed and 0 or 200

                    if Visible then
                        Framework.Window.Maintab.Visible = true
                        Mainline.Visible = true
                    end

                    Nodes.Tween(Mainpage.UIPadding, {
                        Time = 0.3,
                        Style = "Exponential",
                        Direction = "Out",
                        Goal = {
                            PaddingLeft = UDim.new(0, PaddingLeft),
                        },
                    }):Play()

                    Nodes.Tween(Head.UICorner, {
                        Time = 0.25,
                        Style = "Exponential",
                        Direction = "Out",
                        Goal = {
                            TopLeftRadius = UDim.new(0, Cached.IsFullScreen and 0 or Radius),
                        },
                    }):Play()

                    Nodes.MultiTweens(Pages.UICorner, {
                        TopLeftRadius = {
                            Time = 0.25,
                            Goal = UDim.new(0, Radius),
                        },
                        BottomLeftRadius = {
                            Time = 0.25,
                            Goal = UDim.new(0, Radius),
                        },
                    })

                    Nodes.Tween(Mainline, {
                        Time = 0.2,
                        Style = "Exponential",
                        Direction = "Out",
                        Goal = {
                            BackgroundTransparency = IsCollapsed and 1 or 0,
                        },
                    }):Play()

                    task.delay(0.2, function()
                        if Application.IsCollapseTab then
                            Framework.Window.Maintab.Visible = false
                            Mainline.Visible = false
                        end
                    end)

                    return nil
                end

                if Type == 'TextChanged' then
                    if Info[3] then
                        local TotalTabs = #Application.Tabs

                        Nodes.Tween(BackButton.ImageLabel, {
                            Time = 0.2, Style = "Linear", Direction = "Out",
                            Goal = { ImageTransparency = (TotalTabs <= 1 or Info[3] <= 1) and 0.6 or 0 },
                        }):Play()

                        Nodes.Tween(NextButton.ImageLabel, {
                            Time = 0.2, Style = "Linear", Direction = "Out",
                            Goal = { ImageTransparency = (TotalTabs <= 1 or Info[3] >= TotalTabs) and 0.6 or 0 },
                        }):Play() 
                    end

                    Title.Text = Info[1]
                    Desc.Text = Info[2]

                    if Nodes.IsThaiCharacter(Info[2]) then
                        Text.UIListLayout.Padding = UDim.new(0, 0)
                        Desc.TextSize = 14
                    else
                        Text.UIListLayout.Padding = UDim.new(0, 2)
                        Desc.TextSize = 12
                    end

                    if Nodes.IsThaiCharacter(Info[1]) then
                        Title.TextSize = 16
                    else
                        Title.TextSize = 15
                    end
                end
            end)
        end)

        Framework.Pages = __index
        Framework.PageLayout = PageLayout
    end)

    Application:NewElement("@Elements", function()
        local Elements = {} do
            Framework.Elements = Elements
        end

        local Pages = Framework.Pages
        local PageLayout = Framework.PageLayout
        local Tabscrolling = Framework.Tabscrolling

        function Application:MakeTab(Settings)
            local TabModule = {
                Tweenings = {},
                Icon = Settings.Icon,
                Selected = Settings.Selected,
                Title = Settings.Title,
                Description = Settings.Description,
            }

            local IsThai = TabModule.Description and Nodes.IsThaiCharacter(TabModule.Description)
            local LayoutPadding = IsThai and 0 or 2

            Application:NewElement("./PageComponents", function()
                local NewPage = Nodes.New("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Name = "NewPage",
                    Parent = Pages,
                    Size = UDim2.new(1, 0, 1, 0),
                    ScrollBarImageTransparency = 1,
                    ClipsDescendants = true,
                    ScrollBarThickness = 0,
                }) do
                    Nodes.New("UIListLayout", {
                        Padding = UDim.new(0, 15),
                        Parent = NewPage,
                        SortOrder = SortOrder.LayoutOrder,
                        HorizontalAlignment = HorizontalAlignment.Center,
                    })

                    Nodes.New("UIPadding", {
                        Parent = NewPage,
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10),
                        PaddingTop = UDim.new(0, 10),
                    })
                end

                TabModule.Index = NewPage
            end)

            Application:NewElement("./TabComponents", function()
                local NewTab = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "NewTab",
                    Parent = Tabscrolling,
                    Size = UDim2.new(1, 0, 0, 50),
                })

                NewTab:SetAttribute('OnPage', false)

                local Left = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "Left",
                    Parent = NewTab,
                    Size = UDim2.new(1, 0, 1, 0),
                }) do
                    Nodes.New("UIListLayout", {
                        Padding = UDim.new(0, LayoutPadding),
                        Parent = Left,
                        SortOrder = SortOrder.LayoutOrder,
                        VerticalAlignment = VerticalAlignment.Center,
                    })

                    Nodes.New("UIPadding", {
                        Parent = Left,
                        PaddingBottom = UDim.new(0, 3),
                        PaddingLeft = UDim.new(0, 20),
                    })
                end

                local Title = Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Name = "Title",
                    Parent = Left,
                    Size = UDim2.new(0, 100, 0, 0),
                    TextTruncate = TextTruncate.AtEnd,
                    RichText = true,
                    FontFace = Nodes.FontMedium,
                    Text = TabModule.Title,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 15,
                    TextXAlignment = TextXAlignment.Left,
                })

                local Footer = Nodes.New("TextLabel", {
                    AutomaticSize = AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Name = "Footer",
                    Parent = Left,
                    Size = UDim2.new(0, 120, 0, 0),
                    TextTruncate = TextTruncate.AtEnd,
                    RichText = true,
                    FontFace = Nodes.FontMedium,
                    Text = TabModule.Description,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextXAlignment = TextXAlignment.Left,
                })

                local Line = Nodes.New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Name = "Line",
                    Parent = NewTab,
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Right = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "Right",
                    Parent = NewTab,
                    Size = UDim2.new(1, 0, 1, 0),
                }) do
                    Nodes.New("UIListLayout", {
                        Parent = Right,
                        SortOrder = SortOrder.LayoutOrder,
                        HorizontalAlignment = HorizontalAlignment.Right,
                        VerticalAlignment = VerticalAlignment.Center,
                    })

                    Nodes.New("UIPadding", {
                        Parent = Right,
                        PaddingRight = UDim.new(0, 20),
                    })
                end

                local ScaleLucide = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "ScaleLucide",
                    Parent = Right,
                    Size = UDim2.new(0, 20, 0, 20),
                })

                local Lucide = Nodes.New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Name = "Lucide",
                    Parent = ScaleLucide,
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = Nodes.Asset(TabModule.Icon),
                    ImageTransparency = 0.5,
                })

                local Actived = Nodes.New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(234, 234, 234),
                    Name = "Actived",
                    Parent = NewTab,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 5, 0, 0)
                })

                TabModule.Text = {
                    Title = Title,
                    Footer = Footer
                }

                TabModule.Tab = NewTab
                TabModule.Lucide = Lucide
                TabModule.Order = #Application.Tabs + 1
                TabModule.Tweenings['@TabComponents'] = {
                    Actived = {
                        Selected = {
                            BackgroundTransparency = {
                                Time = 0.25,
                                Goal = 0
                            },
                            Size = {
                                Time = 0.15,
                                Goal = UDim2.new(0, 5, 1, 0)
                            }
                        },
                        UnSelect = {
                            BackgroundTransparency = {
                                Time = 0.25,
                                Goal = 1
                            },
                            Size = {
                                Time = 0.15,
                                Goal = UDim2.new(0, 5, 0, 0)
                            }
                        }
                    },
                    Lucide = {
                        Selected = {
                            Rotation = {
                                Time = 0.1,
                                Goal = 45
                            },
                            ImageTransparency = {
                                Time = 0.15,
                                Goal = 0
                            }
                        },
                        UnSelect = {
                            Rotation = {
                                Time = 0.1,
                                Goal = 0
                            },
                            ImageTransparency = {
                                Time = 0.15,
                                Goal = 0.5
                            }
                        }
                    },
                    NewTab = {
                        Selected = {
                            BackgroundTransparency = {
                                Time = 0.15,
                                Goal = 0.975
                            },
                        },
                        UnSelect = {
                            BackgroundTransparency = {
                                Time = 0.15,
                                Goal = 1
                            }
                        }
                    },
                }
            end)

            local Tab = TabModule.Tab
            local Page = TabModule.Index
            local Tweenings = TabModule.Tweenings['@TabComponents']

            Page.UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Page.CanvasSize = UDim2.new(0, 0, 0, Page.UIListLayout.AbsoluteContentSize.Y + 20)
            end)

            TabModule.BindToSelect = function(SelectTab, IsSelected, CurrentOrder)
                SelectTab:SetAttribute("OnPage", IsSelected)

                local State = IsSelected and "Selected" or "UnSelect"

                Nodes.ScrollTo(Tabscrolling, SelectTab)

                Nodes.MultiTweens(
                    SelectTab,
                    Tweenings.NewTab[State]
                )

                Nodes.MultiTweens(
                    SelectTab.Actived,
                    Tweenings.Actived[State]
                )
                Nodes.MultiTweens(
                    SelectTab.Right.ScaleLucide.Lucide,
                    Tweenings.Lucide[State]
                )

                if not IsSelected then
                    return
                end

                Application.Signal:Fire("TextChanged", {
                    TabModule.Title,
                    TabModule.Description,
                    CurrentOrder,
                })

                Application.SelectTab = SelectTab
                PageLayout:JumpTo(Page) 
            end

            TabModule.OnBindable = function(CurrentOrder)
                Framework.MainSearch.Text = ""

                for _, v in Framework.Pages:GetChildren() do
                    if v.Name == 'NewPage' and v.Visible then
                        v.Visible = false
                    end
                end

                for _, Frame in Tabscrolling:GetChildren() do
                    if Frame.Name == 'NewTab' then
                        TabModule.BindToSelect(Frame, false)
                    end
                end

                Page.Visible = true
                TabModule.BindToSelect(Tab, true, CurrentOrder)
            end

            Nodes.Button(Tab).MouseButton1Click:Connect(function()
                if not Tab:GetAttribute('OnPage') then
                    TabModule.OnBindable(TabModule.Order)
                end
            end)

            table.insert(Application.Tabs, TabModule)

            task.delay(0.15, function()
                if Application.IsFirstRunning then
                    TabModule.OnBindable(TabModule.Order)
                    Application.IsFirstRunning = false
                end
            end)

            function TabModule:Switch()
                if not Tab:GetAttribute('OnPage') then
                    TabModule.OnBindable(TabModule.Order)
                end
            end

            function TabModule:ScrollTo(Target)
                if not Target then return end
                if not Target:IsDescendantOf(Page) then return end

                task.delay(1, function()
                    Nodes.ScrollTo(Page, Target)
                end)
            end

            function TabModule:Section(Text)
                local SectionModule = {
                    Title = Text
                }

                local NewSection = Nodes.New("Frame", {
                    AutomaticSize = AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                    Name = "NewSection",
                    Parent = Page,
                }) do
                    Nodes.New("UIStroke", {
                        Color = Color3.fromRGB(35, 35, 35),
                        Thickness = 0.6,
                        Parent = NewSection,
                        BorderStrokePosition = "Inner"
                    })

                    Nodes.New("UICorner", {
                        BottomLeftRadius = UDim.new(0, 10),
                        BottomRightRadius = UDim.new(0, 10),
                        TopRightRadius = UDim.new(0, 5),
                        TopLeftRadius = UDim.new(0, 5),
                        Parent = NewSection,
                    })

                    Nodes.New("UIStroke", {
                        Thickness = 1.5,
                        Transparency = 0.7,
                        Name = "Shadow",
                        Parent = NewSection,
                        BorderStrokePosition = "Outer"
                    })

                    Nodes.New("UIShadow", {
                        Parent = NewSection,
                        Transparency = 0.75,
                        BlurRadius = UDim.new(0, 10)
                    })

                    Nodes.New("UIListLayout", {
                        SortOrder = SortOrder.LayoutOrder,
                        HorizontalAlignment = HorizontalAlignment.Center,
                        Parent = NewSection,
                    })
                end

                local Header = Nodes.New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(33, 33, 33),
                    Name = "Header",
                    Parent = NewSection,
                    Size = UDim2.new(1, 0, 0, 35),
                }) do
                    Nodes.New("UICorner", {
                        BottomLeftRadius = UDim.new(0, 0),
                        BottomRightRadius = UDim.new(0, 0),
                        TopRightRadius = UDim.new(0, 5),
                        TopLeftRadius = UDim.new(0, 5),
                        Parent = Header,
                    })
                end

                local Left = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "Left",
                    Parent = Header,
                    Size = UDim2.new(1, 0, 1, 0),
                }) do
                    Nodes.New("UIPadding", {
                        PaddingLeft = UDim.new(0, 15),
                        Parent = Left,
                    })

                    Nodes.New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        FillDirection = FillDirection.Horizontal,
                        SortOrder = SortOrder.LayoutOrder,
                        VerticalAlignment = VerticalAlignment.Center,
                        Parent = Left,
                    })

                    Nodes.New("TextLabel", {
                        AutomaticSize = AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Name = "Title",
                        Parent = Left,
                        Size = UDim2.new(0, 0, 0, 0),
                        FontFace = Nodes.FontMedium,
                        Text = SectionModule.Title,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 15,
                        TextXAlignment = TextXAlignment.Left,
                    })
                end

                local Right = Nodes.New("Frame", {
                    BackgroundTransparency = 1,
                    Name = "Right",
                    Parent = Header,
                    Size = UDim2.new(1, 0, 1, 0),
                }) do
                    Nodes.New("UIPadding", {
                        PaddingRight = UDim.new(0, 15),
                        Parent = Right,
                    })

                    Nodes.New("UIListLayout", {
                        Padding = UDim.new(0, 7),
                        FillDirection = FillDirection.Horizontal,
                        SortOrder = SortOrder.LayoutOrder,
                        HorizontalAlignment = HorizontalAlignment.Right,
                        VerticalAlignment = VerticalAlignment.Center,
                        Parent = Right,
                    })

                    local Red = Nodes.New("Frame", {
                        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
                        LayoutOrder = 5,
                        Name = "Red",
                        Parent = Right,
                        Size = UDim2.new(0, 10, 0, 10),
                    }) do
                        Nodes.New("UICorner", {
                            CornerRadius = UDim.new(1, 0),
                            Parent = Red,
                        })

                        Nodes.New("UIStroke", {
                            Transparency = 0.5,
                            Parent = Red,
                        })
                    end

                    local Yellow = Nodes.New("Frame", {
                        BackgroundColor3 = Color3.fromRGB(254, 188, 46),
                        LayoutOrder = 4,
                        Name = "Yellow",
                        Parent = Right,
                        Size = UDim2.new(0, 10, 0, 10),
                    }) do
                        Nodes.New("UICorner", {
                            CornerRadius = UDim.new(1, 0),
                            Parent = Yellow,
                        })

                        Nodes.New("UIStroke", {
                            Transparency = 0.5,
                            Parent = Yellow,
                        })
                    end

                    local Green = Nodes.New("Frame", {
                        BackgroundColor3 = Color3.fromRGB(40, 200, 64),
                        LayoutOrder = 3,
                        Name = "Green",
                        Parent = Right,
                        Size = UDim2.new(0, 10, 0, 10),
                    }) do
                        Nodes.New("UICorner", {
                            CornerRadius = UDim.new(1, 0),
                            Parent = Green,
                        })

                        Nodes.New("UIStroke", {
                            Transparency = 0.5,
                            Parent = Green,
                        })
                    end
                end

                return Nodes.BuildElements(Application, {
                    Section = NewSection,
                    Page = Page
                })
            end

            return TabModule
        end

        Application.Signal:Connect(function(Type, Info)
            if Type == 'Searchable' then
                local Word = Info.Word
                local HasResult = false

                for _, TabModule in Application.Tabs do
                    local Text = TabModule.Text

                    local Title = Text.Title
                    local Footer = Text.Footer

                    if Word == "" then
                        TabModule.Tab.Visible = true

                        Title.RichText = false
                        Title.Text = TabModule.Title

                        Footer.RichText = false
                        Footer.Text = TabModule.Description

                        continue
                    end

                    local TitleMatch = TabModule.Title:lower():find(Word:lower(), 1, true)
                    local FooterMatch = TabModule.Description:lower():find(Word:lower(), 1, true)

                    if not TitleMatch and not FooterMatch then
                        TabModule.Tab.Visible = false
                        continue
                    end

                    HasResult = true
                    TabModule.Tab.Visible = true

                    Title.RichText = true
                    Footer.RichText = true

                    Title.Text = Nodes.Highlight(TabModule.Title, Word)
                    Footer.Text = Nodes.Highlight(TabModule.Description, Word)
                end

                Application.Signal:Fire('SetResultTab', Word ~= "" and not HasResult)

                return nil
            end

            if Type ~= "PreviousTab" and Type ~= "NextTab" then
                return nil
            end

            local Order, Tab = Application:GetTargetOrder(Type)
            if not Tab or not Order then return end
            Info.Function(); Tab.OnBindable(Order)
        end)

        return Elements
    end)

    Application:NewElement("@Pillow", function()
        local PillowScreen = Nodes.New("ScreenGui", {
            Name = Folder,
            Parent = Nodes.Parent,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            IgnoreGuiInset = true,
        })

        local Pillow = Nodes.New("TextButton", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Name = "Pillow",
            Parent = PillowScreen,
            Position = UDim2.new(0.06, 0, 0.35, 0),
            Size = UDim2.new(0, 50, 0, 50),
            Text = "",
            ZIndex = 999,
            AutoButtonColor = false,
        })

        local Background = Nodes.New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Background",
            Parent = Pillow,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://105462327036706",
            ImageColor3 = Color3.fromRGB(22, 22, 22),
            ImageContent = Content.fromUri("rbxassetid://105462327036706"),
        })

        local LogoImage = Nodes.New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = "Logo",
            Parent = Background,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 25, 0, 25),
            Image = Nodes.Asset(Logo),
            ScaleType = ScaleType.Crop,
        })

        local Scale = Nodes.New("UIScale", {
            Parent = Background,
            Scale = 1,
        })

        Pillow.MouseButton1Click:Connect(function()
            Framework.Window.Visible = not Framework.Window.Visible

            Scale.Scale = 0.8

            Nodes.Tween(Scale, {
                Time = 0.35,
                Style = "Back",
                Direction = "Out",
                Goal = { Scale = 1 }
            }):Play()
        end)

        Nodes.Draggable(Pillow, function()
            return Cached.IsResizing
        end)
    end)

    return Application
end

return Nodes
