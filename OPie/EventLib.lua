-- EventLib.lua: Handles event/timer management.
local ECi_Version = 1.13;
local ECi_Enabled, EC_Core, Events, ErrorCache, ErrorTraceCache, Timers, TimerCount, TimerNext;
local errorMessage = "[%s] Encountered |cffff8000|Hectrace:%d|h[Error in %s]|h|r."

local function ECi_Panic(aspect, text, st, source)
 local key = aspect .. "." .. text;
 if not ErrorCache[key] or ErrorCache[key] < 5 then
  tinsert(ErrorTraceCache, {aspect, text, string.gsub(text .. "\n" .. debugstack(st or 2),"Interface\\AddOns\\","")});
  DEFAULT_CHAT_FRAME:AddMessage(errorMessage:format(source or "EventLib", #ErrorTraceCache, aspect),0.8,0.3,0);
 end
 ErrorCache[key] = (ErrorCache[key] or 0) + 1;
end

local function ECi_Register(event, handle, handler)
 if not Events[event] then
  EC_Core:RegisterEvent(event);
  Events[event] = {};
 elseif Events[event][handle] then
  return ECi_Panic("ERegister:" .. handle,"Duplicate blocked.");
 end
 Events[event][handle] = handler;
end
local function ECi_Raise(event, ...)
 if Events[event] then
  for k,v in pairs(Events[event]) do
	 local ok, r = EC_pcall(nil, "OnEvent:" .. event .. ": " .. k, v, event, ...);
   if ok and r == "remove" then
    EC_Unregister(event, k);
   end
  end
 end
end
local function ECi_Unregister(event, handle)
 if Events[event] and Events[event][handle] then
  Events[event][handle] = nil;
  if not next(Events[event]) then
   Events[event] = nil; EC_Core:UnregisterEvent(event);
  end
 end
end

local function ECi_HandleTimer()
 local time = GetTime();
 if time > TimerNext then
  TimerNext = time+60;
  for h, v in pairs(Timers) do
   local f,i,p = unpack(v);
   if p < time then
    local ok, r = EC_pcall(nil, "Timer:" .. h, f);
    if ok and r == "remove" then
     EC_DelTimer(h);
    else
     Timers[h][3] = time+Timers[h][2];
     TimerNext = min(TimerNext,Timers[h][3]);
    end
   else
    TimerNext = min(TimerNext,Timers[h][3]);
   end
  end
 end
end
local function ECi_Timer(handle, func, interval)
 if Timers[handle] then
  return ECi_Panic("TRegister:" .. handle,"Duplicate blocked.");
 end
 Timers[handle], TimerCount, TimerNext = {func, interval, GetTime()+interval}, TimerCount + 1, min(TimerNext, GetTime()+interval);
 if TimerCount == 1 then
  EC_Core:SetScript("OnUpdate",ECi_HandleTimer);
 end
end
local function ECi_DelTimer(handle)
 if Timers[handle] then
  Timers[handle], TimerCount = nil, TimerCount - 1;
  if TimerCount == 0 then EC_Core:SetScript("OnUpdate",nil); end
 end
end
local function ECi_Error(source, aspect, desc, level)
	ECi_Panic(aspect, desc, (level or 0)+3, source);
end
local ECi_pcall; do
	local args, argc, pfunc, esource, easpect = {}, 0;
	local function call()	return pfunc(unpack(args, 1, argc)); end
	local function err(text) ECi_Panic(easpect, text, 3, esource); return text; end
	function ECi_pcall(source, aspect, func, ...)
		pfunc, argc, esource, easpect = func, select("#", ...), source, aspect;
		args[1], args[2], args[3], args[4], args[5] = ...;
		for i=6,argc,5 do
			args[i], args[i+1], args[i+2], args[i+3], args[i+4] = select(i, ...);
		end
		return xpcall(call, err);
	end
end
local function ECi_Migrate()
 ECi_Enabled = false;
 EC_Core:SetScript("OnEvent", nil);
 EC_Core:SetScript("OnUpdate", nil);
 return Events, Timers;
end

do
 local old = ChatFrame_OnHyperlinkShow;
 function ChatFrame_OnHyperlinkShow(...) -- self, link, text, button
  local _, link = ...;
  local ref = type(link) == "string" and tonumber(link:match("^ectrace:(%d+)$"));
  if ECi_Enabled and ref and ErrorTraceCache[ref] then
   ref = ErrorTraceCache[tonumber(ref)];
   ShowUIPanel(ItemRefTooltip);
   if not ItemRefTooltip:IsVisible() then
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
   end
   ItemRefTooltip:ClearLines();
   ItemRefTooltip:AddLine("|cffff8000Error Fragment|r");
   ItemRefTooltip:AddLine("In " .. ref[1] .. ": " .. ref[2]:gsub("\\", "\\ "), 1, 1, 1, true);
   ItemRefTooltip:AddLine(ref[3]:gsub("\\", " \\ "), 0.8, 0.8, 0.8, true);
   ItemRefTooltip:AddLine("May be turned in for reputation with addon authors.", 1, 0.82, 0);
   ItemRefTooltip:Show();
  else
   old(...);
  end
 end
end

-- This part controls which version of EventLib is global.
if not EC_Version or EC_Version < ECi_Version then
 ECi_Enabled, EC_Core = true, CreateFrame("FRAME",nil,WorldFrame)
 Events, ErrorCache, ErrorTraceCache, Timers, TimerCount, TimerNext = {}, {}, {}, {}, 0, 0;
 if EC_Migrate then
  Events, Timers = EC_Migrate();
  for k in pairs(Events) do
   EC_Core:RegisterEvent(k);
  end
  for k in pairs(Timers) do
   TimerCount = TimerCount + 1;
  end
  if TimerCount > 0 then
   EC_Core:SetScript("OnUpdate",ECi_HandleTimer);
  end
 end
 EC_Version, EC_Register, EC_Unregister, EC_Raise, EC_Timer, EC_DelTimer, EC_Migrate, EC_Error, EC_pcall = ECi_Version, ECi_Register, ECi_Unregister, ECi_Raise, ECi_Timer, ECi_DelTimer, ECi_Migrate, ECi_Error, ECi_pcall;
 EC_Core:SetScript("OnEvent",function (self, ...) EC_Raise(...); end);
end