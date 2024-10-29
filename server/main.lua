--[[ ===================================================== ]] --
--[[             MH Auto Park Script by MaDHouSe           ]] --
--[[ ===================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()

local function Debug(src, seat, name, entity, netid, type)
    if Config.Debug then
        local player = GetPlayerName(src)
        local seatTxt = ""
        if seat == -1 then seatTxt = "Driver seat" end
        if seat == 0 then seatTxt = "CoDriver seat" end
        if seat >= 1 then seatTxt = "Back seat" end
        print("[^3"..GetCurrentResourceName().."^7] - ["..type.."] - Player "..player.." Vehicle: "..name.." Seat: "..seatTxt.." Entity: "..entity.." Netid:"..netid)
    end
end

local function Save(src, data)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)
        if DoesEntityExist(vehicle) then
            MySQL.Async.execute("INSERT INTO player_parking (citizenid, citizenname, plate, steerangle, fuel, body, engine, oil, model, modelname, data, time, coords, cost, parktime, parking) VALUES (@citizenid, @citizenname, @plate, @steerangle, @fuel, @body, @engine, @oil, @model, @modelname, @data, @time, @coords, @cost, @parktime, @parking)", {
                ["@citizenid"] = Player.PlayerData.citizenid,
                ["@citizenname"] = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                ["@plate"] = data.plate,
                ["@steerangle"] = data.steerangle,
                ["@fuel"] = data.fuel,
                ["@body"] = data.body,
                ["@engine"] = data.engine,
                ["@oil"] = data.oil,
                ["@model"] = data.model,
                ["@modelname"] = data.modelname,
                ["@data"] = json.encode(data),
                ["@time"] = os.time(),
                ["@coords"] = json.encode(data.location),
                ["@cost"] = 0,
                ["@parktime"] = 0,
                ["@parking"] = data.parking
            })
            MySQL.Async.execute('UPDATE player_vehicles SET state = 3 WHERE plate = ? AND citizenid = ?', {data.plate, Player.PlayerData.citizenid})
        end
    end
end

QBCore.Functions.CreateCallback("mh-autopark:server:save", function(source, cb, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?', {Player.PlayerData.citizenid, data.plate})[1]
        if result ~= nil then
            if result.state == 0 then
                if result.plate == data.plate then
                    Save(src, data)
                    QBCore.Functions.Notify(src, "Vehicle with "..data.plate.." is parked!", "success", 5000)
                    cb(true)
                    return
                else
                    QBCore.Functions.Notify(src, "You don't own a vehicle with the plate "..data.plate.."...", "error", 5000)
                    cb(false)
                    return
                end
            elseif result.state == 3 then
                QBCore.Functions.Notify(src, "Vehicle with "..data.plate.." is already parked...", "error", 5000)
                cb(false)
                return
            end
        else
            cb(false)
            return
        end
    end
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local parked = MySQL.Sync.fetchAll('SELECT * FROM player_parking WHERE plate = ?', {plate})[1]
    if parked ~= nil then 
        MySQL.Async.execute("DELETE FROM player_parking WHERE AND plate = ?", {plate})
        MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ?', {plate})
        TriggerClientEvent('mh-parking:client:unparkVehicle', -1, plate, false)
    end
end)

RegisterNetEvent("baseevents:enteredVehicle", function(currentVehicle, currentSeat, vehicleName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        Debug(src, currentSeat, vehicleName, currentVehicle, netId, "Entered")
        if currentSeat == -1 then
            local Player = QBCore.Functions.GetPlayer(src)
            local plate = GetVehicleNumberPlateText(vehicle)
            local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?', {Player.PlayerData.citizenid, plate})[1]
            if result ~= nil then
                local parked = MySQL.Sync.fetchAll('SELECT * FROM player_parking WHERE citizenid = ? AND plate = ?', {Player.PlayerData.citizenid, plate})[1]
                if parked ~= nil then 
                    MySQL.Async.execute("DELETE FROM player_parking WHERE citizenid = ? AND plate = ?", {Player.PlayerData.citizenid, plate})
                    MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ? AND citizenid = ?', {plate, Player.PlayerData.citizenid})
                end
            end
        end
    end
end)

RegisterNetEvent('baseevents:leftVehicle', function(currentVehicle, currentSeat, vehicleName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        Debug(src, currentSeat, vehicleName, currentVehicle, netId, "Left")
        TriggerClientEvent('mh-autopark:client:autoPark', -1, src, netId)
    end
end)
