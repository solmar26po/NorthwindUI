--[[
    Northwind UI
    Original Roblox/Luau interface library inspired by modern dashboard layouts.
    UI only: this module does not contain game automation or exploit functionality.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Northwind = {
    Version = "1.0.0",
    Flags = {},
    Options = {},
    Windows = {},
    Configs = {},
    ActiveTheme = "Midnight",
    Themes = {
        Midnight = {
            Background = Color3.fromRGB(12, 14, 27),
            Sidebar = Color3.fromRGB(15, 17, 32),
            Surface = Color3.fromRGB(24, 28, 45),
            SurfaceAlt = Color3.fromRGB(35, 40, 65),
            Border = Color3.fromRGB(48, 54, 82),
            Text = Color3.fromRGB(237, 239, 250),
            Muted = Color3.fromRGB(145, 151, 181),
            Accent = Color3.fromRGB(124, 138, 255),
            AccentSoft = Color3.fromRGB(86, 91, 174),
            Success = Color3.fromRGB(102, 214, 153),
            Danger = Color3.fromRGB(255, 103, 131),
        },
        Obsidian = {
            Background = Color3.fromRGB(10, 10, 13),
            Sidebar = Color3.fromRGB(14, 14, 18),
            Surface = Color3.fromRGB(23, 23, 30),
            SurfaceAlt = Color3.fromRGB(34, 34, 44),
            Border = Color3.fromRGB(55, 55, 70),
            Text = Color3.fromRGB(244, 244, 248),
            Muted = Color3.fromRGB(156, 156, 171),
            Accent = Color3.fromRGB(186, 124, 255),
            AccentSoft = Color3.fromRGB(111, 71, 153),
            Success = Color3.fromRGB(105, 220, 154),
            Danger = Color3.fromRGB(255, 104, 121),
        },
        Nord = {
            Background = Color3.fromRGB(29, 35, 47),
            Sidebar = Color3.fromRGB(35, 42, 55),
            Surface = Color3.fromRGB(46, 55, 71),
            SurfaceAlt = Color3.fromRGB(59, 69, 88),
            Border = Color3.fromRGB(75, 85, 105),
            Text = Color3.fromRGB(236, 239, 244),
            Muted = Color3.fromRGB(180, 190, 209),
            Accent = Color3.fromRGB(136, 192, 208),
            AccentSoft = Color3.fromRGB(85, 131, 145),
            Success = Color3.fromRGB(163, 190, 140),
            Danger = Color3.fromRGB(191, 97, 106),
        },
    },
    _themeBindings = {},
    _configProvider = nil,
}

local function create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    instance.Parent = properties and properties.Parent or nil
    return instance
end

local function round(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
        Parent = parent,
    })
end

local function tween(instance, duration, properties, style, direction)
    local info = TweenInfo.new(
        duration or 0.18,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local animation = TweenService:Create(instance, info, properties)
    animation:Play()
    return animation
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local arguments = table.pack(...)
    task.spawn(function()
        local ok, message = pcall(callback, table.unpack(arguments, 1, arguments.n))
        if not ok then
            warn("[Northwind UI] Callback error: " .. tostring(message))
        end
    end)
end

local function readableKey(keyCode)
    local name = tostring(keyCode):gsub("Enum.KeyCode.", "")
    return name:gsub("Left", "L-"):gsub("Right", "R-")
end

local function colorToTable(color)
    return {
        R = math.floor(color.R * 255 + 0.5),
        G = math.floor(color.G * 255 + 0.5),
        B = math.floor(color.B * 255 + 0.5),
    }
end

local function tableToColor(value)
    return Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255)
end

function Northwind:_theme()
    return self.Themes[self.ActiveTheme] or self.Themes.Midnight
end

function Northwind:_bind(instance, property, token)
    instance[property] = self:_theme()[token]
    table.insert(self._themeBindings, {
        Instance = instance,
        Property = property,
        Token = token,
    })
    return instance
end

function Northwind:SetTheme(theme)
    if type(theme) == "string" then
        assert(self.Themes[theme], "Unknown Northwind theme: " .. theme)
        self.ActiveTheme = theme
    elseif type(theme) == "table" then
        local custom = table.clone(self:_theme())
        for token, value in pairs(theme) do
            custom[token] = value
        end
        self.Themes.Custom = custom
        self.ActiveTheme = "Custom"
    end

    local palette = self:_theme()
    for index = #self._themeBindings, 1, -1 do
        local binding = self._themeBindings[index]
        if not binding.Instance or not binding.Instance.Parent then
            table.remove(self._themeBindings, index)
        else
            tween(binding.Instance, 0.24, {
                [binding.Property] = palette[binding.Token],
            })
        end
    end
    task.defer(function()
        for _, option in pairs(self.Options) do
            if option.SetValue then
                option:SetValue(option.Value, true)
            end
        end
    end)
end

function Northwind:SetAccent(color)
    local custom = table.clone(self:_theme())
    custom.Accent = color
    custom.AccentSoft = custom.Accent:Lerp(custom.Surface, 0.45)
    self:SetTheme(custom)
end

function Northwind:SetConfigProvider(provider)
    self._configProvider = provider
end

function Northwind:GetConfigData()
    local values = {}
    local palette = {}
    for token, color in pairs(self:_theme()) do
        if typeof(color) == "Color3" then
            palette[token] = colorToTable(color)
        end
    end
    for flag, option in pairs(self.Options) do
        if option.Save ~= false then
            local value = option:GetValue()
            if typeof(value) == "Color3" then
                values[flag] = { __type = "Color3", value = colorToTable(value) }
            elseif typeof(value) == "EnumItem" then
                values[flag] = { __type = "KeyCode", value = value.Name }
            else
                values[flag] = value
            end
        end
    end
    return {
        version = self.Version,
        theme = self.ActiveTheme,
        palette = palette,
        values = values,
    }
end

function Northwind:ExportConfig()
    return HttpService:JSONEncode(self:GetConfigData())
end

function Northwind:ImportConfig(data)
    if type(data) == "string" then
        data = HttpService:JSONDecode(data)
    end
    assert(type(data) == "table", "Config must be a table or JSON string")
    if data.theme and data.theme ~= "Custom" and self.Themes[data.theme] then
        self:SetTheme(data.theme)
        if self.Options.Northwind_Theme then
            self.Options.Northwind_Theme:SetValue(data.theme, true)
        end
    elseif data.palette then
        local palette = {}
        for token, color in pairs(data.palette) do
            palette[token] = tableToColor(color)
        end
        self:SetTheme(palette)
    end
    for flag, value in pairs(data.values or {}) do
        local option = self.Options[flag]
        if option then
            if type(value) == "table" and value.__type == "Color3" then
                value = tableToColor(value.value)
            elseif type(value) == "table" and value.__type == "KeyCode" then
                value = Enum.KeyCode[value.value]
            end
            option:SetValue(value, false)
        end
    end
end

function Northwind:SaveConfig(name)
    name = tostring(name or "default")
    local encoded = self:ExportConfig()
    self.Configs[name] = encoded
    if self._configProvider and self._configProvider.Save then
        self._configProvider:Save(name, encoded)
    end
    return encoded
end

function Northwind:LoadConfig(name)
    name = tostring(name or "default")
    local encoded = self.Configs[name]
    if self._configProvider and self._configProvider.Load then
        encoded = self._configProvider:Load(name) or encoded
    end
    if not encoded then
        return false, "Config does not exist"
    end
    self:ImportConfig(encoded)
    return true
end

function Northwind:DeleteConfig(name)
    name = tostring(name or "default")
    self.Configs[name] = nil
    if self._configProvider and self._configProvider.Delete then
        self._configProvider:Delete(name)
    end
end

local Option = {}
Option.__index = Option

function Option:GetValue()
    return self.Value
end

function Option:OnChanged(callback)
    table.insert(self.ChangedCallbacks, callback)
    return self
end

function Option:_emit(silent)
    Northwind.Flags[self.Flag] = self.Value
    if silent then
        return
    end
    safeCallback(self.Callback, self.Value)
    for _, callback in ipairs(self.ChangedCallbacks) do
        safeCallback(callback, self.Value)
    end
end

local function newOption(flag, default, callback)
    local option = setmetatable({
        Flag = flag,
        Value = default,
        Callback = callback,
        ChangedCallbacks = {},
        Save = true,
    }, Option)
    if flag then
        Northwind.Options[flag] = option
        Northwind.Flags[flag] = default
    end
    return option
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local Panel = {}
Panel.__index = Panel

local function addHover(button, normalToken, hoverToken)
    Northwind:_bind(button, "BackgroundColor3", normalToken)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = Northwind:_theme()[hoverToken] })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = Northwind:_theme()[normalToken] })
    end)
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function resolveParent(config)
    if config.Parent then
        return config.Parent
    end
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    error("Northwind UI must run on the client or receive a Parent in CreateWindow")
end

