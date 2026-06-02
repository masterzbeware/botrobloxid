-- KYRO HUB COMPLETE - MINING + MEAT + STORAGE
-- MERGED BY L-01 (XXO MODE)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer


-- ============ REMOTES MEAT ============
local MeatSystemRemotes = ReplicatedStorage:WaitForChild("MeatSystemRemotes")
local MeatTapAction = MeatSystemRemotes.TapAction

local CuciMeatRemotes = ReplicatedStorage:WaitForChild("CuciMeatRemotes")
local CuciPlayerConfirmed = CuciMeatRemotes.PlayerConfirmed
local CuciTapAction = CuciMeatRemotes.TapAction

local PackagingMeatRemotes = ReplicatedStorage:WaitForChild("PackagingMeatRemotes")
local PackageDragComplete = PackagingMeatRemotes.DragComplete

local WarlokRemotes = ReplicatedStorage:WaitForChild("WarlokRemotes")
local ClientAction = WarlokRemotes.ClientAction
local SystemNotify = WarlokRemotes.SystemNotify

local WiseShopRemotes = ReplicatedStorage:WaitForChild("WiseShopRemotes")
local BuyCart = WiseShopRemotes.BuyCart

-- ============ REMOTES MINING ============
local MiningEvent = ReplicatedStorage:WaitForChild("RockSystem"):WaitForChild("MiningEvent")
local CuciBatuEvent = ReplicatedStorage:WaitForChild("CuciBatuSystem"):WaitForChild("CuciBatuEvent")
local SmeltingEvent = ReplicatedStorage:WaitForChild("SmeltingSystem"):WaitForChild("SmeltingEvent")

-- ============ INVENTORY REMOTE ============
local InvRequest = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InvRemotes"):WaitForChild("InvRequest")

-- ============ FLUENT UI ============
local Fluent = loadstring(game:HttpGet(
    "https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"
))()

local Window = Fluent:CreateWindow({
    Title = "KYRO HUB | COMPLETE",
    SubTitle = "Premium",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 380),
    Acrylic = true,
    Theme = "Amber Glow",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Search = true
})

local Tabs = {
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "solar/map-point-bold" }),
    Mining = Window:AddTab({ Title = "Mining", Icon = "solar/widget-bold" }),
    Daging = Window:AddTab({ Title = "Meat", Icon = "solar/bonfire-linear" }),
    Storage = Window:AddTab({ Title = "Storage", Icon = "solar/archive-bold" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "solar/shop-2-bold" })
}

-- ============ VARIABLES MEAT ============
local meatEnabled = false
local cuciEnabled = false
local packageEnabled = false

local isMeatActive = false
local isCuciActive = false
local isPackageActive = false
local packageDragSent = false

local meatTapSpeed = 0.03
local cuciTapSpeed = 0.05
local packageDelay = 1.5

-- ============ VARIABLES SHOP/SELL ============
local buyItemName = "BigKnife"
local buyQuantity = 1

local autoSellEnabled = false
local sellAmount = 100
local autoSellLoopRunning = false

local sellItems = {
    "AClassMeat",
    "Iron Bar",
    "Gold Bar",
    "Diamond Bar",
    "Ruby Bar"
}
local selectedSellItem = sellItems[1]

-- ============ VARIABLES MINING ============
local autoMining = false
local autoCuciBatu = false
local autoSmelting = false
local autoTransferByCount = false
local transparencyThreshold = 0.9
local transferThreshold = 70
local selectedStorageItem = "Rock"

-- ============ FUNCTIONS EQUIP BIGKNIFE ============
local function findBigKnife()
    local character = LocalPlayer.Character
    if character then
        local knife = character:FindFirstChild("BigKnife")
        if knife then return knife end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local knife = backpack:FindFirstChild("BigKnife")
        if knife then return knife end
    end

    local equipados = LocalPlayer:FindFirstChild("equipados")
    if equipados then
        local knife = equipados:FindFirstChild("BigKnife")
        if knife then return knife end
    end

    return nil
