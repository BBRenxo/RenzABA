--// ==========================================
--//        ABA Morph System | Hardened
--// ==========================================

local getgenv = getgenv or function() return _G end
local LPH_NO_VIRTUALIZE = getgenv().LPH_NO_VIRTUALIZE or function(...) return ... end
local LPH_JIT_MAX = getgenv().LPH_JIT_MAX or function(...) return ... end
getgenv().LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE
getgenv().LPH_JIT_MAX = LPH_JIT_MAX

-- File system & executor polyfills
local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end
local listfiles = listfiles or function() return {} end
local getcustomasset = getcustomasset or getsynasset or function(path) return path end

local IsDebug = true
local StartTick = tick()

local function debugPrint(LogType, ...)
    if IsDebug then
        local func = LogType or print
        func("[MORPH DEBUG]", ...)
    end
end

-- Inline standalone Maid implementation (zero 3rd-party GitHub dependency)
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(task)
    if not task then return end
    local taskId = #self._tasks + 1
    self._tasks[taskId] = task
    return taskId
end

function Maid:DoCleaning()
    for key, task in pairs(self._tasks) do
        if typeof(task) == "RBXScriptConnection" then
            task:Disconnect()
        elseif typeof(task) == "Instance" then
            task:Destroy()
        elseif type(task) == "function" then
            pcall(task)
        elseif type(task) == "table" and type(task.Destroy) == "function" then
            pcall(function() task:Destroy() end)
        end
        self._tasks[key] = nil
    end
end

function Maid:__newindex(index, newTask)
    if Maid[index] ~= nil then
        rawset(self, index, newTask)
        return
    end

    local oldTask = self._tasks[index]
    if oldTask == newTask then return end

    if typeof(oldTask) == "RBXScriptConnection" then
        oldTask:Disconnect()
    elseif typeof(oldTask) == "Instance" then
        oldTask:Destroy()
    elseif type(oldTask) == "function" then
        pcall(oldTask)
    elseif type(oldTask) == "table" and type(oldTask.Destroy) == "function" then
        pcall(function() oldTask:Destroy() end)
    end

    self._tasks[index] = newTask
end

function Maid:__index(index)
    if Maid[index] ~= nil then
        return Maid[index]
    end
    return self._tasks[index]
end

local maidInstance = Maid.new()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")

local Player = Players.LocalPlayer
local PlayerGui = Player:FindFirstChild('PlayerGui') or Player:WaitForChild('PlayerGui', 5)

local CurrentSound = nil
local ThemeCheck = ReplicatedStorage:FindFirstChild('ThemeCheck') or ReplicatedStorage:WaitForChild('ThemeCheck', 2)
local MusicFolder = ReplicatedStorage:FindFirstChild('Music')

local function getPartWithName(Model: Instance, s: string)
    if not Model then return nil end
    local direct = Model:FindFirstChild(s, true)
    if direct and direct:IsA('BasePart') then
        return direct
    end
    for _, v in pairs(Model:GetDescendants()) do
        if v:IsA('BasePart') and v.Name == s then
            return v
        end
    end
    return nil
end

