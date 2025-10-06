-- Barrier.lua
-- Command !barrier: Bot membentuk formasi penghalang di sekitar VIP
-- Kompatibel dengan Stop.lua

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[Barrier] RunService tidak tersedia!")
          return
      end

      -- 🔹 Nonaktifkan mode lain
      vars.BarrierActive = not vars.BarrierActive
      vars.FollowAllowed = false
      vars.RowActive = false
      vars.SquareActive = false
      vars.WedgeActive = false
      vars.ShieldActive = false
      vars.FrontlineActive = false
      vars.CircleMoveActive = false
      vars.PushupActive = false
      vars.SyncActive = false
      vars.ReportingActive = false
      vars.RoomVIPActive = false
      vars.CurrentFormasiTarget = client

      if not vars.BarrierActive then
          print("[BARRIER] Dinonaktifkan")
          if vars.BarrierConnection then
              pcall(function() vars.BarrierConnection:Disconnect() end)
              vars.BarrierConnection = nil
          end
          return
      end

      print("[BARRIER] Formasi Barrier diaktifkan. Target:", client.Name)

      -- 🔹 Referensi karakter bot
      local humanoid, myRootPart, moving
      local function updateBotRefs()
          local character = player.Character or player.CharacterAdded:Wait()
          humanoid = character:WaitForChild("Humanoid")
          myRootPart = character:WaitForChild("HumanoidRootPart")
      end
      player.CharacterAdded:Connect(updateBotRefs)
      updateBotRefs()

      local function moveToPosition(targetPos, lookVector)
          if not humanoid or not myRootPart then return end
          if moving then return end
          if (myRootPart.Position - targetPos).Magnitude < 1 then return end

          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false

          if lookVector then
              -- 🔹 Menghadap arah yang sama seperti VIP
              myRootPart.CFrame = CFrame.new(targetPos, targetPos + lookVector)
          end
      end

      -- 🔹 Putuskan koneksi lama
      if vars.BarrierConnection then
          pcall(function() vars.BarrierConnection:Disconnect() end)
          vars.BarrierConnection = nil
      end

      -- 🔹 Loop Heartbeat
      if RunService.Heartbeat then
          vars.BarrierConnection = RunService.Heartbeat:Connect(function()
              if not vars.BarrierActive or not client.Character then return end
              local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
              if not targetHRP then return end

              -- 🔹 Mapping bot
              local orderedBots = {
                  "8802945328", -- B1 kiri VIP
                  "8802939883", -- B2 kiri VIP
                  "8802949363", -- B3 kanan VIP
                  "8802998147", -- B4 kanan VIP
              }

              local myUserId = tostring(player.UserId)
              local index = 1
              for i, uid in ipairs(orderedBots) do
                  if uid == myUserId then
                      index = i
                      break
                  end
              end

              -- 🔹 Konfigurasi jarak
              local jarakSamping = tonumber(vars.SideSpacing) or 3
              local jarakDepanBelakang = tonumber(vars.FrontBackSpacing) or 0 -- VIP di tengah

              -- 🔹 Offset posisi per bot
              local offsetMap = {
                  [1] = Vector3.new(-2*jarakSamping, 0, jarakDepanBelakang), -- B1 kiri paling kiri
                  [2] = Vector3.new(-jarakSamping, 0, jarakDepanBelakang),   -- B2 kiri dekat VIP
                  [3] = Vector3.new(jarakSamping, 0, jarakDepanBelakang),    -- B3 kanan dekat VIP
                  [4] = Vector3.new(2*jarakSamping, 0, jarakDepanBelakang),  -- B4 kanan paling kanan
              }

              local offset = offsetMap[index] or Vector3.zero
              local cframe = targetHRP.CFrame
              local targetPos = (cframe.Position
                  + cframe.RightVector * offset.X
                  + cframe.UpVector * offset.Y
                  + cframe.LookVector * offset.Z)

              -- 🔹 Menghadap sama seperti VIP
              moveToPosition(targetPos, targetHRP.CFrame.LookVector)
          end)
      else
          warn("[Barrier] RunService.Heartbeat tidak tersedia!")
      end
  end
}
