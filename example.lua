--[[
    Northwind UI example
    Repository: https://github.com/solmar26po/NorthwindUI
    All callbacks and telemetry below are harmless demonstrations.
]]

local repo = "https://raw.githubusercontent.com/solmar26po/NorthwindUI/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetProvider(SaveManager:CreateMemoryProvider())

local Window = Library:CreateWindow({
    Title = "Northwind",
    Subtitle = "Window, panels, theme, type, configs",
    ToggleKey = Enum.KeyCode.RightShift,
    Settings = true,
    AutoShow = true,
    Transparency = 0.06,
})

-- Detached HUD elements like the reference image.
Window:CreateStatusBar({
    Title = "Northwind",
    Position = UDim2.fromOffset(16, 28),
})

local KeybindPanel = Window:CreatePanel({
    Title = "Keybinds",
    Icon = "keyboard",
    Position = UDim2.fromOffset(16, 76),
    Width = 210,
})
local menuKey = KeybindPanel:AddValue("Toggle menu", "R-Shift")
local actionKey = KeybindPanel:AddValue("Test action", "F")

local SessionPanel = Window:CreatePanel({
    Title = "Session",
    Icon = "clock",
    Position = UDim2.fromOffset(16, 184),
    Width = 210,
})
local uptimeValue = SessionPanel:AddValue("Uptime", "00:00")
local eventsValue = SessionPanel:AddValue("Events", 0)
local stateValue = SessionPanel:AddValue("State", "Idle")
local demoProgress = SessionPanel:AddProgress("Demo progress", 16)

local MetricsPanel = Window:CreatePanel({
    Title = "Metrics",
    Icon = "activity",
    Position = UDim2.fromOffset(16, 356),
    Width = 210,
})
local playersValue = MetricsPanel:AddValue("Players", #game:GetService("Players"):GetPlayers())
local qualityValue = MetricsPanel:AddValue("Quality", "Smooth")
local workloadProgress = MetricsPanel:AddProgress("Workload", 38)

-- Main tabs and controls.
local Dashboard = Window:AddTab({
    Name = "Dashboard",
    Description = "Overview and harmless test actions",
    Icon = "home",
})

local Actions = Dashboard:AddSection({
    Name = "Actions",
    Description = "Button and notification examples",
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
            Description = "The example button was clicked successfully.",
        })
    end,
})

Actions:AddButton({
    Text = "Show notification",
    Callback = function()
        Window:Notify("Northwind UI", "Animations and notifications are working.")
    end,
})

Actions:AddLabel("These controls only print values and update the demonstration panels.")

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
        print("DemoEnabled:", value)
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
        print("DemoSpeed:", value)
    end,
})

LiveValues:AddDropdown("DemoMode", {
    Text = "Mode",
    Values = { "Relaxed", "Balanced", "Fast" },
    Default = "Balanced",
    Callback = function(value)
        qualityValue:Set(value)
        print("DemoMode:", value)
    end,
})

local Controls = Window:AddTab({
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
    Description = "Click a key field, then press a key",
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
        Window:Notify("Keybind pressed", "The harmless F-key demonstration ran.")
    end,
})

Binds:AddToggle("ExampleToggle", {
    Text = "Example toggle",
    Default = true,
    Callback = function(value)
        print("ExampleToggle:", value)
    end,
})

Binds:AddButton("Reset demo panels", function()
    eventCount = 0
    eventsValue:Set(0)
    stateValue:Set("Idle")
    demoProgress:Set(16)
    workloadProgress:Set(38)
end)

local Appearance = Window:AddTab({
    Name = "Appearance",
    Description = "Preview visual components",
    Icon = "eye",
})

local Preview = Appearance:AddSection({
    Name = "Preview",
    Description = "Typography and component spacing",
    Icon = "sparkles",
    Side = "Left",
})
Preview:AddLabel("Northwind uses rounded cards, restrained gradients, and smooth TweenService animation.")
Preview:AddDivider("Components")
Preview:AddToggle("PreviewToggle", { Text = "Smooth toggle", Default = true })
Preview:AddSlider("PreviewSlider", { Text = "Smooth slider", Min = 0, Max = 100, Default = 72, Suffix = "%" })

local ThemePreview = Appearance:AddSection({
    Name = "Quick themes",
    Description = "The Settings tab has the full controls",
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

-- Harmless live data for the detached panels.
local started = os.clock()
task.spawn(function()
    while Window.ScreenGui and Window.ScreenGui.Parent do
        local elapsed = math.floor(os.clock() - started)
        uptimeValue:Set(string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60))
        playersValue:Set(#game:GetService("Players"):GetPlayers())
        task.wait(1)
    end
end)

Window:Notify({
    Title = "Northwind loaded",
    Description = "Press RightShift to show or hide the interface.",
    Duration = 4,
})

