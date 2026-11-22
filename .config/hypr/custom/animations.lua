-- Personal window animation settings.
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.2, bezier = "standard" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel" })
