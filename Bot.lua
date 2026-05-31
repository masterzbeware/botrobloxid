local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Generator ESP",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "MAIN" }),
    ESP = Window:AddTab({ Title = "ESP" })
}

Tabs.ESP:AddParagraph({
    Title = "ESP Generator",
    Content = "Highlight generator dan tampilkan progress repair."
})

local ESPEnabled = false
local ESPObjects = {}

local function CreateESP(gen)
    if ESPObjects[gen] then
        return
    end

    local part = gen:FindFirstChildWhichIsA("BasePart")

    if not part then
        return
    end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = gen
    highlight.Parent = gen

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GeneratorProgress"
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.TextScaled = false
text.TextSize = 20
text.Font = Enum.Font.GothamBold
text.TextColor3 = Color3.fromRGB(255,255,255)
text.TextStrokeTransparency = 0.5
text.Text = "Progress : 0%"
text.Parent = billboard

    local function UpdateText()
        local progress = gen:GetAttribute("RepairProgress") or 0

        -- jika ternyata game memakai 0-1
        if progress <= 1 then
            progress = progress * 100
        end

        progress = math.floor(progress)

        text.Text = ("Progress : %d%%"):format(progress)

        if progress >= 100 then
            highlight.FillColor = Color3.fromRGB(0,255,0)
        elseif progress > 0 then
            highlight.FillColor = Color3.fromRGB(255,255,0)
        else
            highlight.FillColor = Color3.fromRGB(255,0,0)
        end
    end

    UpdateText()

    local connection = gen:GetAttributeChangedSignal("RepairProgress"):Connect(UpdateText)

    ESPObjects[gen] = {
        Highlight = highlight,
        Billboard = billboard,
        Connection = connection
    }
end

local function RemoveESP()
    for _, data in pairs(ESPObjects) do
        if data.Connection then
            data.Connection:Disconnect()
        end

        if data.Highlight then
            data.Highlight:Destroy()
        end

        if data.Billboard then
            data.Billboard:Destroy()
        end
    end

    table.clear(ESPObjects)
end

local function UpdateESP()
    local Generators = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Generators")

    if not Generators then
        return
    end

    for _, gen in ipairs(Generators:GetChildren()) do
        CreateESP(gen)
    end
end

local Toggle = Tabs.ESP:AddToggle("GeneratorESP", {
    Title = "ESP Generator",
    Default = false
})

Toggle:OnChanged(function(Value)
    ESPEnabled = Value

    if ESPEnabled then
        UpdateESP()
    else
        RemoveESP()
    end
end)

task.spawn(function()
    while task.wait(2) do
        if ESPEnabled then
            UpdateESP()
        end
    end
end)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Loaded",
    Content = "Generator ESP Ready",
    Duration = 5
})