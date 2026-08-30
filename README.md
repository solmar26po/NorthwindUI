# Northwind UI

Northwind UI is an original Roblox/Luau interface library with a translucent dark dashboard design, a fully rounded shell, Builder Sans typography, animated brand gradients, clean borderless marks, crisp code-drawn icons, detachable telemetry panels, and reusable controls.

It contains UI components only. The included example uses harmless test callbacks and mock telemetry.

## Files

```text
NorthwindUI/
├── Library.lua
├── example.lua
├── assets/
│   └── NorthwindLogo.png
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
    CornerRadius = 18,
    PanelsFollowMenuVisibility = false,

    FontPreset = "Builder Sans",
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

    LogoStyle = "Monogram",
    LogoText = "NW",
    LogoSize = 38,
    -- To use an uploaded image instead:
    -- LogoStyle = "Image",
    -- Logo = "rbxassetid://1234567890",
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
Window:CreateStatusBar({
    Title = "My Menu",
    GradientFPS = true,
})

local Panel = Window:CreatePanel({
    Title = "Session",
    Position = UDim2.fromOffset(16, 80),
    FollowMenuVisibility = false,
})

local Time = Panel:AddValue("Uptime", "00:00")
local Progress = Panel:AddProgress("Progress", 25)

Time:Set("04:32")
Progress:Set(70)
```

Set `FollowMenuVisibility = true` on any status bar or detached panel that should close with the main menu. Set it to `false` to keep that panel visible. The generated Settings page also includes a **Keep panels visible** switch that updates every detached panel at once.

## Branding

The clean code-native monogram is the default recommendation:

```lua
local Window = Library:CreateWindow({
    Title = "Northwind",
    LogoStyle = "Monogram",
    LogoText = "NW",
    LogoSize = 38,
})
```

To use `assets/NorthwindLogo.png`, upload it to Roblox and use `LogoStyle = "Image"` with its asset ID. `LogoInset`, `LogoSize`, `LogoTextSize`, `TitleSize`, and `LogoTransparency` control presentation without adding an outlined container. The status bar inherits the same image or monogram and can override any of these fields.

## Typography, gradients, and motion

Builder Sans is the default font. `FontPreset` accepts `"Builder Sans"`, `"Gotham"`, or `"Source Sans"`; `Typography` can instead provide custom `Regular`, `Medium`, and `Bold` Font values.

`BrandGradient` controls the animated menu name, monogram, status title, and optional FPS readout. It supports `Enabled`, `Animated`, `Start`, `Finish`, `Rotation`, `Speed`, and `ApplyToFPS`. The generated Type settings page exposes all common controls live. General interface text remains plain by default, while the existing optional interface-wide text gradient can still be enabled separately.

`Motion.Enabled` disables transitions for reduced motion, and `Motion.Speed` scales their duration. Repeated animations targeting the same properties cancel cleanly instead of stacking.

## Lifecycle and performance

Each window owns one shared pointer controller for dragging and sliders, plus one routed key-input listener. `Window:Destroy()` disconnects them, clears retained theme, font, and gradient references, and removes the window from the library registry. Creating another window with the same `Name` automatically destroys the previous instance cleanly.

## Themes and configs

The Settings tab is generated automatically unless `Settings = false` is passed to `CreateWindow`. It includes:

- Midnight, Obsidian, and Nord theme presets
- Six accent colors with live transitions
- Toggle-interface keybind editing
- A functional **Type** page with Builder Sans/Gotham/Source Sans presets
- Animated brand-gradient colors, speed, logo/status styling, and FPS control
- Optional interface-wide text gradient plus reduced-motion and animation-speed controls
- Detached-panel visibility behavior
- Config save, load, and delete controls

Configs use memory storage by default. To persist them safely in an experience you own, attach a provider that sends config data to a server-owned DataStore. A provider implements `Save`, `Load`, `Delete`, and optionally `List`.

```lua
SaveManager:SetLibrary(Library)
SaveManager:SetProvider(myProvider)
```

Never trust client-supplied config data for gameplay-critical decisions; validate it on the server.

