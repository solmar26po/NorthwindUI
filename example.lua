-- Northwind UI showcase. Every callback below is a harmless visual demonstration.

local repo = "https://raw.githubusercontent.com/solmar26po/NorthwindUI/main/"
local Players = game:GetService("Players")

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Replace the memory provider with your own provider when configs should persist between sessions.
SaveManager:SetProvider(SaveManager:CreateMemoryProvider())

local Window = Library:CreateWindow({
    Title = "Northwind",
    Subtitle = "Premium Roblox interface components",
    ToggleKey = Enum.KeyCode.RightShift,
    Settings = true,
    AutoShow = true,
    Position = UDim2.fromScale(0.48, 0.5),
    Size = UDim2.fromOffset(820, 560),
    Transparency = 0.06,
    CornerRadius = 18,
    PanelsFollowMenuVisibility = true,
    FontPreset = "Gotham",
    Motion = {
        Enabled = true,
        Speed = 1,
    },
    BrandGradient = {
        Enabled = true,
        Animated = true,
        Start = Color3.fromRGB(248, 249, 255),
        Finish = Color3.fromRGB(124, 138, 255),
        Speed = 0.45,
        ApplyToFPS = true,
    },
    BackgroundAnimation = {
        Enabled = true,
        Preset = "Stars",
        Speed = 0.7,
        Density = 0.48,
        Color = Color3.fromRGB(154, 165, 255),
    },
    ScreenAnimation = {
        Enabled = true,
        Preset = "Snow",
        Speed = 0.82,
        Density = 0.62,
        Color = Color3.fromRGB(242, 246, 255),
    },
    Logo = "rbxassetid://131649619262206",
    LogoStyle = "Image",
    LogoSize = 38,
    ESPPreview = {
        Title = "Player ESP",
        Width = 232,
        Height = 372,
        Gap = 12,
        ShowBox = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        ShowTracer = true,
        RotationSpeed = 12,
    },
})

local ESPPreview = Window.ESPPreview

Window:CreateStatusBar({
    Title = "Northwind",
    Position = UDim2.fromOffset(16, 26),
    FollowMenuVisibility = true,
    GradientFPS = true,
})

local KeybindPanel = Window:CreatePanel({
    Title = "Keybinds",
    Icon = "keyboard",
    Position = UDim2.fromOffset(16, 74),
    Width = 188,
    FollowMenuVisibility = true,
})
local menuKey = KeybindPanel:AddValue("Toggle menu", "R-Shift")
local actionKey = KeybindPanel:AddValue("Test action", "F")

local SessionPanel = Window:CreatePanel({
    Title = "Session",
    Icon = "clock",
    Position = UDim2.fromOffset(16, 182),
    Width = 188,
    FollowMenuVisibility = true,
})
local uptimeValue = SessionPanel:AddValue("Uptime", "00:00")
local eventsValue = SessionPanel:AddValue("Events", 0)
local stateValue = SessionPanel:AddValue("State", "Idle")
local demoProgress = SessionPanel:AddProgress("Demo progress", 16)

