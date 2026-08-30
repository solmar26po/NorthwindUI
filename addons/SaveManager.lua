local SaveManager = {
    Library = nil,
    Provider = nil,
}

function SaveManager:CreateMemoryProvider()
    local values = {}
    return {
        Save = function(_, name, encoded)
            values[name] = encoded
        end,
        Load = function(_, name)
            return values[name]
        end,
        Delete = function(_, name)
            values[name] = nil
        end,
        List = function()
            local names = {}
            for name in pairs(values) do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end,
    }
end

function SaveManager:SetLibrary(library)
    self.Library = library
    if self.Provider then
        library:SetConfigProvider(self.Provider)
    end
    return self
end

function SaveManager:SetProvider(provider)
    assert(type(provider) == "table", "Config provider must be a table")
    self.Provider = provider
    if self.Library then
        self.Library:SetConfigProvider(provider)
    end
    return self
end

function SaveManager:Save(name)
    assert(self.Library, "Call SaveManager:SetLibrary first")
    return self.Library:SaveConfig(name)
end

function SaveManager:Load(name)
    assert(self.Library, "Call SaveManager:SetLibrary first")
    return self.Library:LoadConfig(name)
end

function SaveManager:Delete(name)
    assert(self.Library, "Call SaveManager:SetLibrary first")
    return self.Library:DeleteConfig(name)
end

function SaveManager:List()
    if self.Provider and self.Provider.List then
        return self.Provider:List()
    end
    local names = {}
    for name in pairs(self.Library and self.Library.Configs or {}) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function SaveManager:Export()
    assert(self.Library, "Call SaveManager:SetLibrary first")
    return self.Library:ExportConfig()
end

function SaveManager:Import(encoded)
    assert(self.Library, "Call SaveManager:SetLibrary first")
    return self.Library:ImportConfig(encoded)
end

return SaveManager