function Northwind:CreateWindow(config)
    config = config or {}
    local palette = self:_theme()
    local screenParent = resolveParent(config)
    local previousScreen = screenParent:FindFirstChild(config.Name or "NorthwindUI")
    if previousScreen then
        previousScreen:Destroy()
    end
    local screen = create("ScreenGui", {
        Name = config.Name or "NorthwindUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 50,
        Parent = screenParent,
    })

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.fromScale(0.57, 0.5),
        Size = config.Size or UDim2.fromOffset(900, 580),
        BackgroundColor3 = palette.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screen,
    })
    self:_bind(main, "BackgroundColor3", "Background")
    round(main, 14)
    local mainStroke = stroke(main, palette.Border, 0.25)
    self:_bind(mainStroke, "Color", "Border")

    local scale = create("UIScale", { Scale = 0.96, Parent = main })
    tween(scale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 230, 1, 0),
        BackgroundColor3 = palette.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })
    self:_bind(sidebar, "BackgroundColor3", "Sidebar")

    local sidebarLine = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:_bind(sidebarLine, "BackgroundColor3", "Border")

    local brand = create("TextLabel", {
        Position = UDim2.fromOffset(18, 15),
        Size = UDim2.new(1, -36, 0, 42),
        BackgroundTransparency = 1,
        Text = "NW  " .. (config.Title or "Northwind"),
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })
    self:_bind(brand, "TextColor3", "Text")

    local accentMark = create("Frame", {
        Position = UDim2.fromOffset(18, 54),
        Size = UDim2.fromOffset(34, 3),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:_bind(accentMark, "BackgroundColor3", "Accent")
    round(accentMark, 2)

    local search = create("TextBox", {
        Position = UDim2.fromOffset(14, 72),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        PlaceholderText = "  Search the interface...",
        PlaceholderColor3 = palette.Muted,
        Text = "",
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })
    self:_bind(search, "BackgroundColor3", "SurfaceAlt")
    self:_bind(search, "TextColor3", "Text")
    self:_bind(search, "PlaceholderColor3", "Muted")
    round(search, 8)

    local tabList = create("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 122),
        Size = UDim2.new(1, -20, 1, -136),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = palette.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = sidebar,
    })
    self:_bind(tabList, "ScrollBarImageColor3", "Accent")
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList,
    })

    local content = create("Frame", {
        Position = UDim2.fromOffset(230, 0),
        Size = UDim2.new(1, -230, 1, 0),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local pageTitle = create("TextLabel", {
        Position = UDim2.fromOffset(24, 15),
        Size = UDim2.new(1, -48, 0, 26),
        BackgroundTransparency = 1,
        Text = config.Title or "Northwind",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 21,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = content,
    })
    self:_bind(pageTitle, "TextColor3", "Text")

    local pageSubtitle = create("TextLabel", {
        Position = UDim2.fromOffset(24, 42),
        Size = UDim2.new(1, -48, 0, 20),
        BackgroundTransparency = 1,
        Text = config.Subtitle or "A smooth, modular interface",
        TextColor3 = palette.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = content,
    })
    self:_bind(pageSubtitle, "TextColor3", "Muted")

    local titleLine = create("Frame", {
        Position = UDim2.fromOffset(24, 70),
        Size = UDim2.new(1, -48, 0, 1),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = content,
    })
    self:_bind(titleLine, "BackgroundColor3", "Border")

    local pages = create("Frame", {
        Position = UDim2.fromOffset(18, 82),
        Size = UDim2.new(1, -36, 1, -96),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = content,
    })

    local window = setmetatable({
        Library = self,
        ScreenGui = screen,
        Main = main,
        Scale = scale,
        Sidebar = sidebar,
        TabList = tabList,
        Pages = pages,
        TitleLabel = pageTitle,
        SubtitleLabel = pageSubtitle,
        Tabs = {},
        Panels = {},
        Visible = true,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        _activeTab = nil,
        _connections = {},
    }, Window)

    table.insert(self.Windows, window)
    makeDraggable(brand, main)

    search:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(search.Text)
        for _, tab in ipairs(window.Tabs) do
            tab.Button.Visible = query == "" or string.find(string.lower(tab.Name), query, 1, true) ~= nil
        end
    end)

    table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == window.ToggleKey then
            window:Toggle()
        end
    end))

    if config.Settings ~= false then
        window:_createSettingsTab()
    end

    if config.AutoShow == false then
        window:SetVisible(false, true)
    end

    return window
