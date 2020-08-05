local a={}local b=component;local c=computer;c.setArchitecture("Lua 5.3")local d=b.proxy(b.list("eeprom",true)())local e,f,g,h=1,2,3,4;local string=string;local function i()local j=d.getData()if#j==0 then a[e]=false;a[g]=true end;while#j>0 do local k,l=string.unpack("<I1I1",j)j=j:sub(3)a[k]=assert(load("return "..string.unpack("<c"..l,j:sub(1,l)),"=(config)"))()j=j:sub(l+1)end end;local function m()local j=""for k,n in pairs(a)do if type(n)=="string"then n=string.format("'%s'",n)end;n=tostring(n)local o=string.pack("<I1I1c"..#n,k,#n,n)j=j..o end;if#j>256 then error("configuration over 256 bytes!")end;d.setData(j)end;local p={}local q=b.proxy(b.list("gpu",true)())q.bind(b.list("screen",true)())local r=q.setForeground;local s=q.setBackground;local t=q.set;do local u,v=1,1;local function w()local x,y=q.getResolution()if u>x then u,v=1,v+1 end;if v>y then q.copy(1,1,x,y,0,-1)q.fill(1,y,x,1," ")v=y end;if u<1 then u=x;v=v-1 end;if v<1 then v=1 end end;local function z(A)local x,y=q.getResolution()while#A>0 do w()local B=A:sub(1,x-u+1)A=A:sub(#B+1)t(u,v,B)u=u+#B end end;function p.read(C,D)local E=""local F,G=C or u,D or v;local function H()u,v=F,G;z(E.."_ ")end;while true do H()local I,J,K,L=c.pullSignal()if I=="key_down"then if K>31 and K<127 then E=E..string.char(K)elseif K==8 then E=E:sub(1,-2)elseif K==13 then u,v=F,G;z(E.." ")return E end end end end end;i()m()if a[e]=="true"then _G.term=p end;local M=a[h]or 5;local N=a[g]local O=0xDC0000;r(O)local x,y=q.getResolution()q.fill(1,1,x,y," ")if N then t(1,1,"┏━━━━┓")t(1,2,"┃ ╭╮ ┃")t(1,3,"┃ ╰╯ ┃")t(1,4,"┗━━━━┛")r(0xFFFFFF)t(8,2,"OC-BIOS version 0.1.0")t(8,3,"Copyright (c) 2020 Ocawesome101, GNU GPLv3.")local P,Q=c.totalMemory(),c.freeMemory()t(1,5,string.format("\n%dK total, %dK free\n\n",P//1024,Q//1024))end;local function R(A,x)A=A:sub(1,x)A=A..string.rep(" ",x-unicode.len(A))return A end;local function S(T,U)U=U or"Please choose one:"q.fill(1,1,x,y," ")r(O)t(1,1,U)local V=1;local W={[200]=function()if V>1 then V=V-1 else V=#T end end,[208]=function()if V<#T then V=V+1 else V=1 end end}while true do for X=1,#T,1 do local Y="  "if V==X then Y="⇝ "r(0x000000)s(O)else s(0x000000)r(O)end;t(2,X+2,Y..R(T[X],x-8))end;local I,J,J,L=c.pullSignal()if I=="key_down"then if W[L]then W[L]()elseif L==28 then break end end end;q.fill(1,1,x,y," ")return T[V]end;local function Z(_)local a0=b.proxy(_)if not a0.exists("init.lua")then return nil,"init.lua not present"end;local a1,j,a2,a3=a0.open("init.lua"),""repeat local a4=a0.read(a1,math.huge)j=j..(a4 or"")until not a4;a0.close(a1)local a2,a3=load(j,"=(init)")if not a2 then return nil,a3 end;return pcall(a2)end;local function a5(_)local a0=b.proxy(_)local a6=a0.readSector(1):gsub("\0","")local a2,a3=load(a6,"=(bootsector)")if not a2 then return nil,a3 end;return pcall(a2)end;t(1,y,"Press F6 for Config")t(x,y,""..M)local function a7()s(O)r(0x000000)q.fill(1,y//2-1,x,3," ")r(O)s(0x000000)q.fill(1,y//2,x,1," ")return p.read(1,y//2)end;local function a8()local T={"Set menu timeout","Toggle logo on boot","Clear boot address","Exit"}while true do local X=S(T,"OC-BIOS Settings")if X==T[1]then a[h]=tonumber(a7())or M elseif X==T[2]then a[_ID_BOOT_LOGO]=not a[_ID_BOOT_LOGO]elseif X==T[3]then a[f]=nil elseif X==T[4]then m()c.shutdown(true)end end end;local a9=c.uptime()+M;repeat local I,J,J,L=c.pullSignal(math.min(1,c.uptime()-a9))if I=="key_down"and L==64 then a8()end;t(x,y,""..a9-c.uptime()//1)until c.uptime()>=a9;t(1,7,"Detecting drives...")local aa=b.list("filesystem",true)local ab=b.list("drive",true)aa[c.tmpAddress()]=nil;local ac={}for _ in aa do ac[#ac+1]=_ end;for _ in ab do ac[#ac+1]=_ end;t(20,7,"done.")if not a[f]or not component.type(a[f])then local ad=S(ac,"Please select a boot device:")a[f]=ad;m()end;function c.getBootAddress()return a[f]end;function c.setBootAddress(C)a[f]=C;m()end;local _=a[f]while true do local a2,a3;if component.type(_)=="drive"then a2,a3=a5(_)else a2,a3=Z(_)end;if not a2 and a3 then t(1,10,"Boot failed: "..a3)end;repeat local I=c.pullSignal()until I=="key_down"end