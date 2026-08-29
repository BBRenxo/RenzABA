--// Renz Hub Execution Environment Polyfills & Clean Reload Handler
local getgenv = getgenv or function() return _G end

-- Unload previous instance if re-executing
pcall(function()
    if getgenv()._RenzHubInstance and getgenv()._RenzHubInstance.Unload then
        getgenv()._RenzHubInstance:Unload()
    end
    if getgenv().RenzHub and getgenv().RenzHub.Lib and getgenv().RenzHub.Lib.Unload then
        getgenv().RenzHub.Lib:Unload()
    end
    if getgenv().ProjectABA and getgenv().ProjectABA.Lib and getgenv().ProjectABA.Lib.Unload then
        getgenv().ProjectABA.Lib:Unload()
    end
end)

local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end
local delfile = delfile or function() end
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end
local listfiles = listfiles or function() return {} end
local setclipboard = setclipboard or toclipboard or set_clipboard or function() end
local isnetworkowner = isnetworkowner or isnetowner or function() return true end

local LPH_NO_VIRTUALIZE = getgenv().LPH_NO_VIRTUALIZE or function(...) return ... end
local LPH_JIT_MAX = getgenv().LPH_JIT_MAX or function(...) return ... end
getgenv().LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE
getgenv().LPH_JIT_MAX = LPH_JIT_MAX