local function Morph_Function(Morph: Model, Character: Model)
    if not Morph or not Character then return end
    local MorphClone = Morph:Clone()
    
    for _, Child in pairs(Character:GetChildren()) do
        if Child:IsA('Pants') or Child:IsA('Shirt') or Child:IsA('BodyColors') or (Child:IsA('Model') and Child.Name == 'Morph') then
            Child:Destroy()
        end
    end
    
    for _, MorphChild in pairs(MorphClone:GetChildren()) do
        if MorphChild:IsA('Model') then
            local newModel = MorphChild:Clone()
            newModel.Parent = Character
            newModel.Name = 'Morph'
            
            local PartToWeldTo = Character:FindFirstChild(MorphChild.Name)
            if not PartToWeldTo then continue end
            
            local refPart = getPartWithName(MorphClone, MorphChild.Name) or PartToWeldTo
            
            for _, Children in pairs(newModel:GetChildren()) do
                if not Children:IsA('BasePart') then continue end
                Children.CanCollide = false
                local Offset = refPart.CFrame:ToObjectSpace(Children.CFrame)
                local newMotor = Instance.new('Weld')
                newMotor.Part0 = PartToWeldTo
                newMotor.Part1 = Children
                newMotor.C0 = Offset
                newMotor.Name = Children.Name .. 'Weld'
                newMotor.Parent = PartToWeldTo
            end
        elseif MorphChild:IsA('Pants') or MorphChild:IsA('Shirt') or MorphChild:IsA('BodyColors') or MorphChild:IsA('CharacterMesh') then
            MorphChild:Clone().Parent = Character
        elseif MorphChild:IsA('BasePart') and Character:FindFirstChild(MorphChild.Name) then
            Character:FindFirstChild(MorphChild.Name).Transparency = MorphChild.Transparency
        end
    end
    
    local FakeHead = Character:FindFirstChild('FakeHead') or Character:FindFirstChild('Head')
    local HeadPart = getPartWithName(MorphClone, 'Head')
    local BodyColors = Character:FindFirstChildWhichIsA('BodyColors')
    if FakeHead then
        local targetColor = (BodyColors and BodyColors.HeadColor3) or (HeadPart and HeadPart.Color)
        if targetColor then
            FakeHead.Color = targetColor
        end
    end
    
    task.wait()
    MorphClone:Destroy()
end

-- Directory verification and auto-creation
debugPrint(print, 'Checking file integrity...');
if not isfolder('ABA_MorphData') then makefolder('ABA_MorphData') end
if not isfolder('ABA_MorphData/Morphs') then makefolder('ABA_MorphData/Morphs') end
debugPrint(print, 'Files structure verified.');

local Morphs = {}

for _, File in pairs(listfiles('ABA_MorphData/Morphs')) do
    local MorphName = string.match(File, "[^/\\]+$")
    if not MorphName then continue end
    
    debugPrint(warn, 'Reading morph package: ' .. MorphName)
    local MorphTable = {}

    local function loadAsset(Index, Value)
        local fullPath = File .. '/' .. Value
        if isfile(fullPath) then
            debugPrint(print, 'Loading asset: ' .. Value)
            if Value:match('%.rbxm$') then
                pcall(function()
                    local customAsset = getcustomasset(fullPath)
                    local objects = game:GetObjects(customAsset)
                    if objects and #objects > 0 then
                        MorphTable[Index] = objects[1]
                    end
                end)
            elseif Value:match('%.mp3$') then
                pcall(function()
                    local SoundId = getcustomasset(fullPath)
                    local TempSound = Instance.new('Sound')
                    TempSound.SoundId = SoundId
                    ContentProvider:PreloadAsync({TempSound})
                    MorphTable[Index] = TempSound
                    debugPrint(warn, 'Sound loaded successfully: ', SoundId)
                end)
            elseif Value:match('%.lua$') then
                pcall(function()
                    local scriptContent = readfile(fullPath)
                    MorphTable[Index] = loadstring(scriptContent)()
                end)
            end
        end
    end

    loadAsset('Extras', 'Extras.rbxm')
    loadAsset('Morph', 'Morph.rbxm')
    loadAsset('Morph_Mode', 'Morph_Mode.rbxm')
    loadAsset('LuaFunctions', 'LuaFunctions.lua')
    loadAsset('Sound', 'Soundtrack.mp3')
    
    Morphs[MorphName] = MorphTable
end

local function callFunction(MorphIndex, Function, ...)
    if not MorphIndex or not MorphIndex.LuaFunctions then return end
    local Functions = MorphIndex.LuaFunctions
    if not Functions[Function] then
        debugPrint(warn, 'Specific function is missing: ' .. tostring(Function))
        return
    end
    
    local CustomEnvironment = {
        Character = Player.Character,
        Extras = MorphIndex.Extras or nil,
        HasCustomEnvironment = true,
        MorphFunction = Morph_Function,
        EnvironmentFunctions = {},
        Morphs = {
            ['Morph'] = MorphIndex.Morph or nil,
            ['ModeMorph'] = MorphIndex.Morph_Mode or nil
        }
    }
    
    if hookfunction and restorefunction then
        CustomEnvironment.EnvironmentFunctions['restorefunction'] = restorefunction
        CustomEnvironment.EnvironmentFunctions['hookfunction'] = hookfunction
    end
    if getcustomasset then
        CustomEnvironment.EnvironmentFunctions['getcustomasset'] = getcustomasset
    end

    local TargetFunction = Functions[Function]
    pcall(function()
        local ENV = getfenv(TargetFunction)
        for index, value in pairs(CustomEnvironment) do
            ENV[index] = value
        end
        setfenv(TargetFunction, ENV)
    end)

    return coroutine.wrap(TargetFunction)(...)