end

function Window:SetVisible(visible, instant)
    self.Visible = visible
    if visible then
        self.Main.Visible = true
        if instant then
            self.Scale.Scale = 1
        else
            self.Scale.Scale = 0.96
            tween(self.Scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
        end
    else
        if instant then
            self.Main.Visible = false
        else
            tween(self.Scale, 0.16, { Scale = 0.96 })
            task.delay(0.16, function()
                if not self.Visible and self.Main then
                    self.Main.Visible = false
                end
            end)
        end
    end
    for _, panel in ipairs(self.Panels) do
        panel.Frame.Visible = visible
    end
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
end

function Window:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function Window:SelectTab(tab)
    if type(tab) == "string" then
        for _, item in ipairs(self.Tabs) do
            if item.Name == tab then
                tab = item
                break
            end
        end
    end
    if type(tab) ~= "table" then
        return
    end
    self._activeTab = tab
    self.TitleLabel.Text = tab.Name
    self.SubtitleLabel.Text = tab.Description
    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Page.Visible = active
        tween(item.Button, 0.16, {
            BackgroundTransparency = active and 0 or 1,
            BackgroundColor3 = self.Library:_theme().AccentSoft,
        })
        tween(item.ButtonText, 0.16, {
            TextColor3 = active and self.Library:_theme().Text or self.Library:_theme().Muted,
        })
        item.Accent.Visible = active
    end
end

function Window:AddTab(config)
    if type(config) == "string" then
        config = { Name = config }
    end
    config = config or {}
    local palette = self.Library:_theme()
    local name = config.Name or "Tab"

    local button = create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = palette.AccentSoft,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = config.LayoutOrder or (#self.Tabs + 1),
        Parent = self.TabList,
    })
    round(button, 8)

    local accent = create("Frame", {
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.fromOffset(3, 22),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    })
    self.Library:_bind(accent, "BackgroundColor3", "Accent")
    round(accent, 2)

    local icon = create("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.fromOffset(24, 38),
        BackgroundTransparency = 1,
        Text = config.Icon or "◆",
        TextColor3 = palette.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Parent = button,
    })
    self.Library:_bind(icon, "TextColor3", "Muted")

    local buttonText = create("TextLabel", {
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = palette.Muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })
    self.Library:_bind(buttonText, "TextColor3", "Muted")

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = palette.Accent,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = self.Pages,
    })
    self.Library:_bind(page, "ScrollBarImageColor3", "Accent")

    local columns = create("Frame", {
        Size = UDim2.new(1, -6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = page,
    })
    local left = create("Frame", {
        Size = UDim2.new(0.5, -6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = columns,
    })
    local right = create("Frame", {
        Position = UDim2.new(0.5, 6, 0, 0),
        Size = UDim2.new(0.5, -6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = columns,
    })
    local leftLayout = create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = left,
    })
    local rightLayout = create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = right,
    })

    local tab = setmetatable({
        Window = self,
        Library = self.Library,
        Name = name,
        Description = config.Description or "Configure " .. string.lower(name),
        Button = button,
        ButtonText = buttonText,
        Accent = accent,
        Page = page,
        Columns = columns,
        Left = left,
        Right = right,
        LeftLayout = leftLayout,
        RightLayout = rightLayout,
        Sections = {},
        _nextSide = "Left",
        IsSettings = config.IsSettings == true,
    }, Tab)
    table.insert(self.Tabs, tab)

    local function resizeCanvas()
        local height = math.max(leftLayout.AbsoluteContentSize.Y, rightLayout.AbsoluteContentSize.Y)
        columns.Size = UDim2.new(1, -6, 0, height)
        page.CanvasSize = UDim2.fromOffset(0, height + 8)
    end
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)
    rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    button.MouseEnter:Connect(function()
        if self._activeTab ~= tab then
            tween(button, 0.15, { BackgroundTransparency = 0.62 })
        end
    end)
    button.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            tween(button, 0.15, { BackgroundTransparency = 1 })
        end
    end)

    if not self._activeTab or (self._activeTab.IsSettings and not tab.IsSettings) then
        self:SelectTab(tab)
    end
    return tab
