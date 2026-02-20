-- InventoryPicker.lua
-- UI: dropdown isi item inventory + tombol refresh
return {
	Execute = function(tab)
		-- =========================
		-- GLOBAL VARS
		-- =========================
		local vars = _G.BotVars or {}
		vars.SelectedItemId = vars.SelectedItemId or 1
		vars._InvDropdownValues = vars._InvDropdownValues or {}
		vars._InvNameToId = vars._InvNameToId or {}
		_G.BotVars = vars

		-- =========================
		-- TAB & UI
		-- =========================
		local Tabs = vars.Tabs or {}
		local MainTab = tab or Tabs.Main
		if not MainTab then return end

		local Group = MainTab:AddLeftGroupbox("Inventory")

		-- =========================
		-- INVENTORY FETCH (GANTI SESUAI SISTEMMU)
		-- =========================
		-- Kamu WAJIB sesuaikan bagian ini supaya benar2 baca inventory milikmu.
		-- Target: return list seperti:
		-- { {Id=1, Name="Wood"}, {Id=2, Name="Stone"} }
		local function fetchInventoryItems()
			local Players = game:GetService("Players")
			local plr = Players.LocalPlayer
			if not plr then return {} end

			-- CONTOH 1 (umum): dari Folder "Inventory" di Player
			-- Misal ada IntValue/StringValue di plr.Inventory
			-- Kalau sistemmu beda, ganti total ya.
			local result = {}
			local invFolder = plr:FindFirstChild("Inventory")
			if invFolder then
				for _, obj in ipairs(invFolder:GetChildren()) do
					-- contoh: IntValue bernama item, value = id
					if obj:IsA("IntValue") then
						table.insert(result, { Id = obj.Value, Name = obj.Name })
					end
				end
			end

			-- CONTOH 2: kalau inventory dari ModuleScript
			-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
			-- local InventoryClient = require(ReplicatedStorage:WaitForChild("InventoryClient"))
			-- return InventoryClient:GetItems()

			return result
		end

		local function rebuildDropdown()
			local items = fetchInventoryItems()

			table.clear(vars._InvDropdownValues)
			table.clear(vars._InvNameToId)

			for _, it in ipairs(items) do
				local id = it.Id
				local name = it.Name or ("Item "..tostring(id))
				local label = ("%s [%s]"):format(name, tostring(id))

				table.insert(vars._InvDropdownValues, label)
				vars._InvNameToId[label] = id
			end

			if #vars._InvDropdownValues == 0 then
				vars._InvDropdownValues[1] = "(inventory kosong)"
			end
		end

		-- build awal
		rebuildDropdown()

		-- =========================
		-- UI ELEMENTS
		-- =========================
		Group:AddDropdown("DropdownInventory", {
			Text = "Pilih Item (Inventory)",
			Values = vars._InvDropdownValues,
			Default = vars._InvDropdownValues[1],
			Callback = function(selectedLabel)
				local id = vars._InvNameToId[selectedLabel]
				if id then
					vars.SelectedItemId = id
					print("[InventoryPicker] SelectedItemId:", id)
				end
			end
		})

		Group:AddButton({
			Text = "Refresh Inventory",
			Func = function()
				rebuildDropdown()

				-- Cara update dropdown tergantung UI library.
				-- Kalau library kamu punya Options table (mis. Linoria):
				if Options and Options.DropdownInventory then
					Options.DropdownInventory:SetValues(vars._InvDropdownValues)
					Options.DropdownInventory:SetValue(vars._InvDropdownValues[1])
				end

				print("[InventoryPicker] Refreshed. Total:", #vars._InvDropdownValues)
			end
		})

		-- Optional: tampilkan item terpilih sebagai input read-only (kalau UI library mendukung)
		Group:AddInput("SelectedItemIdDisplay", {
			Default = tostring(vars.SelectedItemId),
			Numeric = true,
			Finished = true,
			Text = "Selected Item ID (manual edit opsional)",
			Callback = function(v)
				local n = tonumber(v)
				if n then
					vars.SelectedItemId = n
					print("[InventoryPicker] Manual SelectedItemId:", n)
				end
			end
		})

		print("[InventoryPicker] UI Loaded")
	end
}