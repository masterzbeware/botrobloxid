-- AutoHarvest.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Harvest] Tab tidak ditemukan!")
          return
      end

      -- UI GROUP
      local Group
      if MainTab.AddRightGroupbox then
          Group = MainTab:AddRightGroupbox("Auto Harvest")
      else
          warn("[Auto Harvest] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
          Group = MainTab:AddLeftGroupbox("Auto Harvest")
      end

      -- DEFAULT VARS
      vars.AutoHarvest = vars.AutoHarvest or false
      vars.HarvestDelay = vars.HarvestDelay or 1
      vars.HarvestTarget = vars.HarvestTarget or "Preserves Barrel"
      _G.BotVars = vars

      -- TOGGLE
      Group:AddToggle("ToggleAutoHarvest", {
          Text = "Auto Harvest",
          Default = vars.AutoHarvest,
          Callback = function(v)
              vars.AutoHarvest = v
              print("[Auto Harvest] Toggle:", v and "ON" or "OFF")
          end
      })

      -- ALLOWED BLOCKS / ANIMALS
      local allowedBlocks = {
          "Preserves Barrel",
          "Butter Churn",
          "White Cow",
          "Treetap",
          "Mushroom Box",
          "Compost Bin",
          "Baker's Oven"
      }

      -- DROPDOWN TARGET
      task.spawn(function()
          task.wait(0.5)
          if Group.AddDropdown then
              local dropdown = Group:AddDropdown("DropdownHarvestTarget", {
                  Text = "Pilih Block/Animal",
                  Values = allowedBlocks,
                  Default = vars.HarvestTarget,
                  Multi = false,
                  Callback = function(v)
                      vars.HarvestTarget = v
                      print("[Auto Harvest] Target diubah ke:", v)
                  end
              })
              dropdown:SetValue(vars.HarvestTarget)
          else
              warn("[Auto Harvest] AddDropdown tidak tersedia di Group")
          end
      end)

      -- SLIDER DELAY
      Group:AddSlider("SliderHarvestDelay", {
          Text = "Delay Harvest",
          Default = vars.HarvestDelay,
          Min = 0.3,
          Max = 3,
          Rounding = 1,
          Compact = false,
          Callback = function(v)
              vars.HarvestDelay = v
          end
      })

      -- SERVICES
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Blocks = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks")
      local HarvestCrop = Blocks:WaitForChild("HarvestCrop")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

      -- LOOP HARVEST (toggle OFF benar-benar menghentikan proses)
      coroutine.wrap(function()
          while true do
              if vars.AutoHarvest then
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block.Name == vars.HarvestTarget then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              -- spawn per block biar tidak lag
                              task.spawn(function()
                                  local success, err = pcall(function()
                                      HarvestCrop:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                  end)
                                  if not success then
                                      warn("Gagal harvest", block.Name, err)
                                  end
                              end)
                              task.wait(0.1) -- delay mini antar block untuk mencegah lag
                          end
                      end
                  end
                  task.wait(vars.HarvestDelay)
              else
                  -- toggle OFF → tunggu sampai toggle ON, tidak looping sia-sia
                  repeat task.wait(2) until vars.AutoHarvest
              end
          end
      end)()

      print("[Auto Harvest] Sistem aktif. Target:", vars.HarvestTarget)
  end
}
