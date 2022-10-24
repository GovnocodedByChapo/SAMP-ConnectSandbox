script_name('ConnectSandbox')
script_author('chapo')
require('lib.moonloader')
local ffi = require('ffi')
ffi.cdef([[
    typedef struct { float x, y, z; } CVector;
    int MessageBoxA(
        void* hWnd,
        const char* lpText,
        const char* lpCaption,
        unsigned int uType
    );
]])

req, require = require, function(str, downloadUrl, openurl)
    local result, data = pcall(req, str)
    if not result then
        ffi.C.MessageBoxA(ffi.cast('void*', readMemory(0x00C8CF88, 4, false)), ('Error, lib "%s" not found. Download: %s\n\nvk.com/chaposcripts'):format(str, downloadUrl or 'ссылка не найдена', str, downloadUrl or 'ссылка не найдена'), 'ConnectSandbox error', 0x50000)
        if downloadUrl then
            os.execute('explorer "'..downloadUrl..'"')
        end
        error('Lib '..str..' not found!')
    end
    return data
end
local hook = require('hooks', 'https://www.blast.hk/threads/55743/')
local imgui = require('mimgui', 'https://www.blast.hk/threads/66959/')
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
local inicfg = require('inicfg')
local directIni = 'ConnectSandBoxV1.ini'
local ini = inicfg.load(inicfg.load({
    main = { skin = 0, x = 1135, y = -2036, z = 69, weapons = '[[24]]' },
}, directIni))
inicfg.save(ini, directIni)
local ConnectAttemptCount = 0
local weapons = require('game.weapons')
local Pool = { Vehicles = {}, Peds = {} }
local SAMP = getModuleHandle('samp.dll')
local isConnected = function() return isSampAvailable() and sampGetCurrentServerName() ~= 'SA-MP' end-- and (sampGetGamestate() == 3 or sampGetGamestate() == 5) end
local getSampVersion = function()
    local Version = { [0x5542F47A] = 'R1', [0x5C0B4243] = 'R3' }
    --print('SAMP', readMemory(getModuleHandle('samp.dll') + 0x128, 4, true))
    return Version[readMemory(getModuleHandle('samp.dll') + 0x128, 4, true)] or 'PIZDA'
end
local setPlayerSkin = function(arg)
    if tonumber(arg) then
        local BS = raknetNewBitStream()
        raknetBitStreamWriteInt32(BS, 0)
        raknetBitStreamWriteInt32(BS, tonumber(arg))
        raknetEmulRpcReceiveBitStream(153, BS)
        raknetDeleteBitStream(BS)
        ini.main.skin = tonumber(arg)
        inicfg.save(ini, directIni)
    end
end
local ClearPools = function()
    --lua sampConnectToServer('185.189.15.89', 7228)
    for k, v in ipairs(getAllChars()) do
        if v ~= PLAYER_PED then
            deleteChar(v)
        end
    end
    for k, v in ipairs(getAllVehicles()) do
        deleteCar(v)
    end
    if doesVehicleExist(Vehicle) then
        deleteCar(Vehicle)
    end
end
local SpawnBot = function(skin, x, y, z)
    if not hasModelLoaded(skin) then
        requestModel(skin)
        loadAllModelsNow()
    end
    local temp_ped = createChar(4, skin, x, y, z)
    table.insert(Pool.Peds, { handle = temp_ped, skin = skin })
    return #Pool.Peds
end
local SetBotSkin = function(botIndex, skin)
    local skin = skin == 74 and 0 or skin
    if Pool.Peds[botIndex] then
        local data = Pool.Peds[botIndex]
        if doesCharExist(data.handle) then
            local x, y, z = getCharCoordinates(data.handle)
            deleteChar(data.handle)
            if not hasModelLoaded(skin) then
                requestModel(skin)
                loadAllModelsNow()
            end
            local temp_ped = createChar(4, skin, x, y, z)
            Pool.Peds[botIndex] = { handle = temp_ped, skin = skin }
        end
    end