end

local function isBigKnifeEquipped()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("BigKnife") ~= nil
    end
    return false
end

local function equipBigKnife()
    if isBigKnifeEquipped() then
        Fluent:Notify({ Title = "Equip BigKnife", Content = "Already equipped!", Duration = 2 })
        return true
    end

    local knife = findBigKnife()
    if knife then
        InvRequest:InvokeServer("janemseimais", knife)
        task.wait(0.5)
        if isBigKnifeEquipped() then
            Fluent:Notify({ Title = "Equip BigKnife", Content = "Successfully equipped!", Duration = 2 })
            return true
        end
    end

    InvRequest:InvokeServer("janemseimais_byname", "BigKnife")
    task.wait(0.5)

    if isBigKnifeEquipped() then
        Fluent:Notify({ Title = "Equip BigKnife", Content = "Successfully equipped via name!", Duration = 2 })
        return true
    end

    Fluent:Notify({ Title = "Equip BigKnife", Content = "BigKnife not found in inventory!", Duration = 3 })
    return false
end

-- ============ PROMPT FUNCTIONS MEAT ============
local function getMeatPrompt()
    local rawFolder = Workspace:FindFirstChild("RawMeatFolder")
    if not rawFolder then return nil end

    for _, model in ipairs(rawFolder:GetChildren()) do
        if model:IsA("Model") and model.Name == "RawMeatModel" then
            local meatPart = model:FindFirstChild("MeatPart")
            if meatPart then
                local prompt = meatPart:FindFirstChild("MeatPrompt")
                if prompt and prompt:IsA("ProximityPrompt") then
                    pcall(function() prompt.MaxActivationDistance = 20 end)
                    return prompt
                end
            end
        end
    end
    return nil
end

local function getCuciMeatPrompt()
    local washingStation = Workspace:FindFirstChild("WashingMeatStation")
    if not washingStation then return nil end

    local sinkModel = washingStation:FindFirstChild("SinkModel")
    if not sinkModel then return nil end

    local sinkPart = sinkModel:FindFirstChild("SinkPart")
    if not sinkPart then return nil end

    local prompt = sinkPart:FindFirstChild("CuciPrompt")
    if prompt then
        pcall(function() prompt.MaxActivationDistance = 15 end)
        return prompt
    end
    return nil
end

local function getPackagePrompt()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local name = v.Name:lower()
            if name:find("pack") or name:find("package") then
                pcall(function() v.MaxActivationDistance = 15 end)
                return v
            end
        end
    end
    return nil
end

local function triggerPrompt(prompt)
    if not prompt then return false end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
    end)
    return true
end

-- ============ FUNCTIONS SHOP/SELL ============
local function buyItem()
    BuyCart:FireServer({ [buyItemName] = { Price = 34, Quantity = buyQuantity } })
    Fluent:Notify({ Title = "SHOP", Content = "Buy " .. buyItemName .. " x" .. buyQuantity, Duration = 2 })
end

local function sellItemOnce()
    ClientAction:FireServer("Sell", selectedSellItem, sellAmount)
    Fluent:Notify({ Title = "SELL", Content = "Sold " .. sellAmount .. " x " .. selectedSellItem, Duration = 2 })
end

SystemNotify.OnClientEvent:Connect(function(type, msg)
    if type == "error" then
        Fluent:Notify({ Title = "Sell Error", Content = msg, Duration = 3 })
    end
end)

local function autoSellLoop()
    if autoSellLoopRunning then return end
    autoSellLoopRunning = true
    task.spawn(function()
        while autoSellEnabled do
            ClientAction:FireServer("Sell", selectedSellItem, sellAmount)
            task.wait(2)
        end
        autoSellLoopRunning = false
    end)
end

