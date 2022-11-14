function GM:Think()
    for k, v in ipairs(player.GetAll()) do
		if ( v and IsValid(v) and v:Alive() ) then
			if not ( v.fov ) then
				v.fov = v:GetFOV() or 95
			end

			if not ( v.runspeed ) then
				v.runspeed = 200
			end

			if not ( v.walkspeed ) then
				v.walkspeed = 100
			end

			if not ( v.isPlayingSound ) then
				v.isPlayingSound = false
			end

			if not ( v.isLazy ) then
				v.isLazy = false
			end

			local wep = v:GetActiveWeapon()

			if ( IsValid(wep) ) then
				v:SetAmmo(9999, wep:GetPrimaryAmmoType())
			end

			if ( IsValid(v:GetActiveWeapon()) ) then
				local wep = v:GetActiveWeapon()

				if ( wep.GetToggleAim ) then
					if ( wep:GetToggleAim() ) then
						v.walkspeed = 70
					else
						v.walkspeed = 100
					end
				else
					v.walkspeed = 100
				end
			end

			if ( v:IsSprinting() and v:GetVelocity():Length() != 0 ) then
				v.runspeed = Lerp(0.0030, v.runspeed, 320)
				v.fov = Lerp(0.1, v.fov or 95, 110)
			else
				v.runspeed = Lerp(0.01, v.runspeed, 200)
				v.fov = Lerp(0.1, v.fov or 95, 95)
			end

			if ( v.isLazy ) then
				v.runspeed = 100
				v.walkspeed = 100

				if not ( v.isPlayingSound ) then
					v:EmitSound("player/breathe1.wav")
					v.isPlayingSound = true

					timer.Simple(SoundDuration("player/breathe1.wav"), function()
						v:StopSound("player/breathe1.wav")
						v.isPlayingSound = false
					end)
				end
			end
			
			if not ( timer.Exists(v:SteamID64().."RunTimer") ) then
				timer.Create(v:SteamID64().."RunTimer", 0, 0, function()
					if ( v.runspeed > 300 ) then
						v.isLazy = true
						timer.Simple(5, function()
							v.isLazy = false
						end)
					end
				end)
			else
				timer.Remove(v:SteamID64().."RunTimer")
				timer.Create(v:SteamID64().."RunTimer", 0, 0, function()
					if ( v.runspeed > 300 ) then
						v.isLazy = true
						timer.Simple(5, function()
							v.isLazy = false
						end)
					end
				end)
			end

			v:SetRunSpeed(v.runspeed)
			v:SetFOV(v.fov)
			v:SetWalkSpeed(v.walkspeed)
		end
    end
end

function GM:PlayerInitialSpawn(ply)
    timer.Simple(1, function()
        ply:KillSilent()
        ply:SendLua([[vgui.Create("MilMainMenu")]])
    end)
end

local talkCol = Color(255, 255, 100)
local infoCol = Color(135, 206, 250)
local strTrim = string.Trim
function GM:PlayerSay(ply, text, teamChat, newChat)
	if teamChat == true then return "" end -- disabled team chat

	text = strTrim(text, " ")

	hook.Run("iPostPlayerSay", ply, text)

	if string.StartWith(text, "/") then
		local args = string.Explode(" ", text)
		local command = mrp.chatCommands[string.lower(args[1])]
		if command then
			if command.cooldown and command.lastRan then
				if command.lastRan + command.cooldown > CurTime() then
					return ""
				end
			end

			if command.adminOnly == true and ply:IsAdmin() == false then
				ply:Notify("You must be an admin to use this command.")
				return ""
			end

			if command.leadAdminOnly == true and not ply:IsLeadAdmin() then
				ply:Notify("You must be a lead admin to use this command.")
				return ""
			end

			if command.superAdminOnly == true and ply:IsSuperAdmin() == false then
				ply:Notify("You must be a super admin to use this command.")
				return ""
			end

			if command.requiresArg and (not args[2] or string.Trim(args[2]) == "") then return "" end
			if command.requiresAlive and not ply:Alive() then return "" end

			text = string.sub(text, string.len(args[1]) + 2)

			table.remove(args, 1)
			command.onRun(ply, args, text)
		else
			ply:Notify("The command "..args[1].." does not exist.")
		end
	elseif ply:Alive() then
		text = hook.Run("ProcessICChatMessage", ply, text) or text
		text = hook.Run("ChatClassMessageSend", 1, text, ply) or text

		for v,k in pairs(player.GetAll()) do
			if (ply:GetPos() - k:GetPos()):LengthSqr() <= (300 ^ 2) then
				k:SendChatClassMessage(1, text, ply)
			end
		end

		hook.Run("PostChatClassMessageSend", 1, text, ply)
	end

	return ""
end

util.AddNetworkString("mrpChatMessage")

