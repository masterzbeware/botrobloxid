-- AutoPlace.lua
return {
	Execute = function(tab)
		-- =========================
		-- GLOBAL VARS
		-- =========================
		local vars = _G.BotVars or {}
		vars.AutoPlace     = vars.AutoPlace or false
		vars.PlaceDelay    = vars.PlaceDelay or 0.3
		vars.PlaceItemId   = vars.PlaceItemId or 1
		vars.PlaceOffsetX  = vars.PlaceOffsetX or 0 -- ✅ sekarang bisa 0
		vars.PlaceOffsetY  = vars.PlaceOffsetY or 0 -- ✅ sekarang bisa 0
		vars._AutoPlaceRun = vars._AutoPlaceRun or false
		_G.BotVars = vars

		-- =========================
		-- TAB & UI
		-- =========================
		local Tabs = vars.Tabs or {}
		local MainTab = tab or Tabs.Main
		if not MainTab then return end

		local Group = MainTab:AddLeftGroupbox("Auto Place")

		Group:AddToggle("ToggleAutoPlace", {
			Text = "Auto Place",
			Default = vars.AutoPlace,
			Callback = function(v)
				vars.AutoPlace = v
				print("[AutoPlace] Toggle:", v and "ON" or "OFF")
			end
		})

		Group:AddSlider("SliderPlaceDelay", {
			Text = "Delay (detik)",
			Min = 0.1,
			Max = 3,
			Default = vars.PlaceDelay,
			Rounding = 1,
			Callback = function(v)
				vars.PlaceDelay = v
			end
		})

		-- ✅ Slider X (0..3)
		Group:AddSlider("SliderPlaceOffsetX", {
			Text = "Offset X",
			Min = 0,
			Max = 3,
			Default = vars.PlaceOffsetX,
			Rounding = 0,
			Callback = function(v)
				vars.PlaceOffsetX = v
			end
		})

		-- ✅ Slider Y (0..3)
		Group:AddSlider("SliderPlaceOffsetY", {
			Text = "Offset Y",
			Min = 0,
			Max = 3,
			Default = vars.PlaceOffsetY,
			Rounding = 0,
			Callback = function(v)
				vars.PlaceOffsetY = v
			end
		})

		Group:AddInput("InputPlaceItemId", {
			Default = tostring(vars.PlaceItemId),
			Numeric = true,
			Finished = true,
			Text = "Item ID",
			Callback = function(v)
				local n = tonumber(v)
				if n then vars.PlaceItemId = n end
			end
		})

		-- =========================
		-- SERVICES
		-- =========================
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local placeRemote = remotesFolder:WaitForChild("PlayerPlaceItem")

		-- =========================
		-- GRID HELPER
		-- =========================
		local function getGridPosInFrontOfPlayer()
			local plr = Players.LocalPlayer
			if not plr then return nil end

			local char = plr.Character or plr.CharacterAdded:Wait()
			local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
			if not hrp then return nil end

			local worldPos = hrp.Position + hrp.CFrame.LookVector * 6

			local gx = math.floor(worldPos.X + 0.5)
			local gy = math.floor(worldPos.Y + 0.5)

			-- ✅ offset bisa 0 jadi tidak mengubah koordinat
			gx = gx + (vars.PlaceOffsetX or 0)
			gy = gy + (vars.PlaceOffsetY or 0)

			return Vector2.new(gx, gy)
		end

		-- =========================
		-- AUTO PLACE LOOP
		-- =========================
		if vars._AutoPlaceRun then
			warn("[AutoPlace] Loop sudah berjalan")
			return
		end
		vars._AutoPlaceRun = true

		task.spawn(function()
			while true do
				if vars.AutoPlace then
					local gridPos = getGridPosInFrontOfPlayer()
					if gridPos then
						local ok, err = pcall(function()
							placeRemote:FireServer(gridPos, vars.PlaceItemId)
						end)
						if not ok then
							warn("[AutoPlace] Gagal place:", err)
						end
					end
				end
				task.wait(vars.PlaceDelay)
			end
		end)

		print("[AutoPlace] System Loaded")
	end
}