-- ============ UI ANGLE DETECTION (MEAT TAP) ============
local function getAngles()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end

    for _, v in ipairs(gui:GetDescendants()) do
        if v.Name == "MainContainer" and v:IsA("Frame") and v.Visible then
            local track = v:FindFirstChild("TrackArea")
            if track then
                local t = track:FindFirstChild("TargetPivot")
                local c = track:FindFirstChild("CursorPivot")
                if t and c then
                    return t.Rotation, c.Rotation
                end
            end
        end
    end
    return nil, nil
end

-- ============ TAP SYSTEM (MEAT) ============
RunService.RenderStepped:Connect(function()
    local t, c = getAngles()

    if isMeatActive and meatEnabled and t and c then
        local diff = math.abs(c - t)
        diff = math.min(diff, 360 - diff)
        if diff <= 5 then
            MeatTapAction:FireServer(c)
        end
    end

    if isCuciActive and cuciEnabled and t and c then
        local diff = math.abs(c - t)
        diff = math.min(diff, 360 - diff)
        if diff <= 5 then
            CuciTapAction:FireServer(c)
        end
    end
end)

-- ============ MEAT EVENTS ============
MeatSystemRemotes.StartSession.OnClientEvent:Connect(function() isMeatActive = true end)
MeatSystemRemotes.UpdateUI.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" or status == "FAIL" then isMeatActive = false end
end)

CuciMeatRemotes.ShowConfirm.OnClientEvent:Connect(function()
    if cuciEnabled then CuciPlayerConfirmed:FireServer() end
end)

CuciMeatRemotes.StartMinigame.OnClientEvent:Connect(function() isCuciActive = true end)
CuciMeatRemotes.UpdateUI.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" or status == "FAIL" then isCuciActive = false end
end)

PackagingMeatRemotes.StartMinigame.OnClientEvent:Connect(function()
    isPackageActive = true
    packageDragSent = false
end)

PackagingMeatRemotes.UpdateUI.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" or status == "FAIL" then
        isPackageActive = false
        packageDragSent = false
    end
end)

local function sendPackageDrag()
    if not packageEnabled or not isPackageActive or packageDragSent then return end
    task.wait(packageDelay)
    PackageDragComplete:FireServer()
    packageDragSent = true
end

-- ============ AUTO MEAT LOOP ============
task.spawn(function()
    while true do
        if meatEnabled then
            local rawFolder = Workspace:FindFirstChild("RawMeatFolder")
            if rawFolder then
                for _, model in ipairs(rawFolder:GetChildren()) do
                    if model:IsA("Model") and model.Name == "RawMeatModel" then
                        local meatPart = model:FindFirstChild("MeatPart")
                        if meatPart then
                            local prompt = meatPart:FindFirstChild("MeatPrompt")
                            if prompt and prompt:IsA("ProximityPrompt") then
                                pcall(function()
                                    prompt.MaxActivationDistance = 20
                                    fireproximityprompt(prompt)
                                end)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if cuciEnabled then
            local prompt = getCuciMeatPrompt()
            if prompt then triggerPrompt(prompt) end
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if packageEnabled then
            local prompt = getPackagePrompt()
            if prompt then triggerPrompt(prompt) end
            sendPackageDrag()
        end
        task.wait(2)
    end
end)

-- ============ MINING FUNCTIONS ============
local function getInvRequestRemote()
    local inv = ReplicatedStorage:FindFirstChild("Modules")
    if inv then
        inv = inv:FindFirstChild("InvRemotes")
        if inv then
            inv = inv:FindFirstChild("InvRequest")
            if inv then return inv end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteFunction") and (v.Name:lower():find("invrequest") or v.Name:lower():find("inv")) then
            return v
        end
    end
    return nil
end

