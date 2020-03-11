-- GRUB-like BIOS --

local gpu = component.list("gpu")()
local screen = component.list("screen")()

if not (gpu and screen) then
  error("GPU and screen are required")
end

gpu = component.proxy(gpu)
gpu.bind(screen)

local w, h = gpu.maxResolution()
gpu.setResolution(w, h)

gpu.fill(1, 1, w, h, " ")

local function drawMenuFrame()
  gpu.set(w / 2 - 20, 1, "OpenComputers Unified Bootloader v0.1.0")
  gpu.setBackground(0x000000)
  gpu.fill(3, 2, w - 6, 1, unicode.char(0x2550)) -- top
  gpu.fill(3, 3, w - 6, h - 9, unicode.char(0x2551)) -- sides
  gpu.fill(3, h - 7, w - 6, 1, unicode.char(0x2550)) -- bottom
  gpu.set(3, 2, unicode.char(0x2554)) -- top left
  gpu.set(w - 4, 2, unicode.char(0x2557)) -- top right
  gpu.set(3, h - 7, unicode.char(0x255A)) -- bottom left
  gpu.set(w - 4, h - 7, unicode.char(0x255D)) -- bottom right
  gpu.fill(4, 3, w - 8, h - 10, " ")
  gpu.set(3, h - 5, ("Use %s and %s to navigate entries."):format(unicode.char(0x2191), unicode.char(0x2193)))
  gpu.set(3, h - 4, "Press [enter] to boot the selected entry.")
end

local function pad(text)
  return text .. (" "):rep((w - 8) - #text)
end

local function drawMenuEntry(dy, text, selected)
  if selected then
    gpu.setBackground(0xFFFFFF)
    gpu.setForeground(0x000000)
  else
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
  end
  gpu.set(4, dy + 2, pad(text))
end

local function trace(toTrace)
  local traceback = debug.traceback(toTrace, 2):gsub("\t", "  ")
  local ln = 2
  for line in traceback:gmatch("[^\n]+") do
    gpu.set(1, ln, line)
    ln = ln + 1
  end
end

local function boot(addr, file)
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
  gpu.set(1, 1, "Loading " .. file .. "...")
  local h, e = component.invoke(addr, "open", file)
  if not h then
    trace(e)
    while true do computer.pullSignal() end
  end
  local b = ""
  repeat
    local c = component.invoke(addr, "read", h, math.huge)
    b = b .. (c or "")
  until not c

  local ok, err = load(b, "="..file, "t", _G)
  if not ok then
    trace(err)
    while true do computer.pullSignal() end
  end

  ok()
end

drawMenuFrame()

local filesystems = component.list("filesystem")

local bootable = {}

for addr, _ in filesystems do
  if component.invoke(addr, "exists", "/boot/kernel.lua") then
    bootable[#bootable + 1] = {address = addr, path = "/boot/kernel.lua"}
  end
  if component.invoke(addr, "exists", "/init.lua") then
    bootable[#bootable + 1] = {address = addr, path = "/init.lua"}
  end
end

local function redraw(highlighted)
  local y = 1
  for _, e in next, bootable do
    drawMenuEntry(y, ("%s from %s"):format(e.path, e.address), y == highlighted)
    y = y + 1
  end
end

computer.setBootAddress = function()end -- Stub

local baddr = ""

function computer.getBootAddress()
  return baddr
end

local sel = 1
while true do
  redraw(sel)
  local event, _, _, code = computer.pullSignal()
  if event == "key_down" then
    if code == 200 then -- Up
      if sel > 1 then
        sel = sel - 1
      end
    elseif code == 208 then -- Down
      if sel < #bootable then
        sel = sel + 1
      end
    elseif code == 28 then -- Enter
      local data = bootable[sel]
      baddr = data.address
      boot(data.address, data.path)
    end
  end
end
