local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local MiningEvent = ReplicatedStorage:WaitForChild("RockSystem"):WaitForChild("MiningEvent")
local CuciBatuEvent = ReplicatedStorage:WaitForChild("CuciBatuSystem"):WaitForChild("CuciBatuEvent")
local SmeltingEvent = ReplicatedStorage:WaitForChild("SmeltingSystem"):WaitForChild("SmeltingEvent")

-- FLUENT UI
local Fluent = loadstring(game:HttpGet(
    "https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"
))()

local Window = Fluent:CreateWindow({
    Title = "KYRO HUB",
    SubTitle = "Premium",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = true,
    Theme = "Amber Glow",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Search = true
})

local Tabs = {
    Mining = Window:AddTab({ Title = "Mining", Icon = "solar/widget-bold" }),
    Storage = Window:AddTab({ Title = "Storage", Icon = "solar/archive-bold"}),
    Daging = Window:AddTab({ Title = "Meat", Icon = "solar/bonfire-linear" })
}

local selectedItem = "Rock"

-- ============ VARIABLES ============
local autoMining = false
local autoCuci = false
local autoSmelting = false
local autoTransferByCount = false
local transparencyThreshold = 0.9
local transferThreshold = 70

-- ============ GET INVREQUEST REMOTE ============
local function getInvRequest()
    local InvRequest = ReplicatedStorage:FindFirstChild("Modules")
    if InvRequest then
        InvRequest = InvRequest:FindFirstChild("InvRemotes")
        if InvRequest then
            InvRequest = InvRequest:FindFirstChild("InvRequest")
            if InvRequest then
                return InvRequest
            end
        end
    end
    
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteFunction") and (v.Name:lower():find("invrequest") or v.Name:lower():find("inv")) then
            return v
        end
    end
    return nil
end

