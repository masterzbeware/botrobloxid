return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[AutoAim] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Auto Aim (Male Target)")

      vars.AutoAim = vars.AutoAim or false

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Players = game:GetService("Players")
      local Workspace = game:GetService("Workspace")
      local RunService = game:GetService("RunService")
      
      local player = Players.LocalPlayer
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent")

      -- Store untuk hook
      getgenv().AutoAimHooks = getgenv().AutoAimHooks or {}

      Group:AddToggle("ToggleAutoAim", {
          Text = "Auto Aim to Male",
          Default = vars.AutoAim,
          Callback = function(v)
              vars.AutoAim = v
              if v then
                  print("✅ Auto Aim aktif - Akan auto kena ke Male")
              else
                  print("❌ Auto Aim nonaktif")
              end
          end
      })

      -- Cari SEMUA target Male di workspace dengan filter
      local function findMaleTargets()
          local targets = {}
          
          for _, male in pairs(Workspace:GetChildren()) do
              if male.Name == "Male" and male:IsA("Model") then
                  -- Cek apakah ini karakter player sendiri
                  local isLocalPlayer = false
                  for _, plr in pairs(Players:GetPlayers()) do
                      if plr.Character == male then
                          isLocalPlayer = true
                          break
                      end
                  end
                  
                  -- Skip karakter sendiri dan cek struktur
                  if not isLocalPlayer and male:FindFirstChild("Head") and male:FindFirstChild("Humanoid") then
                      local humanoid = male.Humanoid
                      if humanoid.Health > 0 then -- Hanya target yang masih hidup
                          table.insert(targets, {
                              Model = male,
                              Head = male.Head,
                              Humanoid = humanoid
                          })
                      end
                  end
              end
          end
          
          return targets
      end

      -- Cari target terdekat
      local function findClosestMaleTarget()
          local targets = findMaleTargets()
          local closestTarget = nil
          local closestDistance = math.huge
          
          local character = player.Character
          if not character or not character:FindFirstChild("Head") then
              return nil
          end
          
          local localHead = character.Head
          
          for _, target in pairs(targets) do
              local distance = (localHead.Position - target.Head.Position).Magnitude
              if distance < closestDistance then
                  closestDistance = distance
                  closestTarget = target
              end
          end
          
          return closestTarget
      end

      -- Hook BulletEvent (lebih sederhana)
      if BulletEvent and not getgenv().AutoAimHooks.BulletEvent then
          local oldFire = BulletEvent.Fire
          getgenv().AutoAimHooks.BulletEvent = true
          
          BulletEvent.Fire = function(self, ...)
              local args = {...}
              
              if vars.AutoAim and args[1] == 2 then -- Packet tembakan
                  local target = findClosestMaleTarget()
                  
                  if target then
                      -- Simpan data asli untuk fallback
                      local originalTarget = args[4]
                      local originalPos = args[3]
                      
                      -- Ubah argumen untuk kena ke Male
                      args[3] = target.Head.Position -- Target position
                      args[4] = target.Head -- Hit object
                      args[5] = Vector3.new(0, 1, 0) -- Normal vector
                      args[6] = Enum.Material.SmoothPlastic
                      args[7] = "intermediaterifle_556x45mmNATO_M855"
                      args[8] = true
                      
                      print("🎯 Auto Aim: Target -> " .. target.Head.Name .. " | Distance: " .. math.floor((target.Head.Position - args[2]).Magnitude))
                      
                      -- Execute dengan args yang dimodifikasi
                      return oldFire(self, unpack(args))
                  end
              end
              
              -- Fallback ke original
              return oldFire(self, ...)
          end
          
          print("✅ [Auto Aim] Hook BulletEvent aktif")
      end

      -- Visual indicator untuk target
      local aimBeam = Instance.new("Part")
      aimBeam.Name = "AutoAimBeam"
      aimBeam.Anchored = true
      aimBeam.CanCollide = false
      aimBeam.Material = Enum.Material.Neon
      aimBeam.BrickColor = BrickColor.new("Bright red")
      aimBeam.Size = Vector3.new(0.2, 0.2, 10)
      aimBeam.Parent = Workspace

      -- Update visual setiap frame
      local connection
      Group:AddToggle("ToggleAimVisual", {
          Text = "Show Aim Line",
          Default = false,
          Callback = function(v)
              if v and not connection then
                  connection = RunService.Heartbeat:Connect(function()
                      if vars.AutoAim then
                          local target = findClosestMaleTarget()
                          if target then
                              local character = player.Character
                              if character and character:FindFirstChild("Head") then
                                  local startPos = character.Head.Position
                                  local endPos = target.Head.Position
                                  
                                  aimBeam.Position = (startPos + endPos) / 2
                                  aimBeam.CFrame = CFrame.lookAt(aimBeam.Position, endPos)
                                  aimBeam.Size = Vector3.new(0.2, 0.2, (startPos - endPos).Magnitude)
                                  aimBeam.Transparency = 0.3
                              end
                          else
                              aimBeam.Transparency = 1
                          end
                      else
                          aimBeam.Transparency = 1
                      end
                  end)
              elseif connection and not v then
                  connection:Disconnect()
                  connection = nil
                  aimBeam.Transparency = 1
              end
          end
      })

      -- Info panel
      Group:AddLabel("Status: Menunggu target Male...")
      
      local statusLabel = Group:AddLabel("Targets: 0")
      
      -- Update target count periodically
      coroutine.wrap(function()
          while wait(1) do
              if vars.AutoAim then
                  local targets = findMaleTargets()
                  statusLabel:SetText("Targets: " .. #targets)
                  
                  if #targets > 0 then
                      local closest = findClosestMaleTarget()
                      if closest then
                          local distance = math.floor((player.Character.Head.Position - closest.Head.Position).Magnitude)
                          statusLabel:SetText("Targets: " .. #targets .. " | Closest: " .. distance .. " studs")
                      end
                  end
              end
          end
      end)()

      print("✅ [Auto Aim] Sistem aktif. Akan target semua Male di workspace!")
  end
}