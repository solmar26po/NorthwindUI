// Run with LUAU_BIN pointing to the official Luau CLI executable.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const source = fs.readFileSync('Library.lua', 'utf8');
const start = source.indexOf('-- BEGIN GENERATED ICON DATA');
const end = source.indexOf('local function setIconColor', start);
assert.ok(start >= 0 && end > start);
const png = fs.readFileSync('assets/NorthwindIcons.png');
const encoded = source.match(/local ICON_ATLAS_PNG = "([^"]+)"/)[1];
assert.deepEqual(Buffer.from(encoded, 'base64'), png, 'Embedded PNG must match asset');
assert.equal(png.readUInt32BE(16), 480);
assert.equal(png.readUInt32BE(20), 384);
const expected = '"' + [...png].map(x=>'\\'+String(x).padStart(3,'0')).join('') + '"';
const harness = `
local expected = ${expected}
local Vector2 = {new=function(x,y) return {X=x,Y=y} end}
local UDim2 = {new=function(...) return {...} end, fromScale=function(...) return {...} end, fromOffset=function(...) return {...} end}
local Enum = {ScaleType={Fit="Fit"}}
local function library(options)
    options = options or {}
    local state = {writes=0,registrations=0,bindings={},cached=options.cached}
    local getcustomasset, getsynasset, readfile, writefile
    if not options.noFiles then
        writefile=function(_,bytes)
            if options.writeError then error("unwritable") end
            state.writes+=1; state.cached=bytes
        end
        readfile=function() if state.cached==nil then error("not cached") end return state.cached end
    end
    local register=function()
        state.registrations+=1
        if options.registerError then error("unsupported") end
        if options.emptyAsset then return "" end
        return "rbxasset://local-test.png"
    end
    if options.syn then getsynasset=register elseif not options.noRegister then getcustomasset=register end
    local palette={Text="white",Muted="gray",Accent="purple"}
    local Northwind={}
    function Northwind:_theme() return palette end
    function Northwind:_bind(instance,property,token)
        instance[property]=palette[token]
        table.insert(state.bindings,{Instance=instance,Property=property,Token=token})
    end
    local function create(className,properties)
        local instance=table.clone(properties);instance.ClassName=className;instance.Children={}
        if instance.Parent then table.insert(instance.Parent.Children,instance) end
        return instance
    end
    local function round() end
    local function stroke(parent,color) return create("UIStroke",{Parent=parent,Color=color}) end
    ${source.slice(start,end)}
    return Northwind,state
end
local lib,state=library()
local names=lib:GetIconNames()
assert(#names==20)
for index,name in ipairs(names) do
    local frame=lib:CreateIcon(nil,{Name=name,ColorToken="Accent"})
    assert(#frame.Children==1,"one image per icon")
    local image=frame.Children[1]
    assert(image.ClassName=="ImageLabel" and image.Name==name and image.ImageColor3=="purple")
    assert(image.ImageRectOffset.X==((index-1)%5)*96 and image.ImageRectOffset.Y==math.floor((index-1)/5)*96)
    assert(image.ImageRectSize.X==96 and image.ImageRectSize.Y==96)
end
assert(state.writes==1 and state.registrations==1)
assert(state.cached==expected,"Luau decoder must preserve every PNG byte")
assert(lib:GetIconRenderer()=="PNG atlas")
names[1]="modified";assert(lib:GetIconNames()[1]=="home")
for _,case in ipairs({{"gear","settings"},{"configs","save"},{"⌨","keyboard"},{"unknown","sparkles"}}) do
    assert(lib:CreateIcon(nil,{Name=case[1]}).Children[1].Name==case[2])
end
local custom=lib:CreateIcon(nil,{Name="rbxassetid://123"}).Children[1]
assert(custom.Image=="rbxassetid://123" and custom.ImageRectOffset==nil)
-- Theme changes can reach every image through the same binding used by tabs.
for _,binding in ipairs(state.bindings) do binding.Instance[binding.Property]="updated" end
assert(custom.ImageColor3=="updated")
local cached,cachedState=library({cached=expected})
assert(cached:GetIconRenderer()=="PNG atlas" and cachedState.writes==0)
local corrupt,corruptState=library({cached="truncated PNG"})
assert(corrupt:GetIconRenderer()=="PNG atlas" and corruptState.cached==expected)
for _,options in ipairs({{noFiles=true},{noRegister=true},{writeError=true},{registerError=true},{emptyAsset=true}}) do
    local fallback=library(options)
    assert(fallback:GetIconRenderer()=="Native fallback")
    local icon=fallback:CreateIcon(nil,{Name="clock"})
    assert(icon.Children[1].ClassName=="Frame")
end
local syn=library({syn=true});assert(syn:GetIconRenderer()=="PNG atlas")
local override,overrideState=library({noFiles=true,noRegister=true})
override:SetIconAtlas("rbxassetid://987")
assert(override:CreateIcon(nil,{Name="home"}).Children[1].Image=="rbxassetid://987")
assert(overrideState.writes==0 and overrideState.registrations==0)
override:SetIconAtlas(false);assert(override:GetIconRenderer()=="Native fallback")
override:SetIconAtlas(nil);assert(override:GetIconRenderer()=="Native fallback")
assert(not pcall(function() override:SetIconAtlas(123) end))
print("PASS: 20 crops, PNG bytes, aliases, theme bindings, cache, overrides, and fallback paths")
`;
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'northwind-icons-'));
try {
  const file=path.join(dir,'icons.luau');fs.writeFileSync(file,harness);
  const result=spawnSync(process.env.LUAU_BIN || 'luau',[file],{encoding:'utf8',timeout:20000});
  assert.equal(result.status,0,result.error?.message || result.stderr);
  process.stdout.write(result.stdout);
} finally { fs.rmSync(dir,{recursive:true,force:true}); }
