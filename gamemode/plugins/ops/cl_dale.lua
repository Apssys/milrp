mrp.Ops = mrp.Ops or {}
mrp.Ops.Reports = mrp.Ops.Reports or {}

local strFind = string.find
local closeMsg = "If I've managed to solve your issue please say 'solved' to close the report."

local function doSay(message)
	mrp.Ops.NewLog({"(#"..mrp.Ops.CurReport..") ", "Automated reply", Color(172, 103, 0), " (Dale)", color_white, ": ", Color(208, 201, 198), message}, false)

	if mrp_userReportMenu and IsValid(mrp_userReportMenu) then
		mrp_userReportMenu:SetupUI()
	end
end

function mrp.Ops.DaleRead(message)
	if mrp.Ops.CurReportClaimed then
		return
	end

	message = string.Trim(message, " ")
	message = string.Replace(message, "\n", "")
	message = string.upper(message)

	local messageNoPunc = string.Replace(message, ".", "")
	messageNoPunc = string.Replace(messageNoPunc, "?", "")
	messageNoPunc = string.Replace(messageNoPunc, ",", "")
	messageNoPunc = string.Replace(messageNoPunc, "!", "")

	if messageNoPunc == "SOLVED" and mrp.Ops.CurReport and OPS_LASTMSG_CLOSE then
		doSay("Thanks for your report! Have a great day!")

		net.Start("opsReportDaleClose")
		net.SendToServer()
		return
	end
end

function mrp.Ops.DaleSay(message, requestClose)
	if mrp.Ops.CurReport then
		LocalPlayer():Notify("A game moderator has replied to your report. Press F3 to view it.")
		doSay(message)

		if requestClose then
			timer.Simple(3, function()
				if mrp.Ops.CurReport then
					doSay(closeMsg)
					OPS_LASTMSG_CLOSE = true
				end
			end)
		end

		net.Start("opsReportDaleRepliedDo")
		net.SendToServer()
	end
end