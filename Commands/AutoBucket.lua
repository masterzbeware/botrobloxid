-- AutoBucket.lua (FINAL FIX)

return {
	Execute = function(tab)
		local vars = _G.BotVars or {}
		local Tabs = vars.Tabs or {}
		local MainTab = tab or Tabs.Main

		if not MainTab then
			warn("[AutoBucket] Tab tidak ditemukan!")
			return
		end

		-- =========================
		-- UI GROUP
		-- =========================
		local Group
		if typeof(MainTab.AddRightGroupbox) == "function" then
			Group = MainTab:AddRightGroupbox("Auto Fill")
		else
			Group = MainTab:AddLeftGroupbox("Auto Fill")
			warn("[AutoBucket] AddRightGroupbox tidak tersedia, gunakan kiri")
		end

		-- =========================
		-- DEFAULT SETTINGS
		-- =========================
		vars.AutoFill = vars.AutoFill or false
		vars.FillDelay = vars.FillDelay or 1
		vars.FillTarget = vars.FillTarget or {"Brick Well"}

		_G.BotVars = vars

		-- =========================
		-- SERVICES
		-- =========================
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local LootService = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory")
		local FillBucket = LootService:WaitForChild("FillBucket")

		local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

		-- =========================
		-- UI: TOGGLE
		-- =========================
		Group:AddToggle("ToggleAutoFill", {
			Text = "Auto Fill Well",
			Default = vars.AutoFill,
			Callback = function(v)
				vars.AutoFill = v
				print("[AutoBucket] Status:", v and "Aktif" or "Mati")
			end
		})

		-- =========================
		-- WELL LIST
		-- =========================
		local allowedWells = {"Brick Well", "Stone Well"}

		-- =========================
		-- UI: DROPDOWN TARGET
		-- =========================
		task.delay(0.7, function()
			if Group.AddDropdown then
				local dropdown = Group:AddDropdown("DropdownFillTarget", {
					Text = "Pilih Well",
					Values = allowedWells,
					Multi = true,
					Default = vars.FillTarget,
					Callback = function(v)
						vars.FillTarget = v
						print("[AutoBucket] Target:", table.concat(v, ", "))
					end
				})

				if dropdown.SetValue and typeof(vars.FillTarget) == "table" then
					dropdown:SetValue(vars.FillTarget)
				end
			else
				warn("[AutoBucket] Dropdown UI tidak tersedia")
			end
		end)

		-- =========================
		-- UI: SLIDER DELAY
		-- =========================
		Group:AddSlider("FillDelaySlider", {
			Text = "Delay Fill (detik)",
			Default = vars.FillDelay,
			Min = 0.2,
			Max = 4,
			Rounding = 0.1,
			Compact = true,
			Callback = function(v)
				vars.FillDelay = v
			end
		})

		-- =========================
		-- MAIN LOOP
		-- =========================
		task.spawn(function()
			while task.wait(vars.FillDelay) do
				if not vars.AutoFill then continue end

				for i, block in ipairs(LoadedBlocks:GetChildren()) do
					if not vars.AutoFill then break end
					if not table.find(vars.FillTarget, block.Name) then continue end
					if not block:IsA("Model") then continue end

					local voxel = block:GetAttribute("VoxelPosition")
					if not voxel then continue end

					local success, err = pcall(function()
						FillBucket:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
					end)

					if success then
						print("[AutoBucket] Fill →", block.Name, "index:", i)
					else
						warn("[AutoBucket] Gagal:", block.Name, "error:", err)
					end

					task.wait(0.2)
				end
			end
		end)

		print("[AutoBucket] Sistem Aktiv ✓ | Target:", table.concat(vars.FillTarget, ", "))
	end
}
