local health = 800

Citizen.CreateThread(function()
while true do
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        local vehicle = GetVehiclePedIsIn((PlayerPedId()), false)
        if GetVehicleBodyHealth(vehicle) > 800 then
            print(GetVehicleBodyHealth(vehicle))
            SetVehicleEngineHealth(vehicle, GetVehicleBodyHealth(vehicle))
        else
            if GetVehicleBodyHealth(vehicle) < 800 and GetVehicleBodyHealth(vehicle) > 700 then
                SetVehicleEngineHealth(vehicle, 450.0)
                SetVehicleBodyHealth(vehicle, 450.0)
                print(GetVehicleBodyHealth(vehicle))
            else
                SetVehicleEngineHealth(vehicle, GetVehicleBodyHealth(vehicle))
                print(GetVehicleBodyHealth(vehicle))
            end
        end
        
    end
    Citizen.Wait(200)
    end
end)