end
local StartTime = -1
local Vehicle, Vehicles = nil, {400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415,
	416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433,
	434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451,
	452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469,
	470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487,
	488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505,
	506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523,
	524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541,
	542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559,
	560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577,
	578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595,
	596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611
}

local Menu = {
    Weapons = {24},
    State = imgui.new.bool(false),
    Search = imgui.new.char[128](''),
    BotSkinId = imgui.new.int(0),
    Citizens = imgui.new.bool(true),
    Buttons = {
        {Label = 'Spawn vehicle', Callback = function() imgui.OpenPopup('Spawn vehicle##pup') end},
        {Label = 'Change skin', Callback = function() imgui.OpenPopup('Skin##pup') end},
        {Label = 'Teleport', Callback = function() imgui.OpenPopup('Teleport##pup') end},
        {Label = 'Weapons', Callback = function() imgui.OpenPopup('Weapons##pup') end},
        {Label = 'Bots', Callback = function() imgui.OpenPopup('Bots##pup') end},
        {Label = 'JetPack', Callback = function() taskJetpack(PLAYER_PED) end},
        {Label = 'CLICK HERE IF YOU ARE STUCKED', Callback = function() setCharCoordinates(PLAYER_PED, getCharCoordinates(PLAYER_PED)) end}
    },
    TeleportPoints = {
        {name = 'Observatory', x = 1126.7293701172, y = -2037.2701416016, z = 69.883499145508},
        {name = 'Skyscraper', x = 1540.5753173828, y = -1353.5942382813, z = 329.46740722656},
        {name = 'Chilliad', x = -2336.8623046875, y = -1597.2878417969, z = 483.68698120117},
        {name = '"Golden Gate" bridge', x = -2664.8452148438, y = 1373.9736328125, z = 55.8125},
        {name = 'Ralway station LS', x = 1758.8635253906, y = -1894.0705566406, z = 13.555848121643},
        {name = 'Railway Station SF', x = -1972.8768310547, y = 120.60735321045, z = 27.6875},
        {name = 'Airport LS', x = 2071.9116210938, y = -2496.2307128906, z = 13.546875},
        {name = 'Airport LV', x = 1533.9407958984, y = 1764.2025146484, z = 10.8203125},
        {name = 'Airport SF', x = -1656.318359375, y = -166.42935180664, z = 14.1484375},
        {name = 'Desert Airport LV', x = 426.84805297852, y = 2530.8107910156, z = 16.624961853027},
        {name = 'Groove Street', x = 2495.6220703125, y = -1687.4509277344, z = 13.516638755798},
        {name = 'Santa Maria Beach', x = 521.87805175781, y = -1825.6357421875, z = 6.0625},
        {name = 'Mad Dog house', x = 1260.9675292969, y = -804.07678222656, z = 88.3125},
        {name = 'Zone 69', x = 132.19763183594, y = 1939.9140625, z = 19.301904678345},
        {name = 'Glen Park', x = 1899.7927246094, y = -1171.4448242188, z = 24.297285079956},
        {name = 'Vagos', x = 2873.5080566406, y = -1591.82421875, z = 23.411462783813}
    }
}
local save = function()
    ini.main.skin = getCharModel(PLAYER_PED)
    ini.main.x, ini.main.y, ini.main.z = getCharCoordinates(PLAYER_PED)
    ini.main.weapon = encodeJson(Menu.Weapons)
    inicfg.save(ini, directIni)
end
local HooksInstalled = false
local Hooks = {
    ['SAMP::CCamera::PointAt']  =       { 'void(__thiscall*)(uintptr_t this, float x, float y, float z, int nSwitchStyle)', 'SAMP_CCamera_PointAt',         SAMP + (getSampVersion() == 'R1' and 0x99180 or 0x9D0D0) },
    ['SAMP::CEntity::Teleport'] =       { 'void(__thiscall *)(uintptr_t this, float x, float y, float z)',                  'SAMP_CEntity_Teleport',        SAMP + (getSampVersion() == 'R1' and 0x9A680 or 0x9E930) },
    ['SAMP::CPed::WarpFromVehicle'] =   { 'void(__thiscall*)(uintptr_t this, float x, float y, float z)',               'SAMP_CPed_WarpFromVehicle',        SAMP + (getSampVersion() == 'R1' and 0xA6E30 or 0xABCE0) },
}