end

local function replaceConnection(Index, Connection)
    debugPrint(print, 'Replacing connection: ' .. tostring(Index))
    if maidInstance[Index] then
        maidInstance[Index] = nil
    end
    if Connection then
        maidInstance[Index] = Connection
    end
end

local function playSoundtrack(CharacterIndex)
    task.wait()
    if CurrentSound then
        CurrentSound:Destroy()
        CurrentSound = nil
    end
    if CharacterIndex and CharacterIndex.Sound then
        local hud = PlayerGui and (PlayerGui:FindFirstChild('HUD') or PlayerGui)
        if not hud then return end
        CurrentSound = CharacterIndex.Sound:Clone()
        CurrentSound.Volume = 1.1
        CurrentSound.Parent = hud
        debugPrint(warn, 'Playing custom soundtrack: ', CurrentSound.TimeLength)
        CurrentSound:Play()
        CurrentSound.Ended:Connect(function()
            if CurrentSound then
                CurrentSound:Destroy()
                CurrentSound = nil
            end
        end)
    end
end

local function spawnInCondition()
    if PlayerGui and PlayerGui:FindFirstChild('HUD') and PlayerGui.HUD:FindFirstChild('1') and PlayerGui.HUD['1'].Visible then
        return true
    end
    if Player.Character and Player.Character:FindFirstChild('HumanoidRootPart') then
        return true
    end
    return false
end

local function Update(Character: Model)
    if not Character then return end
    
    local waitCount = 0
    while not spawnInCondition() and waitCount < 100 do
        task.wait(0.1)
        waitCount = waitCount + 1
    end

    if not Character.Parent then return end
    debugPrint(print, 'Spawn detected. Initializing morph...')

    local Charge = Player:FindFirstChild('Charge') or Player:WaitForChild('Charge', 3)
    local CurrentlyLoadedCharacter = Player:GetAttribute('LastLoadedChar')
    local Index = CurrentlyLoadedCharacter and Morphs[CurrentlyLoadedCharacter]

    if not Index then
        debugPrint(warn, 'No active morph configuration for character: ' .. tostring(CurrentlyLoadedCharacter))
        return
    end

    if Index.Morph then
        debugPrint(warn, 'Morphing base character model...')
        Morph_Function(Index.Morph, Character)
    end

    callFunction(Index, 'OnSpawn')

    local SkillConnection = Character.ChildAdded:Connect(function(Child)
        if Child.Name == 'UsingSkill' then
            debugPrint(print, 'Using skill: ' .. tostring(Child.Value))
            callFunction(Index, 'OnMove', Child.Value)
        end
    end)
    
    local ModeConnection = PlayerGui and PlayerGui.ChildAdded:Connect(function(Child)
        if Child:IsA('LocalScript') and Child.Name:match('CameraScene') then
            playSoundtrack(Index)
            if Charge then
                local ModeEndConnection = Charge:GetPropertyChangedSignal('Value'):Connect(function()
                    if Charge.Value <= 0 then
                        replaceConnection('ModeEndObserver')
                        if CurrentSound then CurrentSound:Destroy(); CurrentSound = nil end
                        if Index['Morph_Mode'] and Index['Morph'] then
                            Morph_Function(Index['Morph'], Character)
                        end
                        callFunction(Index, 'OnModeEnd')
                        debugPrint(warn, 'Awakening mode ended.')
                    end
                end)
                replaceConnection('ModeEndObserver', ModeEndConnection)
            end
            if Index['Morph_Mode'] then
                Morph_Function(Index['Morph_Mode'], Character)
            end
            callFunction(Index, 'OnMode')
        end
    end)

    local PEffect = ReplicatedStorage:FindFirstChild('PEffect')
    if PEffect then
        local ModeConnection2 = PEffect.OnClientEvent:Connect(function(EffectType, DataTable)
            if typeof(EffectType) == 'string' and EffectType:match('AwakeningCamera') then
                if DataTable and DataTable.root and Player.Character and DataTable.root:IsAncestorOf(Player.Character) then
                    playSoundtrack(Index)
                    if Charge then
                        local ModeEndConnection = Charge:GetPropertyChangedSignal('Value'):Connect(function()
                            if Charge.Value <= 0 then
                                replaceConnection('ModeEndObserver')
                                if CurrentSound then CurrentSound:Destroy(); CurrentSound = nil end
                                if Index['Morph_Mode'] and Index['Morph'] then
                                    Morph_Function(Index['Morph'], Character)
                                end
                                callFunction(Index, 'OnModeEnd')
                                debugPrint(warn, 'Awakening mode ended.')
                            end
                        end)
                        replaceConnection('ModeEndObserver', ModeEndConnection)
                    end
                    if Index['Morph_Mode'] then
                        Morph_Function(Index['Morph_Mode'], Character)
                    end
                    callFunction(Index, 'OnMode')
                end
            end
        end)
        replaceConnection('ModeObserver2', ModeConnection2)
    end

    if ModeConnection then replaceConnection('ModeObserver', ModeConnection) end
    replaceConnection('SkillObserver', SkillConnection)
