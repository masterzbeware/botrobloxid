-- AutoCraft.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Craft] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI GROUP
      -- =========================
      local Group
      if MainTab.AddRightGroupbox then
          Group = MainTab:AddRightGroupbox("Auto Craft")
      else
          Group = MainTab:AddLeftGroupbox("Auto Craft")
          warn("[Auto Craft] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
      end

      -- =========================
      -- DEFAULT VARS
      -- =========================
      vars.AutoCraft = vars.AutoCraft or false
      vars.CraftDelay = vars.CraftDelay or 5
      vars.SelectedItem = vars.SelectedItem or "Cacao"
      _G.BotVars = vars

      -- =========================
      -- TOGGLE
      -- =========================
      Group:AddToggle("ToggleAutoCraft", {
          Text = "Auto Craft",
          Default = vars.AutoCraft,
          Callback = function(v)
              vars.AutoCraft = v
              print("[Auto Craft] Toggle:", v and "ON" or "OFF")
          end
      })

      -- =========================
      -- LIST ITEM CRAFT
      -- =========================
      local craftableItems = {"Cacao"} -- isi sesuai kebutuhan game

      -- =========================
      -- DROPDOWN ITEM CRAFT
      -- =========================
      task.spawn(function()
          task.wait(0.5)
          if Group.AddDropdown then
              local dropdown = Group:AddDropdown("DropdownCraftItem", {
                  Text = "Pilih Item Craft",
                  Values = craftableItems,
                  Default = vars.SelectedItem,
                  Multi = false,
                  Callback = function(v)
                      vars.SelectedItem = v
                      print("[Auto Craft] Item Craft diubah ke:", v)
                  end
              })
              dropdown:SetValue(vars.SelectedItem)
          else
              warn("[Auto Craft] AddDropdown tidak tersedia")
          end
      end)

      -- =========================
      -- SLIDER DELAY
      -- =========================
      Group:AddSlider("SliderCraftDelay", {
          Text = "Delay Craft",
          Default = vars.CraftDelay,
          Min = 1,
          Max = 15,
          Rounding = 1,
          Callback = function(v)
              vars.CraftDelay = v
          end
      })

      -- =========================
      -- SERVICES
      -- =========================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local CraftRemote = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Server"):WaitForChild("CraftItem")

      -- =========================
      -- LOOP CRAFT (menggunakan sistem AutoPlant: pause ketika OFF)
      -- =========================
      coroutine.wrap(function()
          while true do
              if vars.AutoCraft then
                  -- ========== PROSES CRAFT ==========
                  pcall(function()
                      CraftRemote:InvokeServer(vars.SelectedItem)
                  end)

                  task.wait(vars.CraftDelay)
              else
                  -- ========== toggle OFF → pause sampai ON ==========
                  repeat task.wait(2) until vars.AutoCraft
              end
          end
      end)()

      print("[Auto Craft] Sistem aktif. Target:", vars.SelectedItem)
  end
}
