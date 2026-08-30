# Northwind UI

> This UI is free to use and made by Solmar26.

Discord: **@solmar793**

Northwind UI is an original Roblox/Luau interface library with a translucent dark dashboard design, a fully rounded shell, Gotham typography, animated brand gradients, compact controls, live palette editing, upgraded code-drawn icons, pooled atmospheric effects, detachable telemetry panels, a local-character ESP preview, and reusable controls.

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
    Size = UDim2.fromOffset(960, 580),

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
        Density = 0.5,
        Color = Color3.fromRGB(154, 165, 255),
    },
    ScreenAnimation = {
        Enabled = true,
        Preset = "Snow",
        Speed = 0.85,
        Density = 0.6,
        Color = Color3.fromRGB(242, 246, 255),
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

Section:AddColorPicker("MyColor", {
    Text = "Custom color",
    Default = Color3.fromRGB(124, 138, 255),
    Callback = function(color)
        print(color)
    end,
})
```

Values are also available through `Library.Flags`, and control objects expose `GetValue()`, `SetValue(value)`, and `OnChanged(callback)`.

Icons use Roblox UI primitives rather than Unicode glyphs, so they do not render as missing-glyph squares. The refreshed set includes `home`, `eye`, `sliders`, `settings`, `window`, `palette`, `save`, `keyboard`, `clock`, `target`, `activity`, `sparkles`, `comet`, `snowflake`, `type`, and `layers`. A custom `rbxassetid://...` image can also be supplied through `Icon`.

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

Followed panels share the main window's open and close timing. Their scale transitions complete together, and all followed surfaces are hidden in the same completion step.

## ESP preview

Pass an `ESPPreview` table to `CreateWindow` to attach a live `ViewportFrame` to the right side of the menu. It safely clones the local character without scripts, anchors it as a presentation dummy, and includes configurable name, box, health, distance, tracer, and rotation styling.

```lua
local Window = Library:CreateWindow({
    Title = "Northwind",
    ESPPreview = {
        Width = 232,
        Height = 372,
        FollowMenuVisibility = true,
        ShowBox = true,
        ShowName = true,
        ShowHealth = true,
        ShowTracer = true,
        RotationSpeed = 12,
    },
})

Window.ESPPreview:SetRotationSpeed(20)
Window.ESPPreview:RefreshCharacter()
```

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

Gotham is the default font. `FontPreset` accepts `"Gotham"`, `"Builder Sans"`, or `"Source Sans"`; `Typography` can instead provide custom `Regular`, `Medium`, and `Bold` Font values.

`BrandGradient` controls the animated menu name, monogram, status title, and optional FPS readout. It supports `Enabled`, `Animated`, `Start`, `Finish`, `Rotation`, `Speed`, and `ApplyToFPS`. The generated Type settings page exposes all common controls live. General interface text remains plain by default, while the existing optional interface-wide text gradient can still be enabled separately.

`Motion.Enabled` disables transitions for reduced motion, and `Motion.Speed` scales their duration. Repeated animations targeting the same properties cancel cleanly instead of stacking.

## Atmospheric animations

`BackgroundAnimation` renders strictly behind the main menu controls. `ScreenAnimation` fills the game view while the menu is open but remains behind the menu, ESP preview, notifications, and detached panels. Both accept `Enabled`, `Preset`, `Speed`, `Density`, and `Color`.

Available presets are `Off`, `Snow`, `Comets`, `Stars`, `Fireflies`, `Rain`, `Bubbles`, `Petals`, and `Embers`. The generated Settings page exposes every option live. Both layers use preallocated particle pools and share one per-window frame update, so changing density never creates particles every frame.

```lua
Window:SetBackgroundAnimation({ Preset = "Comets", Enabled = true })
Window:SetScreenAnimation({ Preset = "Snow", Density = 0.7 })
```

## Lifecycle and performance

Each window owns one shared pointer controller for dragging and sliders, one routed key-input listener, and one shared animation update. Atmospheric particles are created once and recycled. `Window:Destroy()` disconnects retained connections, clears theme, font, and gradient references, and removes the window from the library registry. Creating another window with the same `Name` automatically destroys the previous instance cleanly.

## Themes and configs

The Settings tab is generated automatically unless `Settings = false` is passed to `CreateWindow`. It includes:

- Midnight, Obsidian, and Nord theme presets
- Palette selectors for accent, background, sidebar, cards, inputs, borders, text, muted text, and both gradient systems
- Toggle-interface keybind editing
- A functional **Type** page with Gotham/Builder Sans/Source Sans presets
- Animated brand-gradient colors, speed, logo/status styling, and FPS control
- Optional interface-wide text gradient plus reduced-motion and animation-speed controls
- Detached-panel visibility behavior
- Menu-background and full-screen animation presets, speed, density, and custom colors
- Config save, load, delete, refresh, and saved-config dropdown controls

Configs use memory storage by default. To persist them safely in an experience you own, attach a provider that sends config data to a server-owned DataStore. A provider implements `Save`, `Load`, `Delete`, and optionally `List`.

```lua
SaveManager:SetLibrary(Library)
SaveManager:SetProvider(myProvider)
```

