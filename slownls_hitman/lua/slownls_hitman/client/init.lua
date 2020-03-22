--[[  
    Addon: Hitman
    By: SlownLS
]]

SlownLS.Hitman.Contracts = SlownLS.Hitman.Contracts or {}
SlownLS.Hitman.CurrentContract = SlownLS.Hitman.CurrentContract or {}
SlownLS.Hitman.Frame = SlownLS.Hitman.Frame or nil

-- Fonts
surface.CreateFont("SlownLS:Hitman:32", { font = "Roboto", extended = false, size = 32, weight = 500, })
surface.CreateFont("SlownLS:Hitman:24", { font = "Roboto", extended = false, size = 24, weight = 500, })
surface.CreateFont("SlownLS:Hitman:18", { font = "Roboto", extended = false, size = 18, weight = 500, })
surface.CreateFont("SlownLS:Hitman:16", { font = "Roboto", extended = false, size = 16, weight = 500, })

--[[ Functions ]]

function SlownLS.Hitman:openTablet(ent)
    local vm = LocalPlayer():GetViewModel()

    local tblTopLeft = ent:getAttach(vm, "screen_topleft")
    local tblBottomRight = ent:getAttach(vm, "screen_buttomright")

    local intTop, intBottom = tblTopLeft.Pos:ToScreen(), tblBottomRight.Pos:ToScreen()
    
    local w, h = intBottom.x - intTop.x, intBottom.y - intTop.y
    local x, y = intTop.x, intTop.y

    w = w + 3
    h = h + 7

    x = x - 1
    y = y - 5

    local frame = vgui.Create("SlownLS:Hitman:Tablet")
        frame:SetSize(w,h)
        frame:SetPos(x,y)
        frame:load()

    SlownLS.Hitman.Tablet = frame
end

function SlownLS.Hitman:showContract()
    local tblContract = SlownLS.Hitman.CurrentContract

    local intEnd = CurTime() + SlownLS.Hitman.Config.Time

    if( IsValid(SlownLS.Hitman.Frame) ) then 
        SlownLS.Hitman.Frame:Remove()
    end

    local tblPanel = SlownLS.Hitman.Config.Panel

    local intH = 95

    if( tblPanel.showJob ) then
        intH = intH + 35
    end

    if( tblPanel.showDistance ) then
        intH = intH + 40
    end

    local frame = vgui.Create("SlownLS:Hitman:DFrame")
        frame:SetSize(300,intH)
        frame:SetPos(15,15)
        frame:ShowCloseButton(false)
        function frame:Paint(w,h)
            self:drawRect(0, 0, w, h, self:getColor('primary'))
            self:drawRect(0, 0, w, 50, self:getColor('secondary'))

            if( not tblContract or not IsValid(tblContract.victim) ) then 
                self:Remove()
                return
            end

            local pPlayer = tblContract.victim

            local intOffset = 50 + 40

            local intStart = CurTime()
            local intTime = math.Round(intEnd - intStart)
            intTime = math.Clamp(intTime, 0, 9999999999999999)

            draw.SimpleText(self:getLanguage('timeLeft') .. " : " .. string.FormattedTime(intTime, "%02i:%02i"), "SlownLS:Hitman:24", 10, 50 / 2, color_white, 0, 1)

            if( intTime <= 0 ) then
                self:Remove()
                return 
            end

            draw.SimpleText(self:getLanguage('target') .. ": " .. pPlayer:Nick(), "SlownLS:Hitman:24", 10, 50 + 10, color_white, 0, 0)

            if( tblPanel.showJob ) then
                draw.SimpleText(self:getLanguage('occupation') .. ": " .. pPlayer:getDarkRPVar('job'), "SlownLS:Hitman:24", 10, intOffset, color_white, 0, 0)

                intOffset = intOffset + 35
            end

            if( tblPanel.showDistance ) then                
                local range = (math.ceil(100*(LocalPlayer():GetPos():Distance(pPlayer:GetPos())*0.024))/100)

                self:drawRect(0, intOffset, w, h - intOffset, self:getColor('secondary'))
                draw.SimpleText(self:getLanguage('distance') .. ": " .. range .. "m", "SlownLS:Hitman:24", 10, intOffset + 10, color_white, 0, 0)
            end
        end

    SlownLS.Hitman.Frame = frame
