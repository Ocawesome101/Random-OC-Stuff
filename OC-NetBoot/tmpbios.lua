-- Download an operating system to a computer's tmpfs --

local i,l,p,t=component.invoke,component.list,component.proxy,""
for a,_ in l("filesystem")do
  if i(a,"getLabel")=="tmpfs"then
    t=p(a)
    break
  end
end
local e=p(l("eeprom")())
local g=e.getData()
if not g or g==""then
  g="{repo='ocawesome101/open-kernel-2',branch='master'}"
end
local o,e=load("return "..g,"=repodata","t",_G)
if not o then error(e)end
g=o()
local raw,flist=g.rawURL or"https://raw.githubusercontent.com",g.customFileList or false
local I=p(l("internet")())
local G=l("gpu")()
local S=l("screen")()
if G and S then
  G=p(G)
  G.bind(S)
end
local flisturl = (flist and raw.."/"..g.repo.."/"..g.branch.."/files.json") or "https://api.github.com/repos/"..g.repo.."/git/trees/"..g.branch.."?recursive=1"
local rd=I.request(flisturl)
local jh=I.request("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")
rd.finishConnect()
jh.finishConnect()
if G then G.set(1,1,"Downloading JSON parser")end
local j=""
repeat
  local d=jh.read(math.huge)
  j=j..(d or"")
until not d
jh.close()
j=load(j,"=json.lua","t",_G)()
if G then G.set(1,2,"Getting repo data")end
local r=""
repeat
  local d=rd.read(math.huge)
  r=r..(d or"")
until not d
rd.close()
local d=j.decode(r)
if d.message and d.message=="Not Found"then error("Invalid repo")end
if G then G.set(1,3,"Making directories")end
for k,v in pairs(d.tree)do
  if v.type=="tree"then
    t.makeDirectory(v.path)
  end
end
local function dl(U,D)
  local R=I.request(U)
  R.finishConnect()
  local F=""
  repeat
    local Fd=R.read(math.huge)
    F=F..(Fd or"")
  until not Fd
  R.close()
  local h=t.open(D,"w")
  t.write(h,F)
  t.close(h)
end
if G then G.set(1,3,"Downloading files ")end
for k,v in pairs(d.tree)do
  if v.type=="blob"then
    local u=raw.."/"..g.repo.."/"..g.branch.."/"..v.path
    if G then local w,h = G.getResolution();G.set(1,4,(" "):rep(w));G.set(1,4,u);computer.pullSignal(0)end
    dl(u,v.path)
  end
end
-- Standard BIOS stuff --
function computer.getBootAddress()
  return t.address
end
function computer.setBootAddress()
  return true
end
local h,e=t.open("/init.lua","r")
if not h then error("OS is not bootable: "..e)end
local b=""
repeat
  local d=t.read(h,math.huge)
  b=b..(d or"")
until not d
t.close(h)
local o,e=load(b,"=/init.lua","t",_G)
if not o then error(e)end
o()