-- ============ GET ROCK COUNT FROM INVENTORY ============
local function getRockCount()
    local InvRequest = getInvRequest()
    if not InvRequest then
        return 0
    end
    
    local success, inventory = pcall(function()
        return InvRequest:InvokeServer("requestInventory")
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
                                if frame and frame.Name == "Rock" then
                                    local qntLabel = frame:FindFirstChild("Qnt")
                                    if qntLabel then
                                        local qntText = qntLabel.Text
                                        local num = tonumber(qntText:gsub("x", ""))
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
        if item.NomeItem == selectedItem then
            return item.Quantidade or 0
        end
    end
    
    return 0
end

-- ============ TRANSFER FUNCTION ============
local function transferRocksToStorage(amount)
    amount = amount or 70
    
    local InvRequest = getInvRequest()
    if not InvRequest then
        print("[L-01] ❌ InvRequest tidak ditemukan!")
        return false
    end
    
    print("[L-01] 🚀 Transfer " .. amount .. " Rock ke storage...")
    
    local success, result = pcall(function()
        return InvRequest:InvokeServer("invToStorage", selectedItem, amount)
    end)
    
    if success then
        print("[L-01] ✅ Transfer sukses!")
        
        pcall(function()
            InvRequest:InvokeServer("closeStorage")
            print("[L-01] 🚪 Storage ditutup!")
        end)
        return true
    else
        print("[L-01] ❌ Gagal transfer: " .. tostring(result))
        return false
    end
end

-- ============ CHECK AND TRANSFER IF ROCK >= THRESHOLD ============
local function checkAndTransfer()
    if not autoTransferByCount then return end
    
    local rockCount = getRockCount()
    
    if rockCount >= transferThreshold then
        print("[L-01] 🎯 Rock mencapai " .. rockCount .. " (threshold: " .. transferThreshold .. ")")
        transferRocksToStorage(transferThreshold)
        task.wait(1)
    end
end

-- ============ AUTO TRANSFER LOOP ============
local function startAutoTransferByCount()
    task.spawn(function()
        while autoTransferByCount do
            checkAndTransfer()
            task.wait(3)
        end
    end)
end

-- ============ CEK TRANSPARENCY BATU ============
local function isRockTransparent(rock)
    for _, part in ipairs(rock:GetChildren()) do
        if part:IsA("BasePart") and part.Transparency then
            if part.Transparency >= transparencyThreshold then
                return true
            end
        end
    end
    
    if rock:GetAttribute("Transparency") then
        if rock:GetAttribute("Transparency") >= transparencyThreshold then
            return true
        end
    end
    
    local rp = rock:FindFirstChild("RocksPrompt")
    if rp and rp:GetAttribute("Transparency") then
        if rp:GetAttribute("Transparency") >= transparencyThreshold then
            return true
        end
    end
    
    return false
end

-- ============ TELEPORT FUNCTION (FIXED) ============
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

-- ============ AUTO MINING (FIXED - LIKE BEFORE) ============
local function getAllRockPrompts()
    local prompts = {}
    local folder = Workspace:FindFirstChild("Rocks")
    if not folder then 
        return prompts 
    end
    
    for _, rock in ipairs(folder:GetChildren()) do
        local rp = rock:FindFirstChild("RocksPrompt")
        if rp then
            local prompt = rp:FindFirstChild("ProximityPrompt")
            if prompt then
                if not isRockTransparent(rock) then
                    local pos = rp:GetPivot().Position
                    if pos.Magnitude < 0.1 then
                        pos = rock:GetPivot().Position
                    end
                    
                    table.insert(prompts, {
                        prompt = prompt,
                        pos = pos,
                        name = rock.Name
                    })
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

-- ============ AUTO CUCI BATU ============
local cachedCuciPrompt = nil
local lastCuciScan = 0

local function getCuciPrompt()
    if cachedCuciPrompt and tick() - lastCuciScan < 10 then
        return cachedCuciPrompt
    end
    
    lastCuciScan = tick()
    
    local cuciBatuFolder = Workspace:FindFirstChild("CuciBatu")
    if cuciBatuFolder then
        local innerCuciBatu = cuciBatuFolder:FindFirstChild("CuciBatu")
        if innerCuciBatu then
            local cuciPrompt = innerCuciBatu:FindFirstChild("CuciPrompt")
            if cuciPrompt then
                local proximityPrompt = cuciPrompt:FindFirstChild("ProximityPrompt")
                if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
                    cachedCuciPrompt = proximityPrompt
                    return proximityPrompt
                end
            end
        end
    end
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent and parent.Name == "CuciPrompt" then
                cachedCuciPrompt = v
                return v
            end
        end
    end
    
    cachedCuciPrompt = nil
    return nil
end

CuciBatuEvent.OnClientEvent:Connect(function(action)
    if not autoCuci then return end
    if action == "OpenMinigame" then
        task.wait(0.05)
        CuciBatuEvent:FireServer("StopProcess", true)
    end
end)

local function startCuci()
    task.spawn(function()
        while autoCuci do
            local prompt = getCuciPrompt()
            if not prompt then
                task.wait(3)
            else
                pcall(function()
                    prompt.MaxActivationDistance = 30
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                end)
                task.wait(1)
            end
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

-- ============ UI ============
Tabs.Mining:AddSection("Mining")

Tabs.Mining:AddToggle("AutoMiningToggle", { 
    Title = "Auto Mining", 
    Default = false 
}):OnChanged(function(v)
    autoMining = v
    if v then startMining() end
end)

Tabs.Mining:AddSection("Washing")

Tabs.Mining:AddToggle("AutoCuciToggle", { 
    Title = "Auto Cuci Batu", 
    Default = false 
}):OnChanged(function(v)
    autoCuci = v
    if v then 
        cachedCuciPrompt = nil
        startCuci() 
    end
end)

Tabs.Mining:AddSection("Smelting")

Tabs.Mining:AddToggle("AutoSmeltingToggle", { 
    Title = "Auto Smelting", 
    Default = false 
}):OnChanged(function(v)
    autoSmelting = v
    if v then startSmelting() end
end)

-- ============ UI ============
Tabs.Storage:AddSection("Storage")

Tabs.Storage:AddDropdown("StorageItemDropdown", {
    Title = "Select Item",
    Values = {"Rock", "Raw Iron", "Raw Ruby" , "Raw Gold" , "Raw Diamond"},
    Multi = false,
    Default = "Rock",
}):OnChanged(function(value)
    selectedItem = value
    print("[SELECTED ITEM]:", selectedItem)
end)

Tabs.Storage:AddInput("TransferThresholdInput", {
    Title = "Transfer Threshold",
    Default = "10",
    Placeholder = "Amount (1 - 70)",
    Numeric = true,
    Finished = false
}):OnChanged(function(value)

    print("[INPUT RAW]:", value)

    local num = tonumber(value)

    print("[INPUT NUM]:", num)

    if not num then return end

    num = math.clamp(num, 1, 70)

    transferThreshold = num

    print("[THRESHOLD SET]:", transferThreshold)
end)

Tabs.Storage:AddToggle("AutoTransferByCountToggle", { 
    Title = "Auto Transfer to Storage", 
    Default = false 
}):OnChanged(function(v)
    autoTransferByCount = v
    if v then 
        startAutoTransferByCount()
    end
end)

Fluent:Notify({ 
    Title = "KYRO HUB", 
    Content = "Premium", 
    Duration = 5 
})