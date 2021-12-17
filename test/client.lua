local spawnPos = vector3(436.491, -982.172, 30.699)
local criminalBlip = nil;
local copBlipCreated = false;
local criminalBlipCreated = false

local copCars = {"police3", "police2", "police", "policeb", "police4", "fbi"}
local copChasePos = {vector3(427.7331, -1026.866, 28.57223), vector3(431.2643, -1026.745, 28.51262), vector3(435.0636, -1026.83, 28.45566), vector3(438.6568, -1026.472, 28.38661), vector3(442.4537, -1026.427, 28.32192), vector3(446.3131, -1026.264, 28.25114),
vector3(431.4159, -997.2503, 25.04091), vector3(436.4887, -996.9086, 25.04547), vector3(452.6066, -996.5944, 25.04968)}
local criminalPos = {vector3(159.742, -1386.596, 29.10198), vector3(-316.3371, -1091.529, 22.84912), vector3(-330.3386, -694.208, 32.77942), vector3(64.64735, -306.3992, 46.7892)}

local randomPedSkin = {"a_m_m_bevhills_01", "a_m_m_bevhills_02", "a_m_m_eastsa_01", "a_m_m_golfer_01", "a_m_m_mexlabor_01", "a_m_y_ktown_01", "a_m_y_latino_01", "g_m_m_armgoon_01"}

local copBlips = {}

local isACop = false;
local handcuff = false;
local currentTime = 0;
local copChaseStarted = false;
local copChaseStillRunning = false;
local copCar = nil;
local policePosition = nil;

local savedPolicePosition = nil;
local timesCalled = 0


local radius = 205.0
local randomRadius = 105

SetMultiplayerWalletCash()

RegisterKeyMapping('cuff', 'Cuff suspect.', 'keyboard', 'i') 
RegisterKeyMapping('repair', 'Repair your cruiser.', 'keyboard', 'o') 

RegisterCommand('cuff', function()
    if isACop then
        TriggerServerEvent("Handcuff")
    end
end)

function IsPlayerACop()
    return isACop;
end

RegisterNetEvent("GetDistance")
AddEventHandler("GetDistance", function(copCoords, criminalCoords)
    local distance = GetDistanceBetweenCoords(copCoords.x, copCoords.y, copCoords.z, criminalCoords.x, criminalCoords.y, criminalCoords.z, false)
    TriggerServerEvent('TryCuff', distance)
end)

RegisterNetEvent("CriminalHandcuff")
AddEventHandler("CriminalHandcuff", function()
	local lPed = GetPlayerPed(-1)
	if DoesEntityExist(lPed) then
		if IsEntityPlayingAnim(lPed, "mp_arresting", "idle", 3) then
			ClearPedSecondaryTask(lPed)
			SetEnableHandcuffs(lPed, false)
			SetCurrentPedWeapon(lPed, GetHashKey("WEAPON_UNARMED"), true)
			handcuff = false
		else
			RequestAnimDict("mp_arresting")
			while not HasAnimDictLoaded("mp_arresting") do
				Citizen.Wait(100)
			end

			TaskPlayAnim(lPed, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
			SetEnableHandcuffs(lPed, true)
			SetCurrentPedWeapon(lPed, GetHashKey("WEAPON_UNARMED"), true)
			handcuff = true
		end
	end
end)

Citizen.CreateThread(function()
    -- main loop thing
	alreadyDead = false
    while true do
        Citizen.Wait(50)
		local playerPed = GetPlayerPed(-1)
		if IsEntityDead(playerPed) and not alreadyDead then
			killer = GetPedKiller(playerPed)
			killername = false
			for id = 0, 64 do
				if killer == GetPlayerPed(id) then
					killername = GetPlayerName(id)
				end				
			end
			if killer == playerPed then
				TriggerServerEvent('playerDied',0,0)
			elseif killername then
				TriggerServerEvent('playerDied',killername,1)
			else
				TriggerServerEvent('playerDied',0,2)
			end
			alreadyDead = true
		end
		if not IsEntityDead(playerPed) then
			alreadyDead = false
		end
	end
end)

AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawnCallback(function()
        exports.spawnmanager:spawnPlayer({
            x = spawnPos.x,
            y = spawnPos.y,
            z = spawnPos.z,
            model = 'a_m_m_skater_01'
        }, function()
            TriggerEvent('chat:addMessage', {
                args = { 'Welcome to the BaasBeuners Party!~' }
            })
            ClearPedTasks(GetPlayerPed(-1))
            handcuff = false
            if copChaseStillRunning and isACop then
            TriggerEvent('EventManager:Client:StartCopchase', -1, false, policePosition)
            else
            isACop = false;
            end
            
        end)
    end)

    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()
end)

