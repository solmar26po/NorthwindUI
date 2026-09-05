local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local FONT_PRESETS = {
    ["Builder Sans"] = {
        Regular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Medium = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    },
    Gotham = {
        Regular = Font.fromEnum(Enum.Font.Gotham),
        Medium = Font.fromEnum(Enum.Font.GothamMedium),
        Bold = Font.fromEnum(Enum.Font.GothamBold),
    },
    ["Source Sans"] = {
        Regular = Font.fromEnum(Enum.Font.SourceSans),
        Medium = Font.fromEnum(Enum.Font.SourceSansSemibold),
        Bold = Font.fromEnum(Enum.Font.SourceSansBold),
    },
}

local Northwind = {
    Version = "1.7.0",
    Flags = {},
    Options = {},
    Windows = {},
    Configs = {},
    ActiveTheme = "Midnight",
    TypographyPreset = "Gotham",
    Typography = table.clone(FONT_PRESETS.Gotham),
    Motion = {
        Enabled = true,
        Speed = 1,
    },
    TextGradient = {
        Enabled = false,
        Start = Color3.fromRGB(245, 247, 255),
        Finish = Color3.fromRGB(168, 176, 255),
        Rotation = 18,
    },
    BrandGradient = {
        Enabled = true,
        Animated = true,
        Start = Color3.fromRGB(248, 249, 255),
        Finish = Color3.fromRGB(124, 138, 255),
        Rotation = 0,
        Speed = 0.45,
        ApplyToFPS = true,
    },
    Themes = {
        Midnight = {
            Background = Color3.fromRGB(13, 15, 28),
            Sidebar = Color3.fromRGB(16, 18, 31),
            Surface = Color3.fromRGB(25, 29, 47),
            SurfaceAlt = Color3.fromRGB(39, 44, 70),
            Border = Color3.fromRGB(49, 55, 82),
            Text = Color3.fromRGB(241, 243, 250),
            Muted = Color3.fromRGB(151, 158, 187),
            Accent = Color3.fromRGB(124, 138, 255),
            AccentSoft = Color3.fromRGB(83, 89, 174),
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
    _fontBindings = {},
    _textGradientTargets = {},
    _textGradients = {},
    _brandGradients = {},
    _brandGradientConnection = nil,
    _brandPhase = 0,
    _activeTweens = setmetatable({}, { __mode = "k" }),
    _configProvider = nil,
}

local function create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" and property ~= "NoGradient" and property ~= "FontRole" then
            instance[property] = value
        end
    end

    local isTextObject = className == "TextLabel" or className == "TextButton" or className == "TextBox"
    if isTextObject and Northwind._bindFont then
        local role = properties and properties.FontRole
        local legacyFont = properties and properties.Font
        if not role and legacyFont == Enum.Font.GothamBold then
            role = "Bold"
        elseif not role and legacyFont == Enum.Font.GothamMedium then
            role = "Medium"
        end
        Northwind:_bindFont(instance, role or "Regular")
    end

    instance.Parent = properties and properties.Parent or nil
    if className == "TextLabel"
        and not (properties and properties.NoGradient)
        and Northwind._registerTextGradientTarget then
        Northwind:_registerTextGradientTarget(instance)
    end
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
        LineJoinMode = Enum.LineJoinMode.Round,
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
    if not instance or not instance.Parent then
        return nil
    end

    local motion = Northwind.Motion
    if not motion.Enabled then
        for property, value in pairs(properties) do
            instance[property] = value
        end
        return nil
    end

    local propertyNames = {}
    for property in pairs(properties) do
        table.insert(propertyNames, property)
    end
    table.sort(propertyNames)
    local key = table.concat(propertyNames, "|")
    local active = Northwind._activeTweens[instance]
    if not active then
        active = {}
        Northwind._activeTweens[instance] = active
    elseif active[key] then
        active[key]:Cancel()
    end

    local info = TweenInfo.new(
        (duration or 0.18) / math.max(motion.Speed, 0.1),
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local animation = TweenService:Create(instance, info, properties)
    active[key] = animation
    local completedConnection
    completedConnection = animation.Completed:Connect(function()
        if completedConnection then
            completedConnection:Disconnect()
        end
        if active[key] == animation then
            active[key] = nil
        end
    end)
    animation:Play()
    return animation
end

-- BEGIN GENERATED ICON DATA (scripts/build-icons.cjs)
local ICON_ATLAS_FILE = "northwind-icons-84a602f0c90e.png"
local ICON_ATLAS_PNG = "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"
local ICON_ATLAS_NAMES = {
    "home",
    "sliders",
    "eye",
    "settings",
    "window",
    "palette",
    "save",
    "keyboard",
    "clock",
    "activity",
    "target",
    "sparkles",
    "search",
    "chevron-down",
    "toggle",
    "info",
    "comet",
    "snowflake",
    "type",
    "layers",
}
-- END GENERATED ICON DATA

local iconAtlasImage
local iconAtlasAttempted = false
local iconAtlasOverride
local iconAtlasSlots = {}
for index, name in ipairs(ICON_ATLAS_NAMES) do
    iconAtlasSlots[name] = Vector2.new(((index - 1) % 5) * 96, math.floor((index - 1) / 5) * 96)
end

local function decodeIconPNG(encoded)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local values = {}
    for index = 1, #alphabet do values[string.byte(alphabet, index)] = index - 1 end
    local bytes = {}
    for index = 1, #encoded, 4 do
        local a, b, c, d = string.byte(encoded, index, index + 3)
        local value = values[a] * 262144 + values[b] * 4096 + (values[c] or 0) * 64 + (values[d] or 0)
        bytes[#bytes + 1] = string.char(math.floor(value / 65536) % 256)
        if c ~= 61 then bytes[#bytes + 1] = string.char(math.floor(value / 256) % 256) end
        if d ~= 61 then bytes[#bytes + 1] = string.char(value % 256) end
    end
    return table.concat(bytes)
end

local function resolveIconAtlas()
    if iconAtlasOverride ~= nil then return iconAtlasOverride or nil end
    if iconAtlasAttempted then return iconAtlasImage end
    iconAtlasAttempted = true
    local registerAsset = type(getcustomasset) == "function" and getcustomasset
        or (type(getsynasset) == "function" and getsynasset)
    if not registerAsset or type(writefile) ~= "function" then return nil end
    -- One file and one registration per library load; no HTTP or frame callbacks.
    -- Validate cached bytes so an interrupted write cannot leave a broken atlas.
    local ok, image = pcall(function()
        local png = decodeIconPNG(ICON_ATLAS_PNG)
        local cached, contents = false, nil
        if type(readfile) == "function" then cached, contents = pcall(readfile, ICON_ATLAS_FILE) end
        if not cached or contents ~= png then writefile(ICON_ATLAS_FILE, png) end
        return registerAsset(ICON_ATLAS_FILE)
    end)
    if ok and type(image) == "string" and image ~= "" then iconAtlasImage = image end
    return iconAtlasImage
end

-- Call before creating UI. In Studio, upload assets/NorthwindIcons.png and pass
-- its image asset ID. nil restores auto loading; false selects native fallback.
function Northwind:SetIconAtlas(image)
    assert(image == nil or image == false or (type(image) == "string" and image ~= ""), "Expected an image URI, nil, or false")
    iconAtlasOverride = image
    return self
end

function Northwind:GetIconNames()
    return table.clone(ICON_ATLAS_NAMES)
end

function Northwind:GetIconRenderer()
    return resolveIconAtlas() and "PNG atlas" or "Native fallback"
end

local ICON_ALIASES = {
    ["settings"] = "settings", ["gear"] = "settings",
    ["window"] = "window", ["panel"] = "window",
    ["theme"] = "palette", ["palette"] = "palette",
    ["configs"] = "save", ["config"] = "save", ["save"] = "save",
    ["dashboard"] = "home", ["home"] = "home", ["farm"] = "home",
    ["visuals"] = "eye", ["appearance"] = "eye", ["eye"] = "eye",
    ["controls"] = "sliders", ["sliders"] = "sliders", ["inputs"] = "sliders",
    ["keybinds"] = "keyboard", ["keyboard"] = "keyboard",
    ["session"] = "clock", ["clock"] = "clock", ["time"] = "clock",
    ["metrics"] = "activity", ["activity"] = "activity",
    ["targets"] = "target", ["target"] = "target",
    ["actions"] = "sparkles", ["sparkles"] = "sparkles", ["preview"] = "sparkles",
    ["search"] = "search", ["chevron"] = "chevron-down", ["chevron-down"] = "chevron-down",
    ["toggle"] = "toggle", ["info"] = "info",
    ["effects"] = "comet", ["animation"] = "comet", ["comet"] = "comet",
    ["snow"] = "snowflake", ["snowflake"] = "snowflake",
    ["type"] = "type", ["typography"] = "type", ["layers"] = "layers",
}

local LEGACY_ICON_ALIASES = {
    ["◆"] = "sparkles", ["✦"] = "sparkles", ["◇"] = "sliders",
    ["◉"] = "activity", ["◈"] = "target", ["⌂"] = "home",
    ["⌁"] = "sliders", ["⌨"] = "keyboard", ["◷"] = "clock",
    ["⚙"] = "settings", ["▣"] = "window", ["✿"] = "palette",
    ["▤"] = "save", ["☼"] = "palette",
}

local function resolveIconName(value, fallback)
    if type(value) ~= "string" or value == "" then
        return fallback or "sparkles"
    end
    if string.find(value, "rbxasset", 1, true) then
        return value
    end
    return ICON_ALIASES[string.lower(value)] or LEGACY_ICON_ALIASES[value] or fallback or "sparkles"
end

local function makeIcon(parent, iconName, position, size, colorToken)
    local token = colorToken or "Muted"
    local palette = Northwind:_theme()
    local container = create("Frame", {
        Name = "Icon",
        Position = position or UDim2.new(),
        Size = size or UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local icon = { Frame = container, Parts = {} }
    local resolved = resolveIconName(iconName, "sparkles")

    local function track(instance, property)
        local propertyName = property or "BackgroundColor3"
        Northwind:_bind(instance, propertyName, token)
        table.insert(icon.Parts, { Instance = instance, Property = propertyName })
        return instance
    end

    local function line(x1, y1, x2, y2, thickness)
        local dx, dy = x2 - x1, y2 - y1
        local length = math.sqrt(dx * dx + dy * dy)
        local part = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale((x1 + x2) * 0.5, (y1 + y2) * 0.5),
            Size = UDim2.new(length, 0, 0, thickness or 2),
            Rotation = math.deg(math.atan2(dy, dx)),
            BackgroundColor3 = palette[token],
            BorderSizePixel = 0,
            Parent = container,
        })
        round(part, 2)
        return track(part)
    end

    local function circle(x, y, diameter, thickness, filled)
        local part = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(diameter, diameter),
            BackgroundColor3 = palette[token],
            BackgroundTransparency = filled and 0 or 1,
            BorderSizePixel = 0,
            Parent = container,
        })
        round(part, 999)
        if filled then
            track(part)
        else
            local outline = stroke(part, palette[token], 0, thickness or 1.5)
            track(outline, "Color")
        end
        return part
    end

    local function outlineRect(x, y, width, height, radius)
        local part = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(width, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = container,
        })
        round(part, radius or 3)
        local outline = stroke(part, palette[token], 0, 1.5)
        track(outline, "Color")
        return part
    end

    local atlas = iconAtlasSlots[resolved] and resolveIconAtlas()
    if atlas then
        local image = create("ImageLabel", {
            Name = resolved,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = atlas,
            ImageRectOffset = iconAtlasSlots[resolved],
            ImageRectSize = Vector2.new(96, 96),
            ImageColor3 = palette[token],
            ScaleType = Enum.ScaleType.Fit,
            Parent = container,
        })
        track(image, "ImageColor3")
    elseif string.find(resolved, "rbxasset", 1, true) then
        local image = create("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = resolved,
            ImageColor3 = palette[token],
            ScaleType = Enum.ScaleType.Fit,
            Parent = container,
        })
        track(image, "ImageColor3")
    elseif resolved == "search" then
        circle(0.42, 0.42, 0.58, 1.5)
        line(0.62, 0.62, 0.88, 0.88, 1.8)
    elseif resolved == "home" then
        line(0.12, 0.49, 0.5, 0.16, 1.8)
        line(0.5, 0.16, 0.88, 0.49, 1.8)
        outlineRect(0.5, 0.62, 0.58, 0.5, 3)
        outlineRect(0.5, 0.7, 0.16, 0.28, 2)
    elseif resolved == "eye" then
        line(0.08, 0.5, 0.33, 0.27, 1.7)
        line(0.33, 0.27, 0.67, 0.27, 1.7)
        line(0.67, 0.27, 0.92, 0.5, 1.7)
        line(0.92, 0.5, 0.67, 0.73, 1.7)
        line(0.67, 0.73, 0.33, 0.73, 1.7)
        line(0.33, 0.73, 0.08, 0.5, 1.7)
        circle(0.5, 0.5, 0.22, 1, true)
    elseif resolved == "sliders" then
        line(0.12, 0.25, 0.88, 0.25, 1.5)
        line(0.12, 0.5, 0.88, 0.5, 1.5)
        line(0.12, 0.75, 0.88, 0.75, 1.5)
        circle(0.34, 0.25, 0.18, 1.3)
        circle(0.68, 0.5, 0.18, 1.3)
        circle(0.45, 0.75, 0.18, 1.3)
    elseif resolved == "settings" then
        circle(0.5, 0.5, 0.46, 1.6)
        circle(0.5, 0.5, 0.14, 1.2)
        line(0.5, 0.06, 0.5, 0.24, 1.8)
        line(0.5, 0.76, 0.5, 0.94, 1.8)
        line(0.06, 0.5, 0.24, 0.5, 1.8)
        line(0.76, 0.5, 0.94, 0.5, 1.8)
        circle(0.5, 0.06, 0.12, 1, true)
        circle(0.5, 0.94, 0.12, 1, true)
        circle(0.06, 0.5, 0.12, 1, true)
        circle(0.94, 0.5, 0.12, 1, true)
    elseif resolved == "window" then
        outlineRect(0.5, 0.5, 0.82, 0.68, 3)
        line(0.09, 0.36, 0.91, 0.36, 1.4)
        circle(0.21, 0.23, 0.075, 1, true)
        circle(0.35, 0.23, 0.075, 1, true)
        line(0.22, 0.55, 0.78, 0.55, 1.5)
        line(0.22, 0.7, 0.62, 0.7, 1.5)
    elseif resolved == "palette" then
        circle(0.48, 0.5, 0.76, 1.6)
        circle(0.31, 0.34, 0.105, 1, true)
        circle(0.52, 0.25, 0.105, 1, true)
        circle(0.7, 0.39, 0.105, 1, true)
        circle(0.35, 0.65, 0.105, 1, true)
        circle(0.66, 0.68, 0.2, 1.4)
    elseif resolved == "save" then
        outlineRect(0.5, 0.5, 0.7, 0.78, 3)
        line(0.25, 0.13, 0.68, 0.13, 1.6)
        line(0.68, 0.13, 0.85, 0.3, 1.6)
        line(0.3, 0.43, 0.7, 0.43, 1.5)
        line(0.3, 0.58, 0.7, 0.58, 1.5)
        line(0.3, 0.73, 0.58, 0.73, 1.5)
    elseif resolved == "keyboard" then
        outlineRect(0.5, 0.5, 0.86, 0.6, 3)
        for columnIndex = 0, 4 do
            circle(0.22 + columnIndex * 0.14, 0.4, 0.06, 1, true)
            circle(0.22 + columnIndex * 0.14, 0.56, 0.06, 1, true)
        end
        line(0.31, 0.72, 0.69, 0.72, 1.6)
    elseif resolved == "clock" then
        circle(0.5, 0.52, 0.72, 1.5)
        line(0.5, 0.52, 0.5, 0.28, 1.7)
        line(0.5, 0.52, 0.7, 0.63, 1.7)
        line(0.4, 0.08, 0.6, 0.08, 1.7)
    elseif resolved == "target" then
        circle(0.5, 0.5, 0.7, 1.5)
        circle(0.5, 0.5, 0.34, 1.4)
        circle(0.5, 0.5, 0.09, 1, true)
        line(0.5, 0.02, 0.5, 0.2, 1.4)
        line(0.5, 0.8, 0.5, 0.98, 1.4)
        line(0.02, 0.5, 0.2, 0.5, 1.4)
        line(0.8, 0.5, 0.98, 0.5, 1.4)
    elseif resolved == "activity" then
        line(0.08, 0.56, 0.28, 0.56, 2)
        line(0.28, 0.56, 0.4, 0.24, 2)
        line(0.4, 0.24, 0.58, 0.78, 2)
        line(0.58, 0.78, 0.71, 0.43, 2)
        line(0.71, 0.43, 0.92, 0.43, 2)
    elseif resolved == "sparkles" then
        line(0.34, 0.12, 0.34, 0.62, 1.7)
        line(0.09, 0.37, 0.59, 0.37, 1.7)
        line(0.18, 0.2, 0.5, 0.54, 1.4)
        line(0.5, 0.2, 0.18, 0.54, 1.4)
        line(0.74, 0.56, 0.74, 0.9, 1.5)
        line(0.57, 0.73, 0.91, 0.73, 1.5)
    elseif resolved == "toggle" then
        outlineRect(0.5, 0.5, 0.82, 0.48, 999)
        circle(0.35, 0.5, 0.28, 1, true)
    elseif resolved == "comet" then
        circle(0.67, 0.34, 0.24, 1.4)
        line(0.08, 0.84, 0.57, 0.43, 1.8)
        line(0.22, 0.86, 0.62, 0.53, 1.3)
        line(0.08, 0.67, 0.51, 0.31, 1.3)
    elseif resolved == "snowflake" then
        line(0.5, 0.08, 0.5, 0.92, 1.5)
        line(0.14, 0.29, 0.86, 0.71, 1.5)
        line(0.14, 0.71, 0.86, 0.29, 1.5)
        circle(0.5, 0.5, 0.1, 1, true)
    elseif resolved == "type" then
        line(0.16, 0.2, 0.84, 0.2, 1.8)
        line(0.5, 0.2, 0.5, 0.84, 1.8)
        line(0.32, 0.84, 0.68, 0.84, 1.8)
    elseif resolved == "layers" then
        line(0.12, 0.34, 0.5, 0.12, 1.6)
        line(0.5, 0.12, 0.88, 0.34, 1.6)
        line(0.12, 0.34, 0.5, 0.56, 1.6)
        line(0.5, 0.56, 0.88, 0.34, 1.6)
        line(0.16, 0.57, 0.5, 0.78, 1.5)
        line(0.5, 0.78, 0.84, 0.57, 1.5)
    elseif resolved == "chevron-down" then
        line(0.18, 0.34, 0.5, 0.66, 1.6)
        line(0.5, 0.66, 0.82, 0.34, 1.6)
    elseif resolved == "info" then
        circle(0.5, 0.5, 0.74, 1.5)
        line(0.5, 0.43, 0.5, 0.73, 1.7)
        circle(0.5, 0.27, 0.09, 1, true)
    else
        line(0.5, 0.08, 0.5, 0.92, 2)
        line(0.08, 0.5, 0.92, 0.5, 2)
        line(0.22, 0.22, 0.78, 0.78, 1.6)
        line(0.78, 0.22, 0.22, 0.78, 1.6)
    end
    return icon
end

function Northwind:CreateIcon(parent, config)
    config = config or {}
    return makeIcon(parent, config.Name, config.Position, config.Size, config.ColorToken).Frame
end

local function setIconColor(icon, color, duration)
    if not icon then
        return
    end
    for _, part in ipairs(icon.Parts) do
        if part.Instance and part.Instance.Parent then
            tween(part.Instance, duration or 0.16, { [part.Property] = color })
        end
    end
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

local function colorToHex(color)
    local value = colorToTable(color)
    return string.format("#%02X%02X%02X", value.R, value.G, value.B)
end

local function hexToColor(value)
    local cleaned = tostring(value or ""):gsub("#", ""):gsub("%s", "")
    if #cleaned ~= 6 or not string.match(cleaned, "^[%da-fA-F]+$") then
        return nil
    end
    return Color3.fromRGB(
        tonumber(string.sub(cleaned, 1, 2), 16),
        tonumber(string.sub(cleaned, 3, 4), 16),
        tonumber(string.sub(cleaned, 5, 6), 16)
    )
end

function Northwind:_theme()
    return self.Themes[self.ActiveTheme] or self.Themes.Midnight
end

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    end
end

function Northwind:_bindFont(instance, role)
    role = role or "Regular"
    applyFont(instance, self.Typography[role] or self.Typography.Regular)
    table.insert(self._fontBindings, {
        Instance = instance,
        Role = role,
    })
end

function Northwind:SetTypography(preset)
    if type(preset) == "string" then
        assert(FONT_PRESETS[preset], "Unknown Northwind font preset: " .. preset)
        self.TypographyPreset = preset
        self.Typography = table.clone(FONT_PRESETS[preset])
    elseif type(preset) == "table" then
        local custom = table.clone(self.Typography)
        for role, font in pairs(preset) do
            if role == "Regular" or role == "Medium" or role == "Bold" then
                custom[role] = font
            end
        end
        self.TypographyPreset = "Custom"
        self.Typography = custom
    else
        return
    end

    for index = #self._fontBindings, 1, -1 do
        local binding = self._fontBindings[index]
        if not binding.Instance or not binding.Instance.Parent then
            table.remove(self._fontBindings, index)
        else
            applyFont(binding.Instance, self.Typography[binding.Role] or self.Typography.Regular)
        end
    end
end

function Northwind:SetMotion(enabled, speed)
    if enabled ~= nil then
        self.Motion.Enabled = enabled == true
    end
    if speed ~= nil then
        self.Motion.Speed = math.clamp(tonumber(speed) or self.Motion.Speed, 0.25, 3)
    end
end

function Northwind:_attachTextGradient(instance)
    local existing = instance:FindFirstChild("NorthwindTextGradient")
    if existing then
        return existing
    end
    local settings = self.TextGradient
    local gradient = create("UIGradient", {
        Name = "NorthwindTextGradient",
        Color = ColorSequence.new(settings.Start, settings.Finish),
        Rotation = settings.Rotation,
        Enabled = settings.Enabled,
        Parent = instance,
    })
    table.insert(self._textGradients, gradient)
    return gradient
end

function Northwind:_registerTextGradientTarget(instance)
    table.insert(self._textGradientTargets, instance)
    if self.TextGradient.Enabled then
        self:_attachTextGradient(instance)
    end
end

function Northwind:SetTextGradient(startColor, finishColor, rotation, enabled)
    local settings = self.TextGradient
    if typeof(startColor) == "Color3" then
        settings.Start = startColor
    end
    if typeof(finishColor) == "Color3" then
        settings.Finish = finishColor
    end
    if rotation ~= nil then
        settings.Rotation = tonumber(rotation) or settings.Rotation
    end
    if enabled ~= nil then
        settings.Enabled = enabled == true
    end

    for index = #self._textGradientTargets, 1, -1 do
        local target = self._textGradientTargets[index]
        if not target or not target.Parent then
            table.remove(self._textGradientTargets, index)
        else
            local gradient = target:FindFirstChild("NorthwindTextGradient")
            if settings.Enabled and not gradient then
                gradient = self:_attachTextGradient(target)
            end
            if gradient then
                gradient.Enabled = settings.Enabled
                gradient.Color = ColorSequence.new(settings.Start, settings.Finish)
                gradient.Rotation = settings.Rotation
                gradient.Offset = Vector2.new(-0.08, 0)
                tween(gradient, 0.22, { Offset = Vector2.new(0, 0) })
            end
        end
    end
end

local function brandGradientSequence(settings)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, settings.Start),
        ColorSequenceKeypoint.new(0.48, settings.Finish),
        ColorSequenceKeypoint.new(1, settings.Start),
    })