local MetricsPanel = Window:CreatePanel({
    Title = "Metrics",
    Icon = "activity",
    Position = UDim2.fromOffset(16, 354),
    Width = 188,
    FollowMenuVisibility = true,
})
local playersValue = MetricsPanel:AddValue("Players", #Players:GetPlayers())
local qualityValue = MetricsPanel:AddValue("Quality", "Smooth")
local workloadProgress = MetricsPanel:AddProgress("Workload", 38)

local Dashboard = Window:AddTab({
    Name = "Dashboard",
    Description = "Overview and harmless test actions",
    Icon = "home",
})

local Actions = Dashboard:AddSection({
    Name = "Actions",
    Description = "Buttons and notification examples",
    Icon = "sparkles",
    Side = "Left",
})

local eventCount = 0
Actions:AddButton({
    Text = "Run test action",
    Callback = function()
        eventCount += 1
        eventsValue:Set(eventCount)
        stateValue:Set("Tested")
        Window:Notify({
            Title = "Test complete",
            Description = "The demonstration action ran successfully.",
        })
    end,
})

Actions:AddButton({
    Text = "Show notification",
    Callback = function()
        Window:Notify("Northwind UI", "Premium motion and notifications are working.")
    end,
})

Actions:AddLabel("Controls update only this showcase and its detached panels.")

local LiveValues = Dashboard:AddSection({
    Name = "Live values",
    Description = "Inputs update immediately",
    Icon = "activity",
    Side = "Right",
})

LiveValues:AddToggle("DemoEnabled", {
    Text = "Enable demo mode",
    Default = false,
    Callback = function(value)
        stateValue:Set(value and "Active" or "Idle")
    end,
})

LiveValues:AddSlider("DemoSpeed", {
    Text = "Demo speed",
    Min = 1,
    Max = 100,
    Default = 35,
    Suffix = "%",
    Callback = function(value)
        demoProgress:Set(value)
    end,
})

LiveValues:AddDropdown("DemoMode", {
    Text = "Mode",
    Values = { "Relaxed", "Balanced", "Fast" },
    Default = "Balanced",
    Callback = function(value)
        qualityValue:Set(value)
    end,
})

-- CreateTab remains supported for scripts built against the compact API.
local Controls = Window:CreateTab({
    Name = "Controls",
    Description = "Every reusable input component",
    Icon = "sliders",
})

local Inputs = Controls:AddSection({
    Name = "Inputs",
    Description = "Text, dropdown, and slider",
    Icon = "sliders",
    Side = "Left",
})

Inputs:AddInput("ExampleText", {
    Text = "Text field",
    Placeholder = "Enter text...",
    Default = "Hello",
    Callback = function(value)
        print("ExampleText:", value)
    end,
})

Inputs:AddDropdown("ExampleDropdown", {
    Text = "Dropdown",
    Values = { "Option A", "Option B", "Option C" },
    Default = "Option A",
    Callback = function(value)
        print("ExampleDropdown:", value)
    end,
})

Inputs:AddSlider("ExampleSlider", {
    Text = "Slider",
    Min = 0,
    Max = 250,
    Default = 125,
    Rounding = 0,
    Callback = function(value)
        workloadProgress:Set(value / 2.5)
    end,
})

local Binds = Controls:AddSection({
    Name = "Keybinds",
    Description = "Click a field, then press a key",
    Icon = "keyboard",
    Side = "Right",
})

Binds:AddKeybind("ExampleKeybind", {
    Text = "Test action",
    Default = Enum.KeyCode.F,
    Callback = function(value)
        actionKey:Set(tostring(value):gsub("Enum.KeyCode.", ""))
    end,
    Pressed = function()
        Window:Notify("Keybind pressed", "The harmless keybind demonstration ran.")
    end,
})

Binds:AddToggle("ExampleToggle", {
    Text = "Example toggle",
    Default = true,
})

Binds:AddButton("Reset demo panels", function()
    eventCount = 0
    eventsValue:Set(0)
    stateValue:Set("Idle")
    demoProgress:Set(16)
    workloadProgress:Set(38)
end)

local Appearance = Window:Tab({
    Name = "Appearance",
    Description = "Theme and ESP preview controls",
    Icon = "eye",
})

local PreviewControls = Appearance:CreateSection({
    Name = "ESP preview",
    Description = "Live local-character presentation",
    Icon = "target",
    Side = "Left",
})

PreviewControls:AddToggle("ESPPreviewVisible", {
    Text = "Show preview",
    Default = true,
    Callback = function(value)
        ESPPreview:SetVisible(value)
    end,
})

PreviewControls:AddToggle("ESPPreviewBox", {
    Text = "Show box",
    Default = true,
    Callback = function(value)
        ESPPreview:SetBoxEnabled(value)
    end,
})

PreviewControls:AddToggle("ESPPreviewName", {
    Text = "Show name",
    Default = true,
    Callback = function(value)
        ESPPreview:SetNameEnabled(value)
    end,
})

PreviewControls:AddToggle("ESPPreviewHealth", {
    Text = "Show health",
    Default = true,
    Callback = function(value)
        ESPPreview:SetHealthEnabled(value)
    end,
})

PreviewControls:AddToggle("ESPPreviewTracer", {
    Text = "Show tracer",
    Default = true,
    Callback = function(value)
        ESPPreview:SetTracerEnabled(value)
    end,
})

PreviewControls:AddSlider("ESPPreviewRotation", {
    Text = "Rotation speed",
    Min = 0,
    Max = 40,
    Default = 12,
    Suffix = "°/s",
    Callback = function(value)
        ESPPreview:SetRotationSpeed(value)
    end,
})

PreviewControls:AddButton("Refresh character", function()
    ESPPreview:RefreshCharacter()
end)

local ThemePreview = Appearance:AddSection({
    Name = "Quick themes",
    Description = "Settings contains the full editor",
    Icon = "palette",
    Side = "Right",
})

ThemePreview:AddButton("Use Midnight", function()
    ThemeManager:ApplyTheme("Midnight")
end)
ThemePreview:AddButton("Use Obsidian", function()
    ThemeManager:ApplyTheme("Obsidian")
end)
ThemePreview:AddButton("Use Nord", function()
    ThemeManager:ApplyTheme("Nord")
end)
ThemePreview:AddColorPicker("ExampleAccentColor", {
    Text = "Accent",
    Default = Library:_theme().Accent,
    Callback = function(color)
        Library:SetThemeColor("Accent", color)
    end,
})
ThemePreview:AddColorPicker("ExampleCardColor", {
    Text = "Cards",
    Default = Library:_theme().Surface,
    Callback = function(color)
        Library:SetThemeColor("Surface", color)
    end,
})
ThemePreview:AddLabel("Open Settings for every palette surface and animation preset, or Settings → Type for typography and gradients.")

-- Live values keep the showcase moving without changing gameplay.
local started = os.clock()
task.spawn(function()
    while Window.ScreenGui and Window.ScreenGui.Parent do
        local elapsed = math.floor(os.clock() - started)
        uptimeValue:Set(string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60))
        playersValue:Set(#Players:GetPlayers())
        task.wait(1)
    end
end)

menuKey:Set("R-Shift")
Window:Notify({
    Title = "Northwind loaded",
    Description = "Press RightShift to show or hide the complete interface.",
    Duration = 4,
})
