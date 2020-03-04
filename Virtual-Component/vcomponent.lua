-- Virtual-component API. --

local vcomponents = {}

local list, invoke, proxy, comtype = component.list, component.invoke, component.proxy, component.type

local ps = computer.pushSignal

function component.create(componentAPI)
  checkArg(1, componentAPI, "table")
  vcomponents[componentAPI.address] = componentAPI
  ps("component_added", componentAPI.address, componentAPI.type)
end

function component.remove(addr)
  if vcomponents[addr] then
    ps("component_removed", vcomponents[addr].address, vcomponents[addr].type)
    vcomponents[addr] = nil
    return true
  end
  return false
end

function component.list(ctype, match)
  local matches = {}
  for k,v in pairs(vcomponents) do
    if v.type == ctype or not ctype then
      matches[v.address] = v.type
    end
  end
  local o = list(ctype, match)
  local i = 1
  local a = {}
  for k,v in pairs(matches) do
    a[#a+1] = k
  end
  for k,v in pairs(o) do
    a[#a+1] = k
  end
  local function c()
    if a[i] then
      i = i + 1
      return a[i - 1], (matches[a[i - 1]] or o[a[i - 1]])
    else
      return nil
    end
  end
  return setmetatable(matches, {__call = c})
end

function component.invoke(addr, operation, ...)
  checkArg(1, addr, "string")
  checkArg(2, operation, "string")
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

function component.type(addr)
  checkArg(1, addr, "string")
  if vcomponents[addr] then
    return vcomponents[addr].type
  else
    return comtype(addr)
  end
end