local function getItemCount()
    local InvRequestRemote = getInvRequestRemote()
    if not InvRequestRemote then return 0 end

    local success, inventory = pcall(function()
        return InvRequestRemote:InvokeServer("requestInventory")
    end)

    if not success or type(inventory) ~= "table" then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local inventario = playerGui:FindFirstChild("Inventario")
            if inventario then
                local myInv = inventario:FindFirstChild("MyInv")
                if myInv then
                    local conteudo = myInv:FindFirstChild("conteudo")
                    if conteudo then
                        for _, slot in pairs(conteudo:GetChildren()) do
                            if slot:IsA("Frame") then
                                local frame = slot:FindFirstChildWhichIsA("Frame")
                                if frame and frame.Name == selectedStorageItem then
                                    local qntLabel = frame:FindFirstChild("Qnt")
                                    if qntLabel then
                                        local num = tonumber(qntLabel.Text:gsub("x", ""))
                                        return num or 0
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return 0
    end

    for _, item in pairs(inventory) do
        if item.NomeItem == selectedStorageItem then
            return item.Quantidade or 0
        end
    end
    return 0
end

local function transferToStorage(amount)
    amount = amount or 70
    local InvRequestRemote = getInvRequestRemote()
    if not InvRequestRemote then return false end

    local success = pcall(function()
        return InvRequestRemote:InvokeServer("invToStorage", selectedStorageItem, amount)
    end)

    if success then
        pcall(function() InvRequestRemote:InvokeServer("closeStorage") end)
        return true
    end
    return false
end

local function checkAndTransferLoop()
    if not autoTransferByCount then return end
    local count = getItemCount()
    if count >= transferThreshold then
        transferToStorage(transferThreshold)
        task.wait(1)
    end
end

local function startAutoTransfer()
    task.spawn(function()
        while autoTransferByCount do
            checkAndTransferLoop()
            task.wait(3)
        end
    end)
end

local function isRockTransparent(rock)
    for _, part in ipairs(rock:GetChildren()) do
        if part:IsA("BasePart") and part.Transparency then
            if part.Transparency >= transparencyThreshold then return true end
        end
    end
    if rock:GetAttribute("Transparency") then
        if rock:GetAttribute("Transparency") >= transparencyThreshold then return true end
    end
    local rp = rock:FindFirstChild("RocksPrompt")
    if rp and rp:GetAttribute("Transparency") then
        if rp:GetAttribute("Transparency") >= transparencyThreshold then return true end
    end
    return false
end

local function teleportTo(pos)
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
        task.wait(0.5)
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local originalCanCollide = hrp.CanCollide
        hrp.CanCollide = false
        hrp.CFrame = CFrame.new(pos)
        task.wait(0.15)
        hrp.CanCollide = originalCanCollide
    end
end

local function getAllRockPrompts()
    local prompts = {}
    local folder = Workspace:FindFirstChild("Rocks")
    if not folder then return prompts end

    for _, rock in ipairs(folder:GetChildren()) do
        local rp = rock:FindFirstChild("RocksPrompt")
        if rp then
            local prompt = rp:FindFirstChild("ProximityPrompt")
            if prompt then
                if not isRockTransparent(rock) then
                    local pos = rp:GetPivot().Position
                    if pos.Magnitude < 0.1 then pos = rock:GetPivot().Position end
                    table.insert(prompts, { prompt = prompt, pos = pos, name = rock.Name })
                end
            end
        end
    end
    return prompts
end

MiningEvent.OnClientEvent:Connect(function(action)
    if not autoMining then return end
    if action == "OpenMinigame" then
        task.wait(0.05)
        MiningEvent:FireServer("StopProcess", true)
    end
end)

local function startMining()
    task.spawn(function()
        while autoMining do
            local prompts = getAllRockPrompts()
            if #prompts == 0 then
                task.wait(3)
            else
                for _, r in ipairs(prompts) do
                    if not autoMining then break end
                    teleportTo(r.pos + Vector3.new(0, 2, 0))
                    task.wait(0.05)
                    pcall(function()
                        r.prompt.MaxActivationDistance = 25
                        r.prompt:InputHoldBegin()
                        task.wait(0.08)
                        r.prompt:InputHoldEnd()
                    end)
                    task.wait(0.2)
                end
            end
            task.wait(0.05)
        end
    end)
end

-- ============ AUTO CUCI BATU (MINING) ============
local cachedCuciBatuPrompt = nil
local lastCuciBatuScan = 0