end

if Player.Character then
    task.spawn(Update, Player.Character)
end

maidInstance.OnCharacterAdded = Player.CharacterAdded:Connect(Update)

maidInstance.OnCharRemoved = Player.CharacterRemoving:Connect(function(Char: Model)
    local CurrentlyLoadedCharacter = Player:GetAttribute('LastLoadedChar')
    local Index = CurrentlyLoadedCharacter and Morphs[CurrentlyLoadedCharacter]
    debugPrint(print, 'Character removing, clearing state...')

    if Index then
        callFunction(Index, 'OnRemoval')
    end
    if CurrentSound then
        CurrentSound:Destroy()
        CurrentSound = nil
    end
    replaceConnection('ModeEndObserver')
end)

-- Safe Background Music Handler Hook
if getsenv and hookfunction and isfunctionhooked then
    local MusicScript = Player:FindFirstChild('PlayerScripts') and Player.PlayerScripts:FindFirstChild('MusicPlayer')
    if MusicScript then
        local sEnv = getsenv(MusicScript)
        local MusicHandler = sEnv and sEnv.MusicHandler
        if MusicHandler and not isfunctionhooked(MusicHandler) then
            debugPrint(print, 'Hooking game music handler...')
            hookfunction(MusicHandler, function(...)
                debugPrint(warn, 'MusicHandler intercepted:', ...)
            end)
        end
    end

    if ThemeCheck and MusicFolder then
        local ThemeConnection = ThemeCheck.OnClientEvent:Connect(function(Sound)
            if Sound and Sound.Name == Player.Name then
                local CurrentlyLoadedCharacter = Player:GetAttribute('LastLoadedChar')
                local Index = CurrentlyLoadedCharacter and Morphs[CurrentlyLoadedCharacter]
                if Index and Index.Sound then
                    local targetSound = MusicFolder:FindFirstChild(Sound.SoundId)
                    if not targetSound then
                        local waitTime = 0
                        while not MusicFolder:FindFirstChild(Sound.SoundId) and waitTime < 5 do
                            task.wait(0.1)
                            waitTime = waitTime + 0.1
                        end
                        targetSound = MusicFolder:FindFirstChild(Sound.SoundId)
                    end
                    if targetSound then
                        targetSound.Volume = 0
                        debugPrint(print, 'Silenced default character music.')
                    end
                end
            end
        end)
        replaceConnection('ThemeConnection', ThemeConnection)
    end
end

debugPrint(print, 'Morph system initialized successfully in ' .. string.format('%.3f', tick() - StartTick) .. 's')
