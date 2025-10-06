-- ModeBuaya.lua
-- Command !modebuaya {displayname/username}: Bot mengikuti pemain tertentu dan mengirim chat acak setiap 10 detik

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[ModeBuaya] RunService tidak tersedia!")
          return
      end

      -- 🔹 Daftar chat romantis
      local chatList = {
          "Kamu kalau butuh apa-apa, bilang ke aku ya, {name}.",
          "Aku serius sama kamu, {name}. Kalau nggak serius ngapain aku chat kamu setiap hari?",
          "Kamu jangan sedih ya, {name}, kan ada aku di sini.",
          "Aku janji, {name}, aku setia.",
          "Dia itu jahat sama kamu, {name}, kok kamu mau sih? mending sama aku.",
          "Kita sama-sama pernah disakiti, {name}, sepertinya kita jodoh deh.",
          "Senyum dong, {name}, kalau nangis nanti cantiknya luntur.",
          "Kamu jangan pakai pakaian seksi di depan umum, {name}. Kalau di depan aku boleh.",
          "Status kamu galau terus, {name}, sini aku bikin bahagia nggak kayak dia.",
          "Jangan terlalu kelihatan sedih, {name}, cewek cantik kayak kamu nggak boleh sedih.",
          "Sepertinya aku kena diabetes, {name}, soalnya dari kemarin ngelihatin kamu senyum terus.",
          "Aku nggak mau pacaran, {name}, aku maunya ta'arufan aja sama kamu.",
          "Aku serius sama kamu, {name}, kamu mau kan nunggu aku sampai lulus?.",
          "Sejauh apapun aku pergi, {name}, pulangnya pasti ke rumah. Kamu tau kan kalau rumahku itu kamu?",
          "Terimakasih ya, {name}, kamu sudah hadir di hidup aku. Aku nggak mau kehilangan kamu.",
          "Ngemil apa yang paling enak, {name}? Ngemilikin kamu sepenuhnya.",
          "Sejak kenal kamu, {name}, bawaannya pengen belajar terus. Belajar jadi yang terbaik.",
          "Enak ya jadi kamu, {name}, kalau mau lihat bidadari, tinggal lihat di kaca.",
          "Kalo naik motor sama kamu pasti ditilang deh, {name}. Soalnya kita kan bertiga, Aku, Kamu, dan Cinta.",
          "Aku nggak sedih kok kalo besok hari senin, {name}, aku sedihnya kalau nggak ketemu kamu.",
          "Aku hanya ingin hidup cukup, {name}. Cukup lihat senyummu setiap hari.",
          "Meskipun aku udah dewasa, {name}, tapi aku gak bisa hidup mandiri. Buktinya aku gak bisa hidup tanpa kamu."
      }

      -- 🔹 Atur mode ModeBuaya
      vars.FollowAllowed = true
      vars.ShieldActive = false
      vars.RowActive = false
      vars.FrontlineActive = false
      vars.CurrentFormasiTarget = client

      local humanoid, myRootPart, moving

      local function updateBotRefs()
          local character = player.Character or player.CharacterAdded:Wait()
          humanoid = character:WaitForChild("Humanoid")
          myRootPart = character:WaitForChild("HumanoidRootPart")
      end

      player.CharacterAdded:Connect(updateBotRefs)
      updateBotRefs()

      local function moveToPosition(targetPos, lookAtPos)
          if not humanoid or not myRootPart then return end
          if moving then return end
          if (myRootPart.Position - targetPos).Magnitude < 2 then return end

          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false

          if lookAtPos then
              myRootPart.CFrame = CFrame.new(
                  myRootPart.Position,
                  Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
              )
          end
      end

      -- Putuskan koneksi lama
      if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
      if vars.ModeBuayaChatConnection then pcall(function() vars.ModeBuayaChatConnection:Disconnect() end) vars.ModeBuayaChatConnection = nil end

      -- 🔹 Heartbeat loop ModeBuaya (follow)
      if RunService.Heartbeat then
          vars.FollowConnection = RunService.Heartbeat:Connect(function()
              vars.AbsenActive = vars.AbsenActive or {}
              local myId = tostring(player.UserId)
              if vars.AbsenActive[myId] then return end

              if not vars.FollowAllowed or not client.Character then return end
              local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
              if not targetHRP then return end

              local jarakIkut = tonumber(vars.JarakIkut) or 6
              local followSpacing = tonumber(vars.FollowSpacing) or 4

              local orderedBots = {
                  "8802945328", "8802949363", "8802939883", "8802998147"
              }

              local myUserId = tostring(player.UserId)
              local index = 1
              for i, uid in ipairs(orderedBots) do
                  if uid == myUserId then
                      index = i
                      break
                  end
              end

              local backOffset = jarakIkut + (index - 1) * followSpacing
              local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

              moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
          end)

          -- 🔹 Heartbeat loop ModeBuaya (chat acak setiap 10 detik)
          vars.ModeBuayaChatTimer = 0
          vars.ModeBuayaChatConnection = RunService.Heartbeat:Connect(function(step)
              vars.ModeBuayaChatTimer = (vars.ModeBuayaChatTimer or 0) + step
              if vars.ModeBuayaChatTimer >= 10 then
                  vars.ModeBuayaChatTimer = 0
                  if client and client.Parent then
                      local name = client.DisplayName or client.Name
                      local msgIndex = math.random(1, #chatList)
                      local message = chatList[msgIndex]:gsub("{name}", name)
                      pcall(function()
                          player:Chat(message)
                      end)
                  end
              end
          end)
      else
          warn("[ModeBuaya] RunService.Heartbeat tidak tersedia!")
      end

      print("[COMMAND] ModeBuaya aktif, target:", client.Name)
  end
}
