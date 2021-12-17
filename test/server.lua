 local queueHasStarted = false;
 local copchaseStarted = false;
 local players = {};
 local timer = 20;
 local criminal;
 local playerscount;

 local actualCriminal;
 local actualCops = {};

 local timesUpdatedCriminal = 0





RegisterNetEvent("Handcuff")
AddEventHandler("Handcuff", function()
    local currentCop = GetPlayerPed(source)
    local copCoords = GetEntityCoords(currentCop)
    local criminalCoords = GetEntityCoords(GetPlayerPed(actualCriminal))
    TriggerClientEvent('GetDistance', source, copCoords, criminalCoords)
end)



RegisterNetEvent("TryCuff")
AddEventHandler("TryCuff", function(distance)
    if distance < 2 then
        TriggerClientEvent('chat:addMessage', -1, ''.. GetPlayerName(source) .. ' is cuffing the criminal: ' .. GetPlayerName(actualCriminal) .. '. The police have won this round!', {255, 255, 255})
        TriggerClientEvent('CriminalHandcuff', actualCriminal)
        Citizen.Wait(2000)
        ResetCopChase()
        else
        TriggerClientEvent('chat:addMessage', source, 'You are too far away from the criminal! Or he is inside a car.', {255, 255, 255}) 
    end
end)

RegisterCommand('copchase', function(source, args, rawCommand) 
    if not queueHasStarted then
        TriggerClientEvent('chat:addMessage', -1, 'Copchase started by: ' .. GetPlayerName(source) .. '', {255, 255, 255})
        queueHasStarted = true;
        table.insert(players, 1, source);
        playerscount = 1;
            Citizen.CreateThread(function()
                while timer > 0 do
                TriggerClientEvent('chat:addMessage', -1, 'Copchase has been started, type /join to participate! ' .. timer ..' Seconds left!' , {0, 0, 255})
                timer = timer - 1;
                Citizen.Wait(1000);
                if timer == 0 then
                    TriggerClientEvent('chat:addMessage', -1, 'Copchase has started!', {0, 0, 255})
                    copchaseStarted = true;
                    criminal = math.random(1, playerscount)
                    for index, value in ipairs(players) do
                        if criminal == index then   
                        actualCriminal = value
                        TriggerClientEvent('EventManager:Client:StartCopchase', value, true)
                        else 
                            copInfo = {
                                player = value,
                                name = GetPlayerName(value),
                                copLoc = nil;
                            }
                        table.insert(actualCops, 1, copInfo)    
                        TriggerClientEvent('EventManager:Client:StartCopchase', value, false, index)
                        UpdatePolicePositions(); 
                        end
                    end
                end
            end
        end)
    else 
        TriggerClientEvent('chat:addMessage', source, 'Copchase already started use /join to join the copchase.', {255, 255, 255})
    end  
end)

RegisterCommand('join', function(source, args, rawCommand)
    if not copchaseStarted then
    if queueHasStarted then
    local alreadyjoined = false;
    for index, value in ipairs(players) do
        if(GetPlayerName(value) == GetPlayerName(source)) then
            alreadyjoined = true;
        end
    end
    if alreadyjoined then
        TriggerClientEvent('chat:addMessage', source, 'You already joined the copchase!', {255, 255, 255})
    else
        table.insert(players, 1, source)
        playerscount = playerscount + 1;
        TriggerClientEvent('EventManager:Client:JoinCopChase', source, playerscount)
        TriggerClientEvent('chat:addMessage', -1,'' .. GetPlayerName(source) ..  ' joined the chase! Current players: ' .. tostring(playerscount) .. '!', {0, 0, 255})    
    end
else 
    TriggerClientEvent('chat:addMessage', source, 'Copchase has not started yet, type /copchase to start the queue!', {255, 255, 255})
end
else 
    TriggerClientEvent('chat:addMessage', source, 'Copchase has already started, you can not join!', {255, 255, 255})
end
end)


RegisterNetEvent("UpdateCriminalPosition")
AddEventHandler("UpdateCriminalPosition", function()
Citizen.CreateThread(function()
while copchaseStarted do
    timesUpdatedCriminal = timesUpdatedCriminal + 1
    if timesUpdatedCriminal < 60 then
    GetCriminalPosition()
    Citizen.Wait(10000)
else
    GetCriminalPosition()
    Citizen.Wait(2000)
end
end
end)
end)   


function GetCriminalPosition()
    local playedPed = GetPlayerPed(actualCriminal)
    local criminalLoc = GetEntityCoords(playedPed)
    for index, value in ipairs(players) do
        TriggerClientEvent('EventManager:Client:UpdateCriminalPosition', value, criminalLoc)
    end
end

function UpdatePolicePositions()
    Citizen.CreateThread(function()
        while copchaseStarted do
            for index, value in ipairs(actualCops) do
                actualCops[index].loc = GetEntityCoords(GetPlayerPed(actualCops[index].player))
            end
            for index, value in ipairs(actualCops) do
                TriggerClientEvent('UpdatePolicePositions', value.player, actualCops)
            end
            Citizen.Wait(250)
        end
    end)
end

AddEventHandler('playerDropped', function (reason)
    print('Player ' .. GetPlayerName(source) .. ' dropped (Reason: ' .. reason .. ')')
        if source == actualCriminal then
            ResetCopChase()
        end
    end)


    RegisterServerEvent('playerDied')
    AddEventHandler('playerDied',function(killer,reason)
    if source == actualCriminal then
        ResetCopChase()
    end    
	--if killer == "**Invalid**" then 
		--reason = 2
	--end
	--if reason == 0 then
		--TriggerClientEvent('showNotification', -1,"~o~".. GetPlayerName(source).."~w~ committed suicide. ")
	--elseif reason == 1 then
		--TriggerClientEvent('showNotification', -1,"~o~".. killer .. "~w~ killed ~o~"..GetPlayerName(source).."~w~.")
	--else
		--TriggerClientEvent('showNotification', -1,"~o~".. GetPlayerName(source).."~w~ died.")
	--end
end)

function ResetCopChase()
    Citizen.CreateThread(function ()
        Citizen.Wait(2000)
    for index, value in ipairs(players) do
        TriggerClientEvent('ResetToSpawn', value)
    end    
    players = {}
    copchaseStarted = false;
    queueHasStarted = false;
    actualCops = {};
    actualCriminal = nil;
    playerscount = 0;
    timer = 20;
    timesUpdatedCriminal = 0
end)
end



