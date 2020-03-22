--[[  
    Addon: Hitman
    By: SlownLS
]]

AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "Phone box"
ENT.Category = "SlownLS | Hitman"
ENT.Spawnable = true

if( SERVER ) then
    function ENT:Initialize()
        self:SetModel(SlownLS.Hitman.Config.PhoneBoothModel)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end

    function ENT:AcceptInput(strName, _, pCaller)
        if( strName == "Use" && IsValid(pCaller) && pCaller:IsPlayer() ) then
            if( SlownLS.Hitman.Config.BlackList[team.GetName(pCaller:Team())] ) then return end

            SlownLS.Hitman:sendEvent("open_phone", { 
                ent = self
            }, pCaller)
        end
    end 
end