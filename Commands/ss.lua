--Decompiled by Medal, I take no credit I only Made The dumper and I I.. I iron man
local v_u_1 = game:GetService("MarketplaceService")
local v2 = game:GetService("Teams")
local v_u_3 = {}
local v4 = {
	["Trained Search and Rescue"] = {
		["ID"] = 5315995,
		["RANK"] = 30,
		["ACTIVE"] = true
	},
	["Trained Guide"] = {
		["ID"] = 4542650,
		["RANK"] = 70,
		["ACTIVE"] = true
	}
}
v_u_3.TEAM_GROUP_DATA = v4
v_u_3.TEAMS = {
	["Base Camp Doctors"] = v2:WaitForChild("Base Camp Doctors"),
	["Climbers"] = v2:WaitForChild("Climbers"),
	["Climbing Guides"] = v2:WaitForChild("Climbing Guides"),
	["Search and Rescue"] = v2:WaitForChild("Search and Rescue"),
	["Sherpas"] = v2:WaitForChild("Sherpas"),
	["Trained Search and Rescue"] = v2:WaitForChild("Trained Search and Rescue"),
	["Trained Guide"] = v2:WaitForChild("Trained Guide")
}
v_u_3.TEAM_GAMEPASS = {
	["Sherpas"] = 6342451,
	["Climbing Guides"] = 6342445,
	["Base Camp Doctors"] = 6342450,
	["Search and Rescue"] = 6342441
}
v_u_3.TEAM_TOOLS = {
	["Climbers"] = {},
	["Sherpas"] = {
		"Sherpa Helmet",
		"Sherpa Backpack",
		"Red Whistle",
		"Range Flashlight",
		"Bandages",
		"Flare Gun",
		"Handheld Lamp",
		"Portable Oxygen",
		"Portable Water",
		"Advanced Bandages",
		"Medical Kit"
	},
	["Climbing Guides"] = {
		"Guide Helmet",
		"Guide Backpack",
		"Red Whistle",
		"Bandages",
		"Flare Gun",
		"Laser Pointer",
		"Portable Oxygen",
		"Portable Water",
		"Advanced Bandages"
	},
	["Search and Rescue"] = {
		"Rescue Helmet",
		"Rescue Backpack",
		"Red Whistle",
		"Flood Flashlight",
		"Rescue Basket",
		"Flare Gun",
		"Handheld Lamp",
		"Medical Kit"
	},
	["Trained Search and Rescue"] = {
		"Rescue Helmet",
		"Rescue Backpack",
		"Red Whistle",
		"Rescue Basket",
		"Flare Gun",
		"Handheld Lamp",
		"Medical Kit"
	},
	["Base Camp Doctors"] = {
		"Medical Helmet",
		"Medical Backpack",
		"Advanced Medical Kit",
		"Advanced Bandages",
		"Portable Oxygen",
		"Red Whistle"
	},
	["Trained Guide"] = {
		"Guide Helmet",
		"Guide Backpack",
		"Red Whistle",
		"Advanced Bandages",
		"Flare Gun",
		"Handheld Lamp",
		"Laser Pointer",
		"Portable Oxygen",
		"Portable Water"
	}
}
v_u_3.TEAM_PROMPTS = {
	["Search and Rescue"] = "SearchRescueTeamPrompt",
	["Sherpas"] = "SherpaTeamPrompt",
	["Base Camp Doctors"] = "DoctorTeamPrompt",
	["Climbing Guides"] = "GuideTeamPrompt"
}
v_u_3.gamepass_cache = {}
function v_u_3.check_team_perms(p5, p6, p7)
	-- upvalues: (copy) v_u_3, (copy) v_u_1
	local v8 = v_u_3.TEAM_GAMEPASS[p6]
	local v9 = v_u_3.TEAM_GROUP_DATA[p6]
	if v8 then
		v_u_3.gamepass_cache[v8] = v_u_3.gamepass_cache[v8] or {}
		if v_u_3.gamepass_cache[v8][p5.UserId] then
			return true
		end
		local v10, v11 = pcall(v_u_1.UserOwnsGamePassAsync, v_u_1, p5.UserId, v8)
		if p7 and (v10 and not v11) then
			v_u_1:PromptGamePassPurchase(p5, v8)
		end
		return v10 and v11 and v11 or false
	end
	if not v9 then
		return true
	end
	if not v9.ACTIVE then
		return false
	end
	local v12, v13 = pcall(p5.GetRankInGroup, p5, v9.ID)
	if not v12 then
		return false
	end
	local v14 = v9.RANK <= v13
	return v12 and v14 and v14 or false
end
return v_u_3
