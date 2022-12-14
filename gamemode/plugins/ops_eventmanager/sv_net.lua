util.AddNetworkString("mrpOpsEMMenu")
util.AddNetworkString("mrpOpsEMPushSequence")
util.AddNetworkString("mrpOpsEMUpdateEvent")
util.AddNetworkString("mrpOpsEMPlaySequence")
util.AddNetworkString("mrpOpsEMStopSequence")
util.AddNetworkString("mrpOpsEMClientsideEvent")
util.AddNetworkString("mrpOpsEMIntroCookie")
util.AddNetworkString("mrpOpsEMPlayScene")
util.AddNetworkString("mrpOpsEMEntAnim")

net.Receive("mrpOpsEMPushSequence", function(len, ply)
	if (ply.nextOpsEMPush or 0) > CurTime() then return end
	ply.nextOpsEMPush = CurTime() + 1

	if not ply:IsEventAdmin() then
		return
	end

	local seqName = net.ReadString()
	local seqEventCount = net.ReadUInt(16)
	local events = {}

	print("[ops-em] Starting pull of "..seqName.." (by "..ply:Nick().."). Total events: "..seqEventCount.."")

	for i=1, seqEventCount do
		local dataSize = net.ReadUInt(16)
		local eventData = pon.decode(net.ReadData(dataSize))

		table.insert(events, eventData)
		print("[ops-em] Got event "..i.."/"..seqEventCount.." ("..eventData.Type..")")
	end

	mrp.Ops.EventManager.Sequences[seqName] = events

	print("[ops-em] Finished pull of "..seqName..". Ready to play sequence!")

	if IsValid(ply) then
		ply:Notify("Push completed.")
	end
end)

net.Receive("mrpOpsEMPlaySequence", function(len, ply)
	if (ply.nextOpsEMPlay or 0) > CurTime() then return end
	ply.nextOpsEMPlay = CurTime() + 1

	if not ply:IsEventAdmin() then
		return
	end

	local seqName = net.ReadString()

	if not mrp.Ops.EventManager.Sequences[seqName] then
		return ply:Notify("Sequence does not exist on server (push first).")
	end

	if mrp.Ops.EventManager.GetSequence() == seqName then
		return ply:Notify("Sequence already playing.")
	end

	mrp.Ops.EventManager.PlaySequence(seqName)

	print("[ops-em] Playing sequence "..seqName.." (by "..ply:Nick()..").")
	ply:Notify("Playing sequence "..seqName..".")
end)

net.Receive("mrpOpsEMStopSequence", function(len, ply)
	if (ply.nextOpsEMStop or 0) > CurTime() then return end
	ply.nextOpsEMStop = CurTime() + 1

	if not ply:IsEventAdmin() then
		return
	end

	local seqName = net.ReadString()

	if not mrp.Ops.EventManager.Sequences[seqName] then
		return ply:Notify("Sequence does not exist on server (push first).")
	end

	if mrp.Ops.EventManager.GetSequence() != seqName then
		return ply:Notify("Sequence not playing.")
	end

	mrp.Ops.EventManager.StopSequence(seqName)

	print("[ops-em] Stopping sequence "..seqName.." (by "..ply:Nick()..").")
	ply:Notify("Stopped sequence "..seqName..".")
end)

net.Receive("mrpOpsEMIntroCookie", function(len, ply)
	if ply.usedIntroCookie or not mrp.Ops.EventManager.GetEventMode() then
		return
	end
	
	ply.usedIntroCookie = true

	ply:AllowScenePVSControl(true)

	timer.Simple(900, function()
		if IsValid(ply) then
			ply:AllowScenePVSControl(false)
		end
	end)
end)