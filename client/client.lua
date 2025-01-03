-- AI Cars Move-Out Script
-- Loads the configuration from config.lua
Config = Config or {}
dofile("config.lua")

-- Function to detect if the player's vehicle is a police or ambulance vehicle
function isEmergencyVehicle(vehicle)
    local model = GetEntityModel(vehicle)
    for _, emergencyVehicle in ipairs(Config.PoliceVehicles) do
        if model == GetHashKey(emergencyVehicle) then
            return true
        end
    end
    for _, emergencyVehicle in ipairs(Config.AmbulanceVehicles) do
        if model == GetHashKey(emergencyVehicle) then
            return true
        end
    end
    return false
end

-- Function to get nearby vehicles within a specified radius
function GetNearbyVehicles(coords, radius)
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success

    repeat
        local distance = #(coords - GetEntityCoords(vehicle))
        if distance <= radius then
            table.insert(vehicles, vehicle)
        end
        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return vehicles
end

-- Function to move an AI vehicle out of the way
function MoveVehicleOutOfTheWay(vehicle, emergencyCoords)
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver and not IsPedAPlayer(driver) then
        local vehCoords = GetEntityCoords(vehicle)
        local forwardVector = GetEntityForwardVector(vehicle)
        local sideVector = vector3(-forwardVector.y, forwardVector.x, 0)

        local leftCoords = vehCoords + (sideVector * 10.0) -- Move 10 units to the left
        local rightCoords = vehCoords - (sideVector * 10.0) -- Move 10 units to the right

        local leftDistance = #(leftCoords - emergencyCoords)
        local rightDistance = #(rightCoords - emergencyCoords)

        -- Determine the side with the least distance to emergency vehicle
        local targetCoords = (leftDistance < rightDistance) and leftCoords or rightCoords

        -- Command AI to drive to the target coordinates
        TaskVehicleDriveToCoord(driver, vehicle, targetCoords.x, targetCoords.y, targetCoords.z, 20.0, 0, GetEntityModel(vehicle), 786603, 1.0, true)

        -- Temporary action to mimic real-life behavior
        TaskVehicleTempAction(driver, vehicle, 4, 2000)
    end
end

-- Main thread to handle AI cars moving out of the way
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

        if playerVehicle ~= 0 and isEmergencyVehicle(playerVehicle) and IsVehicleSirenOn(playerVehicle) then
            local playerCoords = GetEntityCoords(playerVehicle)
            local nearbyVehicles = GetNearbyVehicles(playerCoords, 50.0) -- Check for vehicles within 50 units

            for _, vehicle in ipairs(nearbyVehicles) do
                if not isEmergencyVehicle(vehicle) then
                    MoveVehicleOutOfTheWay(vehicle, playerCoords)
                end
            end
        end

        Citizen.Wait(500) -- Adjust the delay for performance optimization
    end
end)
