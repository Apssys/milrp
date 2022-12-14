hook.Add("PlayerNoClip", "opsNoclip", function(ply, state)
	if ply:IsAdmin() then
		if SERVER then
			if state then
				mrp.Ops.Cloak(ply)
				ply:GodEnable()
				ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)

				if ply:FlashlightIsOn() then
					ply:Flashlight(false)
				end

				ply:AllowFlashlight(false)
			else
				mrp.Ops.Uncloak(ply)
				ply:GodDisable()
				ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				ply:AllowFlashlight(true)
			end
		end

		return true
	end
end)