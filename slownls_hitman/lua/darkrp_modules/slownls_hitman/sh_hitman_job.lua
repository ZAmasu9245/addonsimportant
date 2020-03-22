-- Default job hitman

TEAM_SHITMAN = DarkRP.createJob("Hitman", {
    color = Color(25, 25, 170, 255),
    model = {
        "models/player/group01/male_01.mdl",
        "models/player/group01/male_02.mdl",
        "models/player/group01/male_03.mdl"
    },
    description = [[Kill all players.]],
    weapons = {"ls_sniper", "slownls_hitman_binoculars", "slownls_hitman_tablet"},
    command = "slownls_hitman",
    max = 2,
    salary = 300,
    admin = 0,
    vote = false,
    hasLicense = true,
})