local isACop = false
local RobberyCheckpoints = {{loc = vector3(26.49102, -1345.805, 29.49702), name = "South LS Convenient store.", isRobbed = false, maxCash = 5000}, {loc = vector3(146.6646, -1044.801, 29.37783), name = "Bank", isRobbed = false, maxCash = 10000}, 
{loc = vector3(22.53048, -1106.929, 29.79703), name = "Clothing store.", isRobbed = false, maxCash = 7500}, {loc = vector3(128.7673, -1286.727, 29.27997), name = "Stripper Place Thing", isRobbed = false, maxCash = 35000}, 
{loc = vector3(-48.43374, -17757.853, 29.42102), name = "Gas station.", isRobbed = false, maxCash = 5000}, {loc = vector3(841.8622, -1033.938, 28.19485), name = "Gun shop.", isRobbed = false, maxCash = 5000},
{loc = vector3(1211.51, -470.7179, 66.2802), name = "Barber shop.", isRobbed = false, maxCash = 5000}, {loc = vector3(1163.69, -324.2904, 69.20506), name = "Gas station.", isRobbed = false, maxCash = 5000}}
local minimumRobberyTime = 20
local money = 0;
local criminalLocationVisible = false
local createdCheckpoints = {}
local createdMinimapBlips = {}
local blipId = 59
local robberyTime = 0

RegisterNetEvent('EventManager:Client:StartCopchase')
AddEventHandler('EventManager:Client:StartCopchase', function()
Citizen.CreateThread(function ()
    Citizen.Wait(90000)
    if not criminalLocationVisible then
        print("Too long, updating criminal position now!")
        TriggerServerEvent("UpdateCriminalPosition")
    end
end)
end)

function CheckIfPlayerIsCop()
    isACop = exports.test:IsPlayerACop()
end


function SetUpRobberyPlaces()
    if not isACop then
    for index, value in ipairs(RobberyCheckpoints) do
        local checkpoint = CreateCheckpoint(47, value.loc.x, value.loc.y , value.loc.z -1, 0.0, 0.0, 0.0, 2.0, 255, 0, 0, 64, 0)
        SetCheckpointCylinderHeight(checkpoint, 2.0, 2.0, 2.0)
        table.insert(createdCheckpoints, 1, checkpoint)
        storeBlip = AddBlipForCoord(value.loc.x, value.loc.y , value.loc.z)
        SetBlipSprite(storeBlip, blipId)
        table.insert(createdMinimapBlips, storeBlip)
    end
    end
end

RegisterNetEvent('EventManager:Client:StartCopchase')
AddEventHandler('EventManager:Client:StartCopchase', function(criminal, position)
    CheckIfPlayerIsCop()
    SetUpRobberyPlaces()
end)

RegisterNetEvent("ResetToSpawn")
AddEventHandler("ResetToSpawn", function ()
    for index, value in ipairs(createdCheckpoints) do
        DeleteCheckpoint(value)
    end
    createdCheckpoints = {}
    for index, value in ipairs(createdMinimapBlips) do
        RemoveBlip(value)
    end
    createdMinimapBlips = {}
end)


RegisterCommand('rob', function()
 CheckIfPlayerIsCop()
 robberyTime = 0
 if not isACop then
     for index, value in ipairs(RobberyCheckpoints) do
          distance = GetDistanceToCheckpoint(value)
         if distance <= 2.0 then
            if value.isRobbed == false then 
                NotifyPolice(value)
                CheckRobberyStatus(value, distance)
            else
            TriggerEvent('chat:addMessage', {
                args = { 'You are either too far away from the checkpoint or this place has been recently robbed!' }
            }) 
            end
         end
     end
 end
end)

function GetDistanceToCheckpoint(value)
    local playerPosition = GetEntityCoords(GetPlayerPed(-1), true)
    local distance = GetDistanceBetweenCoords(playerPosition.x, playerPosition.y, playerPosition.z, value.loc.x, value.loc.y, value.loc.z, true)
    return distance
end

function NotifyPolice(value)
    TriggerServerEvent("NotifyRobbery", value.name)
    TriggerServerEvent("UpdateCriminalPosition")
    TriggerEvent('chat:addMessage', {
        args = { 'Stay in the red circle for ' ..minimumRobberyTime .. ' seconds or the robbery will fail!' }
    })
end

function CheckRobberyStatus(value, distance)
    Citizen.CreateThread(function()
        while robberyTime < minimumRobberyTime do
            distance = GetDistanceToCheckpoint(value)
            print(distance)
            if distance <= 2.0 then
            Citizen.Wait(1000)
            robberyTime = robberyTime + 1
            print(robberyTime)
            if robberyTime == 10 then
                TriggerEvent('chat:addMessage', {
                    args = { 'Halfway there, 10 more seconds to go!' }
                })
            end
            if robberyTime == minimumRobberyTime then
               local robbedMoney = math.random(1000, value.maxCash)
                money = money + robbedMoney
                TriggerEvent('chat:addMessage', {
                    args = { 'You sucessfully robbed: ' ..robbedMoney .. ' dollars!' }
                })
                value.isRobbed = true
            end
        else
            TriggerEvent('chat:addMessage', {
                args = { 'Robbery failed! Try again or flee!' }
            })
            return
        end
    end    
     end)
end