end

function Northwind:_refreshBrandGradients()
    local settings = self.BrandGradient
    local sequence = brandGradientSequence(settings)
    for index = #self._brandGradients, 1, -1 do
        local binding = self._brandGradients[index]
        local gradient = binding.Gradient
        if not gradient or not gradient.Parent then
            table.remove(self._brandGradients, index)
        else
            local enabled = settings.Enabled and (binding.Role ~= "FPS" or settings.ApplyToFPS)
            gradient.Enabled = enabled
            gradient.Color = sequence
            gradient.Rotation = settings.Rotation
            if not settings.Animated then
                gradient.Offset = Vector2.new(0, 0)
            end
        end
    end
end

function Northwind:_ensureBrandGradientAnimator()
    if self._brandGradientConnection and self._brandGradientConnection.Connected then
        return
    end
    if #self.Windows == 0 and #self._brandGradients == 0 then
        return
    end
    self._brandGradientConnection = RunService.RenderStepped:Connect(function(delta)
        local settings = self.BrandGradient
        if not settings.Enabled or not settings.Animated then
            return
        end
        self._brandPhase = (self._brandPhase + delta * settings.Speed) % 2
        local phase = self._brandPhase
        local offset = phase <= 1 and (-1 + phase * 2) or (3 - phase * 2)
        for index = #self._brandGradients, 1, -1 do
            local binding = self._brandGradients[index]
            local gradient = binding.Gradient
            if not gradient or not gradient.Parent then
                table.remove(self._brandGradients, index)
            elseif gradient.Enabled then
                gradient.Offset = Vector2.new(offset, 0)
            end
        end
    end)
end

function Northwind:_attachBrandGradient(instance, role)
    local gradient = create("UIGradient", {
        Name = "NorthwindBrandGradient",
        Color = brandGradientSequence(self.BrandGradient),
        Rotation = self.BrandGradient.Rotation,
        Enabled = true,
        Parent = instance,
    })
    table.insert(self._brandGradients, {
        Gradient = gradient,
        Role = role or "Brand",
    })
    self:_refreshBrandGradients()
    self:_ensureBrandGradientAnimator()
    return gradient
