--[[ ===================================================== ]] --
--[[             MH Auto Park Script by MaDHouSe           ]] --
--[[ ===================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false

local function GetStreetName(entity)
    return GetStreetNameFromHashKey(GetStreetNameAtCoord(GetEntityCoords(entity).x, GetEntityCoords(entity).y, GetEntityCoords(entity).z))
end

local function Save(vehicle)
    local props = QBCore.Functions.GetVehicleProperties(vehicle)
    if props then
        SetVehicleEngineOn(vehicle, false, false, true)
        QBCore.Functions.TriggerCallback("mh-autopark:server:save", function(isSaved)
            if isSaved then
                Wait(2000)
                RequestAnimSet("anim@mp_player_intmenu@key_fob@")
                TaskPlayAnim(PlayerPedId(), 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false)
                Wait(2000)
                ClearPedTasks(PlayerPedId())
                SetVehicleLights(vehicle, 2)
                Wait(150)
                SetVehicleLights(vehicle, 0)
                Wait(150)
                SetVehicleLights(vehicle, 2)
                Wait(150)
                SetVehicleLights(vehicle, 0)
                TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.2)
            end
        end, {
            netid = NetworkGetNetworkIdFromEntity(vehicle),
            modelname = GetLabelText(GetDisplayNameFromVehicleModel(props.model)),
            livery = GetVehicleLivery(vehicle),
            steerangle = GetVehicleSteeringAngle(vehicle),
            fuel = GetVehicleFuelLevel(vehicle),
            body = GetVehicleBodyHealth(vehicle),
            engine = GetVehicleEngineHealth(vehicle),
            oil = GetVehicleOilLevel(vehicle),
            props = props,
            plate = props.plate,
            model = props.model,
            parking = GetStreetName(vehicle),
            citizenid = PlayerData.citizenid,
            health = {
                engine = GetVehicleEngineHealth(vehicle),
                body = GetVehicleBodyHealth(vehicle),
                tank = GetVehiclePetrolTankHealth(vehicle)
            },
            location = vector4(GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y, GetEntityCoords(vehicle).z, GetEntityHeading(vehicle))
        })
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerData = {}
        isLoggedIn = false
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerData = QBCore.Functions.GetPlayerData()
        isLoggedIn = true
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
end)

RegisterNetEvent("mh-autopark:client:autoPark", function(driver, netid)
    if isLoggedIn then
        local player = PlayerData.source
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) and driver == player then Save(vehicle) end
    end
end)