function CheckCopCar(vehicleName)
for key, value in pairs(copCars) do 
    if value == vehicleName then return true end
end
return false
end

Citizen.CreateThread(function()
    while true do
    Citizen.Wait(0)
    local playerPed = GetPlayerPed(-1)
    local playerLocalisation = GetEntityCoords(playerPed)
    ClearAreaOfCops(playerLocalisation.x, playerLocalisation.y, playerLocalisation.z, 400.0)
    end
    end)


RegisterCommand('setcopcar', function(source, args)
    -- account for the argument not being passed
    local vehicleName = args[1]

    -- check if the vehicle actually exists
    if not IsModelInCdimage(vehicleName) or not IsModelAVehicle(vehicleName) or not CheckCopCar(vehicleName) and not copChaseStarted then
        TriggerEvent('chat:addMessage', {
            args = { 'Gast, wat is een: ' .. vehicleName .. '. Gekkie, of deze mag niet. Of hij bestaat niet.' }
        })
        return
    end
    copCar = vehicleName
end)

TriggerEvent('chat:addSuggestion', '/setcopcar', 'Choose your cop car.', {
    { name="Name of the cop car", help= 'Example: police3 (LSPD Vapid Interceptor), police2 (LSPD Bravado Buffalo), police (LSPD Vapid Stanier 2nd Gen), fbi (unmarked Bravado Buffalo 1st Gen), police4 (unmarked Vapid Stanier 2nd Gen), policeb (LSPD police bike)' }
})

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        currentTime = currentTime + 1
    end
end)

RegisterCommand('repair', function()
local maxTime = 60
        if currentTime > maxTime then
            if IsPedInAnyVehicle(PlayerPedId(), false) and isACop then
                local localPlayerPed = GetPlayerPed(-1)
                local localVehicle = GetVehiclePedIsIn(localPlayerPed, false)
                SetVehicleFixed(localVehicle)
                SetVehicleDeformationFixed(localVehicle)
                SetVehicleBodyHealth(localVehicle, 1000.0)
                currentTime = 0
            end
        else    
            TriggerEvent('chat:addMessage', {
                args = { 'You can not spam repair!' }
            })
        end
    end)


RegisterCommand('c', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
print(playerCoords)
end)