local CurrentlyPlayingTrack = nil
local AttachToBack = nil
local RaidenSkipModeConnection = nil
local function APBreaker(Value) end
local function AntiPools(Value) end
local function AntiGiornoFlowers(Value) end

    if not game.IsLoaded then
        game.Loaded:Wait();
    end;

    -- HasExecuted bypass: allows instant re-execution

    getgenv().HasExecuted = true;
    getgenv().AfterKey = getgenv().AfterKey or 'T';

    local ReplicatedStorage = game:GetService("ReplicatedStorage");
    local Players = game:GetService("Players");
    local Debris = game:GetService("Debris");
    local TextChatService = game:GetService("TextChatService");
    local UserInputService = game:GetService("UserInputService");
    local ContextActionService = game:GetService('ContextActionService');
    local HttpService = game:GetService('HttpService');
    local TweenService = game:GetService("TweenService");
    local RunService = game:GetService("RunService");
    local TeleportService = game:GetService("TeleportService");
    local VirtualInputManager = game:GetService("VirtualInputManager");
    local Live = workspace:WaitForChild('Live');

    local Effect = ReplicatedStorage:WaitForChild('Effect');

    loadstring([[getgenv().LPH_NO_VIRTUALIZE = function(...) return ...; end;]])()
    loadstring([[getgenv().LPH_JIT_MAX = function(...) return ...; end;]])()

    local Connections = {};

    local Player = Players.LocalPlayer;
    local PlayerGui = Player.PlayerGui;
    local StarterGui = game:GetService("StarterGui");

    local StreamerModeConnections = {};
    local StreamerModeString = '';

    local function ProcessPlayer(Frame)
        if Frame:IsA('Frame') and Frame.Name ~= 'TeamLabel' then
            if Frame:FindFirstChild('PlayerName') then
                local Name = Frame:FindFirstChild('PlayerName');
                Name.Text = StreamerModeString;
                table.insert(StreamerModeConnections, Name:GetPropertyChangedSignal('Text'):Connect(LPH_NO_VIRTUALIZE(function()
                    if Name.Text ~= StreamerModeString then
                        Name.Text = StreamerModeString;
                    end;
                end)));
            end;
        end;
    end;

    local function ProcessTeam(Frame)
        if Frame.Name ~= 'Axis' and Frame:IsA('Frame') then
            for _, v in Frame:GetChildren() do
                ProcessPlayer(v);
            end;
            table.insert(StreamerModeConnections, Frame.ChildAdded:Connect(ProcessPlayer));
        end;
    end;

    local function Process(ScreenGui)
        if ScreenGui:IsA('ScreenGui') and ScreenGui.Name == 'StartFight' then
            for _, v in ScreenGui:GetChildren() do
                if v.Name:match('Team') then
                    if v:FindFirstChild('picked') then
                        v:FindFirstChild('picked').Text = StreamerModeString;
                    end;
                end;
            end;
        elseif ScreenGui:IsA('ScreenGui') and ScreenGui.Name == 'CustomLeaderboard' then
            local MainFrame = ScreenGui:WaitForChild('Main');
            for _, v in MainFrame:GetChildren() do
                ProcessTeam(v);
            end;
            table.insert(StreamerModeConnections, MainFrame.ChildAdded:Connect(ProcessTeam));
        elseif ScreenGui:IsA('ScreenGui') and ScreenGui.Name == 'HUD' then
            local Died = ScreenGui:WaitForChild('Died');
            table.insert(StreamerModeConnections, Died:GetPropertyChangedSignal('Visible'):Connect(LPH_NO_VIRTUALIZE(function()
                if Died.Visible then
                    Died.Text = 'Killed by ' .. StreamerModeString;
                end;
            end)));
        end;
    end;

    local function ProcessLive(v)
        local Humanoid = v:WaitForChild('Humanoid');
        if not Humanoid then return; end;
        local LevelModel;

        for _, Child in v:GetChildren() do
            if string.match(Child.Name, "^%[.-%]$") then
                LevelModel = Child;
                break;
            end;
        end;

        local LevelHumanoid = (LevelModel and LevelModel:FindFirstChildWhichIsA('Humanoid')) or nil;

        if LevelHumanoid then
            LevelHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
        end;
        Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
        table.insert(StreamerModeConnections, Humanoid:GetPropertyChangedSignal('DisplayDistanceType'):Connect(function()
            Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
        end));
    end;

    local function StreamerModeCallback()
        for _,v in StreamerModeConnections do
        v:Disconnect();
        end;
        table.clear(StreamerModeConnections);
        if not Toggles.StreamerMode.Value then
            if isfile("stuffnstuff/streamermode.txt") then
                delfile("stuffnstuff/streamermode.txt");
            end;
            return;
        end;
        if not isfile("stuffnstuff/streamermode.txt") then
            writefile("stuffnstuff/streamermode.txt", "streamer mode lalalallalala");
        end;
        if PlayerGui:FindFirstChild('StartFight') then
            Process(PlayerGui.StartFight);
        end;

        if PlayerGui:FindFirstChild('CustomLeaderboard') then
            Process(PlayerGui.CustomLeaderboard);
        end;

        if PlayerGui:FindFirstChild('HUD') then
            Process(PlayerGui.HUD);
        end;
        
        for _, v in Live:GetChildren() do
            ProcessLive(v);
        end;

        table.insert(StreamerModeConnections, Live.ChildAdded:Connect(ProcessLive));
        table.insert(StreamerModeConnections, PlayerGui.ChildAdded:Connect(Process));
    end;

    if isfile("stuffnstuff/streamermode.txt") then
        if PlayerGui:FindFirstChild('StartFight') then
            Process(PlayerGui.StartFight);
        end;

        if PlayerGui:FindFirstChild('CustomLeaderboard') then
            Process(PlayerGui.CustomLeaderboard);
        end;

        if PlayerGui:FindFirstChild('HUD') then
            Process(PlayerGui.HUD);
        end;
        
        for _, v in Live:GetChildren() do
            ProcessLive(v);
        end;

        table.insert(StreamerModeConnections, Live.ChildAdded:Connect(ProcessLive));
        table.insert(StreamerModeConnections, PlayerGui.ChildAdded:Connect(Process));
    end;


    if not Player.Character then
        repeat task.wait() until Player.Character
    end;
    task.wait(1);

    local Mouse = Player:GetMouse();

    local Camera = workspace.CurrentCamera;


    local ESP_Gui = game:GetObjects('rbxassetid://99131262255411')[1];

    local moveForward  = 0
    local moveBackward = 0
    local moveLeft     = 0
    local moveRight    = 0

    local Bindings = {
        { Enum.KeyCode.W, function(v) moveForward  = v end, -1 },
        { Enum.KeyCode.S, function(v) moveBackward = v end,  1 },
        { Enum.KeyCode.A, function(v) moveLeft     = v end, -1 },
        { Enum.KeyCode.D, function(v) moveRight    = v end,  1 },
    }

    for _, binding in ipairs(Bindings) do
        local keyCode, setter, value = binding[1], binding[2], binding[3]
        ContextActionService:BindAction(
            HttpService:GenerateGUID(false),
            function(_, inputState)
                setter((inputState == Enum.UserInputState.Begin) and value or 0)
                return Enum.ContextActionResult.Pass
            end,
            false,
            keyCode
        );
    end;

    local function GetMoveVector()
        return Vector3.new(moveLeft + moveRight, 0, moveForward + moveBackward);
    end;

    local function dodge(args)
        if Player.Character and Player.Backpack:FindFirstChild('Input', true) then
            Player.Backpack.Input:FireServer('dodge', args);
        end;
    end;

    function getTarget(s2: string, n14: number) 
        local v177 = n14 or 3000

        local v178 = s2 == "OnlyTeam"
        local v179 = s2 == "WithTeam"

        local LocalPlayer = Player;
        local CurrentCamera = workspace.CurrentCamera;
        local Character = LocalPlayer.Character;

        if not Character then return; end;

        if v178 and not LocalPlayer.Team then
            return nil, Mouse.Hit.Position
        end

        local v181 = nil
        local n15 = 0.4
        local CFramePosition = CurrentCamera.CFrame.Position
        local lookVector = CurrentCamera.CFrame.lookVector

        for _, v186 in workspace.Live:GetChildren() do
            if v186.Name == LocalPlayer.Name or v186:FindFirstChild("NoTarg") then
                continue
            end

            local NoTargetBy = v186:FindFirstChild("NoTargetBy")

            if NoTargetBy and NoTargetBy.Value == Character.Name then
                continue
            end

            local Humanoid2 = v186:FindFirstChild("Humanoid")
            local v189 = Humanoid2 and (Humanoid2.Health > 0 and v186:FindFirstChild("Torso"))
            local v190 = v189 and (v189.Transparency < 1 and v186:FindFirstChild("HumanoidRootPart"))

            if not v190 or v177 < (v190.Position - Character:GetPivot().Position).magnitude then
                continue
            end

            local v191 = game.Players:GetPlayerFromCharacter(v186) or game.Players:FindFirstChild(v186.Name)

            if v191 and not v186:HasTag("Loaded") then
                continue
            end

            if v178 then
                if not v191 or v191.Team ~= LocalPlayer.Team then
                    continue
                end
            elseif not v179 and v191 and LocalPlayer.Team and v191.Team == LocalPlayer.Team then
                continue
            end

            local magnitude = (CFrame.new(CFramePosition, v190.Position).lookVector - lookVector).magnitude

            if magnitude < n15 then
                n15 = magnitude
                v181 = v186
            end

            if not v181 then
                local TargeterOffset = v186:FindFirstChild("TargeterOffset")

                if TargeterOffset then
                    local magnitude2 = (CFrame.new(CFramePosition, v190.Position + TargeterOffset.Value).lookVector - lookVector).magnitude

                    if magnitude2 < n15 then
                        n15 = magnitude2
                        v181 = v186
                    end
                end
            end
        end

        return v181, Mouse.Hit.Position
    end

    local PermanentConnections = {};
    local PreviousCharacterConnections = {};

    local repo = 'https://raw.githubusercontent.com/Fmeat51/newlib/refs/heads/main';

    local Library = loadstring(game:HttpGet(repo .. '/Library.lua'))();
    local SaveManager = loadstring(game:HttpGet(repo .. '/SaveManager.lua'))();
    local ThemeManager = loadstring(game:HttpGet(repo .. '/ThemeManager.lua'))();

    local function Notify(x, y, Alt)

        if getgenv().SilentMode then
            return;
        end;

        if ((Toggles and Toggles.SilentLock) and Toggles.SilentLock.Value) then
            return;
        end;
        if not Alt then
            Library:Notify(string.format("%s | %s", x or '', y or '') .. ' | .gg/cWh43mFDms', 5)
        else
            Library:Notify(x);
        end;
    end;


    getgenv().ProjectABA = {
        Lib = Library,
        SaveManager = SaveManager,
        ThemeManager = ThemeManager,
        Notification = Notify
    };


    PermanentConnections.Effect = Effect.OnClientEvent:Connect(LPH_NO_VIRTUALIZE(function(Type, ...)
        local Args = {...};
        if Type == 'LocalStoneTurn' then
            local State = Args[3];
            local Charmed = Args[1];

            if State == true then
                Charmed:SetAttribute('CharmedAt', tick());
            elseif State == false then
                Charmed:SetAttribute('CharmedAt', nil);
            end;
        end;
    end));

    -- Drawing check bypassed;

    local Watermark;
    local OuterFrame;
    local AlternateWatermarks = {};
    local WatermarkData = {};

    game:GetService('ScriptContext'):SetTimeout(1);

    local s, err = pcall(function()

        for i = 0, 1, .1 do
            for i2 = 0, 1, .1 do
                for i3 = 0, 1 do
                    local Text = Drawing.new('Text');
                    Text.Color = Color3.new(1,1,1);
                    Text.Transparency = .5;
                    local scaleX = i + 0 * 0.02;
                    local scaleY = i2 + 0 * 0.01;
                    local viewport = workspace.CurrentCamera.ViewportSize;
                    Text.Text = StreamerModeString
                    Text.Visible = true;
                    Text.Position = Vector2.new(
                        scaleX * viewport.X,
                        scaleY * viewport.Y
                    );
                    WatermarkData[Text] = {
                        ScaleX = scaleX,
                        ScaleY = scaleY
                    };
                    Text.Size = (viewport.X*20)/1920;
                    table.insert(AlternateWatermarks, Text);
                end;
            end;
        end;

        workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
            local newSize = workspace.CurrentCamera.ViewportSize;

            for i,v in AlternateWatermarks do
                if v.__OBJECT_EXISTS then
                    local Data = WatermarkData[v];
                    v.Position = Vector2.new(
                        Data.ScaleX * newSize.X,
                        Data.ScaleY * newSize.Y
                    );
                    v.Size = (newSize.X*20)/1920
                end;
            end;
        end);
    end);

    if not s and err then Player:Kick('Drawing unsupported')  return; end;


    local Window = Library:CreateWindow({
        Title = 'ABA Modification Software™ | FREE @ .gg/cWh43mFDms',
        Center = true,
        AutoShow = (not SilentMode),
        TabPadding = 8,
        MenuFadeTime = 0.2
    });



    for i,v in Library.ScreenGui:GetChildren() do
        if v.ZIndex == 1 and v.Name == 'Frame' then
            OuterFrame = v;
        end;
    end;

    if not OuterFrame then
        Player:Kick('Failed to load script');
        return;
    end;

    OuterFrame.Name = 'Main';

    OuterFrame:GetPropertyChangedSignal('Visible'):Connect(function()
        for i,v in AlternateWatermarks do
            v.Visible = OuterFrame.Visible;
        end;
    end);


    Notify('Welcome to ABA Modification software.', nil, nil);
    Notify('This tool is property of ABA Skids United™.', nil, nil);
    Notify('Unauthorized distribution of this software will result in contract termination - Infragmentation will not be taken lightly.', nil, nil);


    --//

    local Tabs = {
        Main = Window:AddTab('Main'),
        Chars = Window:AddTab('Characters'),
        Useless = Window:AddTab('Extras'),
        Animations = Window:AddTab('Animations'),
        Macros = Window:AddTab('Macros'),
        ['UI Settings'] = Window:AddTab('UI Settings'),
    };

    local BuiltInMacros = {

        ["Satoru Gojo"] = {
            ["M1 Double Blue Tp Stack"] = {
                Keybind = nil,  
                Actions = '["m1:on","Three:on","Three:off","Q:on","Q:off","delay:0.292","m1:on","m1:off"]'
            },
        },

        ["Dio"] = {
            ["Combostart (Uptilt)"] = {
                Keybind = nil,
                Actions = '["delay:0.025","m1:on","delay:0.21583","Space:on","delay:0.10006","Three:on","delay:0.2","Three:off","delay:0.16620","Space:off","m1:off"]'
            },
            ["Combostart (Downtilt)"] = {
                Keybind = nil,
                Actions = '["Space:on","delay:0.02000","m1:on","Space:off","delay:0.00000","m1:off","delay:0.01000","Three:on","Three:off"]'
            },
        },

        ["Todo"] = {
            ["Boogie Kicks Extend"] = {
                Keybind = nil,
                Actions = '["Space:on","delay:0.0800","Space:off","m1:on","delay:0.06200","Four:on","Four:off","delay:0.02000","m1:off"]'
            },
        },

        ["Mob"] = {
            ["Barrage + Mode Stack"] = {
                Keybind = nil,
                Actions = '["G:on","delay:0.0400","Two:off","Two:off"]'
            },
        },

        ["Kars"] = {
            ["Victory Is Everything! Extend"] = {
                Keybind = nil,
                Actions = '["One:on","delay:0.1","Space:on","m1:on","delay:0.1","One:off","delay:0.05155","m1:off","delay:0.01227","Space:off"]'
            },
        },

        ["Vegeta [Super]"] = {
            ["Final Strike Combo Start"] = {
                Keybind = nil,
                Actions = '["Space:on","delay:0.00208","m1:on","delay:0.01124","Four:on","delay:0.00111","Four:off","delay:0.00182","Space:off","m1:off"]'
            },
            ["Ult Evasive Combo Starter"] = {
                Keybind = nil,
                Actions = '["delay:0.11580","m1:on","delay:0.16670","Space:on","delay:0.15142","G:on","delay:0.18139","G:off","delay:0.41870","m1:off","delay:0.16439","One:on","delay:0.09996","One:off","Space:off"]'
            }
        },
    }
    local Groupboxes = {
        Miscellaneous = Tabs.Main:AddRightGroupbox('Miscellaneous'),
        ATB = Tabs.Main:AddRightGroupbox('Attach to back'),
        Removals = Tabs.Main:AddRightGroupbox('Removals'),
        RemoteFunctions = Tabs.Main:AddRightGroupbox('RemoteFunctions'),
        Movement = Tabs.Main:AddLeftGroupbox('Movement'),
        Combat = Tabs.Main:AddLeftGroupbox('Combat'),
        Useless = Tabs.Useless:AddLeftGroupbox('Useless'),
        Debug = Tabs.Useless:AddLeftGroupbox('Debug'),
        Dodges = Tabs.Chars:AddLeftGroupbox('Passives'),
        Clones = Tabs.Chars:AddRightGroupbox('Clones'),
        Network = Tabs.Chars:AddRightGroupbox('Network Ownership'),
        Todoroki = Tabs.Chars:AddLeftGroupbox('Todoroki'),
        Gojo = Tabs.Chars:AddLeftGroupbox('Gojo'),
        Bakugo = Tabs.Chars:AddLeftGroupbox('Bakugo'),
        Raiden = Tabs.Chars:AddLeftGroupbox('Raiden'),
        Natsu = Tabs.Chars:AddLeftGroupbox('Natsu'),
        Sukuna = Tabs.Chars:AddRightGroupbox('Sukuna'),
        Deidara = Tabs.Chars:AddRightGroupbox('Mines'),
        Nanami = Tabs.Chars:AddRightGroupbox('Nanami'),
        Naruto = Tabs.Chars:AddRightGroupbox('Naruto/Minato'),
        Rukia = Tabs.Chars:AddRightGroupbox('Rukia'),
        Jojo = Tabs.Chars:AddLeftGroupbox('DIO/JOTARO/DOPPIO'),
        Stands = Tabs.Chars:AddLeftGroupbox('Stands'),
        ESP = Tabs.Useless:AddRightGroupbox('ESP'),
        Prestige = Tabs.Useless:AddRightGroupbox('Prestige'),
        MacroBuilder = Tabs.Macros:AddRightGroupbox('Builder'),
        Animations = Tabs.Animations:AddLeftGroupbox('Animation')
    };


    local function AddAction(input, ended)
        ended = ended or false
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            return ended and "m1:off" or "m1:on"
        end
        local suffix = ended and ":off" or ":on"
        if input.KeyCode then
            return input.KeyCode.Name .. suffix
        end
    end

    local RecordKeybind = "abc"
    local MacroConnections = {};
    local Recorded = {
        Character = 'ichigo',
        File = 'ichigo_1',
        Actions = {}
    };

    local function GetMacroFiles()
        if isfolder('stuffnstuff/ABA/Macros') then
            return listfiles('stuffnstuff/ABA/Macros') or {1}
        end
        return {}
    end

    local function WriteMacroFile()
        local DirPath = 'stuffnstuff/ABA/Macros/'
        if isfolder(DirPath) then
            writefile(DirPath..Recorded.File..'.txt', Recorded.Character.. '\n' .. HttpService:JSONEncode(Recorded.Actions))
        end
    end

    local function RecordCallback()
        if not Toggles.MacroRecord.Value then
            for _, conn in pairs(MacroConnections) do
                conn:Disconnect()
            end
            Options.MacroData:SetValue(HttpService:JSONEncode(Recorded.Actions))
            table.clear(MacroConnections)
            return
        end

        local LastTime = tick()
        local ActiveBinds = {}
        Recorded.Actions = {}
        

        MacroConnections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, isTyping)
            if isTyping then return end
            if input.KeyCode == RecordKeybind then return end
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 then
                local Now = tick()
                local Delay = string.format("%.5f", Now - LastTime)
                LastTime = Now

                if input.KeyCode then
                    ActiveBinds[input.KeyCode] = Now
                end

                table.insert(Recorded.Actions, "delay:" .. Delay)
                table.insert(Recorded.Actions, AddAction(input))
            end
        end)

        MacroConnections["InputEnded"] = UserInputService.InputEnded:Connect(function(input, isTyping)
            if isTyping then return end
            if input.KeyCode == RecordKeybind then return end
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 then
                local Now = tick()
                local Delay = string.format("%.5f", Now - LastTime)
                table.insert(Recorded.Actions, "delay:" .. Delay)
                LastTime = Now

                if input.KeyCode and ActiveBinds[input.KeyCode] then
                    table.insert(Recorded.Actions, AddAction(input, true))
                    ActiveBinds[input.KeyCode] = nil
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    table.insert(Recorded.Actions, "m1:off")
                end
            end
        end)
    end

    local function AddKeyPicker(Label)
        if not Toggles or not Toggles[Label] then return; end;
        Toggles[Label]:AddKeyPicker(Label .. 'KeyPicker',{
            Text = '',
            Default = 'N/A',
            Mode = 'Toggle',
            Callback = function()
                Toggles[Label]:SetValue(
                    not Toggles[Label].Value
                );
            end
        });
    end;

    local Animations = {};

    Groupboxes.Animations:AddInput('AnimationInput', {
        Default = 'rbxassetid://1',
        Numeric = false,
        Finished = true,

        Text = '',
        Tooltip = '',

        Placeholder = '...',
        Callback = function(New)
            if not Animations[New] then
                local Anim = Instance.new("Animation");
                Anim.AnimationId = New;
                Animations[New] = Anim;
            end;
        end;
    });

    Groupboxes.Animations:AddInput('AnimationSpeed', {
        Default = '1',
        Numeric = true,
        Finished = true,

        Text = 'Speed',
        Tooltip = '',

        Placeholder = '0',
    });

    local CurrentlyPlayingTrack;

    --// rbxassetid://6590059626

    Groupboxes.Animations:AddToggle('AnimationPlay', {
        Text = 'Play',
        Default = false,
        Tooltip ='',
        Callback = function()

            if not Toggles.AnimationPlay.Value then
                if CurrentlyPlayingTrack then
                    CurrentlyPlayingTrack:Stop();
                end;
                return;
            end;

            local Animation = Animations[Options.AnimationInput.Value];
            local Character = Player.Character;

            if not Character then return; end;
            if not Animation then return; end;

            local Humanoid = Character:FindFirstChild('Humanoid');

            if not Humanoid then return; end;

            local s, track = pcall(Humanoid.LoadAnimation, Humanoid, Animation);

            if track and s then
                CurrentPlayingTrack = track;
                track:Play();
                track:AdjustSpeed(tonumber(Options.AnimationSpeed.Value));
                
                track.Ended:Connect(function()
                    Toggles.AnimationPlay:SetValue(false);
                end);
            end;
        end;
    });

    AddKeyPicker('AnimationPlay')


    local PlayingMacro = false

    local function ReadInput(x)
        if PlayingMacro == true then return end
        PlayingMacro = true
        local actions = HttpService:JSONDecode(x)
        if not actions then return end

        for _, value in ipairs(actions) do
            if value:sub(1, 6) == "delay:" then
                task.wait(tonumber(value:sub(7)) or 0)
            else
                task.spawn(function()
                    if value == "m1:on" then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    elseif value == "m1:off" then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    elseif value:match(":on$") then
                        local key = value:gsub(":on$", "")
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    elseif value:match(":off$") then
                        local key = value:gsub(":off$", "")
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                    end
                end)
            end
        end
        PlayingMacro = false
    end


    local MacroCharacterHolder = Groupboxes.MacroBuilder:AddInput('MacroCharacter', {
        Default = 'Ichigo',
        Numeric = false,
        Finished = false,

        Text = 'Character',
        Tooltip = 'Character the macro will be used on',

        Placeholder = '...', -- placeholder text when the box is empty
        Callback = function(New)
            Recorded.Character = New;
        end;
    })

    local MacroNameHolder = Groupboxes.MacroBuilder:AddInput('MacroName', {
        Default = 'ichigo_1',
        Numeric = false,
        Finished = false,

        Text = 'File name',
        Tooltip = 'Name of the file',

        Placeholder = '...',
        Callback = function(New)
            Recorded.File = New;
        end;
    })

    Groupboxes.MacroBuilder:AddDivider();

    local MacroFileDropdown = Groupboxes.MacroBuilder:AddDropdown('MacroFiles', {
        Values = GetMacroFiles(),
        Default = 1,
        Multi = false,
        Text = 'Select File'
    })

    local MacroDataHolder = Groupboxes.MacroBuilder:AddInput('MacroData', {
        Default = '[]',
        Numeric = false,
        Finished = true,

        Text = 'Macro Data',
        Tooltip = 'Data for the macro',

        Placeholder = '...',
    });

    Groupboxes.MacroBuilder:AddButton('Import Macro', function()
        local ImportedMacroPath = MacroFileDropdown.Value
        if isfile(ImportedMacroPath) then
            local ImportedName = ImportedMacroPath:match("([^/\\]+)%.txt$")
            local ImportedMacroValue = readfile(ImportedMacroPath)
            local ImportedCharacter = ImportedMacroValue:match("^[^\r\n]+")
            ImportedMacroValue = ImportedMacroValue:match("^[^\n]*\n(.*)$")
            Options.MacroData.Value = ImportedMacroValue
            MacroDataHolder:SetValue(ImportedMacroValue)
            MacroNameHolder:SetValue(ImportedName)
            MacroCharacterHolder:SetValue(ImportedCharacter)
            Recorded.File = ImportedName
            Recorded.Actions = ImportedMacroValue
            Recorded.Character = ImportedCharacter
        end
    end):AddButton('Export Macro', function()
        WriteMacroFile()
        MacroFileDropdown:SetValues(GetMacroFiles())
        setclipboard(Options.MacroData.Value)
    end)

    Groupboxes.MacroBuilder:AddButton('Play Macro', function()
        ReadInput(
            Options.MacroData.Value
        )
    end)

    if Player.UserId ~= 4921746014 then
        Groupboxes.MacroBuilder:AddLabel('Play Macro Keybind'):AddKeyPicker('MacroPlayKeyPicker', {
            Default = 'N/A',
            SyncToggleState = false,
            Mode = 'Toggle',
            Text = 'Play Key',
            NoUI = true,
            Callback = function(Value)
                ReadInput(
                    Options.MacroData.Value
                )
            end
        })
    end

    Groupboxes.MacroBuilder:AddDivider();

    Groupboxes.MacroBuilder:AddToggle('MacroRecord', {
        Text = 'Record Inputs',
        Default = false,
        Tooltip = 'Recording',
        Callback = RecordCallback
    }):AddKeyPicker('MacroRecordKeyPicker', {
        Default = 'N/A',
        SyncToggleState = false,
        Mode = 'Toggle',
        Text = '',
        NoUI = true,
        Callback = function(Value)
            Toggles['MacroRecord']:SetValue(not Toggles['MacroRecord'].Value)
        end;
        ChangedCallback = function(New)
            print(New)
            RecordKeybind = New
        end
    })

    Groupboxes.MacroBuilder:AddDivider();

    local BindedMacros = {}

    for i = 1,5 do
        Groupboxes.MacroBuilder:AddLabel('Keybind '..i):AddKeyPicker('KeyPicker', {
            Default = 'N/A',
            SyncToggleState = false,
            Mode = 'Toggle',
            Text = '',
            NoUI = true,
            Callback = function()
                if BindedMacros[i] then 
                    ReadInput(BindedMacros[i])
                end
            end,
        })
    end

    Groupboxes.MacroBuilder:AddDivider();

    local SelectKeybindDropdown = Groupboxes.MacroBuilder:AddDropdown('KeybindDropdown', {
        Values = {1,2,3,4,5},
        Default = 1,
        Multi = false,
        Text = 'Select Keybind Slot'
    })

    Groupboxes.MacroBuilder:AddButton('Bind Macro Slot',function()
        BindedMacros[SelectKeybindDropdown.Value] = Recorded.Actions
    end)

    local SubwayHit = ReplicatedStorage:FindFirstChild('SubwayHit');
    local BecomeSnail = ReplicatedStorage:FindFirstChild('BecomeSnail');

    local function AntiSubway(Value)
        if Value then
            SubwayHit.Parent = game.ReplicatedFirst;
        else
            SubwayHit.Parent = ReplicatedStorage;
        end;
    end;

    local function AntiSnail(Value)
        if Value then
            BecomeSnail.Parent = game.ReplicatedFirst;
        else
            BecomeSnail.Parent = ReplicatedStorage;
        end;
    end;

    local function teleportEXE()
        TeleportService:Teleport(5240600335);
    end;


    local function getClosest()
        if not Player.Character or not Player.Character:FindFirstChild('HumanoidRootPart') then return; end
        local Coord = Player.Character:GetPivot();
        
        local Current, Distance=nil, 150; 

        for i,v in pairs(workspace.Live:GetChildren()) do
            
            if not v:FindFirstChild('Humanoid') or v:FindFirstChild('Humanoid').Health <= 0 then continue; end
            if not v:FindFirstChild('HumanoidRootPart') then continue; end
            if not Players:GetPlayerFromCharacter(v) then return; end;
            if v == Player.Character then continue; end

            if (v:GetPivot().Position-Coord.Position).Magnitude < Distance then
                Distance = (v:GetPivot().Position-Coord.Position).Magnitude;
                Current = v;
            end;
        end;
        return Current
    end;

    local function VisibilityCheck(Part)
        local _, IsVisible = Camera:WorldToScreenPoint(Part.Position);

        return IsVisible;
    end;

    local Numbers = {
        ["1"] = "One",
        ["2"] = "Two",
        ["3"] = "Three",
        ["4"] = "Four",
        ["5"] = "Five",
        ["6"] = "Six",
        ["7"] = "Seven",
        ["8"] = "Eight",
        ["9"] = "Nine",
        ["0"] = "Zero",
    }

    for Character, CharacterMacros in BuiltInMacros do
        local Groupbox = Tabs.Macros:AddLeftGroupbox(Character .. " Macros");
        for MacroIndex, MacroTable in CharacterMacros do
            Groupbox:AddLabel(MacroIndex):AddKeyPicker(MacroIndex .. 'KeyPicker', {
                Default = 'N/A',
                SyncToggleState = false,
                Mode = 'Toggle',
                Text = '',
                NoUI = true,
                Callback = function()
                    ReadInput(MacroTable.Actions)
                end,
            })
        end;
        task.wait()
    end

    local NoDodgeCDConnection;
    local BakugoConnection;
    local NatsuConnection;
    local TimestopConnection;
    local KiritsuguConnection;
    local KiritsuguCrasherConnection;
    local KiritsuguCrasherConnection2;

    local InfJumpConnection;
    local SpeedConnection;
    local FlyConnection;

    local ConfusionConnection;
    local NoAnimsConnection;

    local RaidenNoSniperConnection;
    local RaidenSkipModeConnection;
    local RocketObject;
    local RocketControlConnection;
    local RocketAddedControl;

    local SukunaMahoragaConnection;
    local SukunaAgitoConnection;

    local GrabObject;
    local GrabObjectConnection;
    local GrabObjectAddedConnection;

    local RasenganConnection;

    local FlyBodyVelocity;

    local CloneConnection;
    local CloneConnection2;

    local LockOnConnection;
    local TargetCycleConnection;

    local TodorokiDebuffConnection;
    local BlueConnection;

    local AutoDeidaraConnection;
    local AntiTobiConnection;
    local AntiRisottoConnection;
    local AntiRaidenConnection;

    local NanamiAuto2Connection;
    local NanamiAuto2Connection2;

    local NetworkApplyConnection;

    local StuffCounter = 0;
    local SelectionBox;

    local TargetUser;

    local AntiDownslamConnection1;
    local AntiDownslamConnection2;

    local function CreateAntiDownslam(vC)
        return vC.ChildAdded:Connect(function(v)
            if v.Name == 'GotSlammed' then
                local Velocity  = Instance.new('BodyVelocity',vC.PrimaryPart)
                Velocity.MaxForce = Vector3.new(0,math.huge,0)
                Velocity.P = 1250
                Velocity.Velocity = Vector3.new(0,140,0)
                Debris:AddItem(Velocity,0.2)
            end
        end)
    end

    local function AntiDownslamLoop()
        if not Toggles.AntiDownslam.Value then
            if AntiDownslamConnection1 then
                AntiDownslamConnection1:Disconnect();
            end;
            if AntiDownslamConnection2 then
                AntiDownslamConnection2:Disconnect();
            end;
            return;
        end;

        if Player.Character then
            AntiDownslamConnection1 = CreateAntiDownslam(Player.Character)
        end    

        AntiDownslamConnection2 = Player.CharacterAdded:Connect(function(vC)
            if AntiDownslamConnection1 then
                AntiDownslamConnection1:Disconnect()
            end
            AntiDownslamConnection1 = CreateAntiDownslam(vC)
        end)
    end;


    local HasProcessed = {};


    local function TargetCycle()
        if not Toggles.TargetCycle.Value then
            if TargetCycleConnection then
                TargetCycleConnection:Disconnect();
            end;
            if TargetUser then
                TargetUser = nil;
            end;
            return;
        end;
        local WaitUntilLoop = false;
        TargetCycleConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if not WaitUntilLoop then
                WaitUntilLoop = true;
                for _, v in workspace.Live:GetChildren() do
                    if v:IsA('Model') and v:FindFirstChild('Humanoid') and v ~= Player.Character and not (v:GetAttribute('KyokaSurpriseOnHit')) then
                        local TargetPlayer = Players:GetPlayerFromCharacter(v);
                        if Toggles.TargetCyclePlayerOnly.Value and (not TargetPlayer) then
                            return;
                        end;
                        if TargetPlayer then
                            if Toggles.TargetCycleTeamCheck.Value then
                                if Player.Team and Player.Team == TargetPlayer.Team then
                                    return;
                                end;
                            end;
                        end;
                        if v:FindFirstChild('Humanoid').Health > 0 then
                            TargetUser = v;
                            task.wait(.2);
                        end;
                    end;
                end;
                WaitUntilLoop = false;
            end;
        end));
    end;

    local function ESPCleanup(v)
        if v.Object then
            v.Object:Destroy();
        end;
        if v.Connection then
            v.Connection:Disconnect();
        end;
    end;

    local ESPConnections = {};
    local ESPStored = {};

    local function teamCheck(toCompare)
        if v.Team and toCompare.Team then
            return (v.Team == toCompare.Team);
        end;
        return false;
    end;

    local function getSecondModeValue(Plr)
        local val = Plr:FindFirstChild('SecondBar');
        if Plr:FindFirstChild('SungJinWooBar') then
            return Plr:FindFirstChild('SungJinWooBar'), Color3.fromRGB(53, 211, 255);
        end;
        if Plr:FindFirstChild('BrolyBar') then
            return Plr:FindFirstChild('BrolyBar');
        end;
        if Plr:FindFirstChild('GatesBar') then
            return Plr:FindFirstChild('GatesBar'), Color3.fromRGB(149, 0, 255);
        end;
        if Plr:FindFirstChild('PucciPieces') then
            return Plr:FindFirstChild('PucciPieces'), Color3.fromRGB(184, 143, 255);
        end;
        if Plr:FindFirstChild('AstaBar') then
            return Plr:FindFirstChild('AstaBar'), Color3.fromRGB(255, 48, 51);
        end;
        if Plr:FindFirstChild('RagnaBar') then
            return Plr:FindFirstChild('RagnaBar'), Color3.fromRGB(140, 180, 255);
        end;
        if Plr:FindFirstChild('RoomBar') then
            return Plr:FindFirstChild('RagnaBar'), Color3.fromRGB(116, 211, 255);
        end;
        if Plr:FindFirstChild('BloodBar') then
            return Plr:FindFirstChild('BloodBar'), Color3.fromRGB(57, 0, 0);
        end;
        if Plr.Character then
            local Char = Plr.Character;
            if Char:FindFirstChild('IndraArrowBar') then
                return Char:FindFirstChild('IndraArrowBar'), Color3.fromRGB(53, 28, 108);
            end;
            if Char:FindFirstChild('HamonMeter') then
                return Char:FindFirstChild('HamonMeter'), Color3.fromRGB(149, 149, 0);
            end;
        end;
        return val or nil;
    end;

    local function GrabSlot(v)
        for _, p in v:GetChildren() do
            if p.Name:match('Slot') then
                return p;
            elseif p.Name == 'M2Skill' then
                return {
                    Name = 'Slot5'
                };
            end;
        end;
    end;

    local function AttachESP(v)
        if ESPStored[v] then
            ESPCleanup(ESPStored[v]);
        end;
        local GUI = ESP_Gui:Clone();
        GUI.Parent = game.CoreGui;

        local Frame = GUI:FindFirstChild('Target');

        local Health = Frame.Health;
        local Mode = Frame.Mode;
        local Info = Frame.Info;
        local Moves = Frame.Moves;

        local Maka = Info.Maka;
        local BlackFlash = Info.BlackFlash;
        local Mahoraga = Info.Mahoraga;
        local Itachi = Info.Crow;
        local Boa = Info.Boa;
        local Iframe = Info.Iframe;
        local Nanami = Info.Nanami;
        
        local Ultimate = Mode.Ultimate;
        local Ultimate2 = Mode.Ultimate2;

        --//local StoredSlotCooldowns = {};

        local newConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if v.Character and v.Character:FindFirstChild('Humanoid') then
                local Root = v.Character:FindFirstChild('HumanoidRootPart');

                if v == Player then
                    GUI.Enabled = Toggles.ESPLP.Value;
                else
                    GUI.Enabled = Toggles.ESPENEMY.Value;
                end;

                if v.Team and Player.Team then
                    
                    if v.Team == Player.Team  and v ~= Player and Toggles.ESPTEAM.Value then
                        Frame.Visible = false;
                    else
                        Frame.Visible = true;
                    end;
                end;

                if not Root then return; end;
                if GUI.Adornee ~= Root then
                    GUI.Adornee = Root;
                end;

                local Backpack = v.Backpack;
                local SecondModeValue, BarColor2 = getSecondModeValue(v);
                local Charge = (v:FindFirstChild('Charge'));

                local Humanoid = v.Character:FindFirstChild('Humanoid');
                local CharacterPivot = v.Character:GetPivot();
                local CameraPivot = Camera.CFrame;

                local Distance = (CameraPivot.Position-CharacterPivot.Position).Magnitude;
                local NewSize = math.clamp((Distance/2)*Options.ESPMultiplier.Value , 20, 60);
                if not Toggles.ESPSCALE.Value then
                    NewSize = 20;
                end;

                Mode.Visible = Toggles.ESPULT.Value;
                Health.Visible = Toggles.ESPHP.Value;
                Moves.Visible = Toggles.ESPMOVES.Value;
                Info.Visible = Toggles.ESPINFO.Value;
                for _, Stroke in Frame:GetChildren() do
                    if Stroke:IsA('UIStroke') then
                        Stroke.Enabled = Toggles.ESPBOX.Value;
                    end;
                end;
                
                --// all other misc checks should be handled here
                local MakaValue = v:FindFirstChild('KishinEgg');
                local BlackFlashValue = v.Character:FindFirstChild('BlackFlashRequirement');
                local MahoragaValue = v.Character:FindFirstChild('WheelSpins');
                local ItachiCrowValue = v.Character:FindFirstChild('CrowClone');
                local IFrameValue = v.Character:FindFirstChild('i') or v.Character:FindFirstChild('ip');
                local RatioCounter = v.Character:GetAttribute('RatioCounter');

                local BoaTimer = v.Character:GetAttribute('CharmedAt');

                if MakaValue then
                    Maka.Visible = true;
                    Maka.AmountText.Text = tostring(MakaValue.Value);
                else
                    if Maka.Visible then
                        Maka.Visible = false;
                    end;
                end;

                if RatioCounter and RatioCounter > 0 then
                    Nanami.Visible = true;
                    Nanami.AmountText.Text = tostring(RatioCounter);
                else
                    if Nanami.Visible then
                        Nanami.Visible = false;
                    end;
                end;

                if IFrameValue then
                    Iframe.Visible = true;
                else
                    if Iframe.Visible then
                        Iframe.Visible = false;
                    end;
                end;

                if ItachiCrowValue then
                    Itachi.Visible = true;
                else
                    if Itachi.Visible then
                        Itachi.Visible = false;
                    end;
                end;

                if BoaTimer then
                    Boa.Visible = true;
                    Boa.AmountText.Text = string.format("%.1f", tostring((
                        tick() - BoaTimer
                    ) or 0));
                else
                    if Boa.Visible then
                        Boa.Visible = false;
                    end;
                end;

                if MahoragaValue then
                    Mahoraga.Visible = true;
                    Mahoraga.AmountText.Text = tostring(MahoragaValue.Value);
                else
                    if Mahoraga.Visible then
                        Mahoraga.Visible = false;
                    end;
                end;

                if BlackFlashValue then
                    BlackFlash.Visible = true;
                    BlackFlash.AmountText.Text = tostring(
                        math.floor(
                            (BlackFlashValue.Value/BlackFlashValue.MaxValue)*100
                        )
                    ) .. '%';
                else
                    if BlackFlash.Visible then
                        BlackFlash.Visible = false;
                    end;
                end;

                --//

                if not Backpack:FindFirstChild('M2Skill', true) then
                    if Moves:FindFirstChild('5') then
                        Moves:FindFirstChild('5').Visible = false;
                    end;
                end;

                for Index, Move: Configuration in Backpack:GetChildren() do
                    if Move:IsA('Configuration') then
                        local Config = Move:FindFirstChild('.Config');
                        if not Config then return; end;                    
                        local Slot = GrabSlot(Config);
                        local Slot_Index = (Slot and string.split(Slot.Name, 'Slot')[2]) or (Index-4);

                        
                        local MoveFrame = Moves:FindFirstChild(Slot_Index);
                        local InfoTag = MoveFrame.InfoTag;
                        MoveFrame.Visible = true;

                        local HunterData = {};

                        if Move.Name == 'Skill Hunter' then
                            if v.Character:FindFirstChild('SkillHunter') then
                                local Object = v.Character:FindFirstChild('SkillHunter');
                                HunterData.Name = Object:GetAttribute('Move');
                                HunterData.GuardBreaks = (Object:GetAttribute('Selected') == 'Guardbreak');
                            end;
                        end;

                        if Move:HasTag('Guardbreaks') or HunterData.GuardBreaks  then
                            InfoTag.Text = 'Guardbreaks';
                            InfoTag.Visible = true;
                        else
                            if InfoTag.Visible then
                                InfoTag.Visible = false;
                            end;
                        end;

                        MoveFrame.UIStroke.Thickness = 0

                        local TeamColor = Color3.fromRGB(223, 43, 43)
                        if v.Team then
                            TeamColor = v.TeamColor.Color
                        end

                        if v.Character:FindFirstChild('UsingSkill') then
                        local Skill = v.Character.UsingSkill
                        if Move.Name == Skill.Value then
                                TeamColor = Color3.fromRGB(255, 255, 255);
                            end;
                        end;

                        MoveFrame.DisableCover.Visible = true;

                        local FoundName = Move.Name;
                        if Move:FindFirstChild('NewName', true) then
                            FoundName = Move:FindFirstChild('NewName', true).Value;
                        end;

                        local NewSize = 1-(Move:GetAttribute('COOLDOWN') or 20)/20;

                        MoveFrame.DisableCover.Size = UDim2.fromScale(1, NewSize);

                        MoveFrame.ImageLabel.ImageColor3 = TeamColor
                        MoveFrame.TextLabel.Text = HunterData.Name or FoundName
                    end;
                end;


                if SecondModeValue then
                    Ultimate2.Visible = true;
                    Ultimate2.Bar.Size = UDim2.fromScale(SecondModeValue.Value/SecondModeValue.MaxValue, .78);
                    Ultimate2.Bar.BackgroundColor3 = BarColor2 or Color3.fromRGB(149, 0, 255);
                else
                    Ultimate2.Visible = false;
                end;
                BarColor = Color3.fromRGB(255, 0, 0);
                if v.Character:FindFirstChild('IfDied') then
                    BarColor = Color3.fromRGB(255, 255, 255);
                    if v.Character:FindFirstChild('SwordWeld', true) then
                        BarColor = Color3.fromRGB(164, 53, 255);
                    end;
                end;
                Ultimate.Bar.BackgroundColor3 = BarColor;
                Ultimate.Bar.Size = UDim2.fromScale(Charge.Value/Charge.MaxValue, .912);

                Health.Bar.Size = UDim2.fromScale(Humanoid.Health/Humanoid.MaxHealth, 1);

                GUI.Size = UDim2.fromScale(NewSize, NewSize);
            end;
        end));

        ESPStored[v] = {
            ['Object'] = GUI,
            ['Connection'] = newConnection
        };
    end;

    local function ESPToggle()
        if not Toggles.ESPToggle.Value then
            for i,v in ESPConnections do
                v:Disconnect();
            end;
            for _, v in ESPStored do
                ESPCleanup(v);
            end;
            return;
        end;
        for i,v in Players:GetPlayers() do
            AttachESP(v);
        end;
        ESPConnections['PlayerAdded'] = Players.PlayerAdded:Connect(AttachESP);
        ESPConnections['PlayerRemoved'] = Players.PlayerRemoving:Connect(function(v)
            if ESPStored[v] then
                ESPCleanup(ESPStored[v]);
            end;
        end);
    end;

    local function AutoDeidara()
        if not Toggles.AutoDeidara.Value then
            if AutoDeidaraConnection then
                AutoDeidaraConnection:Disconnect();
            end;
            return;
        end;

        AutoDeidaraConnection = workspace.Thrown.ChildAdded:Connect(function(Child)
            if Child.Name == 'Ball' and Child:WaitForChild('explode_1.wav',5) then
                if Player.Character then
                    task.wait(.5);
                    Child:WaitForChild('TouchInterest'):Destroy();
                    Child.Transparency = 0;
                end;
            end;
        end);
    end;

    local function Nanami2Process(Character)
        print('binding process');
        NanamiAuto2Connection = Character.ChildAdded:Connect(function(Value)
            if Value.Name == 'UsingSkill' and Value.Value == '7:3 Combo' then
                if not Toggles.NanamiAuto2.Value then return; end;
                local Input = Player.Backpack:FindFirstChild('Input', true);
                if not Input then return; end;
                local Target = getTarget();
                if not Target then return; end;
                for i = 1, 5 do
                    Input:FireServer(
                        'UseMove',
                        {
                            air = false,
                            neutral = true,
                            campos = Camera.CFrame.Position,
                            range = '2',
                            ToolName = '7:3 Combo',
                            camdir = Camera.CFrame.LookVector,
                            targ = Target,
                            teamtarg = Target,
                            mousehit = Mouse.Hit
                        }
                    );
                    
                    task.wait(.1);
                end;
            end;
        end);
    end;

    local function NanamiAuto2()
        if not Toggles.NanamiAuto2.Value then
            if NanamiAuto2Connection then
                NanamiAuto2Connection:Disconnect();
            end;
            if NanamiAuto2Connection2 then
                NanamiAuto2Connection2:Disconnect();
            end;
            return;
        end;
        if Player.Character then
            Nanami2Process(Player.Character);
        end;
        NanamiAuto2Connection2 = Player.CharacterAdded:Connect(Nanami2Process);
    end;


    local function AntiTobi()
        if not Toggles.AntiTobi.Value then
            if AntiTobiConnection then
                AntiTobiConnection:Disconnect();
            end;
            return;
        end;

        AntiTobiConnection = workspace.ChildAdded:Connect(function(Child)
            if Child.Name == 'ExplosiveTagTrap' then
                Child:WaitForChild('HB'):Destroy();
            end;
        end);
    end;

    local function AntiRaiden()
        if not Toggles.AntiRaiden.Value then
            if AntiRaidenConnection then
                AntiRaidenConnection:Disconnect();
            end;
            return;
        end;

        AntiRaidenConnection = workspace.ClearEachMatch.ChildAdded:Connect(function(Child)
            if Child.Name == 'Claymore' then
                Child:WaitForChild('TouchInterest'):Destroy();
                Child:WaitForChild('Toucher'):Destroy();
            end;
        end);
    end;


    local function AntiRisotto()
        if not Toggles.AntiRisotto.Value then
            if AntiRisottoConnection then
                AntiRisottoConnection:Disconnect();
            end;
            return;
        end;

        AntiRisottoConnection = workspace.Thrown.ChildAdded:Connect(function(Child)
            if Child.Name:match('Server') and Child:WaitForChild('TouchInterest', 3) then
                Child:WaitForChild('TouchInterest'):Destroy();
            end;
        end);
    end;



    local function ViewRisotto()
        if not Toggles.ViewRisotto.Value then
            if ViewRisottoConnection then
                ViewRisottoConnection:Disconnect();
            end;
            return;
        end;

        ViewRisottoConnection = workspace.Thrown.ChildAdded:Connect(function(Child)
            if Child.Name:match('Server') and Child:WaitForChild('TouchInterest', 3) then
                Child.Transparency = .5;
            end;
        end);
    end;

    local function ViewDeidara()
        if not Toggles.ViewDeidara.Value then
            if ViewDeidaraConnection then
                ViewDeidaraConnection:Disconnect();
            end;
            return;
        end;

        ViewDeidaraConnection = workspace.Thrown.ChildAdded:Connect(function(Child)
            if Child.Name == 'Ball' and Child:WaitForChild('explode_1.wav',5) then
                if Player.Character then
                    task.wait(.5);
                    Child.Transparency = 0;
                end;
            end;
        end);
    end;

    local Blacklisted = {
        'Tar',
        'DebreeePart2',
        'DebreePart',
        'LgnTrail',
        'Crown',
        'blackFlash'
    };

    local Forced = {
        'Ball',
        Player.Name .. 'Fire'
    };

    local function NetworkApply()
        if not Toggles.NetworkApply.Value then
            if NetworkApplyConnection then
                NetworkApplyConnection:Disconnect();
            end;
            return;
        end;
        NetworkApplyConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            for _, Model in workspace.Thrown:GetChildren() do
                Model = (Model:IsA('Model') and Model.PrimaryPart) or (Model:IsA('BasePart') and Model);
                if Model and (isnetworkowner(Model) and (not table.find(Blacklisted, Model.Name))) or table.find(Forced, Model.Name) then
                    if TargetUser and Toggles.NetworkTarget.Value then
                        Model:PivotTo(TargetUser:GetPivot());
                    elseif not TargetUser and Toggles.NetworkVoid.Value then
                        Model:PivotTo(CFrame.new(Vector3.new(0, 1e6, 0)));
                    end;
                    if not HasProcessed[Model.Name] then
                        HasProcessed[Model.Name] = true;
                        Model:GetPropertyChangedSignal('Parent'):Connect(function()
                            if Model.Parent == nil then
                                if HasProcessed[Model.Name] then
                                    HasProcessed[Model.Name] = nil;
                                end;
                            end;
                        end);
                    end;
                end;
            end;
        end))
    end;

    local function SukunaMahoraga()
        if not Toggles.SukunaMahoraga.Value then
            if SukunaMahoragaConnection then
                SukunaMahoragaConnection:Disconnect();
            end;
            local Mahoraga = workspace.Thrown:FindFirstChild('Mahoraga_' .. Player.Name);
            if Mahoraga then
                local MahoragaRoot = Mahoraga:FindFirstChild('HumanoidRootPart');
                if MahoragaRoot and Player.Character then
                    Mahoraga:PivotTo(Player.Character:GetPivot());
                end;
            end;
            return;
        end;
        SukunaMahoragaConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character then
                local Mahoraga = workspace.Thrown:FindFirstChild('Mahoraga_' .. Player.Name);
                if Mahoraga then
                    local MahoragaRoot = Mahoraga:FindFirstChild('HumanoidRootPart');
                    local MahoragaHumanoid = Mahoraga:FindFirstChild('Humanoid');
                    if MahoragaRoot and MahoragaHumanoid and MahoragaHumanoid.Health > 0 and isnetworkowner(MahoragaRoot) then
                        if TargetUser then
                            Mahoraga:PivotTo(TargetUser:GetPivot()*CFrame.new(Vector3.new(0,Options.MahoragaY.Value,Options.MahoragaZ.Value)));
                        end;
                    end;
                end;
            end;
        end));
    end;

    local function SukunaAgito()
        if not Toggles.SukunaAgito.Value then
            if SukunaAgitoConnection then
                SukunaAgitoConnection:Disconnect();
            end;
            local Mahoraga = workspace.Thrown:FindFirstChild('Agito_' .. Player.Name);
            if Mahoraga then
                local MahoragaRoot = Mahoraga:FindFirstChild('HumanoidRootPart');
                if MahoragaRoot and Player.Character then
                    Mahoraga:PivotTo(Player.Character:GetPivot());
                end;
            end;
            return;
        end;
        SukunaAgitoConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character then
                local Mahoraga = workspace.Thrown:FindFirstChild('Agito_' .. Player.Name);
                if Mahoraga then
                    local MahoragaRoot = Mahoraga:FindFirstChild('HumanoidRootPart');
                    local MahoragaHumanoid = Mahoraga:FindFirstChild('Humanoid');
                    if isnetworkowner(MahoragaRoot) then
                        print('is network owner');
                        if TargetUser then
                            Mahoraga:PivotTo(TargetUser:GetPivot()*CFrame.new(Vector3.new(0,Options.AgitoY.Value,Options.AgitoZ.Value)));
                        end;
                    end;
                end;
            end;
        end));
    end;

    local function VoidMahoraga() --// its void summons
        if not Toggles.VoidMahoraga.Value then
            if VoidMahoragaConnection then
                VoidMahoragaConnection:Disconnect();
            end;
            return;
        end;
        VoidMahoragaConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character then
                for i,v in workspace.Thrown:GetChildren() do
                    if (v.Name:match('Mahoraga_') or v.Name:match('Agito_')) and not Players:GetPlayerFromCharacter(v) and not v.Name:match(Player.Name) then
                        local MahoragaRoot = v:FindFirstChild('HumanoidRootPart');
                        if MahoragaRoot and isnetworkowner(MahoragaRoot) then
                            MahoragaRoot.Anchored = true;
                            MahoragaRoot.Position = Vector3.new(MahoragaRoot.Position.X, workspace.FallenPartsDestroyHeight,MahoragaRoot.Position.Z);
                            MahoragaRoot.Anchored = false;
                        end;
                    end;
                end;
            end;
        end));
    end;


    local function NoAnims()
        if not Toggles.NoAnims.Value then
            if NoAnimsConnection then
                NoAnimsConnection:Disconnect();
            end;
            return;
        end;
        NoAnimsConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character and Player.Character:FindFirstChild('Humanoid') then
                for i,v in Player.Character:FindFirstChild('Humanoid'):GetPlayingAnimationTracks() do
                    v:AdjustSpeed(0);
                    v:Stop();
                end;
            end;
        end));
    end

    local function GojoBlue()
        if not Toggles.GojoBlue.Value then
            if BlueConnection then
                BlueConnection:Disconnect();
            end;
            if Player.Character and Player.Character:FindFirstChild('BlueBuff') then
                Player.Character:FindFirstChild('BlueBuff'):Destroy();
            end;
            return;
        end;
        BlueConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character then
                if not Player.Character:FindFirstChild('BlueBuff') then
                    local newHighlight = Instance.new("Highlight", Player.Character);
                    newHighlight.FillTransparency = 1;
                    newHighlight.OutlineTransparency = 1;
                    newHighlight.OutlineColor = Color3.fromRGB(50, 50, 255);
                    newHighlight.Name = 'BlueBuff';
                end;
            end;
        end));
    end;

    local function RaidenSkipMode()
        if not Toggles.RaidenSkipMode.Value then
            if RaidenSkipModeConnection then
                RaidenSkipMode:Disconnect();
            end;
            return;
        end;
        RaidenSkipMode = Player.PlayerGui.ChildAdded:Connect(function(Child)
            if Child.Name == 'CodecGuiRaiden' then
                Child:WaitForChild('LocalCodec').Enabled = false;
                Child:WaitForChild('Over').OnClientInvoke = function()
                    task.wait(Options.RaidenSkipMode.Value or 0)
                    return;
                end;
                task.wait();
                Child:Destroy();
            end;
        end);
    end;

    local function RaidenNoSniper()
        if not Toggles.RaidenNoSniper.Value then
            if RaidenNoSniperConnection then
                RaidenNoSniperConnection:Disconnect();
            end;
            return;
        end;
        RaidenNoSniperConnection = Player.PlayerGui.ChildAdded:Connect(function(Child)
            if Child.Name == 'sniperGui' then
                task.wait(.1);
                local Character = Player.Character;
                Player.CameraMode = Enum.CameraMode.Classic;
                Camera.FieldOfView = 70;
                UserInputService.MouseIconEnabled = true;
                Player.CameraMinZoomDistance = 20;
                Character:WaitForChild('Humanoid').CameraOffset = Vector3.zero;
                UserInputService.MouseDeltaSensitivity = 1;
                Player.CameraMinZoomDistance = game.StarterPlayer.CameraMinZoomDistance;
                Child.Scope.Visible = false;
                Character:WaitForChild('DontMove', 9e9):Destroy();
            end;
        end);
    end;

    local function PickPrestige(name)
        for i,v in getgc() do
            if typeof(v)=='function' then
                local info = debug.getinfo(v);
                if info.currentline == 8 and info.source:match('PrestigePick') then
                    debug.setupvalue(v, 1, Player:FindFirstChild(name, true));
                end;
            end;
        end;
    end

    local function AntiConfusion()
        if not Toggles.AntiConfusion.Value then
            if ConfusionConnection then
                ConfusionConnection:Disconnect();
            end;
            return;
        end;
        ConfusionConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character and Player.Character:FindFirstChild('Confuse') then
                Player.Character:FindFirstChild('Confuse'):Destroy();
            end;
        end));
    end;

    local function TodorokiDebuff()
        if not Toggles.TodorokiDebuff.Value then
            if TodorokiDebuffConnection then
                TodorokiDebuffConnection:Disconnect();
                TodorokiDebuffConnection = nil;
            end;
            return;
        end;
        TodorokiDebuffConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character and Player.Character:FindFirstChild('TemperatureMeter') then
                Player.Character:FindFirstChild('TemperatureMeter').Value = 0;
            end;
        end));
    end;

    local function LockOnToggle()
        if not Toggles.LockOnToggle.Value then
            StuffCounter = 15;
            if SelectionBox then
                SelectionBox:Destroy();
                SelectionBox = nil;
            end;
            if LockOnConnection then
                LockOnConnection:Disconnect();
            end;
            return;
        end;
        LockOnConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if not Player.Character then
                doReturn = true;
            end;
            if not SelectionBox then
                SelectionBox = game.StarterGui:FindFirstChild('SelectionBox', true):Clone();
            end;
            if TargetUser then
                if TargetUser:FindFirstChild('Humanoid') and TargetUser:FindFirstChild('Humanoid').Health <= 0 then
                    if SelectionBox then
                        SelectionBox:Destroy();
                        SelectionBox = nil;
                        TargetUser = nil;
                    end;
                    return;
                end;
                SelectionBox.Parent = TargetUser;

                if Toggles.NoCircle.Value then
                    SelectionBox.Size = UDim2.fromScale(0, 0);
                end;

                SelectionBox.Enabled = true;
                if StuffCounter > 0 then
                    StuffCounter = math.clamp(StuffCounter - 1, 0, 15)
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.p, TargetUser:GetPivot().Position), 0.5);
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.p, TargetUser:GetPivot().Position);
                end;
            end;
        end));
    end;

    local function CloneEnabled()
        if not Toggles.CloneEnabled.Value then
            if CloneConnection then
                CloneConnection:Disconnect();
            end;
            if CloneConnection2 then
                CloneConnection2:Disconnect();
            end;
            return;
        end;
        CloneConnection = workspace.Live.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(Child)
            local newName = (string.match(Child.Name, ' ') and string.gsub(Child.Name, ' ', '')) or Child.Name;
            if Players:FindFirstChild(newName) and not Players:GetPlayerFromCharacter(Child) then
                local IsOurClone = (newName == Player.Name);
                local Root = Child:WaitForChild('HumanoidRootPart', true);
                task.wait(.1);
                if isnetworkowner(Root) then
                    if TargetUser and IsOurClone then
                        if Toggles.TeleportClones.Value then
                            for i = 1, 10 do
                                Child:PivotTo(TargetUser:GetPivot());
                                task.wait();
                            end;
                        end;
                    end;
                end;
            end;
        end));
        CloneConnection2 = workspace.Thrown.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(Child)
            local newName = (string.match(Child.Name, ' ') and string.gsub(Child.Name, ' ', '')) or Child.Name;
            if Players:FindFirstChild(newName) and not Players:GetPlayerFromCharacter(Child) then
                local IsOurClone = (newName == Player.Name);
                local Root = Child:WaitForChild('HumanoidRootPart', true);
                task.wait(1);
                if isnetworkowner(Root) then
                    if TargetUser and IsOurClone then
                        if Toggles.TeleportClones.Value then
                            for i = 1, 10 do
                                Child:PivotTo(TargetUser:GetPivot());
                                task.wait();
                            end;
                        end;
                    end;
                end;
            end;
        end));
    end;

    local function RocketController()
        if not Toggles.RocketController.Value then
            if RocketControlConnection then
                RocketControlConnection:Disconnect();
            end;
            if RocketAddedControl then
                RocketAddedControl:Disconnect();
            end;
            RocketObject = nil;
            return;
        end;
        RocketAddedControl = workspace.Thrown.ChildAdded:Connect(function(Child)
            if Child:IsA('BasePart') and Child.Name == 'Missile' and isnetworkowner(Child) then
                RocketObject = Child;
            end;
        end);
        RocketControlConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if RocketObject then
                local Velocity = RocketObject:FindFirstChildOfClass('BodyVelocity');
                if Velocity then
                    Velocity.Velocity = Camera.CFrame:VectorToWorldSpace(GetMoveVector() * Options.RocketSpeed.Value);
                end;
            end;
        end));
    end;

    local function Flyhack()
        if not Toggles.Flyhack.Value then
            if FlyBodyVelocity then
                FlyBodyVelocity:Destroy();
                FlyBodyVelocity = nil;
            end;
            if FlyConnection then
                FlyConnection:Disconnect();
            end;
            return;
        end;
        FlyBodyVelocity = Instance.new("BodyVelocity");
        FlyBodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9);

        FlyConnection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            if not Player.Character.HumanoidRootPart then
                return;
            end;
            local RootPart = Player.Character.HumanoidRootPart;

            local bv = RootPart:FindFirstChildOfClass("BodyVelocity")
            if bv and bv ~= FlyBodyVelocity then
                bv.Parent = nil;
            end;
            local Velocity = Camera.CFrame:VectorToWorldSpace(GetMoveVector() * Options.FlySpeed.Value)

            FlyBodyVelocity.Parent = RootPart;
            FlyBodyVelocity.Velocity = Velocity;
        end));
    end;


    local function Speedhack()
        if not Toggles.Speedhack.Value then
            if SpeedConnection then
                SpeedConnection:Disconnect();
            end;
            return
        end

        SpeedConnection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            if not Player.Character or not Player.Character:FindFirstChild('HumanoidRootPart') or not Player.Character:FindFirstChild('Humanoid') then
                return
            end;
            if Toggles.Flyhack.Value then
                return;
            end;
            local RootPart = Player.Character:FindFirstChild('HumanoidRootPart');
            local Humanoid = Player.Character:FindFirstChild('Humanoid');
            RootPart.Velocity = RootPart.Velocity * Vector3.new(0, 1, 0)
            if Humanoid.MoveDirection.Magnitude > 0 then
                RootPart.Velocity = RootPart.Velocity + Humanoid.MoveDirection.Unit * Options.Speedhack.Value
            end;
        end))
    end;


    local TpToVoidConnection;
    local TpToVoidOldCFrame;

    local function InfJump()
        if not Toggles.InfJump.Value then
            if InfJumpConnection then
                InfJumpConnection:Disconnect();
            end;
            return;
        end;
        InfJumpConnection = UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(Input, IsTyping)
            if Input.KeyCode == Enum.KeyCode.Space and (not IsTyping) then
                if not Player.Character then return; end;
                local HumanoidRootPart = Player.Character:FindFirstChild('HumanoidRootPart');
                if not HumanoidRootPart then return; end;
                while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
                    task.wait();
                    if not HumanoidRootPart:FindFirstChildWhichIsA('BodyVelocity') then
                        HumanoidRootPart.Velocity *= Vector3.new(1, 0, 1); --// thank u lycoris
                        HumanoidRootPart.Velocity += Vector3.new(0, Options.InfJump.Value, 0);
                    end;
                end;
            end;
        end));
    end;

    local function RasenganHitbox()
        if not Toggles.RasenganHitbox.Value then
            if RasenganConnection then
                RasenganConnection:Disconnect();
            end;
            return;
        end;
        RasenganConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character then

                for i,v in ({'Right Arm', 'Left Arm'}) do
                    if Player.Character:FindFirstChild(v) then
                        local Limb = Player.Character:FindFirstChild(v);
                        if Limb:WaitForChild('Handle') or Limb:WaitForChild('RasenganPart') then
                            local Handle = Limb:FindFirstChild('Handle') or Limb:WaitForChild('RasenganPart');
                            for _, Weld in Limb:GetChildren() do
                                if Weld:IsA('Weld') and (Weld.Part1 == Handle or Weld.Part0 == Handle) then
                                    Weld.C0 = CFrame.new(Vector3.new(Options.RasenganSizeX.Value,1.5 + Options.RasenganSizeY.Value, Options.RasenganSizeZ.Value));
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end));
    end;

    local function RasenganSize()
    end;

    local Passives = {
        ['Wuxian Dodges'] = 'WuxianDodge',
        ['Mob ??? Dodge'] = 'MobSoru',
        ['Geppo'] = 'ROKUSHIKI',
        ['Flashstep Dodge'] = 'Soru',
        ['MUI Dodge'] = 'UIDodge',
        ['Vigilante Float'] = 'FLOATPASSIVE',
        ['Raiden Dodge'] = 'FaceDodge',
        ['Yuta Dodge'] = 'YutaDodge'
    };

    for ButtonName, FolderName in Passives do

        local Temporary;
        local Object;

        local function Callback()
            if not Toggles[FolderName].Value then
                if Temporary then
                    Temporary:Disconnect();
                end;
                if Object then
                    Object:Destroy();
                    Object = nil;
                end;
                return;
            end;
            Temporary = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
                if not Player.Character then
                    return;
                end;
                if Player.Character:FindFirstChild(FolderName) then
                    return;
                end;
                if not Object or Object.Parent == nil then
                    Object = Instance.new("Folder");
                    Object.Name = FolderName;
                end;
                Object.Parent = Player.Character;
            end));
        end;

        Groupboxes.Dodges:AddToggle(FolderName, {
            Text = ButtonName,
            Default = false,
            Tooltip = 'Applies this effect',
            Callback = Callback
        })
    end;

    local function KiritsuguDodge()
        if not Toggles.Kiritsugu.Value then
            if KiritsuguConnection then
                KiritsuguConnection:Disconnect();
            end;
            if Player.Character:FindFirstChild('ACCEL') then
                Player.Character:FindFirstChild('ACCEL'):Destroy();
            end;
            return;
        end;
        KiritsuguConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if Player.Character then
                if not Player.Character:FindFirstChild('ACCEL') then
                    local NewValue = Instance.new("BoolValue");
                    NewValue.Name = 'ACCEL';
                    NewValue.Parent = Player.Character;
                end;
            end;
        end));
    end

    local function BakugoDodgeSpam()
        if not Toggles.BakugoAura.Value then
            if BakugoConnection then
                BakugoConnection:Disconnect();
            end;
            return;
        end;
        local s = false;
        BakugoConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if s then return; end;
            s = true;
            if Player.Character and Player.Character:FindFirstChild('ExplodDodge') then
                dodge({
                    explod = Enum.KeyCode.W
                })
            end;
            task.wait();
            s = false;
        end));
    end;

    local function NatsuDodgeSpam()
        if not Toggles.NatsuAura.Value then
            if not NatsuConnection then return; end;
            NatsuConnection:Disconnect();
            return;
        end;
        local s = false;
        NatsuConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            if s then return; end;
            s = true;
            if Player.Character and Player.Character:FindFirstChild('NatsuTP') then
                dodge({
                    pos = Player.Character:GetPivot()
                })
            end;
            task.wait(.2);
            s = false;
        end));
    end;

    local function TimestopSpam()
        if not Toggles.TSSpam.Value and TimestopConnection then
            return;
        end;
        coroutine.wrap(LPH_NO_VIRTUALIZE(function()
            while Toggles.TSSpam.Value do
                if Player.Character then
                    local Char = Player.Character;
                    if (Char:FindFirstChild('JotaroTP') or Char:FindFirstChild('KKTP')) then
                        dodge({
                            pos = Char:GetPivot(), 
                            newpos = Char:GetPivot(), 
                            tpos = Char.Torso:GetPivot(), 
                        });
                    end;
                end;
                task.wait(.1);
            end;
        end))();
    end;

    local AT = nil;
    local function AttachToBlacks()
        if (not Toggles.ATB.Value) then
            if AT then AT=nil; end
            if AttachToBack then
                AttachToBack:Disconnect();
            end;
            return;
        end

        AttachToBack = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(delta)
            if not AT then
                AT = getClosest(false);
            end;

            if not Player.Character or not Player.Character:FindFirstChild('HumanoidRootPart') or not Player.Character:FindFirstChild('Humanoid') or Player.Character:FindFirstChild('Humanoid').Health <= 0 then
                return;
            end;
            local Root = Player.Character:FindFirstChild('HumanoidRootPart');
            if not AT then return; end;
            local Pos = AT:GetPivot();
            Root.CFrame = Root.CFrame:lerp(Pos*CFrame.new(0,Options.AttachToBackHeight.Value,Options.AttachToBackRange.Value),0.1);
        end));
    end;

    local RaidenBladeModeConnection;
    local CurrentPreview;


    

    local function RaidenBladeMode()
        if not Toggles.RaidenBladeMode.Value then
            if RaidenBladeModeConnection then
                RaidenBladeModeConnection:Disconnect();
                CurrentPreview = nil;
            end;
            return;
        end;
        RaidenBladeModeConnection = RunService.RenderStepped:Connect(function()
            CurrentPreview = CurrentPreview or workspace.Thrown:FindFirstChild('BladePreview');
            if CurrentPreview then
                if TargetUser then
                    local TargetHum = TargetUser:FindFirstChild('Humanoid');

                    if TargetHum then

                    --[[ if TargetHum.Health <= 50 then
                            Preview:PivotTo(TargetUser.Head:GetPivot()*CFrame.new(Vector3.new(0, -.4, 0)));
                            return;
                        end;

                        if not TargetUser:FindFirstChild('NoM1ing') then
                            Preview:PivotTo(
                                TargetUser['Right Arm']:GetPivot()*CFrame.new(Vector3.new(-.5, 0, 0))*CFrame.Angles(0, 0, math.rad(85))
                            )
                            return;
                        end;

                        if not TargetUser:FindFirstChild('NoBlocking') then
                            Preview:PivotTo(
                                TargetUser['Left Arm']:GetPivot()*CFrame.new(Vector3.new(.5, 0, 0))*CFrame.Angles(0, 0, math.rad(85))
                            );
                            return;
                        end;]]
                    end;
                end;
            end;
        end);
    end;

    local RukiaBankaiConnection;
    local Debounce = false;

    local function RukiaBankai()
        if not Toggles.RukiaBankai.Value then
            if RukiaBankaiConnection then
                RukiaBankaiConnection:Disconnect();
            end;
            Debounce = false;
            return;
        end;
        
        RukiaBankaiConnection = RunService.RenderStepped:Connect(function()
            if Player.Character and Player.Character:FindFirstChild('HumanoidRootPart') and not Debounce then
                if Player.Character.HumanoidRootPart:FindFirstChild('RukiaBankai') then
                    Debounce = true;
                    task.wait(4);
                    Player.Character:BreakJoints();
                    task.wait(3);
                    Debounce = false;
                end;
            end;
        end);
    end;

    Groupboxes.Rukia:AddToggle('RukiaBankai', {
        Text = 'Bankai Reset',
        Default = false,
        Tooltip = '',
        Callback = RukiaBankai
    });

    Groupboxes.Movement:AddToggle('Speedhack', {
        Text = 'Speedhack',
        Default = false,
        Tooltip = 'Character speed',
        Callback = Speedhack,
    });

    AddKeyPicker('Speedhack')

    Groupboxes.Movement:AddSlider('Speedhack', {
        Text = 'Speed',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Compact = false
    });

    Groupboxes.Movement:AddToggle('Flyhack', {
        Text = 'Flyhack',
        Default = false,
        Tooltip = 'Fly hack speed',
        Callback = Flyhack,
    });

    AddKeyPicker('Flyhack')

    Groupboxes.Movement:AddSlider('FlySpeed', {
        Text = 'FlySpeed',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Compact = false
    });

    Groupboxes.Movement:AddToggle('InfJump', {
        Text = 'Infinite jump',
        Default = false,
        Tooltip = 'Go up',
        Callback = InfJump,
    });

    AddKeyPicker('InfJump')

    Groupboxes.Movement:AddSlider('InfJump', {
        Text = 'Infinite Jump Speed',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Compact = false
    });

    Groupboxes.Movement:AddDivider();

    Groupboxes.Movement:AddToggle('RocketController', {
        Text = 'Rocket control',
        Default = false,
        Tooltip = 'Rocket control',
        Callback = RocketController,
    });

    Groupboxes.Movement:AddSlider('RocketSpeed', {
        Text = 'Rocket Speed',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Compact = false
    })

    AddKeyPicker('NoDodgeCD')

    Groupboxes.Bakugo:AddToggle('BakugoAura', {
        Text = 'Bakugo Dodge',
        Default = false,
        Tooltip = 'Spams the bakugo dodge',
        Callback = BakugoDodgeSpam,
    })

    AddKeyPicker('BakugoAura')

    Groupboxes.Nanami:AddToggle('NanamiAuto2', {
        Text = 'Nanami Auto 2',
        Default = false,
        Tooltip = 'Auto presses 2',
        Callback = NanamiAuto2,
    })

    AddKeyPicker('NanamiAuto2')

    Groupboxes.Todoroki:AddToggle('TodorokiDebuff', {
        Text = 'No defrost',
        Default = false,
        Tooltip = 'Removes the need to defrost',
        Callback = TodorokiDebuff
    })

    AddKeyPicker('TodorokiDebuff')

    Groupboxes.Gojo:AddToggle('GojoBlue', {
        Text = 'Permanent blue buff',
        Default = false,
        Tooltip = 'Gives you the dodge benefits of blue',
        Callback = GojoBlue
    })

    AddKeyPicker('GojoBlue')


    Groupboxes.Natsu:AddToggle('NatsuAura', {
        Text = 'Natsu Dodge [MODE]',
        Default = false,
        Tooltip = 'Spams the natsu dodge',
        Callback = NatsuDodgeSpam,
    })

    AddKeyPicker('NatsuAura')

    Groupboxes.Jojo:AddToggle('TSSpam', {
        Text = 'Timestop spam',
        Default = false,
        Tooltip = 'Spams timestop dodges (their effects will be spammed on nearby players)',
        Callback = TimestopSpam,
    })

    AddKeyPicker('TSSpam')

    Groupboxes.Miscellaneous:AddButton({
        Text = 'Quick Reset',
        Func = function()
            Player.Character:BreakJoints()
        end,
        Tooltip = 'doesnt take mode'
    })

    Groupboxes.Miscellaneous:AddToggle('APBreaker', {
        Text = 'AP Breaker [SEMI-BLATANT]',
        Default = false,
        Tooltip = '',
        Callback = APBreaker
    })

    Groupboxes.Removals:AddToggle('AntiBlind', {
        Text = 'Anti solar flare blind',
        Default = false,
        Tooltip = 'anti blind mechanics'
    })

    Groupboxes.Removals:AddToggle('AntiPools', {
        Text = 'Anti Akainu and Gray pools',
        Default = false,
        Tooltip = '',
        Callback = AntiPools,
    })

    Groupboxes.Removals:AddToggle('AntiGiorno', {
        Text = 'Anti Giorno Flowers',
        Default = false,
        Tooltip = 'Prevents giorno flowers from stunning',
        Callback = AntiGiornoFlowers
    })

    Groupboxes.Removals:AddToggle('AntiSnail', {
        Text = 'Anti Snail',
        Default = false,
        Tooltip = 'Prevents weather report snail',
        Callback = AntiSnail
    })

    Groupboxes.Dodges:AddToggle('Kiritsugu', {
        Text = 'Kiritsugu dodges',
        Default = false,
        Tooltip = 'Prevents weather report snail',
        Callback = KiritsuguDodge
    })

    AddKeyPicker('Kiritsugu')

    Groupboxes.Removals:AddToggle('AntiSubway', {
        Text = 'Anti Subway',
        Default = false,
        Tooltip = 'Prevents subway from damaging you',
        Callback = AntiSubway
    })

    Groupboxes.Removals:AddToggle('AntiConfusion', {
        Text = 'Anti Confusion',
        Default = false,
        Tooltip = 'Prevents confusion effects',
        Callback = AntiConfusion
    })

    Groupboxes.Combat:AddToggle('AutoBlackFlash', {
        Text = 'Auto black flash',
        Default = false,
        Tooltip = 'Auto black flash check',
    });

    AddKeyPicker('AutoBlackFlash')

    Groupboxes.Combat:AddToggle('AutoNanami', {
        Text = 'Auto nanami black flash',
        Default = false,
        Tooltip = 'Auto nanami black flash check',
    });

    AddKeyPicker('AutoNanami')

    Groupboxes.Combat:AddToggle('NanamiProbability', {
        Text = 'Probability Toggle',
        Default = false,
        Tooltip = 'chance',
    });

    Groupboxes.Combat:AddSlider('NanamiProbability', {
        Text = 'Probability',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Compact = false
    });

    Groupboxes.Combat:AddToggle('VisibilityCheck', {
        Text = 'Visibility check',
        Default = false,
        Tooltip = 'checks if its present on screen',
    });


    Groupboxes.Combat:AddToggle('AutoKokushibo', {
        Text = 'Auto kokushibo check',
        Default = false,
        Tooltip = 'Auto does kokushibo moons',
    });

    AddKeyPicker('AutoKokushibo')

    Groupboxes.Combat:AddToggle('AutoTengen', {
        Text = 'Auto tengen osu',
        Default = false,
        Tooltip = 'Auto does tengen string performance',
    });

    AddKeyPicker('AutoTengen')

    Groupboxes.Combat:AddDivider();

    Groupboxes.Useless:AddButton({
        Text = 'Gon exe',
        Func = teleportEXE,
        DoubleClick = true,
        Tooltip = 'teleports u to gon exe'
    });

    Groupboxes.Useless:AddDivider();


    Groupboxes.Useless:AddButton({
        Text = 'Grab item',
        Func = function()
            if not Player.Character then return; end;
            local StartPivot = Player.Character:GetPivot();
            if workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('ItemSpawns') then
                for _, Spawner in workspace.Map:FindFirstChild('ItemSpawns'):GetChildren() do
                    if Spawner:FindFirstChild('Empty') and not Spawner.Empty.Value then
                        Player.Character:PivotTo(Spawner:GetPivot());
                        task.wait(.3);
                        break;
                    end;
                end;
            end;
            Player.Character:PivotTo(StartPivot);
        end,
        DoubleClick = true,
        Tooltip = 'teleports u to item'
    });

    Groupboxes.Useless:AddToggle('StreamerMode', {
        Text = 'Streamer mode',
        Default = false,
        Tooltip = 'conceals users',
        Callback = StreamerModeCallback
    });

    Groupboxes.Useless:AddDropdown('Platform', {
        Values = { 'Keyboard' , 'Mobile', 'Controller'},
        Default = 1,
        Multi = false,
        Text = 'Spoof Platform',
        Callback = function(Value)
            ReplicatedStorage.Platform:FireServer(Value);
        end
    })

    Player:GetAttributeChangedSignal('Platform'):Connect(function()
        if Library.Unloaded then return; end;
        ReplicatedStorage.Platform:FireServer(Options.Platform.Value or 'Keyboard');
    end);


    local PeePee = 'Tokita Ohma'

    Groupboxes.Prestige:AddDropdown('CharacterSelect', {
        Values = { 'Tokita Ohma', 'Zenitsu', 'Shisui', 'Tobi', 'Satsuki Kiryuin', 'Achilles', 'Zamasu [Fused]', 'Super Dummy', 'Hercule Satan', 'Shadow DIO', 'Mr President'},
        Default = 1,
        Multi = false,
        Text = 'Select Character',
        Callback = function(Value)
            PeePee = Value
        end
    })

    Groupboxes.Prestige:AddDivider()

    Groupboxes.Prestige:AddButton({
        Text = 'Pick Prestige',
        Func = function()
            PickPrestige(PeePee)
        end,
        Tooltip = 'MUST HAVE PRESTIGE GUI OPEN'
    })


    Groupboxes.Combat:AddToggle('HitboxExtender', {
        Text = 'Hitbox extender',
        Default = false,
        Tooltip = 'Extends size on hitboxes such as pools, etc',
    });

    AddKeyPicker('HitboxExtender')

    Groupboxes.Combat:AddSlider('HitboxSize', {
        Text = 'Hitbox multiplier',
        Default = 50,
        Min = 1,
        Max = 75,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Combat:AddDivider();

    Groupboxes.Combat:AddToggle('LockOnToggle', {
        Text = 'Lock on',
        Default = false,
        Tooltip = 'Enables lock on similar to console',
        Callback = LockOnToggle
    })

    AddKeyPicker('LockOnToggle')

    Groupboxes.Combat:AddToggle('SilentLock', {
        Text = 'No notifications',
        Default = false,
        Tooltip = 'Disables lock on notifications',
    })

    Groupboxes.Combat:AddToggle('NoCircle', {
        Text = 'No lock on circle',
        Default = false,
        Tooltip = 'Disables lock on circle',
    })


    Groupboxes.Combat:AddToggle('TargetCycle', {
        Text = 'Cycles targets between anyone on the map',
        Default = false,
        Tooltip = 'do not use lock on',
        Callback = TargetCycle
    })

    AddKeyPicker('TargetCycle')

    Groupboxes.Combat:AddToggle('TargetCycleTeamCheck', {
        Text = 'Target team check',
        Default = false,
        Tooltip = 'Filters teams based on target cycle'
    })

    Groupboxes.Combat:AddToggle('TargetCyclePlayerOnly', {
        Text = 'Target cycles between exclusively players',
        Default = false,
        Tooltip = 'Filters players based on target cycle'
    })


    Groupboxes.Combat:AddLabel('Target Key'):AddKeyPicker('TargetKeybind', {
        Default = 'T',
        NoUI = false,
        Text = "",
        ChangedCallback = function(NewKey)
            getgenv().AfterKey = NewKey.Name;
        end
    });

    Groupboxes.Combat:AddToggle('NoAnims', {
        Text = 'No anims',
        Default = false,
        Tooltip = 'Removes animations',
        Callback = NoAnims
    });


    Groupboxes.ATB:AddToggle('ATB', {
        Text = 'Attach to back',
        Default = false,
        Tooltip = 'Attaches to nearest player based on an offset',
        Callback = AttachToBlacks,
    })

    AddKeyPicker('ATB')

    Groupboxes.ATB:AddSlider('AttachToBackHeight', {
        Text = 'Attach to back height',
        Default = 0,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.ATB:AddSlider('AttachToBackRange', {
        Text = 'Attach to back X offset',
        Default = 0,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.RemoteFunctions:AddToggle('GetPartCFrame', {
        Text = 'GetPartCFrame Manipulation',
        Default = false,
        Tooltip = 'Allows for altering behavior',
    });

    Groupboxes.RemoteFunctions:AddToggle('TargetPartCFrame', {
        Text = 'Sets a target to always return',
        Default = false,
        Tooltip = 'Allows for cross map black flash',
    });

    Groupboxes.RemoteFunctions:AddSlider('PartCFrameDelay', {
        Text = 'Delay',
        Default = 0,
        Min = 0,
        Max = 30,
        Rounding = 1,
        Compact = false
    });

    Groupboxes.Clones:AddToggle('CloneEnabled', {
        Text = 'Clone exploits',
        Default = false,
        Tooltip ='Makes everything below apply when clones are spawned',
        Callback = CloneEnabled
    });

    Groupboxes.Clones:AddToggle('VoidClones', {
        Text = 'Void clones',
        Default = false,
        Tooltip ='Attempts to void clones which arent yours',
    });

    Groupboxes.Clones:AddToggle('TeleportClones', {
        Text = 'Teleport clones',
        Default = false,
        Tooltip ='Teleports clones as soon as you get ownership',
    });

    Groupboxes.Raiden:AddToggle('RaidenSkipMode', {
        Text = 'Raiden mode delay',
        Default = false,
        Tooltip ='Delays your mode',
        Callback = RaidenSkipMode
    });

    Groupboxes.Raiden:AddSlider('RaidenSkipMode', {
        Text = 'Delay',
        Default = 0,
        Min = 0,
        Max = 15,
        Rounding = 1,
        Compact = false
    });


    Groupboxes.Raiden:AddToggle('RaidenNoSniper', {
        Text = 'Raiden sniper',
        Default = false,
        Tooltip ='Makes the raiden sniper not zoom in and allows you to move during',
        Callback = RaidenNoSniper
    });

    Groupboxes.Raiden:AddToggle('RaidenBladeMode', {
        Text = 'MGR Raiden Auto Chop',
        Default = false,
        Tooltip ='',
        Callback = RaidenBladeMode
    });

    Groupboxes.Sukuna:AddToggle('SukunaMahoraga', {
        Text = 'Mahoraga assist',
        Default = false,
        Tooltip ='Teleports mahoraga behind current target',
        Callback = SukunaMahoraga
    });

    Groupboxes.Sukuna:AddToggle('SukunaAgito', {
        Text = 'Agito assist',
        Default = false,
        Tooltip ='Teleports agito behind current target',
        Callback = SukunaAgito
    });

    Groupboxes.Sukuna:AddSlider('MahoragaY', {
        Text = 'Mahoraga Offset Y',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Sukuna:AddSlider('MahoragaZ', {
        Text = 'Mahoraga Offset Z',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Sukuna:AddSlider('AgitoY', {
        Text = 'Agito Offset Y',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Sukuna:AddSlider('AgitoZ', {
        Text = 'Agito Offset Z',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Sukuna:AddToggle('VoidMahoraga', {
        Text = 'Mahoraga void',
        Default = false,
        Tooltip ='Voids other players sukuna summons',
        Callback = VoidMahoraga
    });

    Groupboxes.Naruto:AddToggle('RasenganHitbox', {
        Text = 'Rasengan size',
        Default = false,
        Tooltip ='Increases rasengan size',
        Callback = RasenganHitbox
    })

    Groupboxes.Naruto:AddSlider('RasenganSizeX', {
        Text = 'Offset X',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Naruto:AddSlider('RasenganSizeY', {
        Text = 'Offset Y',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Naruto:AddSlider('RasenganSizeZ', {
        Text = 'Offset Z',
        Default = 1,
        Min = -20,
        Max = 20,
        Rounding = 1,
        Compact = false
    })

    Groupboxes.Miscellaneous:AddToggle('AntiDownslam', {
        Text = 'Anti Downslam',
        Default = false,
        Tooltip = 'fakes downslam glitch and flings u up when u get slammed',
        Callback = AntiDownslamLoop
    })

    AddKeyPicker('AntiDownslam')

    Groupboxes.ESP:AddToggle('ESPToggle', {
        Text = 'ESP',
        Default = false,
        Tooltip ='Extra sensory perception',
        Callback = ESPToggle
    });

    AddKeyPicker('ESPToggle')

    Groupboxes.ESP:AddToggle('ESPHP', {
        Text = 'ESP Healthbar',
        Default = false,
        Tooltip ='Healthbar',
    });

    Groupboxes.ESP:AddToggle('ESPULT', {
        Text = 'ESP Ultimates',
        Default = false,
        Tooltip ='Ultimate bars',
    });

    Groupboxes.ESP:AddToggle('ESPMOVES', {
        Text = 'ESP Moves',
        Default = false,
        Tooltip ='Moves',
    });

    Groupboxes.ESP:AddToggle('ESPINFO', {
        Text = 'ESP Info',
        Default = false,
        Tooltip ='Gimmicks',
    });

    Groupboxes.ESP:AddToggle('ESPLP', {
        Text = 'ESP Local Player',
        Default = false,
        Tooltip ='ESP targets local player',
    });

    Groupboxes.ESP:AddToggle('ESPENEMY', {
        Text = 'ESP others',
        Default = true,
        Tooltip ='ESP targets others',
    });

    Groupboxes.ESP:AddToggle('ESPTEAM', {
        Text = 'ESP Team check',
        Default = false,
        Tooltip ='ESP only targets players not on your team',
    });

    Groupboxes.ESP:AddToggle('ESPSCALE', {
        Text = 'ESP Scaling',
        Default = true,
        Tooltip ='ESP Scaling',
    });


    Groupboxes.ESP:AddToggle('ESPBOX', {
        Text = 'ESP Box',
        Default = false,
        Tooltip ='Box around the player',
    });

    Groupboxes.ESP:AddSlider('ESPMultiplier', {
        Text = 'Size scaling',
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Compact = false
    });

    Groupboxes.Deidara:AddToggle('AutoDeidara', {
        Text = 'Anti deidara',
        Default = false,
        Tooltip ='nigga',
        Callback = AutoDeidara
    })

    Groupboxes.Deidara:AddToggle('AntiRaiden', {
        Text = 'Anti raiden',
        Default = false,
        Tooltip ='nigga',
        Callback = AntiRaiden
    })

    Groupboxes.Deidara:AddToggle('AntiTobi', {
        Text = 'Anti tobi',
        Default = false,
        Tooltip ='nigga',
        Callback = AntiTobi
    });

    Groupboxes.Deidara:AddToggle('AntiRisotto', {
        Text = 'Anti Risotto',
        Default = false,
        Tooltip ='nigga',
        Callback = AntiRisotto
    })

    Groupboxes.Deidara:AddDivider();

    Groupboxes.Deidara:AddToggle('ViewDeidara', {
        Text = 'Deidara unhide',
        Default = false,
        Tooltip ='nigga',
        Callback = ViewDeidara
    });

    Groupboxes.Deidara:AddToggle('ViewRisotto', {
        Text = 'Risotto unhide',
        Default = false,
        Tooltip ='nigga',
        Callback = ViewRisotto
    })

    Groupboxes.Network:AddToggle('NetworkApply', {
        Text = 'Apply effects',
        Default = false,
        Tooltip ='nigga',
        Callback = NetworkApply
    })

    Groupboxes.Network:AddToggle('NetworkTarget', {
        Text = 'Teleport to Target',
        Default = false,
        Tooltip ='nigga',
    })

    Groupboxes.Network:AddToggle('NetworkVoid', {
        Text = 'Void projectiles',
        Default = false,
        Tooltip ='nigga',
    })

    Connections['ThrownAdded'] = workspace.Thrown.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(Child)
        task.wait();
        if Child:IsA('BasePart') and Child:FindFirstChild('TouchInterest') then
            if Toggles.HitboxExtender.Value then
                coroutine.wrap(function()
                    local OriginalSize = Child.Size;
                    for i = 1,10 do
                        Child.CanCollide = false;
                        Child.Size = OriginalSize * Options.HitboxSize.Value;
                        task.wait(.1);
                    end;
                end)();
            end;
        end;
        if (Child.Name == 'LavaPool' or Child.Name == 'GrayFloor') and Toggles.AntiPools.Value then
            Child:WaitForChild('TouchInterest'):Destroy();
        elseif Child:IsA('BasePart') and (Child.Name == 'Existing' or Child.Name:match('Flower')) and Toggles.AntiGiorno.Value then
            Child:WaitForChild('TouchInterest'):Destroy();
        end;
    end));



    ReplicatedStorage.NanamiCheck.OnClientInvoke = LPH_NO_VIRTUALIZE(function(Target, TimeDur, User)
        local TempGUI = ReplicatedStorage.NanamiCutGUI:Clone();
        TempGUI.MainBar.Rotation = -80;
        TempGUI.Parent = Live[Target.Name].HumanoidRootPart;
        TempGUI.Adornee = Live[Target.Name].HumanoidRootPart;
        local MainBar = TempGUI.MainBar;
        local Cutter = MainBar.Cutter;
        local Temp1,Temp2,Temp3 = false,false,false
        local InputConnection = UserInputService.InputBegan:Connect(function(InputObject)
            if not Temp1 then
                if InputObject.UserInputType == Enum.UserInputType.MouseButton1 or InputObject.KeyCode == Enum.KeyCode.ButtonB then
                    if Temp2 then
                        Temp3 = true;
                        return;
                    end;
                    Temp1 = true;
                end;
            end;
        end);
        
        local Counter = .005;
        local Time = 0;
        while Counter < 1 and (User:GetAttribute('NANAMIAIM') and not (Temp3 or Temp1)) do
            local Timed = task.wait();
            local Division = Timed / TimeDur;
            local Difference = math.abs(.7 - Counter);

            if Counter < .7 then
                MainBar.Rotation = Counter/.7*80-80;
            else
                MainBar.Rotation = 0;
            end;
            if Difference < .025 then
                Division = Division / 8;
            elseif Difference < .05 then
                Division = Division / 4;
            end;
            Counter = Counter + Division;
            Cutter.Position = UDim2.fromScale(Counter, .5);
            if Difference < .02 then
                Temp2 = true;
                if Toggles.AutoNanami.Value then
                    
                    local Break = false;
                    local Rolled = math.random(1, 100);
                    if Toggles.NanamiProbability.Value then
                        if Rolled > Options.NanamiProbability.Value then
                            Break = true;
                            Temp3 = false;
                        end;
                    end;
                    if Toggles.VisibilityCheck.Value and not VisibilityCheck(TempGUI.Parent) then
                        Break = true;
                        Temp3 = false;
                    end;
                    if not Break then
                        Temp3 = true;
                    end;
                end;
            else
                Temp2 = false;
            end;
            if Temp2 then
                Time = Time + Timed;
            end;
        end;
        InputConnection:Disconnect();
        if Temp3 and User:GetAttribute('NANAMIAIM') then
            Cutter.Position = UDim2.fromScale(.7,.5);
            TweenService:Create(TempGUI, TweenInfo.new(.25), {['Size'] = UDim2.new(10,200,10,200)}):Play();
            Cutter.Size = UDim2.fromScale(.016, 12);
            TweenService:Create(Cutter, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
                ['Size'] = UDim2.fromScale(0, 24);
                ['BackgroundColor3'] = Color3.new(1,0,0);
                ['BackgroundTransparency'] = 1
            }):Play();
            local ColorCorrection = Instance.new("ColorCorrectionEffect", game.Lighting);
            ColorCorrection.TintColor = Color3.new(0,0,0);
            Debris:AddItem(ColorCorrection, .15);
        end;
        Debris:AddItem(TempGUI,.5);
        return table.unpack({Temp3, nil, true});
    end);

    local function AttachTengen(ScreenGui)
        if ScreenGui.Name == 'HUD' then
            ScreenGui.ChildAdded:Connect(function(Child)
                if Child.Name == 'KeysFrame' then
                    Child:WaitForChild('LocalScript', 9e9).Disabled = true;
                    game.ReplicatedStorage.OsuCheck.OnClientInvoke = function(p4, p5, p6, p_u_7, p_u_8)
                        local _ = p4 - p5
                        local v_u_9 = Child.Ring:Clone()
                        local v_u_10 = Child.Circle:Clone()
                        v_u_9.Name = "Img"
                        v_u_10.Name = "Img"
                        local v11 = Random.new()
                        v_u_10.Position = UDim2.new(v11:NextNumber(0, 1), 0, v11:NextNumber(0, 1), 0)
                        v_u_9.Position = v_u_10.Position
                        game.Debris:AddItem(v_u_10, p4 + p5 + 0.3)
                        game.Debris:AddItem(v_u_9, p4 + p5 + 0.3)
                        v_u_10:FindFirstChild("TextLabel").Text = p6
                        v_u_10.Visible = true
                        v_u_9.Visible = true
                        v_u_10.Parent = Child
                        v_u_9.Parent = Child
                        game.TweenService:Create(v_u_9, TweenInfo.new(p4, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                            ["Size"] = UDim2.new(0.158, 0, 0.187, 0),
                            ["Position"] = v_u_10.Position
                        }):Play()
                        local v12 = game:GetService("UserInputService")
                        local v_u_13 = false
                        local v_u_14 = false
                        local v_u_15 = false
                        local v17 = v12.InputBegan:Connect(function(p16)
                            -- upvalues: (ref) v_u_13, (copy) p_u_7, (copy) p_u_8, (ref) v_u_14, (ref) v_u_15, (copy) v_u_9, (copy) v_u_10
                            if not v_u_13 then
                                if p16.KeyCode == p_u_7 or p16.KeyCode == p_u_8 then
                                    v_u_15 = true
                                        task.spawn(function()
                                            -- upvalues: (ref) v_u_9, (ref) v_u_10
                                            game.TweenService:Create(v_u_9, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                                                ["ImageTransparency"] = 1,
                                                ["Size"] = UDim2.new(v_u_9.Size.X.Scale * 1.2, 0, v_u_9.Size.Y.Scale * 2, 0)
                                            }):Play()
                                            game.TweenService:Create(v_u_10, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                                                ["ImageTransparency"] = 1,
                                                ["Size"] = UDim2.new(v_u_10.Size.X.Scale * 1.2, 0, v_u_10.Size.Y.Scale * 2, 0)
                                            }):Play()
                                            v_u_10:FindFirstChild("TextLabel").Text = ""
                                            return true;
                                        end)
                                    v_u_13 = true
                                    task.spawn(function()
                                        -- upvalues: (ref) v_u_9, (ref) v_u_10
                                        v_u_9.ImageColor3 = Color3.new(1, 0.152941, 0.152941)
                                        v_u_10.ImageColor3 = Color3.new(1, 0.152941, 0.152941)
                                        game.TweenService:Create(v_u_9, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                                            ["ImageTransparency"] = 1,
                                            ["ImageColor3"] = Color3.new(1, 0.152941, 0.152941)
                                        }):Play()
                                        game.TweenService:Create(v_u_10, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                                            ["ImageTransparency"] = 1
                                        }):Play()
                                        v_u_10:FindFirstChild("TextLabel").Text = ""
                                        return true;
                                    end)
                                end
                            end
                        end)
                        wait(p4)
                        v_u_14 = true
                        wait(p5)
                        v_u_14 = false
                        v17:disconnect()
                        return (Toggles.AutoTengen.Value and true) or v_u_15;
                    end;
                end;
            end);
        end;
    end;

    if PlayerGui:FindFirstChild('HUD') then
        AttachTengen(PlayerGui.HUD);
    end;

    Connections['TengenAdded'] = PlayerGui.ChildAdded:Connect(AttachTengen);

    --[[
    Groupboxes.Debug:AddButton('Infinite Yield', function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source"))();
    end);

    Groupboxes.Debug:AddButton('Cobalt RSpy', function()
        loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))();
    end);]]

    ReplicatedStorage.GetPartCFrame.OnClientInvoke = LPH_NO_VIRTUALIZE(function(Object)
        local Pivot = Object.CFrame;
        if Toggles.GetPartCFrame.Value then
            if Toggles.TargetPartCFrame.Value then
                if TargetUser then
                    Pivot = TargetUser:GetPivot();
                end;
            end;
            task.wait(Options.PartCFrameDelay.Value or 0);
        end;
        return Pivot
    end);

    repeat
        task.wait()
    until Toggles

    local v_u_100 = {};

    game.ReplicatedStorage.KokushiboCheck.OnClientInvoke = LPH_NO_VIRTUALIZE(function(p101, p102)
        local v103 = p101 * 2
        local v104 = p102 * 2
        local v105 = v103 - v104
        local v_u_106 = game.ReplicatedStorage.FrenchKokushibo:Clone()
        for _, v107 in pairs(v_u_106:GetChildren()) do
            game.TweenService:Create(v107, TweenInfo.new(v105, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                ["Position"] = UDim2.new(v107.Position.X.Scale + math.random(1, 2) / 60 * (math.random(0, 1) == 0 and -1 or 1), 0, v107.Position.Y.Scale + math.random(1, 3) / 90 * (math.random(0, 1) == 0 and -1 or 1), 0)
            }):Play()
        end
        v_u_106.Parent = game.Players.LocalPlayer.PlayerGui
        local v108 = game:GetService("UserInputService")
        local v_u_109 = false
        local v_u_110 = false
        local v_u_111 = false
        local v_u_112 = tick()
        local v117 = v108.InputBegan:Connect(function(p113)
            -- upvalues: (ref) v_u_109, (ref) v_u_99, (ref) v_u_110, (ref) v_u_111, (ref) v_u_100, (copy) v_u_112, (copy) v_u_106
            if v_u_109 then
                return
            elseif not table.find({}, game.Players.LocalPlayer.UserId) then
                if p113.UserInputType == Enum.UserInputType.MouseButton2 or p113.KeyCode == Enum.KeyCode.DPadRight then
                    if v_u_110 then
                        v_u_111 = true
                        local v114 = v_u_100
                        local v115 = tick() - v_u_112
                        table.insert(v114, v115)
                        for _, v116 in pairs(v_u_106:GetChildren()) do
                            game.TweenService:Create(v116.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                ["Scale"] = 1.2
                            }):Play()
                            game.TweenService:Create(v116, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                ["ImageTransparency"] = 1
                            }):Play()
                            v116.ImageColor3 = Color3.new(0.345098, 0.847059, 1)
                        end
                        return
                    end
                    v_u_109 = true
                end
            end
        end)
        wait(v105)
        local v118 = tick()
        v_u_110 = true
        if v104 <= 0 then
            if v_u_106 then
                v_u_106:Destroy()
            end
            v117:disconnect()
            return false
        end
        wait(v104)
        for _, v120 in pairs(v_u_106:GetChildren()) do
            game:GetService('TweenService'):Create(v120, TweenInfo.new(v104, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                ["Rotation"] = v120.Rotation + 360
            }):Play()
        end
        v_u_110 = false
        if #v_u_100 > 3 then
            local v121 = -1
            for _, v122 in pairs(v_u_100) do
                if v118 == v122 then
                    v121 = v121 + 1
                end
            end
            if v121 >= 4 then
                --//game.Players.LocalPlayer:Kick()
            end
        end
        v117:Disconnect();
        v_u_111 = (Toggles.AutoKokushibo.Value and true) or v_u_111
        if not v_u_111 then
            for _, v124 in pairs(v_u_106:GetChildren()) do
                game.TweenService:Create(v124.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ["Scale"] = 0.6
                }):Play()
                game.TweenService:Create(v124, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ["ImageTransparency"] = 1
                }):Play()
            end
        end
        game.Debris:AddItem(v_u_106, 0.65)
        for _, v116 in pairs(v_u_106:GetChildren()) do
            if v116.ImageTransparency ~= 1 then
                game.TweenService:Create(v116.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ["Scale"] = 1.2
                }):Play()
                    game.TweenService:Create(v116, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ["ImageTransparency"] = 1
                }):Play()
                v116.ImageColor3 = Color3.new(0.345098, 0.847059, 1)
            end
        end
        return v_u_111;
    end);


    ReplicatedStorage.BlackFlashCheck.OnClientInvoke = LPH_NO_VIRTUALIZE(function(p90, p91) --// .285, 0
        local v92 = p90 - p91
        game.TweenService:Create(workspace.CurrentCamera, TweenInfo.new(v92, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
            ["FieldOfView"] = 6
        }):Play()
        local v93 = game:GetService("UserInputService")
        local v_u_94 = false
        local v_u_95 = false
        local v_u_96 = false
        local v98 = v93.InputBegan:Connect(function(p97)
            -- upvalues: (ref) v_u_94, (ref) v_u_95, (ref) v_u_96
            if not v_u_94 then
                if p97.UserInputType == Enum.UserInputType.MouseButton1 or p97.KeyCode == Enum.KeyCode.ButtonB then
                    if v_u_95 then
                        v_u_96 = true
                        return
                    end
                    v_u_94 = true
                end
            end
        end)
        wait(v92)
        v_u_95 = true
        if p91 <= 0 then
            workspace.CurrentCamera.FieldOfView = 70
            task.spawn(function()
                wait(0.1)
                workspace.CurrentCamera.FieldOfView = 70
            end)
            v98:disconnect()
            return false
        end
        game.TweenService:Create(workspace.CurrentCamera, TweenInfo.new(p91), {
            ["FieldOfView"] = 70
        }):Play()
        wait(p91)
        workspace.CurrentCamera.FieldOfView = 70
        task.spawn(function()
            wait(0.1)
            workspace.CurrentCamera.FieldOfView = 70
        end)
        v_u_95 = false
        v98:disconnect()
        return (
            (p91 ~= 0 and (Toggles.AutoBlackFlash.Value and true)) or v_u_96
        ), true
    end);


    repeat
        task.wait()
    until getgenv().Toggles;

    Connections['UserInputService'] = UserInputService.InputBegan:Connect(function(Input,IsTyping)
        if IsTyping then return; end;
        if Input.KeyCode == Enum.KeyCode[getgenv().AfterKey] then
            local Target = getTarget();
            if TargetUser then
                TargetUser = nil;
                if SelectionBox then
                    SelectionBox:Destroy();
                    SelectionBox = nil;
                end;
                Notify('reseting target');
            else
                if Target then
                    TargetUser = Target;
                    Notify('setting', TargetUser.Name);
                end;
            end;
        end;
    end);

    Library:OnUnload(function()
        if getgenv().ESPStored then
            for _, EspObject in getgenv().ESPStored do
                if EspObject then
                    ESPCleanup(EspObject);
                end;
            end;
        end;
        if getgenv().Connections then
            for _, Connection in getgenv().Connections do
                if Connection then
                    Connection:Disconnect();
                end;
            end;
        end;
        if getgenv().Toggles then
            for ToggleIndex, _ in getgenv().Toggles do
                Toggles[ToggleIndex]:SetValue(false);
            end;
        end;
        for _, v in AlternateWatermarks do
            task.wait();
            v:Remove();
        end;
        Library.Unloaded = true
        getgenv().HasExecuted = false;
    end);


    MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
    MenuGroup:AddButton('Unload', function() Library:Unload() end)
    MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'LeftAlt', NoUI = true, Text = 'Menu keybind' })
    Library.ToggleKeybind = Options.MenuKeybind
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    ThemeManager:SetFolder('stuffnstuff')
    SaveManager:SetFolder('stuffnstuff/ABA')
    if not isfolder('stuffnstuff/ABA/Macros') then makefolder('stuffnstuff/ABA/Macros') end
    SaveManager:BuildConfigSection(Tabs['UI Settings'])
    ThemeManager:ApplyToTab(Tabs['UI Settings'])
    SaveManager:LoadAutoloadConfig()
getgenv()._RenzHubInstance = Library
