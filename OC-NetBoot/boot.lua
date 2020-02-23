-- Sample file for internet-booting an OpenComputers computer using the BIOS also in this folder. --

local gpu = component.list("gpu")()
local screen = component.list("screen")()

component.invoke(gpu, "bind", screen)

gpu = component.proxy(gpu)
gpu.setResolution(gpu.maxResolution())

local w,h = gpu.getResolution()

gpu.fill(1, 1, w, h, " ")
gpu.set(1, 1, "Successfully booted from " .. computer.getBootURL())

while true do
  computer.pullSignal()
end
