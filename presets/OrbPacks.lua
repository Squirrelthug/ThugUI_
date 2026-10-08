





local ThugUI = _G.ThugUI

ThugUI.OrbPacks = {
    health = {
        acid = {
            name = "Acid cloud",
            stack = {
                fill = {
                    file = "",
                    color = { 0.1, 0.8, 0.1 },
                    alpha = 1,
                    blend = "normal"
                },
                layers = {
                    {
                        name = "Acid cloud",
                        kind = "model",
                        file = 327202,
                        path = "spells/acid_ground_cloud.m2",
                        drain = true,
                        camDist = 1,
                        camX = 0,
                        camY = 0,
                        camZ = 0,
                        facing = 0,
                        alpha = 1,
                        scale = 1,
                        x = 0,
                        y = 0
                    }
                }
            }
        }
    },
    mana = {},
    rage = {},
    energy = {},
    pips = {}
}
