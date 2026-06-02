-- KYRO HUB CLEAN VERSION (ALL WORKING - MEAT + CUCI + PACKAGE + EQUIP)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- REMOTES
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

-- INVENTORY REMOTE
local InvRequest = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InvRemotes"):WaitForChild("InvRequest")

-- FLUENT UI
local Fluent = loadstring(game:HttpGet(
    "https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"
))()

local Window = Fluent:CreateWindow({
    Title = "KYRO HUB",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 620),
    Acrylic = true,
    Theme = "Amber Glow",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Search = true
})

local Tabs = {
    Shop = Window:AddTab({ Title = "SHOP", Scrollable = true }),
    Job = Window:AddTab({ Title = "JOB", Scrollable = true })
}

-- VARIABLES JOB
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

-- VARIABLES SHOP
local buyItemName = "BigKnife"
local buyQuantity = 1
local buyItems = { "BigKnife" }

-- SELL
local autoSellEnabled = false
local sellAmount = 100
local autoSellLoopRunning = false

local sellItems = {
    "AClassMeat",
    "BClassMeat",
    "CClassMeat",
    "PackageMeat",
    "CleanMeat"
}
local selectedSellItem = sellItems[1]

-- EQUIP BIGKNIFE FUNCTIONS
local function findBigKnife()
    local character = LocalPlayer.Character
    if character then
        local knife = character:FindFirstChild("BigKnife")
        if knife then
            return knife
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local knife = backpack:FindFirstChild("BigKnife")
        if knife then
            return knife
        end
    end

    local equipados = LocalPlayer:FindFirstChild("equipados")
    if equipados then
        local knife = equipados:FindFirstChild("BigKnife")
        if knife then
            return knife
        end
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
        Fluent:Notify({
            Title = "Equip BigKnife",
            Content = "Already equipped!",
            Duration = 2
        })
        return true
    end

    local knife = findBigKnife()
    if knife then
        InvRequest:InvokeServer("janemseimais", knife)
        task.wait(0.5)

        if isBigKnifeEquipped() then
            Fluent:Notify({
                Title = "Equip BigKnife",
                Content = "Successfully equipped!",
                Duration = 2
            })
            return true
        end
    end

    InvRequest:InvokeServer("janemseimais_byname", "BigKnife")
    task.wait(0.5)

    if isBigKnifeEquipped() then
        Fluent:Notify({
            Title = "Equip BigKnife",
            Content = "Successfully equipped via name!",
            Duration = 2
        })
        return true
    end

    Fluent:Notify({
        Title = "Equip BigKnife",
        Content = "BigKnife not found in inventory!",
        Duration = 3
    })

    return false
end

-- PROMPT FUNCTIONS
local function getMeatPrompt()
    local rawFolder = Workspace:FindFirstChild("RawMeatFolder")
    if not rawFolder then
        return nil
    end

    for _, model in ipairs(rawFolder:GetChildren()) do
        if model:IsA("Model") and model.Name == "RawMeatModel" then
            local meatPart = model:FindFirstChild("MeatPart")

            if meatPart then
                local prompt = meatPart:FindFirstChild("MeatPrompt")

                if prompt and prompt:IsA("ProximityPrompt") then
                    pcall(function()
                        prompt.MaxActivationDistance = 20
                    end)

                    return prompt
                end
            end
        end
    end

    return nil
end

local function getCuciPrompt()
    local washingStation = Workspace:FindFirstChild("WashingMeatStation")
    if not washingStation then
        return nil
    end

    local sinkModel = washingStation:FindFirstChild("SinkModel")
    if not sinkModel then
        return nil
    end

    local sinkPart = sinkModel:FindFirstChild("SinkPart")
    if not sinkPart then
        return nil
    end

    local prompt = sinkPart:FindFirstChild("CuciPrompt")
    if prompt then
        pcall(function()
            prompt.MaxActivationDistance = 15
        end)
        return prompt
    end

    return nil
end

local function getPackagePrompt()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local name = v.Name:lower()
            if name:find("pack") or name:find("package") then
                pcall(function()
                    v.MaxActivationDistance = 15
                end)
                return v
            end
        end
    end

    return nil
end

local function triggerPrompt(prompt)
    if not prompt then
        return false
    end

    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
    end)

    return true
end

-- FUNCTIONS SHOP
local function buyItem()
    BuyCart:FireServer({
        [buyItemName] = {
            Price = 34,
            Quantity = buyQuantity
        }
    })

    Fluent:Notify({
        Title = "SHOP",
        Content = "Buy " .. buyItemName .. " x" .. buyQuantity,
        Duration = 2
    })
end

local function sellItemOnce()
    ClientAction:FireServer("Sell", selectedSellItem, sellAmount)

    Fluent:Notify({
        Title = "SELL",
        Content = "Sold " .. sellAmount .. " x " .. selectedSellItem,
        Duration = 2
    })
