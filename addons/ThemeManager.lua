-- Northwind UI theme helper
local ThemeManager = {
    Library = nil,
}

function ThemeManager:SetLibrary(library)
    self.Library = library
    return self
end

function ThemeManager:RegisterTheme(name, palette)
    assert(self.Library, "Call ThemeManager:SetLibrary first")
    assert(type(name) == "string", "Theme name must be a string")
    assert(type(palette) == "table", "Theme palette must be a table")

    local base = table.clone(self.Library.Themes.Midnight)
    for token, value in pairs(palette) do
        base[token] = value
    end
    self.Library.Themes[name] = base
    return self
end

function ThemeManager:ApplyTheme(name)
    assert(self.Library, "Call ThemeManager:SetLibrary first")
    self.Library:SetTheme(name)
    return self
end

function ThemeManager:SetAccent(color)
    assert(self.Library, "Call ThemeManager:SetLibrary first")
    self.Library:SetAccent(color)
    return self
end

function ThemeManager:SetTextGradient(startColor, finishColor, rotation, enabled)
    assert(self.Library, "Call ThemeManager:SetLibrary first")
    self.Library:SetTextGradient(startColor, finishColor, rotation, enabled)
    return self
end

function ThemeManager:GetThemes()
    assert(self.Library, "Call ThemeManager:SetLibrary first")
    local names = {}
    for name in pairs(self.Library.Themes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

return ThemeManager

