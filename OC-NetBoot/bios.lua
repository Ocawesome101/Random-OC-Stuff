-- Booting from the interwebs --

local eeprom = component.proxy(component.list("eeprom")())
local internet = component.proxy(component.list("internet")())
local pullSignal = computer.pullSignal -- Just in case

function computer.setBootURL(url)
  checkArg(1, url, "string")
  eeprom.setData(url)
end

function computer.getBootURL()
  return eeprom.getData()
end

local url = computer.getBootURL()
if not url or url:sub(1, 8) ~= "https://" then
  computer.setBootURL("https://raw.githubusercontent.com/Ocawesome101/Random-OC-Stuff/master/OC-NetBoot/")
end
local handle, err = internet.request(url .. "/boot.lua")
if not handle then
  error(err)
end

local s, e = handle.finishConnect()
if not s then error(e) end

local d = ""
repeat
  local r = handle.read(math.huge)
  d = d .. (r or "")
until not r

handle.close()

local ok, err = load(d, "=netboot", "t", _G)
if not ok then
  error(err)
end

local status, ret = pcall(ok)
if not status then
  error(ret)
end

error("Halted")
while true do
  pullSignal()
end