-->> Hooks callbacks
SAMP_CCamera_PointAt = function(this, x, y, z, nSwitchStyle) 
    if x == 384 and y == -1557 and z == 20 then
        return false
    else 
        SAMP_CCamera_PointAt(this, x, y, z, nSwitchStyle) 
    end
end
SAMP_CEntity_Teleport = function(this, x, y, z)
    if getDistanceBetweenCoords3d(1133.0504150391, -2038.4034423828, 69.099998474121, x, y, z) <= 1 or getDistanceBetweenCoords3d(2172.4260253906, -1043.7320556641, 70, x, y, z) <= 1 then 
        return false 
    else 
        SAMP_CEntity_Teleport(this, x, y, z) 
    end
end
SAMP_CPed_WarpFromVehicle = function(this, x, y, z)
    if getDistanceBetweenCoords3d(1093.4000244141, -2036.5, 82.710601806641, x, y, z) < 1 or getDistanceBetweenCoords3d(2172.4260253906, -1043.7320556641, 70, x, y, z) <= 1 then
        return false
    else
        SAMP_CPed_WarpFromVehicle(this, x, y, z)
    end
end

addEventHandler('onSendRpc', function(id, bs)
    if not isConnected() then
        if id == 50 then
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
        
            if text:find('^/skin%s(%d+)') then
                setPlayerSkin(tonumber(text:match('/skin (%d+)')))
            elseif text == '/jp' then
                taskJetpack(PLAYER_PED)
            elseif text == '/save' then
                ini.main.skin, ini.main.x, ini.main.y, ini.main.z = getCharModel(PLAYER_PED), getCharCoordinates(PLAYER_PED)
                inicfg.save(ini, directIni)
            end
        elseif id == 119 then
            setCharCoordinates(PLAYER_PED, raknetBitStreamReadFloat(bs), raknetBitStreamReadFloat(bs), raknetBitStreamReadFloat(bs))
        end
    end
end)

addEventHandler('onWindowMessage', function(msg, key)
    if isSampAvailable() and not sampIsCursorActive() and not isConnected() and msg == 0x0100 and key == VK_N then
        save()
        Menu.State[0] = not Menu.State[0]
    end
end)

addEventHandler('onReceivePacket', function(id, bs)
    if id == 34 then --[[ ID_CONNECTION_REQUEST_ACCEPTED ]]
        save()
        ClearPools()
    end
end)

addEventHandler('onScriptTerminate', function(scr, quit)
    if scr == thisScript() then
        ClearPools()
    end
end)

function MessageHook(callback)
    if _G['__HOOK_LastChatMessage__'] == nil then
        _G['__HOOK_LastChatMessage__'] = ''
    end
    lua_thread.create(function()
        while true do
            wait(0)
            local text, prefix, color, pcolor = sampGetChatString(99)
            if text ~= _G['__HOOK_LastChatMessage__'] then
                _G['__HOOK_LastChatMessage__'] = text
                callback(color, text, prefix, prefixcolor)
            end
        end
    end)
end

