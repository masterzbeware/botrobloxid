return {
    Execute = function()
        ----------------------------------------------------------------
        -- Collision.lua
        -- Otomatis mengatur collision/touch pada object tertentu.
        -- Tidak membutuhkan command.
        ----------------------------------------------------------------

        local Workspace = game:GetService("Workspace")

        local function setCanCollideFalse(instance)
            if instance:IsA("BasePart") then
                instance.CanCollide = false
            end
        end

        ----------------------------------------------------------------
        -- 1. workspace.Deco.Lake.Dock1.Pillar
        -- Pillar1 sampai Pillar8 dibuat CanCollide = false.
        ----------------------------------------------------------------

        local deco = Workspace:FindFirstChild("Deco")
        local lake = deco and deco:FindFirstChild("Lake")
        local dock1 = lake and lake:FindFirstChild("Dock1")
        local pillarFolder = dock1 and dock1:FindFirstChild("Pillar")

        if pillarFolder then
            for i = 1, 8 do
                local pillar = pillarFolder:FindFirstChild("Pillar" .. i)

                if pillar then
                    setCanCollideFalse(pillar)
                end
            end
        end

        ----------------------------------------------------------------
        -- 2. workspace.Park["Park Teleport"].TeleportPart1
        -- TeleportPart1 dihapus/destroy sepenuhnya.
        ----------------------------------------------------------------

        local park = Workspace:FindFirstChild("Park")
        local parkTeleport = park and park:FindFirstChild("Park Teleport")
        local teleportPart1 = parkTeleport
            and parkTeleport:FindFirstChild("TeleportPart1")

        if teleportPart1 then
            teleportPart1:Destroy()
        end

        ----------------------------------------------------------------
        -- 3. workspace["Small Stage"]
        -- Semua Model bernama "Bleacher Bench" beserta seluruh
        -- BasePart di dalamnya dibuat CanCollide = false.
        ----------------------------------------------------------------

        local smallStage = Workspace:FindFirstChild("Small Stage")

        if smallStage then
            for _, descendant in ipairs(smallStage:GetDescendants()) do
                if descendant:IsA("Model")
                    and descendant.Name == "Bleacher Bench" then

                    for _, part in ipairs(descendant:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- 4. workspace["Teleportation Portals"].Portal1.Teleport
        -- CanTouch = false.
        ----------------------------------------------------------------

        local portals = Workspace:FindFirstChild("Teleportation Portals")
        local portal1 = portals and portals:FindFirstChild("Portal1")
        local portalTeleport = portal1
            and portal1:FindFirstChild("Teleport")

        if portalTeleport and portalTeleport:IsA("BasePart") then
            portalTeleport.CanTouch = false
        end

        ----------------------------------------------------------------
        -- 5. workspace.Forest
        -- Cari semua Model "RedwoodTreeLarge-Var01".
        -- Di dalam masing-masing model, DogwoodTree_Var01 di-destroy.
        ----------------------------------------------------------------

        local forest = Workspace:FindFirstChild("Forest")

        if forest then
            for _, descendant in ipairs(forest:GetDescendants()) do
                if descendant:IsA("Model")
                    and descendant.Name == "RedwoodTreeLarge-Var01" then

                    local dogwood = descendant:FindFirstChild(
                        "DogwoodTree_Var01",
                        true
                    )

                    if dogwood then
                        dogwood:Destroy()
                    end
                end
            end
        end

        print("[Collision.lua] Collision/touch setup selesai.")
    end
}