end

--[[ Networks ]]

SlownLS.Hitman:addEvent('open_phone', function(tblInfos)
    local ent = tblInfos.ent

    local frame = vgui.Create("SlownLS:Hitman:Phone")
        frame:setEntity(ent)
        frame:load()
end)

SlownLS.Hitman:addEvent('update_contracts', function(tblContracts)
    SlownLS.Hitman.Contracts = tblContracts
end)

SlownLS.Hitman:addEvent('send_contract', function(tblContract)
    SlownLS.Hitman.CurrentContract = tblContract

    SlownLS.Hitman:showContract()
end)

SlownLS.Hitman:addEvent("remove_contract", function()
    SlownLS.Hitman.CurrentContract = nil

    if( IsValid(SlownLS.Hitman.Frame) ) then 
        SlownLS.Hitman.Frame:Remove()
    end

	LocalPlayer().SlownLS_Hitman_Target = "???"
	LocalPlayer().SlownLS_Hitman_Percent = 0
	LocalPlayer().SlownLS_Hitman_Info = "???"    
end)

-- Hooks

hook.Add( "InputMouseApply", "SlownLS:Hitman:Mouse", function(cmd)
    local entWep = LocalPlayer():GetActiveWeapon()

    if( not IsValid(entWep) ) then return end
    if( entWep:GetClass() != "slownls_hitman_tablet" ) then return end
    if( entWep.boolFocus == false ) then return end

	cmd:SetMouseX( 0 )
	cmd:SetMouseY( 0 )

	return true
end )

hook.Add( "StartCommand", "SlownLS:Hitman:StartCommand", function(_, ucmd)
    local entWep = LocalPlayer():GetActiveWeapon()

    if( not IsValid(entWep) ) then return end
    if( entWep:GetClass() != "slownls_hitman_tablet" ) then return end
    if( entWep.boolFocus == false ) then return end

    ucmd:ClearMovement()
    ucmd:RemoveKey( IN_BACK )
    ucmd:RemoveKey( IN_DUCK )
    ucmd:RemoveKey( IN_FORWARD )
    ucmd:RemoveKey( IN_JUMP )
    ucmd:RemoveKey( IN_MOVELEFT )
    ucmd:RemoveKey( IN_MOVERIGHT )
    ucmd:RemoveKey( IN_SPEED )
    ucmd:RemoveKey( IN_WALK )
    ucmd:RemoveKey( IN_RUN )
    ucmd:SetImpulse( 0 )
end)

hook.Add("Think", "SlownLS:Hitman:Think", function()
    local pnl = SlownLS.Hitman.Frame

    if( not IsValid(pnl) ) then return end

    local pPlayer = LocalPlayer()
    local entWep = pPlayer:GetActiveWeapon()

    if( IsValid(entWep) and entWep:GetClass() == "slownls_hitman_binoculars" and entWep.boolZ_InZoom ) then
        if( pnl:IsVisible() ) then
            pnl:SetVisible(false)
        end
    else
        if( not pnl:IsVisible() ) then
            pnl:SetVisible(true)
        end                
    end
end)

hook.Add("HUDShouldDraw", "SlownLS:Hitman:HUDSouldDraw", function(str)
    if( !IsValid(LocalPlayer())) then return end

    local pPlayer = LocalPlayer()
    local entWep = pPlayer:GetActiveWeapon()

    if( IsValid(entWep) and entWep:GetClass() == "slownls_hitman_binoculars" and entWep.boolZ_InZoom and str == "CHudCrosshair" ) then
        return false 
    end
end)

hook.Add("HUDDrawTargetID", "SlownLS:Hitman:HUDDrawTargetID", function()
    local pPlayer = LocalPlayer()
    local entWep = pPlayer:GetActiveWeapon()

    if( IsValid(entWep) and entWep:GetClass() == "slownls_hitman_binoculars" and entWep.boolZ_InZoom ) then
        return false 
    end
end)