function main()
    if not HooksInstalled then
        assert(getSampVersion(), 'ConnectSandbox requires SA:MP R1 or SA:MP R3!')
        for name, data in pairs(Hooks) do 
            _G[data[2]] = hook.jmp.new(data[1], _G[data[2]], data[3]) 
        end
        HooksInstalled = true
    end
    if not isConnected() then
        StartTime = os.clock()
        while not doesCharExist(PLAYER_PED) do wait(0) end
        setCharCoordinates(PLAYER_PED, ini.main.x, ini.main.y, ini.main.z)
        while not isSampAvailable() do wait(0) end
        MessageHook(function(color, text, prefix, pcolor)
            if text:find('^Connecting to (.+)%.%.%.') or text:find('^The server is full%. Retrying%.%.') then
                ConnectAttemptCount = ConnectAttemptCount + 1
                sampSetChatString(99, ('%s (x%s)'):format(text, ConnectAttemptCount), '', color, 0)
                _G['__HOOK_LastChatMessage__'] = ('%s (x%s)'):format(text, ConnectAttemptCount)
            end
        end)
        setPlayerSkin(ini.main.skin)
        restoreCameraJumpcut()
        setCharCoordinates(PLAYER_PED, ini.main.x, ini.main.y, ini.main.z) -- stucked
        for _, id in ipairs(Menu.Weapons) do
            local BS = raknetNewBitStream()
            raknetBitStreamWriteInt32(BS, id)
            raknetBitStreamWriteInt32(BS, 500)
            raknetEmulRpcReceiveBitStream(22, BS)
            raknetDeleteBitStream(BS)
        end
    end
    while true do
        wait(0)
        --sampSetChatString(99, 'zalupa', '', 0xffffffff, 0xffffffff)
        if not isConnected() then
            for k, v in ipairs(Pool.Peds) do
                if doesCharExist(v.handle) then
                    setCharProofs(v.handle, true, true, true, true, true)
                end
            end
            setCharHealth(PLAYER_PED, 200)
            setCharProofs(PLAYER_PED, true, true, true, true, true)
        end
    end
end

imgui.OnInitialize(function() imgui.DarkTheme() end)
local FrameTwo = imgui.OnFrame(
    function() return not isConnected() end,
    function(self)
        self.HideCursor = true
        local resX, resY = getScreenResolution()
        local winsize = imgui.ImVec2(220, 95)
        imgui.SetNextWindowPos(imgui.ImVec2(resX - winsize.x, resY - winsize.y), imgui.Cond.Always, imgui.ImVec2(0, 0))
        imgui.SetNextWindowSize(winsize, imgui.Cond.Always)
        if imgui.Begin('ConnectSandbox::TOOLTIP', Menu.State, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoBackground) then
            local size = imgui.GetWindowSize()
            imgui.SetCursorPos(imgui.ImVec2(5, size.y - 45 - 33 - 10))
            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.05, 0.05, 0.05, 0.7))
            if imgui.BeginChild('Tooltsip', imgui.ImVec2(size.x - 10, 33)) then
                imgui.SetCursorPos(imgui.ImVec2(10, 10))
                local p = imgui.GetCursorScreenPos()
                imgui.Text('N  - Open ConnectSandbox menu')
                local tsize = imgui.CalcTextSize('N').y
                imgui.GetWindowDrawList():AddRect(imgui.ImVec2(p.x - tsize /2 + 3 , p.y), imgui.ImVec2(p.x + tsize - 3, p.y + tsize), 0xFFffffff, 3)--, float rounding = 0.0f, int rounding_corners_flags = ~0, float thickness = 1.0f)
                imgui.EndChild()
            end

            -->> Spinner and time
            imgui.SetCursorPos(imgui.ImVec2(5, size.y - 45))
            if imgui.BeginChild('back', imgui.ImVec2(size.x - 10, 40)) then
                imgui.SetWindowFontScale(1.2)
                local text = ('Connecting... (%s sec.)'):format(tostring(math.floor(os.clock() - StartTime)))
                imgui.SetCursorPos(imgui.ImVec2(20 - imgui.CalcTextSize(text).y / 2, 20 - imgui.CalcTextSize(text).y / 2))
                imgui.Text(text)
                imgui.SetCursorPos(imgui.ImVec2(size.x - 10 - 30, 5))
                Spinner('Connecting to', 10, 3, 0xFFffffff)     
                imgui.EndChild()
            end
            imgui.PopStyleColor()
            imgui.End()
        end
    end
)