end

function Northwind:SetBrandGradient(settings)
    if type(settings) == "boolean" then
        self.BrandGradient.Enabled = settings
    elseif type(settings) == "table" then
        for key, value in pairs(settings) do
            if key == "Enabled" or key == "Animated" or key == "ApplyToFPS" then
                self.BrandGradient[key] = value == true
            elseif key == "Start" or key == "Finish" then
                if typeof(value) == "Color3" then
                    self.BrandGradient[key] = value
                end
            elseif key == "Rotation" then
                self.BrandGradient.Rotation = tonumber(value) or self.BrandGradient.Rotation
            elseif key == "Speed" then
                self.BrandGradient.Speed = math.clamp(tonumber(value) or self.BrandGradient.Speed, 0.05, 2)
            end
        end
    end
    self:_refreshBrandGradients()
    self:_ensureBrandGradientAnimator()
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
        for _, window in ipairs(self.Windows) do
            if window._activeTab and window.Main and window.Main.Parent then
                window:SelectTab(window._activeTab)
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

function Northwind:SetThemeColor(token, color)
    if typeof(color) ~= "Color3" or self:_theme()[token] == nil then
        return
    end
    local custom = table.clone(self:_theme())
    custom[token] = color
    if token == "Accent" or token == "Surface" then
        custom.AccentSoft = custom.Accent:Lerp(custom.Surface, 0.45)
    end
    self:SetTheme(custom)
end

function Northwind:SetConfigProvider(provider)
    self._configProvider = provider
end

function Northwind:GetConfigData()
    local values = {}
    local palette = {}
    local primaryWindow = self.Windows[1]
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
        textGradient = {
            enabled = self.TextGradient.Enabled,
            start = colorToTable(self.TextGradient.Start),
            finish = colorToTable(self.TextGradient.Finish),
            rotation = self.TextGradient.Rotation,
        },
        brandGradient = {
            enabled = self.BrandGradient.Enabled,
            animated = self.BrandGradient.Animated,
            start = colorToTable(self.BrandGradient.Start),
            finish = colorToTable(self.BrandGradient.Finish),
            rotation = self.BrandGradient.Rotation,
            speed = self.BrandGradient.Speed,
            applyToFPS = self.BrandGradient.ApplyToFPS,
        },
        typography = self.TypographyPreset,
        motion = {
            enabled = self.Motion.Enabled,
            speed = self.Motion.Speed,
        },
        animations = primaryWindow and {
            background = {
                enabled = primaryWindow.BackgroundAnimation.Enabled,
                preset = primaryWindow.BackgroundAnimation.Preset,
                speed = primaryWindow.BackgroundAnimation.Speed,
                density = primaryWindow.BackgroundAnimation.Density,
                color = colorToTable(primaryWindow.BackgroundAnimation.Color),
            },
            screen = {
                enabled = primaryWindow.ScreenAnimation.Enabled,
                preset = primaryWindow.ScreenAnimation.Preset,
                speed = primaryWindow.ScreenAnimation.Speed,
                density = primaryWindow.ScreenAnimation.Density,
                color = colorToTable(primaryWindow.ScreenAnimation.Color),
            },
        } or nil,
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
    if data.textGradient then
        self:SetTextGradient(
            tableToColor(data.textGradient.start or {}),
            tableToColor(data.textGradient.finish or {}),
            data.textGradient.rotation,
            data.textGradient.enabled
        )
    end
    if data.brandGradient then
        self:SetBrandGradient({
            Enabled = data.brandGradient.enabled,
            Animated = data.brandGradient.animated,
            Start = tableToColor(data.brandGradient.start or {}),
            Finish = tableToColor(data.brandGradient.finish or {}),
            Rotation = data.brandGradient.rotation,
            Speed = data.brandGradient.speed,
            ApplyToFPS = data.brandGradient.applyToFPS,
        })
    end
    if data.typography and FONT_PRESETS[data.typography] then
        self:SetTypography(data.typography)
    end
    if data.motion then
        self:SetMotion(data.motion.enabled, data.motion.speed)
    end
    if data.animations then
        local function deserialize(settings)
            if not settings then
                return nil
            end
            return {
                Enabled = settings.enabled,
                Preset = settings.preset,
                Speed = settings.speed,
                Density = settings.density,
                Color = tableToColor(settings.color or {}),
            }
        end
        local background = deserialize(data.animations.background)
        local screen = deserialize(data.animations.screen)
        for _, window in ipairs(self.Windows) do
            if background then
                window:SetBackgroundAnimation(background)
            end
            if screen then
                window:SetScreenAnimation(screen)
            end
        end
        local function syncOptions(prefix, settings)
            if not settings then
                return
            end
            local mapped = {
                Enabled = settings.Enabled,
                Preset = settings.Preset,
                Speed = math.floor((settings.Speed or 1) * 100 + 0.5),
                Density = math.floor((settings.Density or 0.55) * 100 + 0.5),
                Color = settings.Color,
            }
            for suffix, value in pairs(mapped) do
                local option = self.Options[prefix .. suffix]
                if option then
                    option:SetValue(value, true)
                end
            end
        end
        syncOptions("Northwind_MenuAnimation", background)
        syncOptions("Northwind_ScreenAnimation", screen)
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

function Northwind:ListConfigs()
    local found = {}
    for name in pairs(self.Configs) do
        found[tostring(name)] = true
    end
    if self._configProvider and self._configProvider.List then
        local ok, names = pcall(function()
            return self._configProvider:List()
        end)
        if ok and type(names) == "table" then
            for _, name in ipairs(names) do
                found[tostring(name)] = true
            end
        end
    end
    local names = {}
    for name in pairs(found) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return names
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

local ESPPreview = {}
ESPPreview.__index = ESPPreview

local function addHover(button, normalToken, hoverToken)
    Northwind:_bind(button, "BackgroundColor3", normalToken)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = Northwind:_theme()[hoverToken] })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = Northwind:_theme()[normalToken] })
    end)
end

local function addSurfaceMotion(frame, outline, restingTransparency, hoverTransparency, outlineTransparency)
    frame.Active = true
    frame.MouseEnter:Connect(function()
        tween(frame, 0.2, { BackgroundTransparency = hoverTransparency })
        if outline then
            tween(outline, 0.2, { Transparency = 0.28 })
        end
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, 0.2, { BackgroundTransparency = restingTransparency })
        if outline then
            tween(outline, 0.2, { Transparency = outlineTransparency or 0.52 })
        end
    end)
end

local AnimationLayer = {}
AnimationLayer.__index = AnimationLayer

local ANIMATION_PRESETS = { "Off", "Snow", "Comets", "Stars", "Fireflies", "Rain", "Bubbles", "Petals", "Embers" }

local function createAnimationLayer(parent, settings, maxParticles)
    local holder = create("Frame", {
        Name = "AnimatedBackdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    local layer = setmetatable({
        Frame = holder,
        Particles = {},
        Random = Random.new(),
        MaxParticles = maxParticles,
        Enabled = false,
        Preset = "Off",
        Speed = 1,
        Density = 0.55,
        Color = Color3.fromRGB(235, 240, 255),
        Active = true,
    }, AnimationLayer)
    for _ = 1, maxParticles do
        local particle = create("Frame", {
            BackgroundColor3 = layer.Color,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = holder,
        })
        round(particle, 999)
        local outline = stroke(particle, layer.Color, 1, 1)
        table.insert(layer.Particles, {
            Frame = particle,
            Outline = outline,
            Active = false,
            X = 0,
            Y = 0,
            VX = 0,
            VY = 0,
            Phase = 0,
            Drift = 0,
        })
    end
    layer:Set(settings or {})
    return layer
end

function AnimationLayer:_hideParticle(particle)
    particle.Active = false
    particle.Frame.Visible = false
end

function AnimationLayer:_spawnParticle(particle, width, height, initial)
    local random = self.Random
    local preset = self.Preset
    local color = self.Color
    local frame = particle.Frame
    local outline = particle.Outline
    particle.Active = true
    particle.Phase = random:NextNumber(0, math.pi * 2)
    particle.Drift = random:NextNumber(5, 24)
    frame.Visible = true
    frame.Rotation = 0
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.3
    outline.Color = color
    outline.Transparency = 1

    if preset == "Snow" then
        local size = random:NextNumber(2, 7)
        particle.X = random:NextNumber(0, width)
        particle.Y = initial and random:NextNumber(0, height) or -size * 2
        particle.VX = random:NextNumber(-6, 6)
        particle.VY = random:NextNumber(18, 48)
        frame.Size = UDim2.fromOffset(size, size)
        frame.BackgroundTransparency = random:NextNumber(0.18, 0.62)
    elseif preset == "Comets" then
        local length = random:NextNumber(34, 82)
        particle.X = initial and random:NextNumber(0, width) or width + length
        particle.Y = initial and random:NextNumber(0, height) or -length * 0.5
        particle.VX = random:NextNumber(-150, -88)
        particle.VY = random:NextNumber(58, 102)
        frame.Size = UDim2.fromOffset(length, random:NextNumber(1, 2.4))
        frame.Rotation = -32
        frame.BackgroundTransparency = random:NextNumber(0.32, 0.68)
    elseif preset == "Stars" then
        local size = random:NextNumber(1.5, 4.5)
        particle.X = random:NextNumber(0, width)
        particle.Y = random:NextNumber(0, height)
        particle.VX = random:NextNumber(-2, 2)
        particle.VY = random:NextNumber(-1, 2)
        frame.Size = UDim2.fromOffset(size, size)
        frame.BackgroundTransparency = random:NextNumber(0.2, 0.64)
    elseif preset == "Fireflies" then
        local size = random:NextNumber(3, 7)
        particle.X = random:NextNumber(0, width)
        particle.Y = random:NextNumber(0, height)
        particle.VX = random:NextNumber(-6, 6)
        particle.VY = random:NextNumber(-8, 4)
        frame.Size = UDim2.fromOffset(size, size)
        frame.BackgroundColor3 = color:Lerp(Color3.fromRGB(255, 239, 142), 0.45)
        frame.BackgroundTransparency = random:NextNumber(0.3, 0.65)
    elseif preset == "Rain" then
        local length = random:NextNumber(12, 26)
        particle.X = random:NextNumber(0, width)
        particle.Y = initial and random:NextNumber(0, height) or -length
        particle.VX = random:NextNumber(-8, 8)
        particle.VY = random:NextNumber(180, 320)
        frame.Size = UDim2.fromOffset(random:NextNumber(1, 1.8), length)
        frame.Rotation = 6
        frame.BackgroundTransparency = random:NextNumber(0.48, 0.76)
    elseif preset == "Bubbles" then
        local size = random:NextNumber(6, 18)
        particle.X = random:NextNumber(0, width)
        particle.Y = initial and random:NextNumber(0, height) or height + size
        particle.VX = random:NextNumber(-8, 8)
        particle.VY = random:NextNumber(-34, -15)
        frame.Size = UDim2.fromOffset(size, size)
        frame.BackgroundTransparency = 1
        outline.Transparency = random:NextNumber(0.45, 0.75)
    elseif preset == "Petals" then
        local widthSize = random:NextNumber(5, 10)
        particle.X = random:NextNumber(0, width)
        particle.Y = initial and random:NextNumber(0, height) or -12
        particle.VX = random:NextNumber(-12, 12)
        particle.VY = random:NextNumber(16, 38)
        frame.Size = UDim2.fromOffset(widthSize, widthSize * 0.52)
        frame.Rotation = random:NextNumber(-45, 45)
        frame.BackgroundColor3 = color:Lerp(Color3.fromRGB(255, 184, 220), 0.28)
        frame.BackgroundTransparency = random:NextNumber(0.28, 0.58)
    elseif preset == "Embers" then
        local size = random:NextNumber(2, 5)
        particle.X = random:NextNumber(0, width)
        particle.Y = initial and random:NextNumber(0, height) or height + 8
        particle.VX = random:NextNumber(-10, 10)
        particle.VY = random:NextNumber(-52, -24)
        frame.Size = UDim2.fromOffset(size, size)
        frame.BackgroundColor3 = color:Lerp(Color3.fromRGB(255, 151, 65), 0.36)
        frame.BackgroundTransparency = random:NextNumber(0.24, 0.62)
    else
        self:_hideParticle(particle)
        return
    end
    frame.Position = UDim2.fromOffset(particle.X, particle.Y)
end

