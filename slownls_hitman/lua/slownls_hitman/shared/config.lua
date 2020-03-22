--[[  
    Addon: Hitman
    By: SlownLS
]]

local CONFIG = {}

-- Language of the script
CONFIG.Language = "en"

-- Enable the FastDL for the models and materials ?
CONFIG.FastDL = true 

-- Model of the phone booth
CONFIG.PhoneBoothModel = "models/props_equipment/phone_booth.mdl" 

-- Hitman jobs
CONFIG.Jobs = {
    ['Hitman'] = true,
}

-- Jobs can't make contract
CONFIG.BlackList = {
    ['Civil Protection'] = true,
}

-- Description configuration (contract)
CONFIG.Verifications = {
    description = {
        required = true,
        min = 2, // Minimum length of the description
        max = 200, // Maxium length of the description
    },
    price = {
        min = 1, // Minimum price of the contract
        max = 10000, // Maximum price of the contract
    }
}

-- Time to finish the contract (in seconds)
CONFIG.Time = 60 * 5 // 0 to disable

-- Hitman panel
CONFIG.Panel = {
    showJob = true, -- Display the victim job
    showDistance = true, -- Display the distance between the hitman and the victim
}

--  Appearance of the menus
CONFIG.Colors = {
    primary = Color(32,32,32),
    secondary = Color(36,36,36),
    
    blue = Color(41,128,185),

    red = Color(190,71,71),
    red2 = Color(255,0,0),

    green = Color(29, 131, 72),
    green2 = Color(0,255,0),

    text = Color(188,188,188),
    outline = Color(44,44,44),
}
 
SlownLS.Hitman.Config = CONFIG