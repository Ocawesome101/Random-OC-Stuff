-- A boot file for the OC Amazon/Sahara clone I'm working on. --

local gpu = component.list("gpu")()
local screen = component.list("screen")()

if gpu and screen then
  component.invoke(gpu, "bind", screen)
  gpu = component.proxy(gpu)
  gpu.setResolution(gpu.maxResolution())
  gpu.set(1, 1, "Booted in " .. tostring(computer.uptime()) .. "s")
  gpu.set(1, 2, "System memory: " .. tostring(math.floor(computer.totalMemory()/1024)) .. "k")
  gpu.set(1, 3, "OC-WebStore cannot yet be run on a standard computer.")
  while true do
    computerm.pullSignal()
  end
end