function AnimationLayer:Set(settings)
    if type(settings) == "string" then
        settings = { Preset = settings, Enabled = settings ~= "Off" }
    elseif type(settings) == "boolean" then
        settings = { Preset = settings and "Stars" or "Off", Enabled = settings }
    end
    settings = settings or {}
    local previousPreset = self.Preset
    local previousEnabled = self.Enabled
    if settings.Preset ~= nil and table.find(ANIMATION_PRESETS, settings.Preset) then
        self.Preset = settings.Preset
    end
    if settings.Enabled ~= nil then
        self.Enabled = settings.Enabled == true
    elseif settings.Preset ~= nil then
        self.Enabled = self.Preset ~= "Off"
    end
    if settings.Speed ~= nil then
        self.Speed = math.clamp(tonumber(settings.Speed) or 1, 0.15, 3)
    end
    if settings.Density ~= nil then
        self.Density = math.clamp(tonumber(settings.Density) or 0.55, 0.1, 1)
    end
    if typeof(settings.Color) == "Color3" then
        self.Color = settings.Color
    end
    local shouldReset = previousPreset ~= self.Preset or (not previousEnabled and self.Enabled)
    if not self.Enabled or self.Preset == "Off" or shouldReset then
        for _, particle in ipairs(self.Particles) do
            self:_hideParticle(particle)
        end
    elseif typeof(settings.Color) == "Color3" then
        for _, particle in ipairs(self.Particles) do
            if particle.Active then
                particle.Frame.BackgroundColor3 = self.Preset == "Fireflies"
                    and self.Color:Lerp(Color3.fromRGB(255, 239, 142), 0.45)
                    or self.Color
                particle.Outline.Color = self.Color
            end
        end
    end
    self.Frame.Visible = self.Active and self.Enabled and self.Preset ~= "Off"
    return self
end

function AnimationLayer:SetActive(active)
    self.Active = active == true
    self.Frame.Visible = self.Active and self.Enabled and self.Preset ~= "Off"
end

function AnimationLayer:Step(delta)
    if not self.Frame.Visible then
        return
    end
    local width = self.Frame.AbsoluteSize.X
    local height = self.Frame.AbsoluteSize.Y
    if width <= 0 or height <= 0 then
        return
    end
    local desired = math.max(1, math.floor(self.MaxParticles * self.Density + 0.5))
    local step = math.min(delta, 1 / 20) * self.Speed
    for index, particle in ipairs(self.Particles) do
        if index > desired then
            if particle.Active then
                self:_hideParticle(particle)
            end
        else
            if not particle.Active then
                self:_spawnParticle(particle, width, height, true)
            end
            if particle.Active then
                particle.Phase += step
                local sway = math.sin(particle.Phase * 1.8) * particle.Drift
                if self.Preset == "Snow"
                    or self.Preset == "Fireflies"
                    or self.Preset == "Bubbles"
                    or self.Preset == "Petals"
                    or self.Preset == "Embers" then
                    particle.X += (particle.VX + sway * 0.16) * step
                else
                    particle.X += particle.VX * step
                end
                particle.Y += particle.VY * step
                if self.Preset == "Stars" or self.Preset == "Fireflies" then
                    particle.Frame.BackgroundTransparency = math.clamp(0.48 + math.sin(particle.Phase * 2.3) * 0.24, 0.12, 0.78)
                end
                local margin = 100
                if particle.X < -margin or particle.X > width + margin or particle.Y < -margin or particle.Y > height + margin then
                    self:_spawnParticle(particle, width, height, false)
                else
                    particle.Frame.Position = UDim2.fromOffset(particle.X, particle.Y)
                end
            end
        end
    end
end

