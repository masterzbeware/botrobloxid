-- AutoCraft.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main
      vars.Tabs = Tabs -- fix penting

      if not MainTab then
          warn("[Auto Craft] Tab tidak ditemukan!")
          return
      end

      -- UI GROUP
      local Group
      if MainTab.AddRightGroupbox then
          Group = MainTab:AddRightGroupbox("Auto Craft")
      else
          Group = MainTab:AddLeftGroupbox("Auto Craft")
          warn("[Auto Craft] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
      end

      -- DEFAULT VARS
      vars.AutoCraft = vars.AutoCraft or false
      vars.CraftDelay = vars.CraftDelay or 5
      vars.CraftItemTarget = vars.CraftItemTarget or "Chocolate Bar"
      _G.BotVars = vars

      -- TOGGLE
      Group:AddToggle("ToggleAutoCraft", {
          Text = "Auto Craft",
          Default = vars.AutoCraft,
          Callback = function(v)
              vars.AutoCraft = v
              print("[Auto Craft] Toggle:", v and "ON" or "OFF")
          end
      })

      -- LIST ITEM CRAFT
      local craftableItems = {
          "Chocolate Bar",
          "Bread",
          "Pie",
          "Apple Pie",
          "Chocolate Cake"
      }

      -- DROPDOWN
      task.spawn(function()
          task.wait(0.5)
          if Group.AddDropdown then
              local dd = Group:AddDropdown("DropdownCraftItemTarget", {
                  Text = "Craft Item",
                  Values = craftableItems,
                  Default = vars.CraftItemTarget,
                  Multi = false,
                  Callback = function(v)
                      vars.CraftItemTarget = v
                      print("[Auto Craft] Craft item diubah ke:", v)
                  end
              })
              dd:SetValue(vars.CraftItemTarget)
          end
      end)

      -- SLIDER
      Group:AddSlider("SliderCraftDelay", {
          Text = "Delay Craft",
          Default = vars.CraftDelay,
          Min = 2,
          Max = 10,
          Rounding = 1,
          Compact = false,
          Callback = function(v)
              vars.CraftDelay = v
          end
      })

      -- SERVICES
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")

      -- LOOP AUTO CRAFT
      coroutine.wrap(function()
          while true do
              if vars.AutoCraft then

                  -- CARI SEMUA OVEN
                  local ovens = {}
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block.Name == "Baker's Oven" then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              table.insert(ovens, voxel)
                          end
                      end
                  end

                  print("[Auto Craft] Total oven ditemukan:", #ovens)

                  -- PROSES CRAFT
                  for i, pos in ipairs(ovens) do
                      task.spawn(function()
                          local success, err = pcall(function()
                              CraftItem:InvokeServer("Baker's Oven", vars.CraftItemTarget, pos)
                          end)

                          if not success then
                              warn("[Auto Craft] Gagal craft:", err)
                          else
                              print("[Auto Craft] Craft", vars.CraftItemTarget, "di oven", i)
                          end
                      end)

                      task.wait(0.1)
                  end

                  task.wait(vars.CraftDelay)

              else
                  repeat task.wait(2) until vars.AutoCraft
              end
          end
      end)()

      print("[Auto Craft] Sistem aktif. Craft item:", vars.CraftItemTarget)
  end
}