end

function Tab:AddSection(config)
    if type(config) == "string" then
        config = { Name = config }
    end
    config = config or {}
    local palette = self.Library:_theme()
    local side = config.Side or self._nextSide
    self._nextSide = side == "Left" and "Right" or "Left"
    local parent = side == "Right" and self.Right or self.Left

    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = palette.Surface,
        BorderSizePixel = 0,
        Parent = parent,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, 11)
    local frameStroke = stroke(frame, palette.Border, 0.28)
    self.Library:_bind(frameStroke, "Color", "Border")
    padding(frame, 14, 14, 12, 14)

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    create("TextLabel", {
        Size = UDim2.fromOffset(28, 26),
        BackgroundTransparency = 1,
        Text = config.Icon or "✦",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = header,
    })
    local title = create("TextLabel", {
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -34, 0, 22),
        BackgroundTransparency = 1,
        Text = config.Name or "Section",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    self.Library:_bind(title, "TextColor3", "Text")
    local subtitle = create("TextLabel", {
        Position = UDim2.fromOffset(34, 21),
        Size = UDim2.new(1, -34, 0, 17),
        BackgroundTransparency = 1,
        Text = config.Description or "",
        TextColor3 = palette.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    self.Library:_bind(subtitle, "TextColor3", "Muted")
    local divider = create("Frame", {
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = header,
    })
    self.Library:_bind(divider, "BackgroundColor3", "Border")

    local controls = create("Frame", {
        Position = UDim2.fromOffset(0, 52),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = controls,
    })

    local section = setmetatable({
        Tab = self,
        Window = self.Window,
        Library = self.Library,
        Frame = frame,
        Controls = controls,
    }, Section)
    table.insert(self.Sections, section)
    return section
end

function Section:_row(height, transparent)
    local palette = self.Library:_theme()
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, height or 36),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = transparent and 1 or 0,
        BorderSizePixel = 0,
        Parent = self.Controls,
    })
    if not transparent then
        self.Library:_bind(row, "BackgroundColor3", "SurfaceAlt")
        round(row, 7)
    end
    return row
end

function Section:AddLabel(text)
    local palette = self.Library:_theme()
    local row = self:_row(24, true)
    local label = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = tostring(text or "Label"),
        TextColor3 = palette.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Muted")
    local handle = {}
    function handle:SetText(value)
        label.Text = tostring(value)
    end
    return handle
end

function Section:AddDivider(text)
    local palette = self.Library:_theme()
    local row = self:_row(text and 26 or 10, true)
    local line = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = row,
    })
    self.Library:_bind(line, "BackgroundColor3", "Border")
    if text then
        local label = create("TextLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(90, 18),
            BackgroundColor3 = palette.Surface,
            BorderSizePixel = 0,
            Text = string.upper(tostring(text)),
            TextColor3 = palette.Muted,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        self.Library:_bind(label, "BackgroundColor3", "Surface")
        self.Library:_bind(label, "TextColor3", "Muted")
    end
end

function Section:AddButton(config, callback)
    if type(config) == "string" then
        config = { Text = config, Callback = callback }
    end
    config = config or {}
    local palette = self.Library:_theme()
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Text = config.Text or config.Name or "Button",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = self.Controls,
    })
    round(button, 7)
    self.Library:_bind(button, "TextColor3", "Text")
    addHover(button, "SurfaceAlt", "AccentSoft")
    button.MouseButton1Click:Connect(function()
        tween(button, 0.08, { Size = UDim2.new(1, 0, 0, 33) })
        task.delay(0.08, function()
            tween(button, 0.12, { Size = UDim2.new(1, 0, 0, 36) })
        end)
        safeCallback(config.Callback)
    end)
    return button
