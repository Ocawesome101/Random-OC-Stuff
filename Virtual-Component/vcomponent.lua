-- Virtual-component API --

local vcomponents = {}

local list, invoke, proxy = component.list, component.invoke, component.proxy

function component.create(componentAPI)
  checkArg(1, componentAPI, "table")
  vcomponents[componentAPI.address] = componentAPI
  computer.pushSignal("component_added", componentAPI.type, componentAPI.address)
end

function component.remove(addr)
  if vcomponents[addr] then
    computer.pushSignal("component_removed", vcomponents[addr].type, vcomponents[addr].address)
    vcomponents[addr] = nil
    return true
  end
  return false
end

function component.list(ctype, match)
  for k,v in pairs(vcomponents) do
    if v.type == ctype then
      return k
    end
  end
  return list(ctype, match)
end

function component.invoke(addr, operation, ...)
  checkArg(1, addr, "string")
  if vcomponents[addr] then
    if vcomponents[addr][operation] then
      return vcomponents[addr][operation](...)
    end
  end
  return invoke(addr, operation, ...)
end

function component.proxy(addr)
  checkArg(1, addr, "string")
  if vcomponents[addr] then
    return vcomponents[addr]
  else
    return proxy(addr)
  end
end
