-- AutoFill.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Fill] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI GROUP
      -- =========================
      local Group
      if MainTab.AddRightGroupbox then
          Group = MainTab:AddLeftGroupbox("Auto Fill")
      else
          Group = MainTab:AddLeftGroupbox("Auto Fill")
          warn("[Auto Fill] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
      end

      -- =========================
      -- DEFAULT VARS
      -- =========================
      vars.AutoFill = vars.AutoFill or false
      vars.FillDelay = vars.FillDelay or 2
      vars.FillTarget = vars.FillTarget or "Brick Well"
      _G.BotVars = vars

      -- =========================
      -- TOGGLE
      -- =========================
      Group:AddToggle("ToggleAutoFill", {
          Text = "Auto Fill Well",
          Default = vars.AutoFill,
          Callback = function(v)
              vars.AutoFill = v
              print("[Auto Fill] Toggle:", v and "ON" or "OFF")
          end
      })

      -- =========================
      -- ALLOWED WELLS
      -- =========================
      local allowedWells = {"Brick Well", "Stone Well"}

      -- =========================
      -- DROPDOWN PILIH TARGET WELL
      -- =========================
      task.spawn(function()
          task.wait(0.5)
          if Group.AddDropdown then
              local dropdown = Group:AddDropdown("DropdownFillTarget", {
                  Text = "Pilih Well",
                  Values = allowedWells,
                  Default = vars.FillTarget,
                  Multi = true, -- bisa pilih 2 target sekaligus
                  Callback = function(v)
                      vars.FillTarget = v
                      print("[Auto Fill] Target diubah ke:", table.concat(v, ", "))
                  end
              })
              dropdown:SetValue(vars.FillTarget)
          else
              warn("[Auto Fill] AddDropdown tidak tersedia di Group")
          end
      end)

      -- =========================
      -- SLIDER DELAY
      -- =========================
      Group:AddSlider("SliderFillDelay", {
          Text = "Delay Fill",
          Default = vars.FillDelay,
          Min = 0.2,
          Max = 4,
          Rounding = 0.1,
          Compact = false,
          Callback = function(v)
              vars.FillDelay = v
          end
      })

      -- =========================
      -- SERVICES
      -- =========================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local FillBucket = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("FillBucket")

      -- =========================
      -- LOOP FILL (toggle OFF menghentikan proses)
      -- =========================
      coroutine.wrap(function()
          while true do
              if vars.AutoFill then
                  for i, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block:IsA("Model") and table.find(vars.FillTarget, block.Name) then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              task.spawn(function()
                                  local success, err = pcall(function()
                                      FillBucket:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                  end)
                                  if success then
                                      print("Fill Well ke-", i, block.Name, "berhasil")
                                  else
                                      warn("Gagal Fill", block.Name, "ke-", i, err)
                                  end
                              end)
                              task.wait(0.1)
                          end
                      end
                  end
                  task.wait(vars.FillDelay)
              else
                  repeat task.wait(2) until vars.AutoFill
              end
          end
      end)()

      print("[Auto Fill] Sistem aktif. Target:", table.concat(vars.FillTarget, ", "))
  end
}
