local QBCore = exports['qb-core']:GetCoreObject()

local Active = false
local emtVeh = nil
local emtPed = nil
local spam = true

 


RegisterCommand("emt911", function(source, args, raw)
	if (QBCore.Functions.GetPlayerData().metadata["isdead"]) or (QBCore.Functions.GetPlayerData().metadata["inlaststand"]) and spam then
		QBCore.Functions.TriggerCallback('npcemt:docOnline', function(EMSOnline, hasEnoughMoney)
			if EMSOnline <= Config.Doctor and hasEnoughMoney and spam then
				SpawnVehicle(GetEntityCoords(PlayerPedId()))
				Notify("Medic is arriving")
			else
				if EMSOnline > Config.Doctor then
					Notify("There Are EMTs Online. Call /911 Instead", "error")
				elseif not hasEnoughMoney then
					Notify("Not Enough Money To Pay For Service", "error")
				else
					Notify("Wait, Paramedic Is On The Way", "primary")
				end	
			end
		end)
	else
		Notify("This Can Only Be Used While Incapacitated", "error")
	end
end)



function SpawnVehicle(x, y, z)  
	spam = false
	local vehhash = GetHashKey("ambulance")                                                     
	local loc = GetEntityCoords(PlayerPedId())
	RequestModel(vehhash)
	while not HasModelLoaded(vehhash) do
		Wait(1)
	end
	RequestModel('s_m_m_paramedic_01')
	while not HasModelLoaded('s_m_m_paramedic_01') do
		Wait(1)
	end
	local spawnRadius = 60                                                    
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(loc.x + math.random(-spawnRadius, spawnRadius), loc.y + math.random(-spawnRadius, spawnRadius), loc.z, 0, 3, 0)

	if not DoesEntityExist(vehhash) then
        mechVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)                        
        ClearAreaOfVehicles(GetEntityCoords(mechVeh), 5000, false, false, false, false, false);  
        SetVehicleOnGroundProperly(mechVeh)
		SetVehicleNumberPlateText(mechVeh, "EMT 911")
		SetEntityAsMissionEntity(mechVeh, true, true)
		SetVehicleEngineOn(mechVeh, true, true, false)
		SetVehicleSiren(mechVeh, true)
        
        mechPed = CreatePedInsideVehicle(mechVeh, 26, GetHashKey('s_m_m_paramedic_01'), -1, true, false)              	
        
        mechBlip = AddBlipForEntity(mechVeh)                                                        	
        SetBlipFlashes(mechBlip, true)  
        SetBlipColour(mechBlip, 5)


		PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
		Wait(2000)
		TaskVehicleDriveToCoord(mechPed, mechVeh, loc.x, loc.y, loc.z, 20.0, 0, GetEntityModel(mechVeh), 524863, 2.0)
		emtVeh = mechVeh
		emtPed = mechPed
		Active = true
    end
end

Citizen.CreateThread(function()
    while true do
      Citizen.Wait(200)
        if Active then
            local loc = GetEntityCoords(GetPlayerPed(-1))
			local lc = GetEntityCoords(emtVeh)
			local ld = GetEntityCoords(emtPed)
            local dist = Vdist(loc.x, loc.y, loc.z, lc.x, lc.y, lc.z)
			local dist1 = Vdist(loc.x, loc.y, loc.z, ld.x, ld.y, ld.z)
            if dist <= 10 then
				if Active then
					TaskGoToCoordAnyMeans(emtPed, loc.x, loc.y, loc.z, 2.0, 0, 0, 786603, 0xbf800000)
				end
				if dist1 <= 1 then 
					Active = false
					ClearPedTasksImmediately(emtPed)
					DoctorNPC()
				end
            end
        end
    end
end)


function DoctorNPC()
	RequestAnimDict("mini@cpr@char_a@cpr_str")
	while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
		Citizen.Wait(1000)
	end

	TaskPlayAnim(emtPed, "mini@cpr@char_a@cpr_str","cpr_pumpchest",1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
	QBCore.Functions.Progressbar("revive_emt", "The EMT Is Giving You Medical Aid", Config.ReviveTime, false, false, {
		disableMovement = false,
		disableCarMovement = false,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		TriggerServerEvent('npcemt:charge')
		Citizen.Wait(500)
        	TriggerEvent("hospital:client:Revive")
		StopScreenEffect('DeathFailOut')	
		Notify("Your Treatment Is Complete. You Were Charged: "..Config.Price, "success")
		TaskEnterVehicle(emtPed, emtVeh, 20000, -1, 1.0, 0, any)
		ClearPedTasks(emtPed)
		SetVehicleSiren(emtVeh, false)
		TaskVehicleDriveWander(emtPed, emtVeh, 55.0, 447)
            local emtDist = #(GetEntityCoords(emtPed) - GetEntityCoords(PlayerPedId()))
            while emtDist < 100.0 do
                emtDist = #(GetEntityCoords(emtPed) - GetEntityCoords(PlayerPedId()))
                Wait(100)
            end
		SetEntityAsNoLongerNeeded(emtPed)
		SetEntityAsNoLongerNeeded(emtVeh)
		spam = true
	end)
end

function Notify(msg, state)
    QBCore.Functions.Notify(msg, state)
end