local function getCuciBatuPrompt()
    if cachedCuciBatuPrompt and tick() - lastCuciBatuScan < 10 then
        return cachedCuciBatuPrompt
    end
    lastCuciBatuScan = tick()

    local cuciBatuFolder = Workspace:FindFirstChild("CuciBatu")
    if cuciBatuFolder then
        local innerCuciBatu = cuciBatuFolder:FindFirstChild("CuciBatu")
        if innerCuciBatu then
            local cuciPrompt = innerCuciBatu:FindFirstChild("CuciPrompt")
            if cuciPrompt then
                local proximityPrompt = cuciPrompt:FindFirstChild("ProximityPrompt")
                if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
                    cachedCuciBatuPrompt = proximityPrompt
                    return proximityPrompt
                end
            end
        end
    end

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent and parent.Name == "CuciPrompt" then
                cachedCuciBatuPrompt = v
                return v
            end
        end
    end
    cachedCuciBatuPrompt = nil
    return nil
end

CuciBatuEvent.OnClientEvent:Connect(function(action)
    if not autoCuciBatu then return end
    if action == "OpenMinigame" then
        task.wait(0.05)
        CuciBatuEvent:FireServer("StopProcess", true)
    end
end)

local function startCuciBatu()
    task.spawn(function()
        while autoCuciBatu do
            local prompt = getCuciBatuPrompt()
            if prompt then
                pcall(function()
                    prompt.MaxActivationDistance = 30
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                end)
            end
            task.wait(0.05)
        end
    end)
end

-- ============ AUTO SMELTING ============
local cachedSmeltingPrompt = nil
local lastSmeltingScan = 0

local function getSmeltingPrompt()
    if cachedSmeltingPrompt and tick() - lastSmeltingScan < 10 then
        return cachedSmeltingPrompt
    end
    lastSmeltingScan = tick()

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local name = v.Name:lower()
            if name:find("smelt") or name:find("furnace") or name:find("forge") then
                cachedSmeltingPrompt = v
                return v
            end
        end
    end
    cachedSmeltingPrompt = nil
    return nil
end

SmeltingEvent.OnClientEvent:Connect(function(action, data)
    if not autoSmelting then return end
    if action == "OpenMenu" and data then
        for barName in pairs(data) do
            SmeltingEvent:FireServer("RequestCraft", barName)
            break
        end
    elseif action == "StartMinigame" then
        task.wait(0.05)
        SmeltingEvent:FireServer("StopProcess", true)
    end
end)

local function startSmelting()
    task.spawn(function()
        while autoSmelting do
            local prompt = getSmeltingPrompt()
            if prompt then
                pcall(function()
                    prompt.MaxActivationDistance = 20
                    prompt:InputHoldBegin()
                    task.wait(0.1)
                    prompt:InputHoldEnd()
                end)
            else
                task.wait(3)
            end
            task.wait(2)
        end
    end)
end


-- ============ UI Teleport TAB ============

Tabs.Teleport:AddSection("Main Location")

Tabs.Teleport:AddButton({
    Title = "Carnaval",
    Callback = function()
        teleportTo(Vector3.new(3914.3, 619.4, 4493.3))
    end
})

Tabs.Teleport:AddSection("Safe Zones")

Tabs.Teleport:AddButton({
    Title = "Relax Zone",
    Callback = function()
        teleportTo(Vector3.new(4346.3, 619.4, 4546.9))
    end
})

Tabs.Teleport:AddSection("City Services")

Tabs.Teleport:AddButton({
    Title = "Binco (Colthing Store)",
    Callback = function()
        teleportTo(Vector3.new(3167.4, 610.5, 5134.9))
    end
})

Tabs.Teleport:AddSection("Work Areas")

Tabs.Teleport:AddButton({
    Title = "Mining Area",
    Callback = function()
        teleportTo(Vector3.new(3375.7, 609.6, 3725.6))
    end
})

