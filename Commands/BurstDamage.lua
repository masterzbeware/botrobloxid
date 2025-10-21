return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat
      if not tab then return warn("[BurstDamage] Tab Combat tidak ditemukan!") end

      local Camera = workspace.CurrentCamera
      local RunService = game:GetService("RunService")
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send

      vars.BurstEnabled = vars.BurstEnabled or false
      vars.TargetPart = vars.TargetPart or "Torso"
      vars.BurstCount = vars.BurstCount or 3
      vars.BurstDelay = vars.BurstDelay or 0.1

      local Group = tab:AddLeftGroupbox("Burst Damage")
      Group:AddToggle("BurstToggle", {
          Text = "Aktifkan Burst Damage",
          Default = vars.BurstEnabled,
          Callback = function(v) vars.BurstEnabled = v end
      })
      Group:AddDropdown("TargetPart", {
          Text = "Target Part",
          Default = vars.TargetPart,
          Values = { "Head", "Torso", "HumanoidRootPart" },
          Callback = function(v) vars.TargetPart = v end
      })

      local validTargets = {}
      local function isValidNPC(model)
          if not model:IsA("Model") or model.Name ~= "Male" then return false end
          local humanoid = model:FindFirstChildOfClass("Humanoid")
          if not humanoid or humanoid.Health <= 0 then return false end
          for _, c in ipairs(model:GetChildren()) do
              if typeof(c.Name) == "string" and string.sub(c.Name,1,3) == "AI_" then
                  return true
              end
          end
          return false
      end

      local function getClosestTarget()
          local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
          local closest, bestDist = nil, math.huge
          for _, model in ipairs(workspace:GetChildren()) do
              if isValidNPC(model) then
                  local part = model:FindFirstChild(vars.TargetPart)
                  if part then
                      local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                      if onScreen then
                          local dist = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                          if dist < bestDist then
                              closest = part
                              bestDist = dist
                          end
                      end
                  end
              end
          end
          return closest
      end

      RunService.RenderStepped:Connect(function()
          if not vars.BurstEnabled then return end
          local target = getClosestTarget()
          if target then
              for i = 1, vars.BurstCount do
                  local bulletData = {
                      Velocity = 3110,
                      Caliber = "intermediaterifle_556x45mmNATO_M855",
                      UID = "BURST_"..tostring(i),
                      Ignore = workspace.Male,
                      OriginCFrame = Camera.CFrame,
                      Tracer = "Default",
                      Replicate = true,
                      Local = true,
                      Range = 2100
                  }
                  Send:Fire(1, bulletData.UID, bulletData)
                  task.wait(vars.BurstDelay)
              end
          end
      end)

      print("✅ [BurstDamage] Siap — aktifkan toggle untuk menembak otomatis.")
  end
}
