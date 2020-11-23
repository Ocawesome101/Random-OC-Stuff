--------------------------------------------------
-- OC-BIOS spec reference implementation.       --
-- Copyright (C) 2020 Ocawesome101              --
--                                              --
-- This program is free software: you can       --
-- redistribute it and/or modify it under the   --
-- terms of the GNU General Public License as   --
-- published by the Free Software Foundation,   --
-- either version 3 of the License, or  (at     --
-- your option) any later version.              --
--                                              --
-- This program is distributed in the hope that --
-- it will be useful, but WITHOUT ANY WARRANTY; --
-- without even the implied warranty of         --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR  --
-- PURPOSE.  See the GNU General Public License --
-- for more details.                            --
--                                              --
-- You should have received a copy of the GNU   --
-- General Public License along with this       --
-- program.  If not, see                        --
-- <https://www.gnu.org/licenses/>.             --
--------------------------------------------------

local config  = {}
local comp    = component
local pc      = computer
pc.setArchitecture("Lua 5.3")
local eeprom  = comp.proxy(comp.list("eeprom", true)())
-- configuration IDs
local _ID_EXPOSE_TERM,_ID_BOOT_ADDR, _ID_MENU_TIME = 1, 2, 4
local string = string
local function loadconfig()
  local data = eeprom.getData()
  if #data == 0 then
    config[_ID_EXPOSE_TERM] = false
    config[_ID_SHOW_LOGO] = true
  end
  while #data > 0 do
    local id, len = string.unpack("<I1I1", data)
    data = data:sub(3)
    config[id] = assert(load("return " .. string.unpack("<c"..len, data:sub(1, len)), "=(config)"))() -- I'm so, so sorry.
    data = data:sub(len+1)
  end
end