local Frame = imgui.OnFrame(
    function() return Menu.State[0] end,
    function(self)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 300, 245
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.Appearing, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.Always)
        if imgui.Begin('ConnectSandbox', Menu.State, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
            local size = imgui.GetWindowSize()
            imgui.SetCursorPos(imgui.ImVec2(5, 30))
            if imgui.BeginChild('pages', imgui.ImVec2(size.x - 10, size.y - 5 - 30), true) then
                for k, v in ipairs(Menu.Buttons) do
                    imgui.SetCursorPos(imgui.ImVec2(5, 5 + (24 * (k - 1)) + (5 * (k - 1))))
                    if imgui.Button(v.Label, imgui.ImVec2(size.x - 10 - 10, 24)) then
                        v.Callback()
                        imgui.StrCopy(Menu.Search, '')
                        save()
                    end 
                end
                -->> Popups
                ----> Bots
                if imgui.BeginPopupModal('Bots##pup', _, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(300, 500))
                    local size = imgui.GetWindowSize()
                    imgui.SetCursorPos(imgui.ImVec2(5, 30))
                    if imgui.BeginChild('BotsList', imgui.ImVec2(size.x - 10, size.y - 5 - 30 - 30), true) then
                        imgui.SetCursorPos(imgui.ImVec2(5, 5))
                        if imgui.Button('Spawn bot', imgui.ImVec2(size.x - 20, 24)) then 
                            local newindex = SpawnBot(0, getCharCoordinates(PLAYER_PED))
                        end
                        imgui.Separator()
                        for index, data in ipairs(Pool.Peds) do
                            if data.handle and doesCharExist(data.handle) then
                                imgui.SetCursorPosX(5)
                                imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0, 0.5))
                                if imgui.Button(('#%s, Skin: %s'):format(tostring(index), data.skin), imgui.ImVec2(size.x - 20, 24)) then
                                    Menu.BotSkinId[0] = data.skin
                                    imgui.OpenPopup('botedit_'..index)
                                end
                                imgui.PopStyleVar()
                                if imgui.BeginPopup('botedit_'..index) then
                                    if imgui.Button('Delete', imgui.ImVec2(100, 24)) then 
                                        deleteChar(data.handle)
                                        table.remove(Pool.Peds, index) 
                                    end
                                    if imgui.Button('Teleport to me', imgui.ImVec2(100, 24)) then 
                                        setCharHeading(data.handle, getCharHeading(PLAYER_PED))
                                        setCharCoordinates(data.handle, getCharCoordinates(PLAYER_PED))
                                    end
                                    imgui.PushItemWidth(100)
                                    if imgui.InputInt('Skin ID', Menu.BotSkinId) then
                                        if Menu.BotSkinId[0] > 311 then 
                                            Menu.BotSkinId[0] = 311 
                                        elseif Menu.BotSkinId[0] < 0 then
                                            Menu.BotSkinId[0] = 0
                                        elseif Menu.BotSkinId == 74 then
                                            Menu.BotSkinId[0] = 0
                                        end
                                        SetBotSkin(index, Menu.BotSkinId[0])
                                        --setPlayerModel(data.handle, Menu.BotSkinId[0])
                                    end
                                    imgui.PopItemWidth()
                                    imgui.EndPopup()
                                end
                            end
                        end
                        imgui.EndChild()
                    end
                    imgui.SetCursorPos(imgui.ImVec2(5, size.y - 30))
                    if imgui.Button(u8'Close##Skin##pup', imgui.ImVec2(size.x - 10, 24)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end
                ----> Skin
                if imgui.BeginPopupModal('Skin##pup', _, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(300, 500))
                    local size = imgui.GetWindowSize()
                    imgui.SetCursorPos(imgui.ImVec2(5, 30))
                    if imgui.BeginChild('SkinsList', imgui.ImVec2(size.x - 10, size.y - 5 - 30 - 30), true) then
                        imgui.SetCursorPos(imgui.ImVec2(5, 5))
                        imgui.SetCursorPos(imgui.ImVec2(5, 5))
                        imgui.PushItemWidth(size.x - 30)
                        imgui.InputTextWithHint('##Menu.Search', 'Search', Menu.Search, ffi.sizeof(Menu.Search))
                        imgui.PopItemWidth()
                        imgui.Separator()
                        for id = 0, 311 do
                            if #ffi.string(Menu.Search) == 0 or tostring(id):find(ffi.string(Menu.Search)) then
                                imgui.SetCursorPosX(5)
                                if imgui.Button(('%s'):format(tostring(id)), imgui.ImVec2(size.x - 30, 24)) then
                                    setPlayerSkin(id)
                                    imgui.CloseCurrentPopup()
                                end
                            end
                        end
                        imgui.EndChild()
                    end
                    imgui.SetCursorPos(imgui.ImVec2(5, size.y - 30))
                    if imgui.Button(u8'Close##Skin##pup', imgui.ImVec2(size.x - 10, 24)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end

                ----> Weapons
                if imgui.BeginPopupModal('Weapons##pup', _, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(300, 500))
                    local size = imgui.GetWindowSize()
                    imgui.SetCursorPos(imgui.ImVec2(5, 30))
                    if imgui.BeginChild('WeaponsList', imgui.ImVec2(size.x - 10, size.y - 5 - 30 - 30), true) then
                        imgui.SetCursorPos(imgui.ImVec2(5, 5))
                        for id = 1, 46 do
                            if weapons.get_name(id) ~= nil then
                                imgui.SetCursorPosX(5)
                                if imgui.Button(('%s. %s'):format(tostring(id), weapons.get_name(id)), imgui.ImVec2(size.x - 30, 24)) then
                                    --> GivePlayerWeapon - ID: 22
                                    --> Parameters: UINT32 dWeaponID, UINT32 dBullets
                                    local BS = raknetNewBitStream()
                                    raknetBitStreamWriteInt32(BS, id)
                                    raknetBitStreamWriteInt32(BS, 500)
                                    raknetEmulRpcReceiveBitStream(22, BS)
                                    raknetDeleteBitStream(BS)
                                    imgui.CloseCurrentPopup()
                                    table.insert(Menu.Weapons, id)
                                    save()
                                end
                            end
                        end
                        imgui.EndChild()
                    end
                    imgui.SetCursorPos(imgui.ImVec2(5, size.y - 30))
                    if imgui.Button(u8'Close##Weapons##pup', imgui.ImVec2(size.x - 10, 24)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end

                ----> Vehicle
                if imgui.BeginPopupModal('Spawn vehicle##pup', _, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(300, 500))
                    local size = imgui.GetWindowSize()
                    imgui.SetCursorPos(imgui.ImVec2(5, 30))
                    if imgui.BeginChild('vehlist', imgui.ImVec2(size.x - 10, size.y - 5 - 30 - 30), true) then
                        imgui.SetCursorPos(imgui.ImVec2(5, 5))
                        imgui.PushItemWidth(size.x - 30)
                        imgui.InputTextWithHint('##Menu.Search', 'Search', Menu.Search, ffi.sizeof(Menu.Search))
                        imgui.PopItemWidth()
                        imgui.Separator()
                        for _, id in ipairs(Vehicles) do
                            imgui.SetCursorPosX(5)
                            if #ffi.string(Menu.Search) == 0 or ('%s. %s'):format(tostring(id), getNameOfVehicleModel(id) or 'UNKNOWN MODEL'):lower():find(ffi.string(Menu.Search)) then
                                if imgui.Button(('%s. %s'):format(tostring(id), getNameOfVehicleModel(id) or 'UNKNOWN MODEL'), imgui.ImVec2(size.x - 30, 24)) then
                                    if isCharInAnyCar(PLAYER_PED) then
                                        warpCharFromCarToCoord(PLAYER_PED, getCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED)))
                                    end
                                    if doesVehicleExist(Vehicle) then deleteCar(Vehicle) end
                                    if not hasModelLoaded(id) then
                                        requestModel(id)
                                        loadAllModelsNow()
                                    end
                                    Vehicle = createCar(id, getCharCoordinates(PLAYER_PED))
                                    warpCharIntoCar(PLAYER_PED, Vehicle)
                                    restoreCameraJumpcut()
                                    --pointCameraAtCar(storeCarCharIsInNoSave(PLAYER_PED), 0, 0)
                                    imgui.CloseCurrentPopup()
                                end
                            end
                        end
                        imgui.EndChild()
                    end
                    imgui.SetCursorPos(imgui.ImVec2(5, size.y - 30))
                    if imgui.Button(u8'Close##Spawn vehicle##pup', imgui.ImVec2(size.x - 10, 24)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end

                ----> Teleport
                if imgui.BeginPopupModal('Teleport##pup', _, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(300, 500))
                    local size = imgui.GetWindowSize()
                    imgui.SetCursorPos(imgui.ImVec2(5, 30))
                    if imgui.BeginChild('tplist', imgui.ImVec2(size.x - 10, size.y - 5 - 30 - 30), true) then
                        for index, data in ipairs(Menu.TeleportPoints) do
                            imgui.SetCursorPosX(5)
                            if imgui.Button(data.name, imgui.ImVec2(size.x - 30, 24)) then
                                setCharCoordinates(PLAYER_PED, data.x, data.y, data.z)
                                imgui.CloseCurrentPopup()
                            end
                        end
                        imgui.EndChild()
                    end
                    imgui.SetCursorPos(imgui.ImVec2(5, size.y - 30))
                    if imgui.Button(u8'Close##Teleport##pup', imgui.ImVec2(size.x - 10, 24)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end
                imgui.EndChild()
            end
            imgui.End()
        end
    end
)

function imgui.DarkTheme()
    imgui.SwitchContext()
    --==[ STYLE ]==--
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10

    --==[ BORDER ]==--
    imgui.GetStyle().WindowBorderSize = 0
    imgui.GetStyle().ChildBorderSize = 0
    imgui.GetStyle().PopupBorderSize = 0
    imgui.GetStyle().FrameBorderSize = 0
    imgui.GetStyle().TabBorderSize = 0

    --==[ ROUNDING ]==--
    imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 5
    imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().PopupRounding = 5
    imgui.GetStyle().ScrollbarRounding = 5
    imgui.GetStyle().GrabRounding = 5
    imgui.GetStyle().TabRounding = 5

    --==[ ALIGN ]==--
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    
    --==[ COLORS ]==--
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(1,1,1,1)--imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

Spinner = function(label, radius, thickness, color) -- Author: AnWu ( from https://www.blast.hk/threads/27544/ )
    local style = imgui.GetStyle()
    local pos = imgui.GetCursorScreenPos()
    local size = imgui.ImVec2(radius * 2, (radius + style.FramePadding.y) * 2)
    
    imgui.Dummy(imgui.ImVec2(size.x + style.ItemSpacing.x, size.y))

    local DrawList = imgui.GetWindowDrawList()
    DrawList:PathClear()
    
    local num_segments = 30
    local start = math.abs(math.sin(imgui.GetTime() * 1.8) * (num_segments - 5))
    
    local a_min = 3.14 * 2.0 * start / num_segments
    local a_max = 3.14 * 2.0 * (num_segments - 3) / num_segments

    local centre = imgui.ImVec2(pos.x + radius, pos.y + radius + style.FramePadding.y)
    
    for i = 0, num_segments do
        local a = a_min + (i / num_segments) * (a_max - a_min)
        DrawList:PathLineTo(imgui.ImVec2(centre.x + math.cos(a + imgui.GetTime() * 8) * radius, centre.y + math.sin(a + imgui.GetTime() * 8) * radius))
    end

    DrawList:PathStroke(color, false, thickness)
    return true
end

--lua sampConnectToServer('185.189.15.89', 7228)