end

function Section:AddToggle(flag, config)
    if type(flag) == "table" then
        config = flag
        flag = config.Flag
    end
    config = config or {}
    flag = flag or config.Flag or config.Text or "Toggle"
    local palette = self.Library:_theme()
    local row = self:_row(38, true)
    local label = create("TextLabel", {
        Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Text or config.Name or flag,
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Text")
    local track = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(43, 22),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(track, "BackgroundColor3", "SurfaceAlt")
    round(track, 11)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(3, 11),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = palette.Text,
        BorderSizePixel = 0,
        Parent = track,
    })
    self.Library:_bind(knob, "BackgroundColor3", "Text")
    round(knob, 8)

    local option = newOption(flag, config.Default == true, config.Callback)
    function option:SetValue(value, silent)
        self.Value = value == true
        tween(track, 0.18, {
            BackgroundColor3 = self.Value and Northwind:_theme().Accent or Northwind:_theme().SurfaceAlt,
        })
        tween(knob, 0.18, {
            Position = self.Value and UDim2.fromOffset(24, 11) or UDim2.fromOffset(3, 11),
        })
        self:_emit(silent)
    end
    track.MouseButton1Click:Connect(function()
        option:SetValue(not option.Value)
    end)
    option:SetValue(option.Value, true)
    return option
end

