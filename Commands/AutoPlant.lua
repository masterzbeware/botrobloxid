-- AutoPlant.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Plant

      if not MainTab then
          warn("[Auto Plant] Tab tidak ditemukan!")
          return
      end

      -- UI GROUP
      local Group
      if MainTab.AddRightGroupbox then
          Group = MainTab:AddRightGroupbox("Auto Plant")
      else
          Group = MainTab:AddLeftGroupbox("Auto Plant")
          warn("[Auto Plant] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
      end

      -- DEFAULT VARS
      vars.AutoPlant = vars.AutoPlant or false
      vars.PlantDelay = vars.PlantDelay or 10
      vars.PlantTarget = vars.PlantTarget or "Cacao"
      _G.BotVars = vars

      -- TOGGLE
      Group:AddToggle("ToggleAutoPlant", {
          Text = "Auto Plant",
          Default = vars.AutoPlant,
          Callback = function(v)
              vars.AutoPlant = v
              print("[Auto Plant] Toggle:", v and "ON" or "OFF")
          end
      })

      -- MODEL / CROP YANG DIIZINKAN
      local allowedCrops = {"Cacao"}

      -- DROPDOWN PILIH CROP
      task.spawn(function()
          task.wait(0.5)
          if Group.AddDropdown then
              local dropdown = Group:AddDropdown("DropdownPlantTarget", {
                  Text = "Pilih Crop",
                  Values = allowedCrops,
                  Default = vars.PlantTarget,
                  Multi = false,
                  Callback = function(v)
                      vars.PlantTarget = v
                      print("[Auto Plant] Target diubah ke:", v)
                  end
              })
              dropdown:SetValue(vars.PlantTarget)
          else
              warn("[Auto Plant] AddDropdown tidak tersedia di Group")
          end
      end)

      -- SLIDER DELAY
      Group:AddSlider("SliderPlantDelay", {
          Text = "Delay Plant",
          Default = vars.PlantDelay,
          Min = 1,
          Max = 20,
          Rounding = 1,
          Compact = false,
          Callback = function(v)
              vars.PlantDelay = v
          end
      })

      -- SERVICES
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")

      -- LOOP PLANT
      coroutine.wrap(function()
          while true do
              if vars.AutoPlant then
                  for i, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block:IsA("MeshPart") and block.Name == vars.PlantTarget then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              local pos = vector.create(voxel.X, voxel.Y, voxel.Z)
                              task.spawn(function()
                                  local success, err = pcall(function()
                                      HarvestCrop:InvokeServer(pos)
                                  end)
                                  if success then
                                      print("Harvest", vars.PlantTarget, "ke-", i, "berhasil")
                                  else
                                      warn("Gagal harvest", vars.PlantTarget, i, err)
                                  end
                              end)
                              task.wait(0.1)
                          end
                      end
                  end
                  task.wait(vars.PlantDelay)
              else
                  -- toggle OFF → tunggu sampai ON lagi
                  repeat task.wait(0.5) until vars.AutoPlant
              end
          end
      end)()

      print("[Auto Plant] Sistem aktif. Target:", vars.PlantTarget)
  end
}