local function isPointerButton(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerMovement(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
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
    if config.FontPreset then
        self:SetTypography(config.FontPreset)
    end
    if config.Typography then
        self:SetTypography(config.Typography)
    end
    if type(config.Motion) == "table" then
        self:SetMotion(config.Motion.Enabled, config.Motion.Speed)
    elseif config.Motion ~= nil then
        self:SetMotion(config.Motion)
    end
    if config.BrandGradient ~= nil then
        self:SetBrandGradient(config.BrandGradient)
    end
    local palette = self:_theme()
    local screenParent = resolveParent(config)
    local screenName = config.Name or "NorthwindUI"

    for index = #self.Windows, 1, -1 do
        local existing = self.Windows[index]
        if existing.ScreenGui
            and existing.ScreenGui.Parent == screenParent
            and existing.ScreenGui.Name == screenName then
            existing:Destroy()
            break
        end
    end
    local previousScreen = screenParent:FindFirstChild(screenName)
    if previousScreen then
        previousScreen:Destroy()
    end
    local screen = create("ScreenGui", {
        Name = screenName,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 50,
        Parent = screenParent,
    })
    local screenAnimation = createAnimationLayer(screen, config.ScreenAnimation or {
        Enabled = false,
        Preset = "Off",
    }, 56)

    local cornerRadius = config.CornerRadius or 18
    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.fromScale(0.57, 0.5),
        Size = config.Size or UDim2.fromOffset(960, 580),
        BackgroundColor3 = palette.Background,
        BackgroundTransparency = config.Transparency == nil and 0.06 or config.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screen,
    })
    self:_bind(main, "BackgroundColor3", "Background")
    round(main, cornerRadius)
    local mainStroke = stroke(main, palette.Border, 0.38, 1.15)
    self:_bind(mainStroke, "Color", "Border")

    local scale = create("UIScale", { Scale = 0.96, Parent = main })
    tween(scale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
    local backgroundAnimation = createAnimationLayer(main, config.BackgroundAnimation or {
        Enabled = false,
        Preset = "Off",
    }, 34)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 230, 1, 0),
        BackgroundColor3 = palette.Sidebar,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = main,
    })
    self:_bind(sidebar, "BackgroundColor3", "Sidebar")
    round(sidebar, cornerRadius)

    local sidebarFill = create("Frame", {
        Name = "InnerCornerFill",
        Position = UDim2.fromOffset(cornerRadius, 0),
        Size = UDim2.new(1, -cornerRadius, 1, 0),
        BackgroundColor3 = palette.Sidebar,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:_bind(sidebarFill, "BackgroundColor3", "Sidebar")

    local sidebarLine = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:_bind(sidebarLine, "BackgroundColor3", "Border")

    local hasCustomLogo = type(config.Logo) == "string" and config.Logo ~= ""
    local logoStyle = config.LogoStyle or (hasCustomLogo and "Image" or "Monogram")
    hasCustomLogo = hasCustomLogo and logoStyle == "Image"
    local logoSize = math.clamp(tonumber(config.LogoSize) or 36, 24, 44)
    local logoInset = math.clamp(tonumber(config.LogoInset) or 0, 0, 10)
    local brandMark = create("Frame", {
        Name = "BrandMark",
        Position = UDim2.fromOffset(17, math.floor((64 - logoSize) * 0.5)),
        Size = UDim2.fromOffset(logoSize, logoSize),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    local brandLetter = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = config.LogoText or "NW",
        TextColor3 = palette.Text,
        TextSize = config.LogoTextSize or 16,
        FontRole = "Bold",
        NoGradient = true,
        Parent = brandMark,
    })
    self:_bind(brandLetter, "TextColor3", "Text")
    if hasCustomLogo then
        brandLetter.Visible = false
        local brandImage = create("ImageLabel", {
            Position = UDim2.fromOffset(logoInset, logoInset),
            Size = UDim2.new(1, -logoInset * 2, 1, -logoInset * 2),
            BackgroundTransparency = 1,
            Image = config.Logo,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            Parent = brandMark,
        })
        tween(brandImage, 0.3, { ImageTransparency = config.LogoTransparency or 0 })
    end

    local brandOffset = 17 + logoSize + 10
    local brand = create("TextLabel", {
        Position = UDim2.fromOffset(brandOffset, 11),
        Size = UDim2.new(1, -brandOffset - 12, 0, 42),
        BackgroundTransparency = 1,
        Text = config.Title or "Northwind",
        TextColor3 = palette.Text,
        TextSize = config.TitleSize or 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontRole = "Bold",
        NoGradient = true,
        Parent = sidebar,
    })
    self:_bind(brand, "TextColor3", "Text")

    local searchShell = create("Frame", {
        Position = UDim2.fromOffset(14, 72),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:_bind(searchShell, "BackgroundColor3", "SurfaceAlt")
    round(searchShell, 8)
    local searchStroke = stroke(searchShell, palette.Border, 0.72)
    self:_bind(searchStroke, "Color", "Border")
    makeIcon(searchShell, "search", UDim2.fromOffset(11, 10), UDim2.fromOffset(14, 14), "Muted")

    local search = create("TextBox", {
        Position = UDim2.fromOffset(31, 0),
        Size = UDim2.new(1, -37, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        PlaceholderText = "Search the interface...",
        PlaceholderColor3 = palette.Muted,
        Text = "",
        TextColor3 = palette.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchShell,
    })
    self:_bind(search, "TextColor3", "Text")
    self:_bind(search, "PlaceholderColor3", "Muted")

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

    local primarySubtab = create("TextButton", {
        Position = UDim2.fromOffset(24, 62),
        Size = UDim2.fromOffset(58, 22),
        BackgroundTransparency = 1,
        Text = "Settings",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = content,
    })
    self:_bind(primarySubtab, "TextColor3", "Text")
    local secondarySubtab = create("TextButton", {
        Position = UDim2.fromOffset(100, 62),
        Size = UDim2.fromOffset(42, 22),
        BackgroundTransparency = 1,
        Text = "Type",
        TextColor3 = palette.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Visible = false,
        Parent = content,
    })
    self:_bind(secondarySubtab, "TextColor3", "Muted")

    local activeSubtab = create("Frame", {
        Position = UDim2.fromOffset(24, 88),
        Size = UDim2.fromOffset(56, 2),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = content,
    })
    self:_bind(activeSubtab, "BackgroundColor3", "Accent")
    round(activeSubtab, 1)

    local titleLine = create("Frame", {
        Position = UDim2.fromOffset(24, 89),
        Size = UDim2.new(1, -48, 0, 1),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = content,
    })
    self:_bind(titleLine, "BackgroundColor3", "Border")

    local pages = create("Frame", {
        Position = UDim2.fromOffset(18, 101),
        Size = UDim2.new(1, -36, 1, -115),
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
        SubtabLabel = primarySubtab,
        TypeSubtabButton = secondarySubtab,
        HeaderUnderline = activeSubtab,
        BackgroundAnimation = backgroundAnimation,
        ScreenAnimation = screenAnimation,
        Tabs = {},
        Panels = {},
        Logo = config.Logo,
        LogoStyle = logoStyle,
        LogoText = config.LogoText or "NW",
        LogoSize = logoSize,
        BrandLabel = brand,
        LogoLabel = brandLetter,
        PanelsFollowMenuVisibility = config.PanelsFollowMenuVisibility ~= false,
        Visible = true,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        _activeTab = nil,
        _connections = {},
        _keybindHandlers = {},
        _activePointer = nil,
        _destroyed = false,
    }, Window)

    table.insert(self.Windows, window)
    self:_attachBrandGradient(brand, "Brand")
    if not hasCustomLogo then
        self:_attachBrandGradient(brandLetter, "Logo")
    end
    window:_initInputController()
    window:_bindDrag(brand, main)
    window:_connect(RunService.RenderStepped, function(delta)
        backgroundAnimation:Step(delta)
        screenAnimation:Step(delta)
    end)

    window:_connect(search:GetPropertyChangedSignal("Text"), function()
        local query = string.lower(search.Text)
        for _, tab in ipairs(window.Tabs) do
            tab.Button.Visible = query == "" or string.find(string.lower(tab.Name), query, 1, true) ~= nil
        end
    end)

    window:_connect(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == window.ToggleKey then
            window:Toggle()
        end
        for _, handler in ipairs(window._keybindHandlers) do
            handler(input, processed)
        end
    end)

    window:_connect(primarySubtab.MouseButton1Click, function()
        window:SetHeaderSubtab("Settings")
    end)
    window:_connect(secondarySubtab.MouseButton1Click, function()
        window:SetHeaderSubtab("Type")
    end)

    if config.Settings ~= false then
        window:_createSettingsTab()
    end

    if config.ESPPreview then
        local previewConfig = type(config.ESPPreview) == "table" and config.ESPPreview or {}
        window:CreateESPPreview(previewConfig)
    end

    if config.AutoShow == false then
        window:SetVisible(false, true)
    end

    return window
end

function Window:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function Window:_initInputController()
    if self._pointerControllerReady then
        return
    end
    self._pointerControllerReady = true

    self:_connect(UserInputService.InputChanged, function(input)
        local active = self._activePointer
        if not active or not isPointerMovement(input) then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch and active.Input ~= input then
            return
        end
        if active.Target and not active.Target.Parent then
            self._activePointer = nil
            return
        end

        if active.Kind == "Drag" then
            local delta = input.Position - active.Start
            active.Target.Position = UDim2.new(
                active.Position.X.Scale,
                active.Position.X.Offset + delta.X,
                active.Position.Y.Scale,
                active.Position.Y.Offset + delta.Y
            )
        elseif active.Kind == "Slider" then
            active.Update(input)
        end
    end)

    self:_connect(UserInputService.InputEnded, function(input)
        local active = self._activePointer
        if not active or not isPointerButton(input) then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Touch or active.Input == input then
            self._activePointer = nil
        end
    end)
end

function Window:_bindDrag(handle, target)
    return self:_connect(handle.InputBegan, function(input)
        if isPointerButton(input) then
            self._activePointer = {
                Kind = "Drag",
                Input = input,
                Target = target,
                Start = input.Position,
                Position = target.Position,
            }
        end
    end)
end

function Window:_bindSlider(track, update)
    return self:_connect(track.InputBegan, function(input)
        if isPointerButton(input) then
            self._activePointer = {
                Kind = "Slider",
                Input = input,
                Target = track,
                Update = update,
            }
            update(input)
        end
    end)
end

function Window:_registerKeybind(handler)
    table.insert(self._keybindHandlers, handler)
end

function Window:SetVisible(visible, instant)
    self.Visible = visible == true
    instant = instant or not self.Library.Motion.Enabled
    local closeDuration = 0.16 / math.max(self.Library.Motion.Speed, 0.1)
    if visible then
        self.Main.Visible = true
        self.ScreenAnimation:SetActive(true)
        for _, panel in ipairs(self.Panels) do
            if panel.FollowMenuVisibility and panel.Enabled ~= false then
                panel.Frame.Visible = true
            end
        end
        if instant then
            self.Scale.Scale = 1
            for _, panel in ipairs(self.Panels) do
                if panel.FollowMenuVisibility and panel.Scale then
                    panel.Scale.Scale = 1
                end
            end
        else
            self.Scale.Scale = 0.96
            tween(self.Scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
            for _, panel in ipairs(self.Panels) do
                if panel.FollowMenuVisibility and panel.Scale then
                    panel.Scale.Scale = 0.96
                    tween(panel.Scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
                end
            end
        end
    else
        if instant then
            self.Main.Visible = false
            self.ScreenAnimation:SetActive(false)
            for _, panel in ipairs(self.Panels) do
                if panel.FollowMenuVisibility then
                    panel.Frame.Visible = false
                end
            end
        else
            tween(self.Scale, 0.16, { Scale = 0.96 })
            for _, panel in ipairs(self.Panels) do
                if panel.FollowMenuVisibility and panel.Scale then
                    tween(panel.Scale, 0.16, { Scale = 0.96 })
                end
            end
            task.delay(closeDuration, function()
                if not self.Visible and self.Main then
                    self.Main.Visible = false
                    self.ScreenAnimation:SetActive(false)
                    for _, panel in ipairs(self.Panels) do
                        if panel.FollowMenuVisibility then
                            panel.Frame.Visible = false
                        end
                    end
                end
            end)
        end
    end
end

function Window:SetPanelsFollowMenuVisibility(follow)
    self.PanelsFollowMenuVisibility = follow == true
    for _, panel in ipairs(self.Panels) do
        panel:SetFollowMenuVisibility(self.PanelsFollowMenuVisibility)
    end
end

function Window:SetBrandGradient(settings)
    self.Library:SetBrandGradient(settings)
    return self
end

function Window:SetTypography(preset)
    self.Library:SetTypography(preset)
    return self
end

function Window:SetMotion(enabled, speed)
    self.Library:SetMotion(enabled, speed)
    return self
end

function Window:SetBackgroundAnimation(settings)
    self.BackgroundAnimation:Set(settings)
    self.BackgroundAnimation:SetActive(self.Visible)
    return self
end

function Window:SetScreenAnimation(settings)
    self.ScreenAnimation:Set(settings)
    self.ScreenAnimation:SetActive(self.Visible)
    return self
end

function Window:SetHeaderSubtab(name)
    if not self.SettingsTab or self._activeTab ~= self.SettingsTab then
        return
    end
    local showType = name == "Type" and self.SettingsTab.TypePage ~= nil
    self.SettingsTab.Page.Visible = not showType
    self.SettingsTab.TypePage.Page.Visible = showType
    tween(self.SubtabLabel, 0.16, {
        TextColor3 = showType and self.Library:_theme().Muted or self.Library:_theme().Text,
    })
    tween(self.TypeSubtabButton, 0.16, {
        TextColor3 = showType and self.Library:_theme().Text or self.Library:_theme().Muted,
    })
    tween(self.HeaderUnderline, 0.18, {
        Position = showType and UDim2.fromOffset(100, 88) or UDim2.fromOffset(24, 88),
        Size = showType and UDim2.fromOffset(30, 2) or UDim2.fromOffset(56, 2),
    })
    self._headerSubtab = showType and "Type" or "Settings"
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
end

function Window:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self._activePointer = nil
    table.clear(self._keybindHandlers)

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    if self.ESPPreview then
        self.ESPPreview:Destroy()
    end

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

    local windowIndex = table.find(self.Library.Windows, self)
    if windowIndex then
        table.remove(self.Library.Windows, windowIndex)
    end

    for index = #self.Library._themeBindings, 1, -1 do
        local binding = self.Library._themeBindings[index]
        if not binding.Instance or not binding.Instance.Parent then
            table.remove(self.Library._themeBindings, index)
        end
    end
    for index = #self.Library._fontBindings, 1, -1 do
        local binding = self.Library._fontBindings[index]
        if not binding.Instance or not binding.Instance.Parent then
            table.remove(self.Library._fontBindings, index)
        end
    end
    for index = #self.Library._textGradientTargets, 1, -1 do
        local target = self.Library._textGradientTargets[index]
        if not target or not target.Parent then
            table.remove(self.Library._textGradientTargets, index)
        end
    end
    for index = #self.Library._textGradients, 1, -1 do
        local gradient = self.Library._textGradients[index]
        if not gradient or not gradient.Parent then
            table.remove(self.Library._textGradients, index)
        end
    end
    for index = #self.Library._brandGradients, 1, -1 do
        local binding = self.Library._brandGradients[index]
        if not binding.Gradient or not binding.Gradient.Parent then
            table.remove(self.Library._brandGradients, index)
        end
    end
    if #self.Library.Windows == 0 and self.Library._brandGradientConnection then
        self.Library._brandGradientConnection:Disconnect()
        self.Library._brandGradientConnection = nil
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
    self.SubtabLabel.Text = tab.Name
    self.TypeSubtabButton.Visible = tab.IsSettings == true
    if self.SettingsTab and self.SettingsTab.TypePage then
        self.SettingsTab.TypePage.Page.Visible = false
    end
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
        setIconColor(item.Icon, active and self.Library:_theme().Text or self.Library:_theme().Muted, 0.16)
        item.Accent.Visible = active
    end
    if tab.IsSettings and self.SettingsTab then
        self:SetHeaderSubtab("Settings")
    else
        tween(self.HeaderUnderline, 0.18, {
            Position = UDim2.fromOffset(24, 88),
            Size = UDim2.new(0, math.max(30, math.min(72, #tab.Name * 7)), 0, 2),
        })
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
    local buttonStroke = stroke(button, palette.Border, 1)
    self.Library:_bind(buttonStroke, "Color", "Border")

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

    local icon = makeIcon(button, config.Icon or name, UDim2.fromOffset(13, 10), UDim2.fromOffset(18, 18), "Muted")

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
        Icon = icon,
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
            tween(button, 0.18, { BackgroundTransparency = 0.74 })
            tween(buttonStroke, 0.18, { Transparency = 0.72 })
            setIconColor(icon, self.Library:_theme().Text, 0.18)
        end
    end)
    button.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            tween(button, 0.15, { BackgroundTransparency = 1 })
            tween(buttonStroke, 0.18, { Transparency = 1 })
            setIconColor(icon, self.Library:_theme().Muted, 0.18)
        end
    end)

    if not self._activeTab or (self._activeTab.IsSettings and not tab.IsSettings) then
        self:SelectTab(tab)
    end
    return tab
end

Window.CreateTab = Window.AddTab
Window.Tab = Window.AddTab

function Tab:AddSubPage(name)
    local palette = self.Library:_theme()
    local page = create("ScrollingFrame", {
        Name = tostring(name or "SubPage") .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = palette.Accent,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = self.Window.Pages,
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
    local subPage = setmetatable({
        Window = self.Window,
        Library = self.Library,
        Name = tostring(name or "SubPage"),
        Page = page,
        Columns = columns,
        Left = left,
        Right = right,
        LeftLayout = leftLayout,
        RightLayout = rightLayout,
        Sections = {},
        _nextSide = "Left",
    }, Tab)
    local function resizeCanvas()
        local height = math.max(leftLayout.AbsoluteContentSize.Y, rightLayout.AbsoluteContentSize.Y)
        columns.Size = UDim2.new(1, -6, 0, height)
        page.CanvasSize = UDim2.fromOffset(0, height + 8)
    end
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)
    rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)
    return subPage
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
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        Parent = parent,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, 11)
    local frameStroke = stroke(frame, palette.Border, 0.52)
    self.Library:_bind(frameStroke, "Color", "Border")
    addSurfaceMotion(frame, frameStroke, 0.10, 0.055)
    local sectionScale = create("UIScale", { Scale = 0.985, Parent = frame })
    tween(sectionScale, 0.26, { Scale = 1 }, Enum.EasingStyle.Quint)
    padding(frame, 14, 14, 12, 14)

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    makeIcon(header, config.Icon or config.Name, UDim2.fromOffset(3, 4), UDim2.fromOffset(20, 20), "Text")
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
        BackgroundTransparency = transparent and 1 or 0.12,
        BorderSizePixel = 0,
        Parent = self.Controls,
    })
    if not transparent then
        self.Library:_bind(row, "BackgroundColor3", "SurfaceAlt")
        round(row, 7)
        local rowStroke = stroke(row, palette.Border, 0.78)
        self.Library:_bind(rowStroke, "Color", "Border")
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
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = palette.SurfaceAlt,
        BorderSizePixel = 0,
        Text = config.Text or config.Name or "Button",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = self.Controls,
    })
    round(button, 6)
    local buttonStroke = stroke(button, palette.Border, 0.68)
    self.Library:_bind(buttonStroke, "Color", "Border")
    self.Library:_bind(button, "TextColor3", "Text")
    addHover(button, "SurfaceAlt", "AccentSoft")
    button.MouseButton1Click:Connect(function()
        tween(button, 0.08, { Size = UDim2.new(1, -4, 0, 28), Position = UDim2.fromOffset(2, 1) })
        task.delay(0.08, function()
            tween(button, 0.14, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new() })
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
    local row = self:_row(34, true)
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
        Size = UDim2.fromOffset(40, 20),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(track, "BackgroundColor3", "SurfaceAlt")
    round(track, 10)
    local trackStroke = stroke(track, palette.Border, 0.72)
    self.Library:_bind(trackStroke, "Color", "Border")
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(3, 10),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = palette.Text,
        BorderSizePixel = 0,
        Parent = track,
    })
    self.Library:_bind(knob, "BackgroundColor3", "Text")
    round(knob, 7)
    local knobStroke = stroke(knob, palette.Border, 0.72)
    self.Library:_bind(knobStroke, "Color", "Border")

    local option = newOption(flag, config.Default == true, config.Callback)
    function option:SetValue(value, silent)
        self.Value = value == true
        tween(track, 0.18, {
            BackgroundColor3 = self.Value and Northwind:_theme().Accent or Northwind:_theme().SurfaceAlt,
        })
        tween(knob, 0.18, {
            Position = self.Value and UDim2.fromOffset(23, 10) or UDim2.fromOffset(3, 10),
        })
        tween(knob, 0.18, {
            BackgroundColor3 = self.Value and Northwind:_theme().Text or Northwind:_theme().Muted,
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
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(track, "BackgroundColor3", "SurfaceAlt")
    round(track, 3)
    local sliderStroke = stroke(track, palette.Border, 0.82)
    self.Library:_bind(sliderStroke, "Color", "Border")
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

    local function update(input)
        local width = track.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
        option:SetValue(minimum + (maximum - minimum) * percent)
    end
    self.Window:_bindSlider(track, update)
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
    local row = self:_row(36, true)
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
        Size = UDim2.new(0.58, 0, 0, 30),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.08,
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
    round(box, 6)
    local boxStroke = stroke(box, palette.Border, 0.72)
    self.Library:_bind(boxStroke, "Color", "Border")
    padding(box, 9, 9, 0, 0)

    local option = newOption(flag, tostring(config.Default or ""), config.Callback)
    function option:SetValue(value, silent)
        self.Value = tostring(value or "")
        box.Text = self.Value
        self:_emit(silent)
    end
    box.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, 0.16, { Transparency = 0.72, Color = Northwind:_theme().Border })
        option:SetValue(box.Text)
        if enterPressed then
            safeCallback(config.Finished, box.Text)
        end
    end)
    box.Focused:Connect(function()
        tween(boxStroke, 0.16, { Transparency = 0.18, Color = Northwind:_theme().Accent })
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
    local row = self:_row(36, true)
    local label = create("TextLabel", {
        Size = UDim2.new(0.42, -6, 0, 36),
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
        Size = UDim2.new(0.58, 0, 0, 30),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    self.Library:_bind(button, "BackgroundColor3", "SurfaceAlt")
    round(button, 6)
    local dropdownStroke = stroke(button, palette.Border, 0.72)
    self.Library:_bind(dropdownStroke, "Color", "Border")
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
    local arrowHolder = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        Parent = button,
    })
    makeIcon(arrowHolder, "chevron-down", UDim2.fromOffset(8, 8), UDim2.fromOffset(14, 14), "Muted")
    local list = create("Frame", {
        Position = UDim2.new(0.42, 0, 0, 37),
        Size = UDim2.new(0.58, 0, 0, 0),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = row,
    })
    self.Library:_bind(list, "BackgroundColor3", "SurfaceAlt")
    round(list, 6)
    local listStroke = stroke(list, palette.Border, 0.58)
    self.Library:_bind(listStroke, "Color", "Border")
    local listLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = list,
    })

    local option = newOption(flag, config.Default or values[1], config.Callback)
    local open = false
    local function setOpen(value)
        open = value
        list.Visible = true
        local targetHeight = value and math.min(#values * 26, 130) or 0
        tween(list, 0.18, { Size = UDim2.new(0.58, 0, 0, targetHeight) })
        tween(row, 0.18, { Size = UDim2.new(1, 0, 0, value and (43 + targetHeight) or 36) })
        tween(arrowHolder, 0.18, { Rotation = value and 180 or 0 })
        tween(dropdownStroke, 0.18, {
            Transparency = value and 0.18 or 0.72,
            Color = value and Northwind:_theme().Accent or Northwind:_theme().Border,
        })
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
                Size = UDim2.new(1, 0, 0, 26),
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
    local row = self:_row(36, true)
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
        Size = UDim2.fromOffset(108, 28),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.08,
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
    round(button, 6)
    local keyStroke = stroke(button, palette.Border, 0.72)
    self.Library:_bind(keyStroke, "Color", "Border")

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
        tween(keyStroke, 0.15, { Transparency = 0.18, Color = Northwind:_theme().Accent })
    end)
    self.Window:_registerKeybind(function(input, processed)
        if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
            listening = false
            option:SetValue(input.KeyCode)
            tween(button, 0.15, { BackgroundColor3 = Northwind:_theme().SurfaceAlt })
            tween(keyStroke, 0.15, { Transparency = 0.72, Color = Northwind:_theme().Border })
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
    flag = flag or config.Flag or config.Text or "Color"
    local colors = config.Colors or {
        Color3.fromRGB(124, 138, 255),
        Color3.fromRGB(180, 120, 255),
        Color3.fromRGB(255, 116, 181),
        Color3.fromRGB(90, 202, 255),
        Color3.fromRGB(96, 220, 159),
        Color3.fromRGB(255, 173, 91),
        Color3.fromRGB(255, 104, 121),
        Color3.fromRGB(238, 241, 250),
        Color3.fromRGB(151, 158, 187),
        Color3.fromRGB(48, 54, 82),
        Color3.fromRGB(24, 28, 46),
        Color3.fromRGB(10, 12, 23),
    }
    local defaultColor = config.Default
    if type(defaultColor) == "string" then
        defaultColor = hexToColor(defaultColor)
    end
    if typeof(defaultColor) ~= "Color3" then
        defaultColor = colors[1]
    end
    local palette = self.Library:_theme()
    local row = self:_row(36, true)
    local label = create("TextLabel", {
        Size = UDim2.new(0.42, -6, 0, 36),
        BackgroundTransparency = 1,
        Text = config.Text or config.Name or flag,
        TextColor3 = palette.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    self.Library:_bind(label, "TextColor3", "Text")

    local control = create("Frame", {
        Position = UDim2.new(0.42, 0, 0, 3),
        Size = UDim2.new(0.58, 0, 0, 30),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = row,
    })
    self.Library:_bind(control, "BackgroundColor3", "SurfaceAlt")
    round(control, 6)
    local controlStroke = stroke(control, palette.Border, 0.72)
    self.Library:_bind(controlStroke, "Color", "Border")

    local swatch = create("TextButton", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = defaultColor,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = control,
    })
    round(swatch, 5)
    stroke(swatch, Color3.fromRGB(255, 255, 255), 0.74)

    local hexBox = create("TextBox", {
        Position = UDim2.fromOffset(31, 0),
        Size = UDim2.new(1, -64, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = colorToHex(defaultColor),
        TextColor3 = palette.Muted,
        PlaceholderColor3 = palette.Muted,
        TextSize = 10,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = control,
    })
    self.Library:_bind(hexBox, "TextColor3", "Muted")
    self.Library:_bind(hexBox, "PlaceholderColor3", "Muted")

    local paletteButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(31, 30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = control,
    })
    makeIcon(paletteButton, "palette", UDim2.fromOffset(7, 6), UDim2.fromOffset(18, 18), "Muted")

    local popup = create("Frame", {
        Position = UDim2.new(0.42, 0, 0, 37),
        Size = UDim2.new(0.58, 0, 0, 0),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = row,
    })
    self.Library:_bind(popup, "BackgroundColor3", "SurfaceAlt")
    round(popup, 6)
    local popupStroke = stroke(popup, palette.Border, 0.56)
    self.Library:_bind(popupStroke, "Color", "Border")

    local option = newOption(flag, defaultColor, config.Callback)
    local open = false
    local function setOpen(value)
        open = value == true
        popup.Visible = true
        tween(popup, 0.18, { Size = UDim2.new(0.58, 0, 0, open and 78 or 0) })
        tween(row, 0.18, { Size = UDim2.new(1, 0, 0, open and 121 or 36) })
        tween(controlStroke, 0.18, {
            Transparency = open and 0.2 or 0.72,
            Color = open and Northwind:_theme().Accent or Northwind:_theme().Border,
        })
        if not open then
            task.delay(0.18, function()
                if not open then
                    popup.Visible = false
                end
            end)
        end
    end
    function option:SetValue(value, silent)
        if type(value) == "string" then
            value = hexToColor(value)
        end
        if typeof(value) ~= "Color3" then
            return
        end
        self.Value = value
        swatch.BackgroundColor3 = value
        hexBox.Text = colorToHex(value)
        self:_emit(silent)
    end
    for index, color in ipairs(colors) do
        local column = (index - 1) % 5
        local rowIndex = math.floor((index - 1) / 5)
        local choice = create("TextButton", {
            Position = UDim2.fromOffset(8 + column * 25, 7 + rowIndex * 24),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = popup,
        })
        round(choice, 5)
        stroke(choice, Color3.fromRGB(255, 255, 255), 0.78)
        choice.MouseButton1Click:Connect(function()
            option:SetValue(color)
            setOpen(false)
        end)
    end
    swatch.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)
    paletteButton.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)
    hexBox.FocusLost:Connect(function()
        local color = hexToColor(hexBox.Text)
        if color then
            option:SetValue(color)
        else
            hexBox.Text = colorToHex(option.Value)
        end
    end)
    option.ColorValues = colors
    option:SetValue(option.Value, true)
    return option
end

Section.Button = Section.AddButton
Section.Label = Section.AddLabel
Section.Divider = Section.AddDivider
Section.Switch = Section.AddToggle
Section.TextField = Section.AddInput
Section.Slider = Section.AddSlider
Section.Dropdown = Section.AddDropdown
Section.Keybind = Section.AddKeybind
Tab.Section = Tab.AddSection
Tab.CreateSection = Tab.AddSection

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
        Size = config.Size or UDim2.fromOffset(284, 36),
        BackgroundColor3 = palette.Surface,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, 9)
    local frameStroke = stroke(frame, palette.Border, 0.42)
    self.Library:_bind(frameStroke, "Color", "Border")
    addSurfaceMotion(frame, frameStroke, 0.16, 0.09, 0.42)
    local statusScale = create("UIScale", { Scale = 0.97, Parent = frame })
    tween(statusScale, 0.26, { Scale = 1 }, Enum.EasingStyle.Quint)

    if config.GradientFPS ~= nil then
        self.Library:SetBrandGradient({ ApplyToFPS = config.GradientFPS })
    end
    local logoImage = config.Logo or self.Logo
    local hasCustomLogo = type(logoImage) == "string" and logoImage ~= ""
    local logoStyle = config.LogoStyle or self.LogoStyle or (hasCustomLogo and "Image" or "Monogram")
    hasCustomLogo = hasCustomLogo and logoStyle == "Image"
    local logoSize = math.clamp(tonumber(config.LogoSize) or 26, 20, 30)
    local logoInset = math.clamp(tonumber(config.LogoInset) or 0, 0, 6)
    local logo = create("Frame", {
        Name = "BrandMark",
        Position = UDim2.fromOffset(8, math.floor((36 - logoSize) * 0.5)),
        Size = UDim2.fromOffset(logoSize, logoSize),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = frame,
    })
    local logoLetter = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = config.LogoText or self.LogoText or "NW",
        TextColor3 = palette.Text,
        TextSize = config.LogoTextSize or 12,
        FontRole = "Bold",
        NoGradient = true,
        Parent = logo,
    })
    self.Library:_bind(logoLetter, "TextColor3", "Text")
    if hasCustomLogo then
        logoLetter.Visible = false
        local logoImageLabel = create("ImageLabel", {
            Position = UDim2.fromOffset(logoInset, logoInset),
            Size = UDim2.new(1, -logoInset * 2, 1, -logoInset * 2),
            BackgroundTransparency = 1,
            Image = logoImage,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            Parent = logo,
        })
        tween(logoImageLabel, 0.28, { ImageTransparency = config.LogoTransparency or 0 })
    end
    local brandOffset = 8 + logoSize + 7
    local brand = create("TextLabel", {
        Position = UDim2.fromOffset(brandOffset, 0),
        Size = UDim2.fromOffset(128 - brandOffset, 36),
        BackgroundTransparency = 1,
        Text = config.Title or "Northwind",
        TextColor3 = palette.Text,
        TextSize = config.TitleSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontRole = "Bold",
        NoGradient = true,
        Parent = frame,
    })
    self.Library:_bind(brand, "TextColor3", "Text")
    self.Library:_attachBrandGradient(brand, "Brand")
    if not hasCustomLogo then
        self.Library:_attachBrandGradient(logoLetter, "Logo")
    end
    local fps = create("TextLabel", {
        Position = UDim2.fromOffset(130, 0),
        Size = UDim2.fromOffset(65, 36),
        BackgroundTransparency = 1,
        Text = "FPS --",
        TextColor3 = palette.Text,
        TextSize = 11,
        FontRole = "Medium",
        NoGradient = true,
        Parent = frame,
    })
    self.Library:_bind(fps, "TextColor3", "Text")
    self.Library:_attachBrandGradient(fps, "FPS")
    local separatorA = create("Frame", {
        Position = UDim2.fromOffset(128, 10),
        Size = UDim2.fromOffset(1, 16),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = frame,
    })
    self.Library:_bind(separatorA, "BackgroundColor3", "Border")
    local clock = create("TextLabel", {
        Position = UDim2.fromOffset(201, 0),
        Size = UDim2.new(1, -211, 1, 0),
        BackgroundTransparency = 1,
        Text = "00:00:00",
        TextColor3 = palette.Text,
        TextSize = 11,
        FontRole = "Regular",
        NoGradient = true,
        Parent = frame,
    })
    self.Library:_bind(clock, "TextColor3", "Text")
    local separatorB = create("Frame", {
        Position = UDim2.fromOffset(197, 10),
        Size = UDim2.fromOffset(1, 16),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = frame,
    })
    self.Library:_bind(separatorB, "BackgroundColor3", "Border")
    self:_bindDrag(frame, frame)

    local frames = 0
    local elapsed = 0
    clock.Text = os.date("%H:%M:%S")
    self:_connect(RunService.RenderStepped, function(delta)
        if not frame.Visible then
            frames = 0
            elapsed = 0
            return
        end
        frames += 1
        elapsed += delta
        if elapsed >= 0.5 then
            fps.Text = "FPS " .. tostring(math.floor(frames / elapsed + 0.5))
            clock.Text = os.date("%H:%M:%S")
            frames = 0
            elapsed = 0
        end
    end)
    local followVisibility = config.FollowMenuVisibility
    if followVisibility == nil then
        followVisibility = self.PanelsFollowMenuVisibility
    end
    local panel = setmetatable({
        Frame = frame,
        Scale = statusScale,
        Window = self,
        Rows = {},
        FollowMenuVisibility = followVisibility,
        Enabled = true,
    }, Panel)
    frame.Visible = (not followVisibility) or self.Visible
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
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, 9)
    local frameStroke = stroke(frame, palette.Border, 0.42)
    self.Library:_bind(frameStroke, "Color", "Border")
    addSurfaceMotion(frame, frameStroke, 0.16, 0.09, 0.42)
    local panelScale = create("UIScale", { Scale = 0.98, Parent = frame })
    tween(panelScale, 0.24, { Scale = 1 }, Enum.EasingStyle.Quint)
    padding(frame, 10, 10, 9, 10)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
    })
    local titleRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        Parent = frame,
    })
    makeIcon(titleRow, config.Icon or config.Title, UDim2.fromOffset(1, 4), UDim2.fromOffset(16, 16), "Text")
    local title = create("TextLabel", {
        Position = UDim2.fromOffset(23, 0),
        Size = UDim2.new(1, -23, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "Panel",
        TextColor3 = palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleRow,
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
    self:_bindDrag(titleRow, frame)
    local panel = setmetatable({
        Frame = frame,
        Scale = panelScale,
        Window = self,
        Layout = layout,
        Rows = {},
        Enabled = true,
        FollowMenuVisibility = config.FollowMenuVisibility == nil
            and self.PanelsFollowMenuVisibility
            or config.FollowMenuVisibility == true,
        _nextOrder = 2,
    }, Panel)
    frame.Visible = (not panel.FollowMenuVisibility) or self.Visible
    table.insert(self.Panels, panel)
    return panel
end

function Panel:SetFollowMenuVisibility(follow)
    self.FollowMenuVisibility = follow == true
    if self.FollowMenuVisibility then
        self.Frame.Visible = self.Window.Visible and self.Enabled ~= false
    else
        self.Frame.Visible = self.Enabled ~= false
    end
    return self
end

function Panel:SetVisible(visible)
    self.Enabled = visible == true
    self.Frame.Visible = self.Enabled and ((not self.FollowMenuVisibility) or self.Window.Visible)
    return self
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

function ESPPreview:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function ESPPreview:SetFollowMenuVisibility(_follow)
    self.FollowMenuVisibility = true
    self.Frame.Visible = self.Enabled and self.Window.Visible
    return self
end

function ESPPreview:SetVisible(visible)
    self.Enabled = visible == true
    self.Frame.Visible = self.Enabled and ((not self.FollowMenuVisibility) or self.Window.Visible)
    return self
end

function ESPPreview:SetBoxEnabled(enabled)
    self.Box.Visible = enabled == true
    return self
end

function ESPPreview:SetNameEnabled(enabled)
    self.NameLabel.Visible = enabled == true
    return self
end

function ESPPreview:SetHealthEnabled(enabled)
    self.HealthTrack.Visible = enabled == true
    return self
end

function ESPPreview:SetDistanceEnabled(enabled)
    self.DistanceLabel.Visible = enabled == true
    return self
end

function ESPPreview:SetTracerEnabled(enabled)
    self.Tracer.Visible = enabled == true
    return self
end

function ESPPreview:SetRotationSpeed(speed)
    self.RotationSpeed = tonumber(speed) or 0
    return self
end

function ESPPreview:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return self
    end
    self.BoxStroke.Color = color
    self.HealthFill.BackgroundColor3 = color
    self.Tracer.BackgroundColor3 = color
    self.LiveDot.BackgroundColor3 = color
    return self
end

function ESPPreview:_updateHealth(humanoid)
    local health = humanoid and humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 1
    if math.abs(health - self._lastHealth) > 0.001 then
        self._lastHealth = health
        tween(self.HealthFill, 0.18, { Size = UDim2.fromScale(1, health) })
    end
end

function ESPPreview:RefreshCharacter(character)
    if self._destroyed then
        return self
    end
    if self.Model then
        self.Model:Destroy()
        self.Model = nil
    end
    if self._healthConnection then
        self._healthConnection:Disconnect()
        self._healthConnection = nil
    end
    if self._maxHealthConnection then
        self._maxHealthConnection:Disconnect()
        self._maxHealthConnection = nil
    end
    character = character or (LocalPlayer and LocalPlayer.Character)
    if not character then
        self.EmptyLabel.Visible = true
        return self
    end

    local wasArchivable = character.Archivable
    character.Archivable = true
    local ok, clone = pcall(function()
        return character:Clone()
    end)
    character.Archivable = wasArchivable
    if not ok or not clone then
        self.EmptyLabel.Visible = true
        return self
    end

    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") or descendant:IsA("Tool") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            descendant.CastShadow = false
        elseif descendant:IsA("Humanoid") then
            descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    end

    clone.Name = "PreviewCharacter"
    clone.Parent = self.WorldModel
    local boundsCFrame, boundsSize = clone:GetBoundingBox()
    local boundsOffset = clone:GetPivot():ToObjectSpace(boundsCFrame)
    self.ModelPivot = boundsOffset:Inverse()
    self.Angle = 0
    clone:PivotTo(self.ModelPivot)
    self.Camera.FieldOfView = 32
    local distance = math.max(boundsSize.Y * 1.38, boundsSize.X * 1.85, 5.5)
    local focus = Vector3.new(0, boundsSize.Y * 0.025, 0)
    self.Camera.CFrame = CFrame.lookAt(Vector3.new(0, focus.Y, -distance), focus)
    self.Model = clone
    self.EmptyLabel.Visible = false
    local sourceHumanoid = character:FindFirstChildOfClass("Humanoid")
    self:_updateHealth(sourceHumanoid)
    if sourceHumanoid then
        self._healthConnection = sourceHumanoid.HealthChanged:Connect(function()
            self:_updateHealth(sourceHumanoid)
        end)
        self._maxHealthConnection = sourceHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
            self:_updateHealth(sourceHumanoid)
        end)
    end
    if LocalPlayer then
        self.NameLabel.Text = LocalPlayer.DisplayName
        self.DistanceLabel.Text = LocalPlayer.Name .. "  •  YOU"
    end
    return self
end

function ESPPreview:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    if self._healthConnection then
        self._healthConnection:Disconnect()
    end
    if self._maxHealthConnection then
        self._maxHealthConnection:Disconnect()
    end
    for index = #self.Window.Panels, 1, -1 do
        if self.Window.Panels[index] == self then
            table.remove(self.Window.Panels, index)
            break
        end
    end
    if self.Window.ESPPreview == self then
        self.Window.ESPPreview = nil
    end
    self.Frame:Destroy()
end

function Window:CreateESPPreview(config)
    config = config or {}
    if self.ESPPreview then
        self.ESPPreview:Destroy()
    end

    local palette = self.Library:_theme()
    local width = math.clamp(tonumber(config.Width) or 232, 190, 360)
    local height = math.clamp(tonumber(config.Height) or 372, 260, 520)
    local gap = math.clamp(tonumber(config.Gap) or 12, 0, 40)
    local frame = create("Frame", {
        Name = "ESPPreview",
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = palette.Surface,
        BackgroundTransparency = config.Transparency == nil and 0.08 or config.Transparency,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    self.Library:_bind(frame, "BackgroundColor3", "Surface")
    round(frame, config.CornerRadius or 14)
    local frameStroke = stroke(frame, palette.Border, 0.28, 1.1)
    self.Library:_bind(frameStroke, "Color", "Border")
    addSurfaceMotion(frame, frameStroke, 0.08, 0.035, 0.28)
    local previewScale = create("UIScale", { Scale = 0.96, Parent = frame })
    tween(previewScale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    local liveDot = create("Frame", {
        Position = UDim2.fromOffset(14, 21),
        Size = UDim2.fromOffset(7, 7),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = header,
    })
    self.Library:_bind(liveDot, "BackgroundColor3", "Accent")
    round(liveDot, 4)
    local title = create("TextLabel", {
        Position = UDim2.fromOffset(29, 4),
        Size = UDim2.new(1, -78, 1, -8),
        BackgroundTransparency = 1,
        Text = config.Title or "ESP Preview",
        TextColor3 = palette.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontRole = "Bold",
        Parent = header,
    })
    self.Library:_bind(title, "TextColor3", "Text")
    local liveLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -13, 0.5, 0),
        Size = UDim2.fromOffset(42, 20),
        BackgroundColor3 = palette.AccentSoft,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Text = "LIVE",
        TextColor3 = palette.Text,
        TextSize = 9,
        FontRole = "Bold",
        Parent = header,
    })
    self.Library:_bind(liveLabel, "BackgroundColor3", "AccentSoft")
    self.Library:_bind(liveLabel, "TextColor3", "Text")
    round(liveLabel, 6)

    local divider = create("Frame", {
        Position = UDim2.fromOffset(12, 47),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = palette.Border,
        BorderSizePixel = 0,
        Parent = frame,
    })
    self.Library:_bind(divider, "BackgroundColor3", "Border")

    local viewport = create("ViewportFrame", {
        Position = UDim2.fromOffset(12, 59),
        Size = UDim2.new(1, -24, 1, -71),
        BackgroundColor3 = palette.Background,
        BackgroundTransparency = config.ViewportTransparency == nil and 0.18 or config.ViewportTransparency,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(170, 174, 205),
        LightColor = Color3.fromRGB(245, 247, 255),
        LightDirection = Vector3.new(-1, -0.6, -1),
        ClipsDescendants = true,
        Parent = frame,
    })
    self.Library:_bind(viewport, "BackgroundColor3", "Background")
    round(viewport, 10)
    local viewportStroke = stroke(viewport, palette.Border, 0.62)
    self.Library:_bind(viewportStroke, "Color", "Border")
    local viewportGradient = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(142, 151, 255)),
        }),
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.84),
            NumberSequenceKeypoint.new(1, 0.98),
        }),
        Parent = viewport,
    })

    local worldModel = create("WorldModel", { Parent = viewport })
    local camera = create("Camera", { Parent = viewport })
    viewport.CurrentCamera = camera

    local box = create("Frame", {
        Position = UDim2.fromScale(0.19, 0.1),
        Size = UDim2.fromScale(0.62, 0.76),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = viewport,
    })
    local boxStroke = stroke(box, palette.Accent, 0.08, 1.35)
    self.Library:_bind(boxStroke, "Color", "Accent")
    round(box, 3)

    local nameLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.095),
        Size = UDim2.new(0.86, 0, 0, 19),
        BackgroundTransparency = 1,
        Text = LocalPlayer and LocalPlayer.DisplayName or "Local Player",
        TextColor3 = palette.Text,
        TextSize = 11,
        FontRole = "Bold",
        Parent = viewport,
    })
    self.Library:_bind(nameLabel, "TextColor3", "Text")

    local healthTrack = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(0.165, 0.1),
        Size = UDim2.fromScale(0.018, 0.76),
        BackgroundColor3 = palette.SurfaceAlt,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = viewport,
    })
    self.Library:_bind(healthTrack, "BackgroundColor3", "SurfaceAlt")
    round(healthTrack, 4)
    local healthFill = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        Parent = healthTrack,
    })
    self.Library:_bind(healthFill, "BackgroundColor3", "Accent")
    round(healthFill, 4)

    local distanceLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromScale(0.5, 0.875),
        Size = UDim2.new(0.9, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = LocalPlayer and (LocalPlayer.Name .. "  •  YOU") or "YOU",
        TextColor3 = palette.Muted,
        TextSize = 9,
        FontRole = "Medium",
        Parent = viewport,
    })
    self.Library:_bind(distanceLabel, "TextColor3", "Muted")

    local tracer = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 1),
        Size = UDim2.new(0, 1, 0.12, 0),
        BackgroundColor3 = palette.Accent,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Parent = viewport,
    })
    self.Library:_bind(tracer, "BackgroundColor3", "Accent")

    local emptyLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -28, 0, 44),
        BackgroundTransparency = 1,
        Text = "Waiting for your character…",
        TextColor3 = palette.Muted,
        TextSize = 11,
        TextWrapped = true,
        Parent = viewport,
    })
    self.Library:_bind(emptyLabel, "TextColor3", "Muted")

    local followVisibility = true
    local preview = setmetatable({
        Window = self,
        Frame = frame,
        Scale = previewScale,
        Viewport = viewport,
        WorldModel = worldModel,
        Camera = camera,
        Box = box,
        BoxStroke = boxStroke,
        NameLabel = nameLabel,
        HealthTrack = healthTrack,
        HealthFill = healthFill,
        DistanceLabel = distanceLabel,
        Tracer = tracer,
        EmptyLabel = emptyLabel,
        LiveDot = liveDot,
        Gradient = viewportGradient,
        FollowMenuVisibility = followVisibility,
        Enabled = true,
        RotationSpeed = tonumber(config.RotationSpeed) or 12,
        Angle = 0,
        _connections = {},
        _destroyed = false,
        _lastHealth = -1,
    }, ESPPreview)
    self.ESPPreview = preview
    table.insert(self.Panels, preview)
    frame.Visible = (not followVisibility) or self.Visible
    box.Visible = config.ShowBox ~= false
    nameLabel.Visible = config.ShowName ~= false
    healthTrack.Visible = config.ShowHealth ~= false
    distanceLabel.Visible = config.ShowDistance ~= false
    tracer.Visible = config.ShowTracer ~= false

    local function syncAttachment()
        if preview._destroyed or not self.Main.Parent then
            return
        end
        local mainPosition = self.Main.AbsolutePosition
        local mainSize = self.Main.AbsoluteSize
        local x = mainPosition.X + mainSize.X + gap
        local y = mainPosition.Y + (mainSize.Y - height) * 0.5 + (tonumber(config.OffsetY) or 0)
        frame.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
    end
    preview:_connect(self.Main:GetPropertyChangedSignal("AbsolutePosition"), syncAttachment)
    preview:_connect(self.Main:GetPropertyChangedSignal("AbsoluteSize"), syncAttachment)
    task.defer(syncAttachment)

    if LocalPlayer then
        preview:_connect(LocalPlayer.CharacterAdded, function(character)
            task.delay(0.35, function()
                if not preview._destroyed then
                    preview:RefreshCharacter(character)
                end
            end)
        end)
        preview:_connect(LocalPlayer.CharacterAppearanceLoaded, function(character)
            preview:RefreshCharacter(character)
        end)
    end

    preview:_connect(RunService.RenderStepped, function(delta)
        if not frame.Visible then
            return
        end
        preview.Angle = (preview.Angle + math.rad(preview.RotationSpeed) * delta) % (math.pi * 2)
        if preview.Model and preview.Model.Parent and preview.ModelPivot then
            preview.Model:PivotTo(CFrame.Angles(0, preview.Angle, 0) * preview.ModelPivot)
        end
    end)

    preview:RefreshCharacter()
    if typeof(config.Accent) == "Color3" then
        preview:SetAccent(config.Accent)
    end
    return preview