function Section:AddSlider(flag, config)
    if type(flag) == "table" then
        config = flag
        flag = config.Flag
    end
    config = config or {}
    flag = flag or config.Flag or config.Text or "Slider"
    local minimum = config.Min or 0
    local maximum = config.Max or 100
    local rounding = config.Rounding or 0
    local suffix = config.Suffix or ""
    local palette = self.Library:_theme()
    local row = self:_row(56, true)
    local label = create("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = config.Text or config.Name or flag,
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Text")
    local valueLabel = create("TextLabel", {
        Position = UDim2.new(0.7, 0, 0, 0),
        Size = UDim2.new(0.3, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = palette.Muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
    self.Library:_bind(valueLabel, "TextColor3", "Muted")
    local track = create("TextButton", {
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(track, "BackgroundColor3", "SurfaceAlt")
    round(track, 3)
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    self.Library:_bind(fill, "BackgroundColor3", "Accent")
    round(fill, 3)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    self.Library:_bind(knob, "BackgroundColor3", "Accent")
    round(knob, 7)

    local option = newOption(flag, config.Default or minimum, config.Callback)
    function option:SetValue(value, silent)
        value = math.clamp(tonumber(value) or minimum, minimum, maximum)
        local multiplier = 10 ^ rounding
        value = math.floor(value * multiplier + 0.5) / multiplier
        self.Value = value
        local percent = (value - minimum) / math.max(maximum - minimum, 1)
        tween(fill, 0.1, { Size = UDim2.new(percent, 0, 1, 0) })
        tween(knob, 0.1, { Position = UDim2.fromScale(percent, 0.5) })
        valueLabel.Text = tostring(value) .. suffix
        self:_emit(silent)
    end

    local dragging = false
    local function update(input)
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        option:SetValue(minimum + (maximum - minimum) * percent)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    option:SetValue(option.Value, true)
    return option
end

function Section:AddInput(flag, config)
    if type(flag) == "table" then
        config = flag
        flag = config.Flag
    end
    config = config or {}
    flag = flag or config.Flag or config.Text or "Input"
    local palette = self.Library:_theme()
    local row = self:_row(42, true)
    local label = create("TextLabel", {
        Size = UDim2.new(0.42, -6, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Text or config.Name or flag,
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Text")
    local box = create("TextBox", {
        Position = UDim2.new(0.42, 0, 0, 3),
        Size = UDim2.new(0.58, 0, 1, -6),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        PlaceholderText = config.Placeholder or "Type here...",
        PlaceholderColor3 = palette.Muted,
        Text = tostring(config.Default or ""),
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        ClearTextOnFocus = false,
        Parent = row,
    })
    self.Library:_bind(box, "BackgroundColor3", "SurfaceAlt")
    self.Library:_bind(box, "TextColor3", "Text")
    self.Library:_bind(box, "PlaceholderColor3", "Muted")
    round(box, 7)
    padding(box, 9, 9, 0, 0)

    local option = newOption(flag, tostring(config.Default or ""), config.Callback)
    function option:SetValue(value, silent)
        self.Value = tostring(value or "")
        box.Text = self.Value
        self:_emit(silent)
    end
    box.FocusLost:Connect(function(enterPressed)
        option:SetValue(box.Text)
        if enterPressed then
            safeCallback(config.Finished, box.Text)
        end
    end)
    return option
end

function Section:AddDropdown(flag, config)
    if type(flag) == "table" then
        config = flag
        flag = config.Flag
    end
    config = config or {}
    flag = flag or config.Flag or config.Text or "Dropdown"
    local values = config.Values or {}
    local palette = self.Library:_theme()
    local row = self:_row(42, true)
    local label = create("TextLabel", {
        Size = UDim2.new(0.42, -6, 0, 42),
        BackgroundTransparency = 1,
        Text = config.Text or config.Name or flag,
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Text")
    local button = create("TextButton", {
        Position = UDim2.new(0.42, 0, 0, 3),
        Size = UDim2.new(0.58, 0, 0, 36),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(button, "BackgroundColor3", "SurfaceAlt")
    round(button, 7)
    local valueText = create("TextLabel", {
        Position = UDim2.fromOffset(9, 0),
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })
    self.Library:_bind(valueText, "TextColor3", "Text")
    local arrow = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(30, 36),
        BackgroundTransparency = 1,
        Text = "⌄",
        TextColor3 = palette.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = button,
    })
    self.Library:_bind(arrow, "TextColor3", "Muted")
    local list = create("Frame", {
        Position = UDim2.new(0.42, 0, 0, 43),
        Size = UDim2.new(0.58, 0, 0, 0),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = row,
    })
    self.Library:_bind(list, "BackgroundColor3", "SurfaceAlt")
    round(list, 7)
    local listLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = list,
    })

    local option = newOption(flag, config.Default or values[1], config.Callback)
    local open = false
    local function setOpen(value)
        open = value
        list.Visible = true
        local targetHeight = value and math.min(#values * 30, 150) or 0
        tween(list, 0.18, { Size = UDim2.new(0.58, 0, 0, targetHeight) })
        tween(row, 0.18, { Size = UDim2.new(1, 0, 0, value and (48 + targetHeight) or 42) })
        arrow.Text = value and "⌃" or "⌄"
        if not value then
            task.delay(0.18, function()
                if not open then
                    list.Visible = false
                end
            end)
        end
    end
    function option:SetValue(value, silent)
        self.Value = value
        valueText.Text = tostring(value or "None")
        self:_emit(silent)
        setOpen(false)
    end
    function option:SetValues(newValues)
        values = newValues or {}
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        self:_build()
    end
    function option:_build()
        for index, value in ipairs(values) do
            local item = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "  " .. tostring(value),
                TextColor3 = Northwind:_theme().Muted,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = index,
                Parent = list,
            })
            Northwind:_bind(item, "TextColor3", "Muted")
            item.MouseButton1Click:Connect(function()
                option:SetValue(value)
            end)
            item.MouseEnter:Connect(function()
                tween(item, 0.12, { BackgroundTransparency = 0, BackgroundColor3 = Northwind:_theme().AccentSoft })
            end)
            item.MouseLeave:Connect(function()
                tween(item, 0.12, { BackgroundTransparency = 1 })
            end)
        end
    end
    button.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)
    option:_build()
    option:SetValue(option.Value, true)
    return option
end

function Section:AddKeybind(flag, config)
    if type(flag) == "table" then
        config = flag
        flag = config.Flag
    end
    config = config or {}
    flag = flag or config.Flag or config.Text or "Keybind"
    local palette = self.Library:_theme()
    local row = self:_row(40, true)
    local label = create("TextLabel", {
        Size = UDim2.new(1, -118, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Text or config.Name or flag,
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Text")
    local button = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(108, 32),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(button, "BackgroundColor3", "SurfaceAlt")
    self.Library:_bind(button, "TextColor3", "Text")
    round(button, 7)

    local listening = false
    local option = newOption(flag, config.Default or Enum.KeyCode.Unknown, config.Callback)
    function option:SetValue(value, silent)
        if typeof(value) ~= "EnumItem" then
            value = Enum.KeyCode[tostring(value)] or Enum.KeyCode.Unknown
        end
        self.Value = value
        button.Text = readableKey(value)
        self:_emit(silent)
    end
    button.MouseButton1Click:Connect(function()
        listening = true
        button.Text = "Press a key..."
        tween(button, 0.15, { BackgroundColor3 = Northwind:_theme().AccentSoft })
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
            listening = false
            option:SetValue(input.KeyCode)
            tween(button, 0.15, { BackgroundColor3 = Northwind:_theme().SurfaceAlt })
        elseif not processed and input.KeyCode == option.Value then
            safeCallback(config.Pressed, option.Value)
        end
    end)
    option:SetValue(option.Value, true)
    return option
end

function Section:AddColorPicker(flag, config)
    if type(flag) == "table" then
        config = flag
        flag = config.Flag
    end
    config = config or {}
    local colors = config.Colors or {
        Color3.fromRGB(124, 138, 255),
        Color3.fromRGB(180, 120, 255),
        Color3.fromRGB(255, 116, 181),
        Color3.fromRGB(90, 202, 255),
        Color3.fromRGB(96, 220, 159),
        Color3.fromRGB(255, 173, 91),
    }
    local names = config.Names or { "Periwinkle", "Violet", "Rose", "Sky", "Mint", "Amber" }
    local dropdownValues = {}
    for index, name in ipairs(names) do
        dropdownValues[index] = name
    end
    local defaultIndex = 1
    for index, color in ipairs(colors) do
        if color == config.Default then
            defaultIndex = index
        end
    end
    local option = self:AddDropdown(flag, {
        Text = config.Text or "Accent",
        Values = dropdownValues,
        Default = names[defaultIndex],
        Callback = function(name)
            local index = table.find(names, name) or 1
            safeCallback(config.Callback, colors[index])
        end,
    })
    option.ColorValues = colors
    option.ColorNames = names
    return option
end

-- Compatibility aliases for a compact API.
Section.Button = Section.AddButton
Section.Label = Section.AddLabel
Section.Divider = Section.AddDivider
Section.Switch = Section.AddToggle
Section.TextField = Section.AddInput
Section.Slider = Section.AddSlider
Section.Dropdown = Section.AddDropdown
Section.Keybind = Section.AddKeybind
Tab.Section = Tab.AddSection

function Window:Notify(config, description, duration)
    if type(config) == "string" then
        config = { Title = config, Description = description, Duration = duration }
    end
    config = config or {}
    local palette = self.Library:_theme()
    local holder = self.ScreenGui:FindFirstChild("Notifications")
    if not holder then
        holder = create("Frame", {
            Name = "Notifications",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(300, 500),
            BackgroundTransparency = 1,
            Parent = self.ScreenGui,
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = holder,
        })
    end
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = palette.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = holder,
    })
    self.Library:_bind(card, "BackgroundColor3", "Surface")
    round(card, 10)
    local cardStroke = stroke(card, palette.Border, 1)
    self.Library:_bind(cardStroke, "Color", "Border")
    local bar = create("Frame", {
        Size = UDim2.fromOffset(4, 78),
        BackgroundColor3 = config.Color or palette.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = card,
    })
    round(bar, 2)
    local title = create("TextLabel", {
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1,
        Text = config.Title or "Northwind",
        TextColor3 = palette.Text,
        TextTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    local body = create("TextLabel", {
        Position = UDim2.fromOffset(16, 32),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundTransparency = 1,
        Text = config.Description or "Notification",
        TextColor3 = palette.Muted,
        TextTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card,
    })
    tween(card, 0.2, { BackgroundTransparency = 0.04 })
    tween(cardStroke, 0.2, { Transparency = 0.25 })
    tween(bar, 0.2, { BackgroundTransparency = 0 })
    tween(title, 0.2, { TextTransparency = 0 })
    tween(body, 0.2, { TextTransparency = 0 })
    task.delay(config.Duration or 3.5, function()
        tween(card, 0.2, { BackgroundTransparency = 1 })
        tween(cardStroke, 0.2, { Transparency = 1 })
        tween(bar, 0.2, { BackgroundTransparency = 1 })
        tween(title, 0.2, { TextTransparency = 1 })
        tween(body, 0.2, { TextTransparency = 1 })
        task.delay(0.22, function()
            card:Destroy()
        end)
    end)
end

function Window:CreateStatusBar(config)
    config = config or {}
    local palette = self.Library:_theme()
    local frame = create("Frame", {
        Position = config.Position or UDim2.fromOffset(16, 28),
        Size = config.Size or UDim2.fromOffset(276, 36),
        BackgroundColor3 = palette.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, 8)
    local frameStroke = stroke(frame, palette.Border, 0.3)
    self.Library:_bind(frameStroke, "Color", "Border")
    local brand = create("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.fromOffset(116, 36),
        BackgroundTransparency = 1,
        Text = "NW  " .. (config.Title or "Northwind"),
        TextColor3 = palette.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    self.Library:_bind(brand, "TextColor3", "Accent")
    local fps = create("TextLabel", {
        Position = UDim2.fromOffset(130, 0),
        Size = UDim2.fromOffset(65, 36),
        BackgroundTransparency = 1,
        Text = "FPS --",
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = frame,
    })
    self.Library:_bind(fps, "TextColor3", "Text")
    local clock = create("TextLabel", {
        Position = UDim2.fromOffset(201, 0),
        Size = UDim2.new(1, -211, 1, 0),
        BackgroundTransparency = 1,
        Text = "00:00:00",
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = frame,
    })
    self.Library:_bind(clock, "TextColor3", "Text")
    makeDraggable(frame, frame)

    local frames = 0
    local elapsed = 0
    local connection = RunService.RenderStepped:Connect(function(delta)
        frames += 1
        elapsed += delta
        if elapsed >= 0.5 then
            fps.Text = "FPS " .. tostring(math.floor(frames / elapsed + 0.5))
            frames = 0
            elapsed = 0
        end
        clock.Text = os.date("%H:%M:%S")
    end)
    table.insert(self._connections, connection)
    local panel = setmetatable({ Frame = frame, Window = self, Rows = {} }, Panel)
    table.insert(self.Panels, panel)
    return panel
end

function Window:CreatePanel(config)
    config = config or {}
    local palette = self.Library:_theme()
    local frame = create("Frame", {
        Position = config.Position or UDim2.fromOffset(16, 76),
        Size = UDim2.fromOffset(config.Width or 210, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = palette.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, 9)
    local frameStroke = stroke(frame, palette.Border, 0.28)
    self.Library:_bind(frameStroke, "Color", "Border")
    padding(frame, 10, 10, 9, 10)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
    })
    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = (config.Icon or "◈") .. "  " .. (config.Title or "Panel"),
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
        Parent = frame,
    })
    self.Library:_bind(title, "TextColor3", "Text")
    local line = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = frame,
    })
    self.Library:_bind(line, "BackgroundColor3", "Border")
    makeDraggable(title, frame)
    local panel = setmetatable({
        Frame = frame,
        Window = self,
        Layout = layout,
        Rows = {},
        _nextOrder = 2,
    }, Panel)
    table.insert(self.Panels, panel)
    return panel
end

function Panel:AddValue(name, initial)
    local palette = Northwind:_theme()
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        LayoutOrder = self._nextOrder,
        Parent = self.Frame,
    })
    self._nextOrder += 1
    local label = create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    Northwind:_bind(label, "TextColor3", "Text")
    local value = create("TextLabel", {
        Position = UDim2.fromScale(0.6, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(initial or "--"),
        TextColor3 = palette.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
    Northwind:_bind(value, "TextColor3", "Muted")
    local handle = { Row = row }
    function handle:Set(newValue)
        value.Text = tostring(newValue)
    end
    self.Rows[name] = handle
    return handle
end

function Panel:AddProgress(name, initial)
    local palette = Northwind:_theme()
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder = self._nextOrder,
        Parent = self.Frame,
    })
    self._nextOrder += 1
    local label = create("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    Northwind:_bind(label, "TextColor3", "Text")
    local value = create("TextLabel", {
        Position = UDim2.fromScale(0.7, 0),
        Size = UDim2.new(0.3, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = palette.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
    Northwind:_bind(value, "TextColor3", "Muted")
    local track = create("Frame", {
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = row,
    })
    Northwind:_bind(track, "BackgroundColor3", "SurfaceAlt")
    round(track, 3)
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    Northwind:_bind(fill, "BackgroundColor3", "Accent")
    round(fill, 3)
    local handle = { Row = row }
    function handle:Set(percent)
        percent = math.clamp(tonumber(percent) or 0, 0, 100)
        value.Text = tostring(math.floor(percent + 0.5)) .. "%"
        tween(fill, 0.2, { Size = UDim2.new(percent / 100, 0, 1, 0) })
    end
    handle:Set(initial or 0)
    self.Rows[name] = handle
    return handle
end

function Window:_createSettingsTab()
    local settings = self:AddTab({
        Name = "Settings",
        Description = "Window, theme, keybinds, and configs",
        Icon = "⚙",
        LayoutOrder = 999,
        IsSettings = true,
    })
    local windowSection = settings:AddSection({
        Name = "Window",
        Description = "Show, hide, and unload",
        Icon = "▣",
        Side = "Left",
    })
    windowSection:AddKeybind("Northwind_ToggleKey", {
        Text = "Toggle interface",
        Default = self.ToggleKey,
        Callback = function(value)
            self.ToggleKey = value
        end,
    })
    windowSection:AddButton({
        Text = "Unload interface",
        Callback = function()
            self:Destroy()
        end,
    })

    local themeSection = settings:AddSection({
        Name = "Theme",
        Description = "Smooth live color updates",
        Icon = "✿",
        Side = "Left",
    })
    local themeOption = themeSection:AddDropdown("Northwind_Theme", {
        Text = "Preset",
        Values = { "Midnight", "Obsidian", "Nord" },
        Default = self.Library.ActiveTheme,
        Callback = function(value)
            self.Library:SetTheme(value)
        end,
    })
    themeOption.Save = false
    local accentOption = themeSection:AddColorPicker("Northwind_Accent", {
        Text = "Accent color",
        Default = self.Library:_theme().Accent,
        Callback = function(value)
            self.Library:SetAccent(value)
        end,
    })
    accentOption.Save = false

    local configSection = settings:AddSection({
        Name = "Configs",
        Description = "Current session or custom provider",
        Icon = "▤",
        Side = "Right",
    })
    local configName = configSection:AddInput("Northwind_ConfigName", {
        Text = "Name",
        Default = "default",
        Placeholder = "config name",
    })
    configName.Save = false
    configSection:AddButton({
        Text = "Save config",
        Callback = function()
            self.Library:SaveConfig(configName.Value)
            self:Notify("Config saved", configName.Value .. " is ready to load")
        end,
    })
    configSection:AddButton({
        Text = "Load config",
        Callback = function()
            local ok, message = self.Library:LoadConfig(configName.Value)
            self:Notify(ok and "Config loaded" or "Unable to load", ok and configName.Value or message)
        end,
    })
    configSection:AddButton({
        Text = "Delete config",
        Callback = function()
            self.Library:DeleteConfig(configName.Value)
            self:Notify("Config deleted", configName.Value)
        end,
    })
    configSection:AddLabel("Configs persist when a storage provider is attached. Without one, they last for the current session.")

    self.SettingsTab = settings
    return settings
end

return Northwind