RegisterNetEvent('ResetToSpawn')
AddEventHandler('ResetToSpawn', function()
SetEntityCoords(GetPlayerPed(-1), spawnPos)
ClearPedTasks(GetPlayerPed(-1))
    RemoveBlip(criminalBlip)
    copChaseStarted = false
    copBlipCreated = false;
    criminalBlip = nil;
    isACop = false;
    handcuff = false;
    copChaseStillRunning = false
    criminalBlipCreated = false
    policePosition = nil
    timesCalled = 0
    radius = 205.0
    randomRadius = 105
    RemoveAllPedWeapons(PlayerPedId(), false)
    for index, value in ipairs(copBlips) do
        RemoveBlip(value.blip)
        value.blip = nil;
    end
    copBlips = {}
    local model = GetHashKey('a_m_m_skater_01')
    RequestModel(model)

    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent('EventManager:Client:CopChase')
AddEventHandler('EventManager:Client:CopChase', function(value)
    TriggerEvent('chat:addMessage', {
        args = { 'Copchase has started. Started by: ' .. tostring(value) .. ''}
    })
end)

RegisterNetEvent('EventManager:Client:JoinCopChase')
AddEventHandler('EventManager:Client:JoinCopChase', function(value)
    TriggerEvent('chat:addMessage', {
        args = { 'Joined copchase. current amount of players :' .. tostring(value) .. ''}
    })
end)

RegisterNetEvent('EventManager:Client:StartCopchase')
AddEventHandler('EventManager:Client:StartCopchase', function(criminal, position)
    TriggerEvent('chat:addMessage', {
        args = { 'Copchase starts now!'}
    })
    copChaseStarted = true;
    if not criminal or isACop then
        if policePosition == nil then
            policePosition = position
        end
    isACop = true    
    local model = GetHashKey('s_m_y_cop_01')
    RequestModel(model)

    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    SetEntityCoords(GetPlayerPed(-1), copChasePos[policePosition])

    if copCar == nil then
        copCar = 'police3'
    end

    RequestModel(copCar)    

    while not HasModelLoaded(copCar) do
        Wait(500) 
    end

    local playerPed = PlayerPedId() -- get the local player ped
    local pos = GetEntityCoords(playerPed) -- get the position of the local player ped
    SetEntityHeading(playerPed, 45)
    SetPedRandomProps (playerPed)

    -- create the vehicle
    local vehicle = CreateVehicle(copCar, copChasePos[policePosition], GetEntityHeading(playerPed), true, false)

    -- set the player ped into the vehicle's driver seat
    SetPedIntoVehicle(playerPed, vehicle, -1)

    -- give the vehicle back to the game (this'll make the game decide when to despawn the vehicle)
    SetEntityAsNoLongerNeeded(vehicle)

    -- release the model
    SetModelAsNoLongerNeeded(copCar)

    if not copChaseStillRunning then
    FreezeEntityPosition(GetVehiclePedIsIn(GetPlayerPed(-1), false), true)    
    freezeTimer = 20
    freezeTime = 0
    Citizen.CreateThread(function()
    TriggerEvent('chat:addMessage', {
        args = { 'Giving the criminal a 20 second lead. You will be unfrozen afterwards!'}
    })
    while freezeTime < freezeTimer do
        Citizen.Wait(1000);
        freezeTime = freezeTime +1
        if freezeTime == 10 then
            TriggerEvent('chat:addMessage', {
                args = { '10 seconds left!'}
            })
        end
        if freezeTime == 15 then
            TriggerEvent('chat:addMessage', {
                args = { '5 seconds left!'}
            })
        end
    end
    FreezeEntityPosition(GetVehiclePedIsIn(GetPlayerPed(-1), false), false)
    Citizen.Wait(10000)
    SetupCopWeaponry()
    TriggerEvent('chat:addMessage', {
        args = { 'Weapons free! Reminder: Friendly fire is a punishable offense.'}
    })

    copChaseStillRunning = true
    end)
end
    if copChaseStillRunning then
        SetupCopWeaponry()
    end
    else 
     


    local model = GetHashKey('player_two')
    RequestModel(model)

    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)   

    local criminalPosition = criminalPos[math.random(1, 4)]


    SetEntityCoords(GetPlayerPed(-1), criminalPosition)

    local car = "Dominator"

    RequestModel(car)    

    while not HasModelLoaded(car) do
        Wait(500) 
    end

    local playerPed = PlayerPedId() -- get the local player ped
    SetupCriminalWeaponry()
    local pos = GetEntityCoords(playerPed) -- get the position of the local player ped
    SetEntityHeading(playerPed, 45)

    -- create the vehicle
    local vehicle = CreateVehicle(car, criminalPosition, GetEntityHeading(playerPed), true, false)

    -- set the player ped into the vehicle's driver seat
    SetPedIntoVehicle(playerPed, vehicle, -1)

    -- give the vehicle back to the game (this'll make the game decide when to despawn the vehicle)
    SetEntityAsNoLongerNeeded(vehicle)

    -- release the model
    SetModelAsNoLongerNeeded(car)
    end

end)

RegisterNetEvent('EventManager:Client:UpdateCriminalPosition')
AddEventHandler('EventManager:Client:UpdateCriminalPosition', function(value)
    if not criminalBlipCreated then
    criminalBlip = CreateCriminalBlip(value);
    criminalBlipCreated = true
    else
    UpdateCriminalBlip(value);
    end    
end)

function CreateCriminalBlip(value) 
    criminalBlip = AddBlipForRadius(value.x , value.y, value.z, radius)
    SetBlipSprite(criminalBlip, 9)
    SetBlipAlpha(criminalBlip, 100)
    SetBlipColour(criminalBlip, 1)
    SetBlipCoords(criminalBlip, value.x + (math.random(-randomRadius, randomRadius)), value.y + (math.random(-randomRadius, randomRadius)), value.z + (math.random(-randomRadius, randomRadius)))
    return criminalBlip
end

function UpdateCriminalBlip(value)
timesCalled = timesCalled + 1
if timesCalled > 50 and timesCalled < 70 then
radius = radius - 8
randomRadius = randomRadius -4
RemoveBlip(criminalBlip)
criminalBlip = nil
criminalBlip = CreateCriminalBlip(value)
else
SetBlipCoords(criminalBlip, value.x + (math.random(-randomRadius, randomRadius)), value.y + (math.random(-randomRadius, randomRadius)), value.z + (math.random(-randomRadius, randomRadius)))
end
end

RegisterNetEvent('UpdatePolicePositions')
AddEventHandler('UpdatePolicePositions', function(value)
    if not copBlipCreated then 
        for index, value in ipairs(value) do
            policeBlip = AddBlipForCoord(value.loc)
            SetBlipSprite(policeBlip, 41)
            SetBlipScale(policeBlip, 0.8)
            ShowNumberOnBlip(policeBlip, index)
           copInfo = {
               name = value.name,
               blip = policeBlip,
               copLoc = value.loc 
           }
           table.insert(copBlips, 1, copInfo)
        end
        copBlipCreated = true    
    else
        for copIndex, copValue in ipairs(copBlips) do
            for index, value in ipairs(value) do
                if copValue.name == value.name then
                    loc = value.loc
                    SetBlipCoords(copValue.blip, loc)
                end
            end
    end
    end
end)

function SetupCriminalWeaponry()
   local ped = PlayerPedId()
   GiveWeaponToPed(ped, 0x1B06D571, 100, false, false)
end

function SetupCopWeaponry()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, 0x1B06D571, 100, false, false)
    GiveWeaponToPed(ped, 911657153, 100, false, false)
 end

 Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)

		if handcuff and not IsEntityPlayingAnim(GetPlayerPed(PlayerId()), "mp_arresting", "idle", 3) then
			Citizen.Wait(3000)
			Citizen.Trace("BACKUP CUFFING TRIGGERED")
			TaskPlayAnim(GetPlayerPed(PlayerId()), "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
		end

		if IsEntityPlayingAnim(GetPlayerPed(PlayerId()), "mp_arresting", "idle", 3) then
			DisableControlAction(1, 140, true)
			DisableControlAction(1, 141, true)
			DisableControlAction(1, 142, true)
			SetPedPathCanUseLadders(GetPlayerPed(PlayerId()), false)
			if IsPedInAnyVehicle(GetPlayerPed(PlayerId()), false) then
				DisableControlAction(0, 59, true)
			end
		end
	end
end)


