-- Profile.lua
-- Perintah: !profile {username/displayname}

return {
	Execute = function(msg, client)
		local vars = _G.BotVars or {}
		local TextChatService = vars.TextChatService or game:GetService("TextChatService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")

		-- Ambil isi pesan dari berbagai kemungkinan
		local content = tostring(msg.Text or msg.Message or msg.Body or "")
		local lowerContent = string.lower(content)

		-- Pastikan mengandung perintah !profile
		if not string.find(lowerContent, "!profile") then
			return
		end

		-- Ambil semua teks setelah !profile (termasuk spasi dan emoji)
		local username = string.match(content, "!profile%s+(.+)")
		if username then
			username = username:gsub("^%s*(.-)%s*$", "%1") -- trim spasi
		end

		-- Dapatkan channel chat
		local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

		-- Validasi input
		if not username or username == "" then
			if channel then
				channel:SendAsync("⚠️ Format salah! Gunakan: !profile {username/displayname}")
			else
				warn("⚠️ Tidak ada channel RBXGeneral ditemukan!")
			end
			return
		end

		print("[DEBUG] Username input:", username)

		-- Coba dapatkan UserId dari username
		local targetUserId = nil
		local ok, result = pcall(function()
			return Players:GetUserIdFromNameAsync(username)
		end)

		if ok and result then
			targetUserId = result
		else
			-- Coba cocokkan displayname atau username di server
			for _, player in ipairs(Players:GetPlayers()) do
				if string.lower(player.DisplayName) == string.lower(username)
				or string.lower(player.Name) == string.lower(username) then
					targetUserId = player.UserId
					break
				end
			end
		end

		-- Jika tetap tidak ketemu
		if not targetUserId then
			if channel then
				channel:SendAsync("❌ Pengguna '" .. username .. "' tidak ditemukan.")
			end
			return
		end

		print("[DEBUG] Found UserId:", targetUserId)

		-- Ambil data profil dari server
		local playerDataProvider = ReplicatedStorage
			:WaitForChild("Connections")
			:WaitForChild("dataProviders")
			:WaitForChild("playerData")

		local statsResult
		local success, err = pcall(function()
			local argsStats = {"getPlayerStats", targetUserId}
			statsResult = playerDataProvider:InvokeServer(unpack(argsStats))
		end)

		print("[DEBUG] InvokeServer success:", success, "stats:", statsResult)

		if not success or not statsResult then
			if channel then
				channel:SendAsync("⚠️ Gagal mengambil data profil untuk '" .. username .. "'.")
			end
			return
		end

		-- Ambil nilai dari hasil data
		local connections = statsResult.Connections or statsResult.connections or statsResult.Friends or 0
		local followers = statsResult.Followers or statsResult.followers or 0
		local following = statsResult.Following or statsResult.following or 0

		local message = string.format(
			"📊 Profil %s:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d",
			username, connections, followers, following
		)

		if channel then
			pcall(function()
				channel:SendAsync(message)
			end)
		else
			print(message)
		end
	end
}
