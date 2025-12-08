-- AutoHarvest.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or (vars.Tabs and vars.Tabs.Main)

      if not MainTab then
          warn("[Auto Harvest] Tab tidak ditemukan!")
          return
      end

      -- UI GROUP
      local Group = MainTab:AddLeftGroupbox("Auto Harvest")

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
          end
      })

      -- BLOCKS/ANIMALS YANG DIIZINKAN
      local allowedBlocks = {
          "Preserves Barrel",
          "Butter Churn",
          "White Cow",
          "Treetap",
          "Mushroom Box"
      }

      -- DROPDOWN PILIH TARGET
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
          Max = 2,
          Rounding = 1,
          Compact = false,
          Callback = function(v)
              vars.HarvestDelay = v
          end
      })

      -- SERVICES
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")

      -- LOOP HARVEST REAL-TIME
      coroutine.wrap(function()
          while true do
              if not vars.AutoHarvest then
                  task.wait(0.1)
              else
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block.Name == vars.HarvestTarget then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              task.spawn(function()
                                  local success, err = pcall(function()
                                      HarvestCrop:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                  end)
                                  if success then
                                      print("Harvest", block.Name, "berhasil di posisi:", voxel)
                                  else
                                      warn("Gagal harvest", block.Name, err)
                                  end
                              end)
                          end
                      end
                  end
                  task.wait(vars.HarvestDelay)
              end
          end
      end)()

      print("[Auto Harvest] Sistem aktif. Target:", vars.HarvestTarget)
  end
}
