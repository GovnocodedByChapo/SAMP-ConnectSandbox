script_name('ConnectSandbox')
script_author('chapo')
require('lib.moonloader')
local ffi = require('ffi')
local hook = require('hooks')
local inicfg = require('inicfg')
local directIni = 'ConnectSandBoxV1.ini'
local ini = inicfg.load(inicfg.load({
    main = { skin = 0, x = 1135, y = -2036, z = 69 },
}, directIni))
inicfg.save(ini, directIni)
ffi.cdef([[typedef struct { float x, y, z; } CVector;]])

local SAMP = getModuleHandle('samp.dll')
local isConnected = function() return isSampAvailable() and sampGetCurrentServerName() ~= 'SA-MP' end-- and (sampGetGamestate() == 3 or sampGetGamestate() == 5) end
local getSampVersion = function()
    local Version = { [0x5542F47A] = 'R1', [0x5C0B4243] = 'R3' }
    return Version[readMemory(getModuleHandle('samp.dll') + 0x128, 4, true)] or nil
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

local Hooks = {
    ['SAMP::CCamera::PointAt']  = { 'void(__thiscall*)(uintptr_t this, float x, float y, float z, int nSwitchStyle)', 'SAMP_CCamera_PointAt',  SAMP + (getSampVersion() == 'R1' and 0x99180 or 0x9D0D0) },
    ['SAMP::CEntity::Teleport'] = { 'void(__thiscall *)(uintptr_t this, float x, float y, float z)',                  'SAMP_CEntity_Teleport', SAMP + (getSampVersion() == 'R1' and 0x9A680 or 0x9E930) }
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
    if getDistanceBetweenCoords3d(1133.0504150391, -2038.4034423828, 69.099998474121, x, y, z) < 1 then 
        return false 
    else 
        SAMP_CEntity_Teleport(this, x, y, z) 
    end
end

addEventHandler('onSendRpc', function(id, bs)
    local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
    if not isConnected() then
        if text:find('^/skin%s(%d+)') then
            setPlayerSkin(tonumber(text:match('/skin (%d+)')))
        elseif text == '/jp' then
            taskJetpack(PLAYER_PED)
        elseif text == '/save' then
            ini.main.skin, ini.main.x, ini.main.y, ini.main.z = getCharModel(PLAYER_PED), getCharCoordinates(PLAYER_PED)
            inicfg.save(ini, directIni)
        end
    end
end)

function main()
    assert(getSampVersion(), 'ConnectSandbox requires SA:MP R1 or SA:MP R3!')
    for name, data in pairs(Hooks) do 
        _G[data[2]] = hook.jmp.new(data[1], _G[data[2]], data[3]) 
    end
    if not isConnected() then
        while not doesCharExist(PLAYER_PED) do wait(0) end
        setCharCoordinates(PLAYER_PED, ini.main.x, ini.main.y, ini.main.z)
        pointCameraAtChar(PLAYER_PED, 0, 1)
        taskJetpack(PLAYER_PED)
        while not isSampAvailable() do wait(0) end
        setPlayerSkin(ini.main.skin)
        pointCameraAtChar(PLAYER_PED, 0, 1)
    end
    wait(-1)
end