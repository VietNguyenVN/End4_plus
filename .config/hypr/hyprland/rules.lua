-- ######## Window rules ########

-- Disable blur for xwayland context menus
hl.window_rule({match = {class = "^()$", title = "^()$"}, no_blur = true})

-- Helper para float+center+size
local function float_center(match, size)
    local rule = {match = match, float = true, center = true}
    hl.window_rule(rule)
    if size then
        hl.window_rule({match = match, size = size})
    end
end

-- Floating dialogs
local float_titles = {
    "^(Open File)(.*)$",
    "^(Select a File)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Save As)(.*)$",
    "^(Library)(.*)$",
    "^(File Upload)(.*)$",
    "^(.*)(wants to save)$",
    "^(.*)(wants to open)$",
}
for _, t in ipairs(float_titles) do
    float_center({title = t})
end

-- Choose wallpaper
float_center({title = "^(Choose wallpaper)(.*)$"}, {"(monitor_w*0.60)", "(monitor_h*0.65)"})

-- Float no center
local float_only_class = {
    "^(blueberry\\.py)$",
    "^(guifetch)$",
    ".*plasmawindowed.*",
    "kcm_.*",
    ".*io.github.wallpaper.selector.*",
    ".*bluedevilwizard",
    "^(plasma-changeicons)$",
    "^dev\\.warp\\.Warp$",
}
for _, c in ipairs({"^(blueberry\\.py)$", "^(guifetch)$", ".*plasmawindowed.*", "kcm_.*", ".*bluedevilwizard"}) do
    hl.window_rule({match = {class = c}, float = true})
end
for _, t in ipairs({".*Welcome", ".*Shell conflicts.*"}) do
    hl.window_rule({match = {title = t}, float = true})
end

-- float+center+size per clase
local fcs_class = {
    {class = "^(pavucontrol)$",                             size = {"(monitor_w*0.45)", "(monitor_h*0.45)"}},
    {class = "^(org.pulseaudio.pavucontrol)$",              size = {"(monitor_w*0.45)", "(monitor_h*0.45)"}},
    {class = "^(nm-connection-editor)$",                    size = {"(monitor_w*0.45)", "(monitor_h*0.45)"}},
    {class = "org.freedesktop.impl.portal.desktop.kde",     size = {"(monitor_w*0.60)", "(monitor_h*0.65)"}},
    {class = "io.github.wallpaper.selector",     			size = {"(monitor_w*0.65)", "(monitor_h*0.65)"}},
    {class = "^(Zotero)$",                                  size = {"(monitor_w*0.45)", "(monitor_h*0.45)"}},
    {class = "^(Sysfetch)$",                                size = {"(monitor_w*0.19)", "(monitor_h*0.55)"}},
    {class = "^(pavucontrol-qt)$",                          size = {"(monitor_w*0.55)", "(monitor_h*0.55)"}},
    {class = "^(org.kde.discover)$",                        size = {"(monitor_w*0.65)", "(monitor_h*0.65)"}},
    {class = "^(org.kde.kdialog)$",                        size = {"(monitor_w*0.65)", "(monitor_h*0.65)"}},
    {class = "^(org.kde.gwenview)$",                        size = {"(monitor_w*0.65)", "(monitor_h*0.65)"}},
    {class = "^(walls.py)$",                                size = {"(monitor_w*0.45)", "(monitor_h*0.55)"}},
    {class = "^(mpv)$",                                     size = {"(monitor_w*0.75)", "(monitor_h*0.75)"}},
}
for _, r in ipairs(fcs_class) do
    float_center({class = r.class}, r.size)
end

-- kitty extra
hl.window_rule({match = {class = "^(kitty)$"}, xray = false})

-- plasma-changeicons
hl.window_rule({match = {class = "^(plasma-changeicons)$"}, float = true, no_initial_focus = true, move = {999999, 999999}})

-- Dolphin copy
hl.window_rule({match = {title = "^(Copying — Dolphin)$"}, move = {40, 80}})

-- Tiling
hl.window_rule({match = {class = "^dev\\.warp\\.Warp$"}, tile = true})

-- Picture-in-Picture
local pip = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
hl.window_rule({match = {title = pip},
    float = true, pin = true, keep_aspect_ratio = true,
    move = {"(monitor_w*0.73)", "(monitor_h*0.72)"},
    size = {"(monitor_w*0.25)", "(monitor_h*0.25)"},
})

-- Screen sharing
local sharing = ".*is sharing (a window|your screen).*"
hl.window_rule({match = {title = sharing},
    float = true, pin = true,
    move = {"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"},
})

-- Tearing
for _, t in ipairs({".*\\.exe", ".*minecraft.*"}) do
    hl.window_rule({match = {title = t}, immediate = true})
end
hl.window_rule({match = {class = "^(steam_app).*"}, immediate = true})

-- Jetbrains
hl.window_rule({match = {class = "^jetbrains-.*$", float = 1, title = "^$|^\\s$|^win\\d+$"}, no_initial_focus = true})

-- No shadow tiled
hl.window_rule({match = {float = 0}, no_shadow = true})

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ######## Layer rules ########
-- Helper blur+ignore_alpha
local function blur_layer(ns, alpha)
    hl.layer_rule({match = {namespace = ns}, blur = true})
    if alpha then hl.layer_rule({match = {namespace = ns}, ignore_alpha = alpha}) end
end

hl.layer_rule({match = {namespace = ".*"}, xray = true})

local no_anim_ns = {"walker","selection","overview","launcher","anyrun","indicator.*","osk","hyprpicker","noanim"}
for _, ns in ipairs(no_anim_ns) do
    hl.layer_rule({match = {namespace = ns}, no_anim = true})
end

blur_layer("gtk-layer-shell", 0)
blur_layer("launcher", 0.5)
blur_layer("notifications", 0.69)
hl.layer_rule({match = {namespace = "logout_dialog"}, blur = true})

-- ags
hl.layer_rule({match = {namespace = "sideleft.*"}, animation = "slide left"})
hl.layer_rule({match = {namespace = "sideright.*"}, animation = "slide right"})

local blur_06 = {"session[0-9]*","bar[0-9]*","barcorner.*","dock[0-9]*","indicator.*","overview[0-9]*","launcher[0-9]*","cheatsheet[0-9]*","sideright[0-9]*","sideleft[0-9]*","osk[0-9]*"}
for _, ns in ipairs(blur_06) do
    blur_layer(ns, 0.6)
end

hl.layer_rule({match = {namespace = "gtk4-layer-shell"}, no_anim = true})