Tabs.Teleport:AddButton({
    Title = "Butcher (Meat)",
    Callback = function()
        teleportTo(Vector3.new(-3584.9, 613.3, 12878.0))
    end
})

Tabs.Teleport:AddSection("City Location")

Tabs.Teleport:AddButton({
    Title = "Hospital",
    Callback = function()
        teleportTo(Vector3.new(2512.2, 610.4, 5992.5))
    end
})

Tabs.Teleport:AddButton({
    Title = "Police Department",
    Callback = function()
        teleportTo(Vector3.new(-597.5, 610.5, 4993.1))
    end
})

Tabs.Teleport:AddButton({
    Title = "Restaurant",
    Callback = function()
        teleportTo(Vector3.new(218.1, 610.7, 4086.7))
    end
})

Tabs.Teleport:AddButton({
    Title = "Government",
    Callback = function()
        teleportTo(Vector3.new(975.8, 757.9, 8002.3))
    end
})

Tabs.Teleport:AddButton({
    Title = "Pharmacy",
    Callback = function()
        teleportTo(Vector3.new(230.6, 610.7, 6116.3))
    end
})


-- ============ FUNGSI SET ROCKS PROMPT CANCOLLIDE ============
local function setAllRocksPromptCollide(collide)
    local folder = Workspace:FindFirstChild("Rocks")
    if not folder then return end
    
    for _, rock in ipairs(folder:GetChildren()) do
        local rp = rock:FindFirstChild("RocksPrompt")
        if rp then
            pcall(function()
                if rp:IsA("BasePart") then
                    rp.CanCollide = collide
                end
                local prompt = rp:FindFirstChild("ProximityPrompt")
                if prompt and prompt:IsA("BasePart") then
                    prompt.CanCollide = collide
                end
            end)
        end
    end
end

-- ============ LOOP UNTUK MEMPERTAHANKAN CanCollide ============
local keepCollideFalse = false

local function startKeepCollideFalse()
    task.spawn(function()
        while keepCollideFalse do
            setAllRocksPromptCollide(false)
            task.wait(0.05)  -- Setiap 0.5 detik direset lagi
        end
    end)
end


-- ============ UI MINING TAB ============
Tabs.Mining:AddSection("Mining")
-- ✅ URUTAN YANG BENAR
Tabs.Mining:AddToggle("AutoMiningToggle", { Title = "Auto Mining", Default = false }):OnChanged(function(v)
    autoMining = v
    
    if v then
        -- Start loop penjaga CanCollide
        keepCollideFalse = true
        startKeepCollideFalse()
        
        -- Set sekali langsung
        setAllRocksPromptCollide(false)
        
        -- Mulai mining
        startMining()
    else
        -- Stop loop penjaga
        keepCollideFalse = false
        
        -- Balikin ke normal
        setAllRocksPromptCollide(true)
    end
end)

Tabs.Mining:AddSection("Refining")
Tabs.Mining:AddToggle("AutoCuciBatuToggle", { Title = "Auto Cuci Batu", Default = false }):OnChanged(function(v)
    autoCuciBatu = v
    if v then startCuciBatu() end
end)

Tabs.Mining:AddSection("Smelting")
Tabs.Mining:AddToggle("AutoSmeltingToggle", { Title = "Auto Smelting", Default = false }):OnChanged(function(v)
    autoSmelting = v
    if v then startSmelting() end
end)

-- ============ UI DAGING TAB (MEAT) ============
Tabs.Daging:AddSection("Butchering")

Tabs.Daging:AddToggle("MeatToggle", { Title = "Auto Meat", Default = false }):OnChanged(function(v)
    meatEnabled = v
    if v then equipBigKnife() end
end)

Tabs.Daging:AddButton({ Title = "Equip BigKnife", Callback = function() equipBigKnife() end })

Tabs.Daging:AddSection("Refining")
Tabs.Daging:AddToggle("CuciMeatToggle", { Title = "Wash Meat", Default = false }):OnChanged(function(v)
    cuciEnabled = v
end)