local function saveconfig()
  local data = ""
  for id, val in pairs(config) do
    if type(val) == "string" then
      val = string.format("'%s'", val)
    end
    val = tostring(val)
    local ent = string.pack("<I1I1c"..#val, id, #val, val)
    data = data .. ent
  end
  if #data > 256 then
    error("configuration over 256 bytes!")
  end
  eeprom.setData(data)
end

local term = {}
local gpu = comp.proxy((comp.list("gpu", true)()))
gpu.bind((comp.list("screen", true)()))
local gsfg=gpu.setForeground
local gsbg=gpu.setBackground
local gs=gpu.set
do
  local cx, cy = 1, 1

  local function chkcpos()
    local w, h = gpu.getResolution()
    if cx > w then
      cx, cy = 1, cy + 1
    end

    if cy > h then
      gpu.copy(1, 1, w, h, 0, -1)
      gpu.fill(1, h, w, 1, " ")
      cy = h
    end

    if cx < 1 then cx = w cy = cy - 1 end
    if cy < 1 then cy = 1 end
  end

  local function write(s)
    local w, h = gpu.getResolution()
    while #s > 0 do
      chkcpos()
      local ln = s:sub(1, w - cx + 1)
      s = s:sub(#ln + 1)
      gs(cx, cy, ln)
      cx = cx + #ln
    end
  end

  function term.read(a,b)
    local buf = ""
    local sx, sy = a or cx, b or cy
    local function redraw() -- TODO TODO TODO: handle going offscreen at the bottom
      cx, cy = sx, sy
      write(buf .. "_ ")
    end
    while true do
      redraw()
      local sig, _, char, code = pc.pullSignal()
      if sig == "key_down" then
        if char > 31 and char < 127 then
          buf = buf .. string.char(char)
        elseif char == 8 then
          buf = buf:sub(1, -2)
        elseif char == 13 then
          cx, cy = sx, sy
          write(buf .. " ")
          return buf
        end
      end
    end
  end
end

loadconfig()
saveconfig()
if config[_ID_EXPOSE_TERM] == "true" then
  _G.term = term
end

local timeout = config[_ID_MENU_TIME] or 5
local fg = 0xDC0000
gsfg(fg)
local w, h = gpu.getResolution()
gpu.fill(1, 1, w, h, " ")
gs(1, 1, "┏━━━━┓")
gs(1, 2, "┃ ╭╮ ┃")
gs(1, 3, "┃ ╰╯ ┃")
gs(1, 4, "┗━━━━┛")
gsfg(0xFFFFFF)
gs(8, 2, "OC-BIOS version 0.1.0")
gs(8, 3, "Copyright (c) 2020 Ocawesome101, GNU GPLv3.")
local total, free = pc.totalMemory(), pc.freeMemory()
gs(1, 5, string.format("\n%dK total, %dK free\n\n", total // 1024, free // 1024))

local function pad(s, w)
  s = s:sub(1, w)
  s = s .. string.rep(" ", w - unicode.len(s))
  return s
end

local function menu(items, title)
  title = title or "Please choose one:"
  gpu.fill(1, 1, w, h, " ")
  gsfg(fg)
  gs(1, 1, title)
  local sel = 1
  local handlers = {
    [200] = function() -- up
      if sel > 1 then
        sel = sel - 1
      else
        sel = #items
      end
    end,
    [208] = function() -- down
      if sel < #items then
        sel = sel + 1
      else
        sel = 1
      end
    end
  }
  while true do
    for i=1, #items, 1 do
      local prefix = "  "
      if sel == i then
        prefix = "⇝ "
        gsfg(0x000000)
        gsbg(fg)
      else
        gsbg(0x000000)
        gsfg(fg)
      end
      gs(2, i + 2, prefix .. pad(items[i], w - 8))
    end
    local sig, _, _, code = pc.pullSignal()
    if sig == "key_down" then
      if handlers[code] then
        handlers[code]()
      elseif code == 28 then
        break
      end
    end
  end
  gpu.fill(1, 1, w, h, " ")
  return items[sel]
end

local function boot_managed(addr)
  local prx = comp.proxy(addr)
  if not prx.exists("init.lua") then
    return nil, "init.lua not present"
  end
  local handle, data, ok, err = prx.open("init.lua"), ""
  repeat
    local chunk = prx.read(handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  prx.close(handle)
  local ok, err = load(data, "=(init)")
  if not ok then
    return nil, err
  end
  return pcall(ok)
end

local function boot_unmanaged(addr)
  local prx = comp.proxy(addr)
  local bootsect = prx.readSector(1):gsub("\0", "")
  local ok, err = load(bootsect, "=(bootsector)")
  if not ok then
    return nil, err
  end
  return pcall(ok)
end

gs(1, h, "Press F6 for Config")
gs(w, h, "" .. timeout)

local function prompt()
  gsbg(fg)
  gsfg(0x000000)
  gpu.fill(1, h // 2 - 1, w, 3, " ")
  gsfg(fg)
  gsbg(0x000000)
  gpu.fill(1, h // 2, w, 1, " ")
  return term.read(1, h // 2)
end

local function config_menu()
  local items
  while true do
    items = {
      "Set menu timeout",
      "Expose term API ("..tostring(config[_ID_EXPOSE_TERM])..")",
      "Clear boot address",
      "Exit"
    }
    local i = menu(items, "OC-BIOS Settings")
    if i == items[1] then
      config[_ID_MENU_TIME] = tonumber(prompt()) or timeout
    elseif i == items[2] then
      config[_ID_EXPOSE_TERM] = not config[_ID_EXPOSE_TERM]
    elseif i == items[3] then
      config[_ID_BOOT_ADDR] = nil
    elseif i == items[4] then
      saveconfig()
      pc.shutdown(true)
    end
  end
end

local max = pc.uptime() + timeout
repeat
  local sig, _, _, code = pc.pullSignal(math.min(1, pc.uptime() - max))
  if sig == "key_down" and code == 64 then config_menu() end
  gs(w, h, "" .. ((max - pc.uptime()) // 1))
until pc.uptime() >= max

gs(1, 7, "Detecting drives...")
local fs = comp.list("filesystem", true)
local drive = comp.list("drive", true)
fs[pc.tmpAddress()] = nil
local boot = {}
for addr in fs do
  boot[#boot + 1] = addr
end
for addr in drive do
  boot[#boot + 1] = addr
end
gs(20, 7, "done.")

if not config[_ID_BOOT_ADDR] or not component.type(config[_ID_BOOT_ADDR]) then
  local boota = menu(boot, "Please select a boot device:")
  config[_ID_BOOT_ADDR] = boota
  saveconfig()
end

function pc.getBootAddress()
  return config[_ID_BOOT_ADDR]
end

function pc.setBootAddress(a)
  config[_ID_BOOT_ADDR] = a
  saveconfig()
end

local addr = config[_ID_BOOT_ADDR]
while true do
  local ok, err
  if component.type(addr) == "drive" then ok, err = boot_unmanaged(addr)
  else ok, err = boot_managed(addr) end
  if not ok and err then
    gs(1, 10, "Boot failed: " .. err)
  end
  repeat local sig = pc.pullSignal() until sig == "key_down"
end
