-- Run from .config/hypr: lua custom/tests/pc.lua
local binds, env, rules, calls = {}, {}, {}, {}
local monitor, special, windows = { name = "DP-2" }, nil, {}
local function action(kind)
 return function(opts) return function() calls[#calls+1] = {kind,opts} end end
end
package.preload['custom.rules'] = function() return true end
package.preload['custom.keybinds'] = function()
 binds['SUPER + C']='codex'; binds['SUPER + Z']='effects'; binds['SUPER + ALT + P']='refresh'
end
local centered=0
package.preload['custom.actions.pointer']=function() return {center_after_navigation=function() centered=centered+1 end} end
package.preload['custom.actions.layout']=function() return {cycle=function(g) calls[#calls+1]={'cycle',g} end} end
hl={env=function(k,v) env[k]=v end, workspace_rule=function(r) rules[#rules+1]=r end,
 window_rule=function() end, bind=function(k,f) assert(not binds[k],k); binds[k]=f end,
 unbind=function(k) binds[k]=nil end, get_active_monitor=function() return monitor end,
 get_active_special_workspace=function() return special end, get_windows=function() return windows end,
 exec_cmd=function(c,o) calls[#calls+1]={'launch',c,o} end, dispatch=function(f) f() end,
 dsp={focus=action('focus'),exec_cmd=action('exec'),global=action('global'),
 workspace={toggle_special=action('toggle')},window={move=action('move')}}}
require('custom.pc'); require('custom.keybinds')
assert(env.qsConfig=='end4-pC' and env.QSG_RHI_BACKEND=='opengl')
assert(#rules==20 and rules[10].monitor=='DP-2' and rules[11].monitor=='HDMI-A-1')
assert(binds['SUPER + C']=='codex' and binds['SUPER + Z']=='effects')
binds['SUPER + ALT + P'](); assert(calls[#calls][2]=='papers')
binds['SUPER + Tab'](); assert(calls[#calls][2].monitor=='HDMI-A-1')
monitor.name='HDMI-A-1'; binds['SUPER + Tab'](); assert(calls[#calls][2].monitor=='DP-2')
monitor=nil; local n=#calls; binds['SUPER + Tab'](); assert(#calls==n)
binds['CTRL + SUPER + Z'](); assert(calls[#calls][2][2]=='lua:zscroll')
binds['SUPER + W'](); assert(calls[#calls][2]=='firefox --new-window')
binds['SUPER + SHIFT + W'](); assert(calls[#calls][2]=='firefox --private-window')
windows={{class='firefox',title='Private Browsing'}}
binds['SUPER + SHIFT + W'](); assert(calls[#calls][1]=='focus')
windows={}; binds['SUPER + O']()
assert(calls[#calls-1][1]=='launch' and calls[#calls-1][3].monitor=='HDMI-A-1')
special={name='special:vesktop'}; n=#calls; binds['SUPER + O'](); assert(#calls==n+2 and calls[#calls][1]=='toggle')
special=nil; windows={{class='vesktop',workspace={name='1'}}}; binds['SUPER + O']()
assert(calls[#calls-2][1]=='move' and centered==1)
print('PASS: PC load order, shared shortcuts, monitor routing, Firefox and special workspace toggles')