net.Receive("mrpChatMessage", function(len, ply) -- should implement a check on len here instead of string.len
	if (ply.nextChat or 0) < CurTime() then
		if len > 15000 then
			ply.nextChat = CurTime() + 1 
			return
		end

		local text = net.ReadString()
		ply.nextChat = CurTime() + 0.3 + math.Clamp(#text / 300, 0, 4)
		
		text = string.sub(text, 1, 1024)
		text = string.Replace(text, "\n", "")
		hook.Run("PlayerSay", ply, text, false, true)
	end
end)

util.AddNetworkString("milMainMenuSpawn")

net.Receive("milMainMenuSpawn", function(len, ply)
	if ( ply:Team() == 0 ) then
        ply:SetTeam(TEAM_TERRORIST)
    end

	local name = net.ReadString()
    if ( ply.firstMenuSpawn or true ) then
        ply:Spawn()
		ply.firstMenuSpawn = false
    end
	ply:SetSyncVar(SYNC_RPNAME, name, true)
	hook.Run("PlayerLoadout", ply)

	local modelr
	if ( isstring(mrp.Teams.Stored[ply:Team()].model) ) then
		modelr = mrp.Teams.Stored[ply:Team()].model
	elseif ( istable(mrp.Teams.Stored[ply:Team()].model) ) then
		modelr = table.Random(mrp.Teams.Stored[ply:Team()].model)
	end

	ply:Give("gmod_tool")
    ply:Give("weapon_physgun")
    ply:Give("mrp_hands")
    ply:Give("weapon_bsmod_punch")
    ply:SetModel(modelr or "models/bread/cod/characters/milsim/shadow_company.mdl")
    ply:Give("ix_rappel")
	ply:SetRunSpeed(200)
    ply:SetWalkSpeed(100)
    ply:SetJumpPower(160)
    ply:SetDuckSpeed(0.5)
    ply:SetUnDuckSpeed(0.5)
    ply:SetLadderClimbSpeed(100)
    ply:SetCrouchedWalkSpeed(0.6)
	ply:SetupHands(ply)
end)

util.AddNetworkString("milMainMenuChangeName")
util.AddNetworkString("milCallsignSet")

net.Receive("milCallsignSet", function(len, ply)
	local callsign = net.ReadString()

	ply:SetSyncVar(SYNC_CALLSIGN, callsign, true)
end)

net.Receive("milMainMenuChangeName", function(len, ply)
	local name = net.ReadString()

	ply:SetSyncVar(SYNC_RPNAME, name, true)
end)

function GM:PostCleanupMap()
	hook.Run("InitPostEntity")
end

function GM:GetFallDamage(ply, speed)
	local dmg = speed * 0.05

	if speed > 780 then
		dmg = dmg + 75
	end

	return dmg
end

concommand.Add("mrp_vehicle_collision", function(ply, cmd, args)
	local veh = ply:GetVehicle()

	if ( veh and IsValid(veh) ) then
		local rveh = veh:GetParent()
		if ( rveh ) then
			rveh:SetSyncVar(SYNC_COLLISIONS, (!rveh:GetSyncVar(SYNC_COLLISIONS, false)), true)
			if ( rveh:GetSyncVar(SYNC_COLLISIONS, false) ) then
				print("isOn")
				veh:SetCollisionGroup(COLLISION_GROUP_VEHICLE_CLIP)
				rveh:SetCollisionGroup(COLLISION_GROUP_VEHICLE_CLIP)
			else
				print("isOff")
				veh:SetCollisionGroup(0)
				rveh:SetCollisionGroup(0)
			end
		end
	end
end)

hook.Add("CanBreakHelicopterRotor", "TesthisLFSHook", function(ply, heli)
	if ( heli:GetCollisionGroup() == COLLISION_GROUP_VEHICLE_CLIP ) then return false end
	return true
end)

hook.Add("LFS.IsEngineStartAllowed", "alwaysAllowLFSStart", function()
	return true
end)

function GM:CanPlayerEnterVehicle(ply, vch, seatnumber)
	if ( ply:KeyDown(IN_WALK) ) then
		return false
	end

	return true
end

function GM:PlayerSpawn(ply, transition)
	if ( ply:Team() == 0 ) then
        ply:SetTeam(TEAM_TERRORIST)
    end

	local modelr
	if ( isstring(mrp.Teams.Stored[ply:Team()].model) ) then
		modelr = mrp.Teams.Stored[ply:Team()].model
	elseif ( istable(mrp.Teams.Stored[ply:Team()].model) ) then
		modelr = table.Random(mrp.Teams.Stored[ply:Team()].model)
	end

	ply:Give("gmod_tool")
    ply:Give("weapon_physgun")
    ply:Give("mrp_hands")
    ply:Give("weapon_bsmod_punch")
    ply:SetModel(modelr or "models/bread/cod/characters/milsim/shadow_company.mdl")
    ply:Give("ix_rappel")
	ply:SetRunSpeed(200)
    ply:SetWalkSpeed(100)
    ply:SetJumpPower(160)
    ply:SetDuckSpeed(0.5)
    ply:SetUnDuckSpeed(0.5)
    ply:SetLadderClimbSpeed(100)
    ply:SetCrouchedWalkSpeed(0.6)
	ply:SetupHands(ply)
end

util.AddNetworkString("mrpSetTeamIndex")

net.Receive("mrpSetTeamIndex", function(len, ply)
	local teamIndex = net.ReadUInt(8)

	ply:SetTeam(teamIndex)

	hook.Run("PlayerLoadout", ply)
end)