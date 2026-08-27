# Northwind UI

Northwind UI is an original Roblox/Luau interface library with a translucent dark dashboard design, smooth color transitions, crisp code-drawn vector icons, detachable telemetry panels, and concise reusable controls.

It contains UI components only. The included example uses harmless test callbacks and mock telemetry.

## Files

```text
NorthwindUI/
├── Library.lua
├── example.lua
└── addons/
    ├── SaveManager.lua
    └── ThemeManager.lua
```

## GitHub loading

This package is configured for `https://github.com/solmar26po/NorthwindUI`. The repository and files must be public for `raw.githubusercontent.com` links to work.

```lua
local repo = "https://raw.githubusercontent.com/solmar26po/NorthwindUI/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

Only use remote code loading in an environment where you are authorized to do so. For a Roblox experience you own, placing `Library.lua` in a ModuleScript and using `require` is safer and lets you review the exact code shipped with the game.

## Basic API

```lua
local Window = Library:CreateWindow({
    Title = "My Menu",
    Subtitle = "My own Northwind interface",
    ToggleKey = Enum.KeyCode.RightShift,
    Settings = true,
    Transparency = 0.06,
})

local Main = Window:AddTab({
    Name = "Main",
    Description = "Main controls",
    Icon = "home",
})

local Section = Main:AddSection({
    Name = "Examples",
    Description = "Reusable components",
    Side = "Left",
})

Section:AddButton("Click me", function()
    print("Clicked")
end)

Section:AddToggle("MyToggle", {
    Text = "Toggle",
    Default = false,
    Callback = function(value)
        print(value)
    end,
})

Section:AddSlider("MySlider", {
    Text = "Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Suffix = "%",
    Callback = function(value)
        print(value)
    end,
})

Section:AddDropdown("MyDropdown", {
    Text = "Dropdown",
    Values = { "One", "Two", "Three" },
    Default = "One",
})

Section:AddInput("MyInput", {
    Text = "Input",
    Placeholder = "Type here...",
})

Section:AddKeybind("MyKey", {
    Text = "Keybind",
    Default = Enum.KeyCode.F,
    Pressed = function()
        print("F pressed")
    end,
})
```

Values are also available through `Library.Flags`, and control objects expose `GetValue()`, `SetValue(value)`, and `OnChanged(callback)`.

Icons use Roblox UI primitives rather than Unicode glyphs, so they do not render as missing-glyph squares. Built-in names include `home`, `eye`, `sliders`, `settings`, `window`, `palette`, `save`, `keyboard`, `clock`, `target`, `activity`, and `sparkles`. A custom `rbxassetid://...` image can also be supplied through `Icon`.

## Detached panels

```lua
Window:CreateStatusBar({ Title = "My Menu" })

local Panel = Window:CreatePanel({
    Title = "Session",
    Position = UDim2.fromOffset(16, 80),
})

local Time = Panel:AddValue("Uptime", "00:00")
local Progress = Panel:AddProgress("Progress", 25)

Time:Set("04:32")
Progress:Set(70)
```

## Themes and configs

The Settings tab is generated automatically unless `Settings = false` is passed to `CreateWindow`. It includes:

- Midnight, Obsidian, and Nord theme presets
- Six accent colors with live transitions
- Toggle-interface keybind editing
- Config save, load, and delete controls

Configs use memory storage by default. To persist them safely in an experience you own, attach a provider that sends config data to a server-owned DataStore. A provider implements `Save`, `Load`, `Delete`, and optionally `List`.

```lua
SaveManager:SetLibrary(Library)
SaveManager:SetProvider(myProvider)
```

Never trust client-supplied config data for gameplay-critical decisions; validate it on the server.