Tabs.Daging:AddSection("Packaging")
Tabs.Daging:AddToggle("PackageToggle", { Title = "Package Meat", Default = false }):OnChanged(function(v)
    packageEnabled = v
end)

Tabs.Daging:AddSlider("PackageDelaySlider", { Title = "Package Delay (s)", Min = 1, Max = 2, Default = 1, Rounding = 1 }):OnChanged(function(v)
    packageDelay = v
end)

Tabs.Shop:AddSection("Shop")

Tabs.Shop:AddInput("BuyAmountInput", { Title = "BigKnife Amount", Default = "1" }):OnChanged(function(v)
    buyQuantity = tonumber(v) or 1
end)

Tabs.Shop:AddButton({ Title = "Buy BigKnife", Callback = buyItem })

Tabs.Shop:AddSection("Sell")

Tabs.Shop:AddDropdown("SellItemDropdown", { Title = "Select Item", Values = sellItems, Default = 1 }):OnChanged(function(v)
    selectedSellItem = v
end)

Tabs.Shop:AddInput("SellAmountInput", { Title = "Amount", Default = "100" }):OnChanged(function(v)
    sellAmount = tonumber(v) or 100
end)

Tabs.Shop:AddButton({ Title = "Sell Now", Callback = sellItemOnce })

Tabs.Shop:AddToggle("AutoSellToggle", { Title = "Auto Sell", Default = false }):OnChanged(function(v)
    autoSellEnabled = v
    if v then autoSellLoop() end
end)

-- ============ UI STORAGE TAB ============
Tabs.Storage:AddSection("Storage")

Tabs.Storage:AddDropdown("StorageItemDropdown", {
    Title = "Select Item",
    Values = {"Rock", "Raw Iron", "Raw Ruby", "Raw Gold", "Raw Diamond"},
    Default = "Rock"
}):OnChanged(function(v)
    selectedStorageItem = v
end)

Tabs.Storage:AddInput("TransferThresholdInput", {
    Title = "Transfer Threshold",
    Default = "70",
    Numeric = true
}):OnChanged(function(v)
    local num = tonumber(v)
    if num then
        transferThreshold = math.clamp(num, 1, 70)
    end
end)

Tabs.Storage:AddToggle("AutoTransferToggle", { Title = "Auto Transfer to Storage", Default = false }):OnChanged(function(v)
    autoTransferByCount = v
    if v then startAutoTransfer() end
end)

Tabs.Storage:AddSection("Withdraw")

-- Variabel untuk withdraw
local withdrawItem = "Rock"
local withdrawAmount = 70

-- Dropdown untuk pilih item
Tabs.Storage:AddDropdown("WithdrawItemDropdown", {
    Title = "Select Item to Withdraw",
    Values = {"Rock", "Raw Iron", "Raw Ruby", "Raw Gold", "Raw Diamond", "AClassMeat", "Iron Bar", "Gold Bar", "Diamond Bar", "Ruby Bar"},
    Default = "Rock"
}):OnChanged(function(v)
    withdrawItem = v
end)

-- TextBox untuk jumlah
Tabs.Storage:AddInput("WithdrawAmountInput", {
    Title = "Amount",
    Default = "70",
    Numeric = true
}):OnChanged(function(v)
    local num = tonumber(v)
    if num then
        withdrawAmount = math.clamp(num, 1, 999)
    end
end)

-- Fungsi withdraw
local function withdrawFromStorage()
    local InvRequestRemote = getInvRequestRemote()
    if not InvRequestRemote then
        return
    end
    
    local success, result = pcall(function()
        return InvRequestRemote:InvokeServer("storageToInv", withdrawItem, withdrawAmount)
    end)
    
    if success then
        -- sukses, tapi tidak ada notify
    else
        -- gagal, tapi juga tidak ada notify
    end
end

-- Button untuk withdraw
Tabs.Storage:AddButton({
    Title = "Withdraw from Storage",
    Callback = withdrawFromStorage
})