-- AutoPlant.lua (Ultra Fast & Anti Lag)
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Plant] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI GROUP
      -- =========================
      local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Auto Plant"))
          or MainTab:AddLeftGroupbox("Auto Plant")

      -- =========================
      -- DEFAULT VARS
      -- =========================
      vars.AutoPlant  = vars.AutoPlant or false
      vars.PlantDelay = vars.PlantDelay or 0.3
      vars.PlantSeed  = vars.PlantSeed or "Wheat Seeds"
      _G.BotVars = vars

      -- =========================
      -- TOGGLE
      -- =========================
      Group:AddToggle("ToggleAutoPlant", {
          Text = "Auto Plant",
          Default = vars.AutoPlant,
          Callback = function(v)
              vars.AutoPlant = v
              print("[Auto Plant] Toggle:", v and "ON" or "OFF")
          end
      })

      -- =========================
      -- DROPDOWN Seed
      -- =========================
      local SeedsList = {"Wheat Seeds", "Carrot Seeds", "Corn Seeds", "Cacao Seeds"} -- sesuaikan dengan game

      task.defer(function()
          local dd = Group:AddDropdown("DropdownPlantSeed", {
              Text = "Pilih Benih",
              Values = SeedsList,
              Default = vars.PlantSeed,
              Callback = function(v)
                  vars.PlantSeed = v
                  print("[Auto Plant] Seed berubah:", v)
              end
          })
          dd:SetValue(vars.PlantSeed)
      end)

      -- =========================
      -- DELAY SLIDER
      -- =========================
      Group:AddSlider("SliderPlantDelay", {
          Text = "Delay Tanam",
          Default = vars.PlantDelay,
          Min = 0.1,
          Max = 3,
          Rounding = 1,
          Callback = function(v)
              vars.PlantDelay = v
          end
      })

      -- =========================
      -- SERVICES
      -- =========================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local PlantCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("PlantCrop")

      -- =========================
      -- AUTO PLANT LOOP
      -- =========================
      coroutine.wrap(function()
          local farmlandVoxels = {}    -- cache posisi Farmland
          local occupiedVoxels = {}    -- cache block di atas untuk cek sudah ditanam

          while true do
              if not vars.AutoPlant then
                  repeat task.wait(0.5) until vars.AutoPlant
              end

              -- Update cache farmland
              farmlandVoxels = {}
              occupiedVoxels = {}

              for _, block in ipairs(LoadedBlocks:GetChildren()) do
                  local voxel = block:GetAttribute("VoxelPosition")
                  if voxel then
                      local key = voxel.X..","..voxel.Y..","..voxel.Z

                      -- Farmland cache
                      if block.Name == "Farmland" then
                          farmlandVoxels[key] = voxel
                      else
                          -- semua block lain dianggap occupied
                          occupiedVoxels[key] = true
                      end
                  end
              end

              -- Tanam batch
              for key, voxel in pairs(farmlandVoxels) do
                  if not vars.AutoPlant then break end

                  local aboveKey = voxel.X..","..(voxel.Y + 1)..","..voxel.Z
                  if not occupiedVoxels[aboveKey] then
                      task.spawn(function()
                          pcall(function()
                              PlantCrop:InvokeServer(Vector3.new(voxel.X, voxel.Y + 1, voxel.Z), vars.PlantSeed)
                          end)
                      end)

                      occupiedVoxels[aboveKey] = true -- update cache langsung
                      task.wait(0.05) -- batch kecil biar aman
                  end
              end

              task.wait(vars.PlantDelay)
          end
      end)()

      print("[Auto Plant] Sistem Aktif. Seed:", vars.PlantSeed)
  end
}