end

function Window:_createSettingsTab()
    local settings = self:AddTab({
        Name = "Settings",
        Description = "Window, panels, theme, type, and configs",
        Icon = "settings",
        LayoutOrder = 999,
        IsSettings = true,
    })
    self.SettingsTab = settings
    local windowSection = settings:AddSection({
        Name = "Window",
        Description = "Show, hide, and unload",
        Icon = "window",
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

    local panelSection = settings:AddSection({
        Name = "Detached panels",
        Description = "Visibility when the menu closes",
        Icon = "activity",
        Side = "Right",
    })
    panelSection:AddToggle("Northwind_KeepPanelsVisible", {
        Text = "Keep panels visible",
        Default = not self.PanelsFollowMenuVisibility,
        Callback = function(value)
            self:SetPanelsFollowMenuVisibility(not value)
        end,
    })
    panelSection:AddLabel("When enabled, FPS and data panels remain on-screen while the main interface is hidden.")

    local themeSection = settings:AddSection({
        Name = "Theme",
        Description = "Every surface is live",
        Icon = "palette",
        Side = "Left",
    })
    local themePickers = {}
    local themeOption = themeSection:AddDropdown("Northwind_Theme", {
        Text = "Preset",
        Values = { "Midnight", "Obsidian", "Nord" },
        Default = self.Library.ActiveTheme,
        Callback = function(value)
            self.Library:SetTheme(value)
            local current = self.Library:_theme()
            for token, picker in pairs(themePickers) do
                picker:SetValue(current[token], true)
            end
        end,
    })
    themeOption.Save = false
    local function addThemePicker(flag, text, token)
        local picker = themeSection:AddColorPicker(flag, {
            Text = text,
            Default = self.Library:_theme()[token],
            Callback = function(value)
                self.Library:SetThemeColor(token, value)
            end,
        })
        picker.Save = false
        themePickers[token] = picker
    end
    addThemePicker("Northwind_Accent", "Accent", "Accent")
    addThemePicker("Northwind_Background", "Background", "Background")
    addThemePicker("Northwind_Sidebar", "Sidebar", "Sidebar")
    addThemePicker("Northwind_Cards", "Cards", "Surface")
    addThemePicker("Northwind_Inputs", "Inputs", "SurfaceAlt")
    addThemePicker("Northwind_Border", "Borders", "Border")
    addThemePicker("Northwind_Text", "Text", "Text")
    addThemePicker("Northwind_Muted", "Muted text", "Muted")

    local configSection = settings:AddSection({
        Name = "Configs",
        Description = "Current session or custom provider",
        Icon = "save",
        Side = "Right",
    })
    local configName = configSection:AddInput("Northwind_ConfigName", {
        Text = "Name",
        Default = "default",
        Placeholder = "config name",
    })
    configName.Save = false
    local configPicker
    local function refreshConfigList(preferred)
        local names = self.Library:ListConfigs()
        if #names == 0 then
            names = { "default" }
        end
        configPicker:SetValues(names)
        local selected = preferred or configPicker.Value
        if not table.find(names, selected) then
            selected = names[1]
        end
        configPicker:SetValue(selected, true)
        configName:SetValue(selected, true)
    end
    configPicker = configSection:AddDropdown("Northwind_SelectedConfig", {
        Text = "Saved configs",
        Values = { "default" },
        Default = "default",
        Callback = function(value)
            configName:SetValue(value, true)
        end,
    })
    configPicker.Save = false
    configSection:AddButton({
        Text = "Save config",
        Callback = function()
            local name = tostring(configName.Value or "default")
            self.Library:SaveConfig(name)
            refreshConfigList(name)
            self:Notify("Config saved", name .. " is ready to load")
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
            local name = tostring(configName.Value or "default")
            self.Library:DeleteConfig(name)
            refreshConfigList()
            self:Notify("Config deleted", name)
        end,
    })
    configSection:AddButton({
        Text = "Refresh config list",
        Callback = function()
            refreshConfigList()
        end,
    })
    configSection:AddLabel("Configs persist when a storage provider is attached. Without one, they last for the current session.")
    refreshConfigList("default")

    local function addAnimationSettings(name, description, icon, side, prefix, layer, apply)
        local section = settings:AddSection({
            Name = name,
            Description = description,
            Icon = icon,
            Side = side,
        })
        local enabledOption
        enabledOption = section:AddToggle(prefix .. "Enabled", {
            Text = "Enable animation",
            Default = layer.Enabled,
            Callback = function(value)
                apply({ Enabled = value })
            end,
        })
        local presetOption = section:AddDropdown(prefix .. "Preset", {
            Text = "Style",
            Values = ANIMATION_PRESETS,
            Default = layer.Preset,
            Callback = function(value)
                local enabled = value ~= "Off"
                enabledOption:SetValue(enabled, true)
                apply({ Preset = value, Enabled = enabled })
            end,
        })
        local colorOption = section:AddColorPicker(prefix .. "Color", {
            Text = "Particle color",
            Default = layer.Color,
            Callback = function(value)
                apply({ Color = value })
            end,
        })
        local speedOption = section:AddSlider(prefix .. "Speed", {
            Text = "Speed",
            Min = 15,
            Max = 300,
            Default = math.floor(layer.Speed * 100 + 0.5),
            Suffix = "%",
            Callback = function(value)
                apply({ Speed = value / 100 })
            end,
        })
        local densityOption = section:AddSlider(prefix .. "Density", {
            Text = "Density",
            Min = 10,
            Max = 100,
            Default = math.floor(layer.Density * 100 + 0.5),
            Suffix = "%",
            Callback = function(value)
                apply({ Density = value / 100 })
            end,
        })
        enabledOption.Save = false
        presetOption.Save = false
        colorOption.Save = false
        speedOption.Save = false
        densityOption.Save = false
        section:AddLabel("Uses a fixed particle pool and one shared frame update for smooth performance.")
    end

    addAnimationSettings(
        "Menu backdrop",
        "Stays behind every control",
        "layers",
        "Left",
        "Northwind_MenuAnimation",
        self.BackgroundAnimation,
        function(settings)
            self:SetBackgroundAnimation(settings)
        end
    )
    addAnimationSettings(
        "Screen effects",
        "Atmosphere behind the interface",
        "comet",
        "Right",
        "Northwind_ScreenAnimation",
        self.ScreenAnimation,
        function(settings)
            self:SetScreenAnimation(settings)
        end
    )

    local typePage = settings:AddSubPage("Type")
    settings.TypePage = typePage
    local gradientSection = typePage:AddSection({
        Name = "Text gradient",
        Description = "Live typography colors",
        Icon = "palette",
        Side = "Left",
    })
    gradientSection:AddToggle("Northwind_TextGradientEnabled", {
        Text = "Enable gradient text",
        Default = self.Library.TextGradient.Enabled,
        Callback = function(value)
            self.Library:SetTextGradient(nil, nil, nil, value)
        end,
    })
    local startInput = gradientSection:AddColorPicker("Northwind_TextGradientStart", {
        Text = "Start color",
        Default = self.Library.TextGradient.Start,
        Callback = function(value)
            self.Library:SetTextGradient(value)
        end,
    })
    local finishInput = gradientSection:AddColorPicker("Northwind_TextGradientFinish", {
        Text = "End color",
        Default = self.Library.TextGradient.Finish,
        Callback = function(value)
            self.Library:SetTextGradient(nil, value)
        end,
    })
    local directionOption = gradientSection:AddDropdown("Northwind_TextGradientDirection", {
        Text = "Direction",
        Values = { "Horizontal", "Diagonal", "Vertical" },
        Default = "Diagonal",
        Callback = function(value)
            local rotations = { Horizontal = 0, Diagonal = 18, Vertical = 90 }
            self.Library:SetTextGradient(nil, nil, rotations[value] or 18)
        end,
    })
    startInput.Save = false
    finishInput.Save = false
    directionOption.Save = false

    local brandSection = typePage:AddSection({
        Name = "Brand gradient",
        Description = "Menu, logo, and status-bar shimmer",
        Icon = "sparkles",
        Side = "Right",
    })
    local brandEnabled = brandSection:AddToggle("Northwind_BrandGradientEnabled", {
        Text = "Enable brand gradient",
        Default = self.Library.BrandGradient.Enabled,
        Callback = function(value)
            self.Library:SetBrandGradient({ Enabled = value })
        end,
    })
    local brandAnimated = brandSection:AddToggle("Northwind_BrandGradientAnimated", {
        Text = "Animate gradient",
        Default = self.Library.BrandGradient.Animated,
        Callback = function(value)
            self.Library:SetBrandGradient({ Animated = value })
        end,
    })
    local brandFPS = brandSection:AddToggle("Northwind_BrandGradientFPS", {
        Text = "Gradient FPS readout",
        Default = self.Library.BrandGradient.ApplyToFPS,
        Callback = function(value)
            self.Library:SetBrandGradient({ ApplyToFPS = value })
        end,
    })
    local brandSpeed = brandSection:AddSlider("Northwind_BrandGradientSpeed", {
        Text = "Animation speed",
        Min = 5,
        Max = 200,
        Default = math.floor(self.Library.BrandGradient.Speed * 100 + 0.5),
        Suffix = "%",
        Callback = function(value)
            self.Library:SetBrandGradient({ Speed = value / 100 })
        end,
    })
    local brandStart = brandSection:AddColorPicker("Northwind_BrandGradientStart", {
        Text = "Start color",
        Default = self.Library.BrandGradient.Start,
        Callback = function(value)
            self.Library:SetBrandGradient({ Start = value })
        end,
    })
    local brandFinish = brandSection:AddColorPicker("Northwind_BrandGradientFinish", {
        Text = "End color",
        Default = self.Library.BrandGradient.Finish,
        Callback = function(value)
            self.Library:SetBrandGradient({ Finish = value })
        end,
    })
    brandEnabled.Save = false
    brandAnimated.Save = false
    brandFPS.Save = false
    brandSpeed.Save = false
    brandStart.Save = false
    brandFinish.Save = false

    local typographySection = typePage:AddSection({
        Name = "Typography & motion",
        Description = "Font family and animation feel",
        Icon = "sliders",
        Side = "Left",
    })
    local fontPreset = typographySection:AddDropdown("Northwind_FontPreset", {
        Text = "Font",
        Values = { "Gotham", "Builder Sans", "Source Sans" },
        Default = self.Library.TypographyPreset ~= "Custom" and self.Library.TypographyPreset or "Gotham",
        Callback = function(value)
            self.Library:SetTypography(value)
        end,
    })
    local motionEnabled = typographySection:AddToggle("Northwind_MotionEnabled", {
        Text = "Smooth animations",
        Default = self.Library.Motion.Enabled,
        Callback = function(value)
            self.Library:SetMotion(value)
        end,
    })
    local motionSpeed = typographySection:AddSlider("Northwind_MotionSpeed", {
        Text = "Motion speed",
        Min = 25,
        Max = 200,
        Default = math.floor(self.Library.Motion.Speed * 100 + 0.5),
        Suffix = "%",
        Callback = function(value)
            self.Library:SetMotion(nil, value / 100)
        end,
    })
    fontPreset.Save = false
    motionEnabled.Save = false
    motionSpeed.Save = false

    local previewSection = typePage:AddSection({
        Name = "Preview",
        Description = "Updates instantly",
        Icon = "eye",
        Side = "Right",
    })
    previewSection:AddLabel("Northwind UI")
    previewSection:AddDivider("Clean hierarchy")
    previewSection:AddLabel("Body text stays crisp and restrained while brand text can use an animated gradient. Motion, font family, gradient colors, speed, and FPS styling are all adjustable.")

    self.TypeSubtabButton.Visible = self._activeTab == settings
    if self._activeTab == settings then
        self:SetHeaderSubtab("Settings")
    end
    return settings
end

return Northwind