end

SystemNotify.OnClientEvent:Connect(function(type, msg)
    if type == "error" then
        Fluent:Notify({
            Title = "Sell Error",
            Content = msg,
            Duration = 3
        })
    end
end)

local function autoSellLoop()
    if autoSellLoopRunning then
        return
    end

    autoSellLoopRunning = true

    task.spawn(function()
        while autoSellEnabled do
            ClientAction:FireServer("Sell", selectedSellItem, sellAmount)
            task.wait(2)
        end

        autoSellLoopRunning = false
    end)
end

-- UI ANGLE DETECTION
local function getAngles()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then
        return
    end

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

-- TAP SYSTEM
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

-- EVENTS
MeatSystemRemotes.StartSession.OnClientEvent:Connect(function()
    isMeatActive = true
end)

MeatSystemRemotes.UpdateUI.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" then
        isMeatActive = false
    elseif status == "FAIL" then
        isMeatActive = false
    end
end)

CuciMeatRemotes.ShowConfirm.OnClientEvent:Connect(function()
    if cuciEnabled then
        CuciPlayerConfirmed:FireServer()
    end
end)

CuciMeatRemotes.StartMinigame.OnClientEvent:Connect(function()
    isCuciActive = true
end)

CuciMeatRemotes.UpdateUI.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" then
        isCuciActive = false
    elseif status == "FAIL" then
        isCuciActive = false
    end
end)

PackagingMeatRemotes.StartMinigame.OnClientEvent:Connect(function()
    isPackageActive = true
    packageDragSent = false
end)

PackagingMeatRemotes.UpdateUI.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" then
        isPackageActive = false
        packageDragSent = false
    end
end)

-- PACKAGE DRAG
local function sendPackageDrag()
    if not packageEnabled or not isPackageActive or packageDragSent then
        return
    end

    task.wait(packageDelay)
    PackageDragComplete:FireServer()
    packageDragSent = true
end

-- AUTO MEAT LOOP
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
            local prompt = getCuciPrompt()
            if prompt then
                triggerPrompt(prompt)
            end
        end

        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if packageEnabled then
            local prompt = getPackagePrompt()

            if prompt then
                triggerPrompt(prompt)
            end

            sendPackageDrag()
        end

        task.wait(2)
    end
end)

-- UI JOB TAB
Tabs.Job:AddSection("Cut Meat")

Tabs.Job:AddToggle("Meat", {
    Title = "Auto Meat",
    Default = false
}):OnChanged(function(v)
    meatEnabled = v

    if v then
        equipBigKnife()
    end
end)

Tabs.Job:AddButton({
    Title = "Equip BigKnife",
    Callback = function()
        equipBigKnife()
    end
})

Tabs.Job:AddSection("Wash Meat")

Tabs.Job:AddToggle("Cuci", {
    Title = "Wash Meat",
    Default = false
}):OnChanged(function(v)
    cuciEnabled = v
end)

Tabs.Job:AddSection("Package Meat")

Tabs.Job:AddToggle("Package", {
    Title = "Package Meat",
    Default = false
}):OnChanged(function(v)
    packageEnabled = v
end)

Tabs.Job:AddSlider("PackageDelay", {
    Title = "Package Delay (s)",
    Min = 1,
    Max = 2,
    Default = 1,
    Rounding = 1
}):OnChanged(function(v)
    packageDelay = v
end)

-- UI SHOP TAB
Tabs.Shop:AddSection("SHOP")

Tabs.Shop:AddInput("BuyAmount", {
    Title = "BigKnife Amount",
    Default = "1"
}):OnChanged(function(v)
    buyQuantity = tonumber(v) or 1
end)

Tabs.Shop:AddButton({
    Title = "Buy BigKnife",
    Callback = buyItem
})

Tabs.Shop:AddSection("SELL")

Tabs.Shop:AddDropdown("SellItem", {
    Title = "Select Item",
    Values = sellItems,
    Default = 1
}):OnChanged(function(v)
    selectedSellItem = v
end)

Tabs.Shop:AddInput("SellAmount", {
    Title = "Amount",
    Default = "100"
}):OnChanged(function(v)
    sellAmount = tonumber(v) or 100
end)

Tabs.Shop:AddButton({
    Title = "Sell Now",
    Callback = sellItemOnce
})

Tabs.Shop:AddToggle("AutoSell", {
    Title = "Auto Sell",
    Default = false
}):OnChanged(function(v)
    autoSellEnabled = v

    if v then
        autoSellLoop()
    end
end)

Fluent:Notify({
    Title = "KYRO HUB",
    Content = "Loaded | Equip BigKnife added!",
    Duration = 3
})