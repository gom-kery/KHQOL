local _, KHQOL = ...
local FC = KHQOL.modules.clock
local L = FC.L

function FC:CreateCalendar()
  self.calendar = { pending = nil, reminders = {} }
  local eventFrame = CreateFrame("Frame")
  self.calendar.eventFrame = eventFrame
  for _, event in ipairs({ "CALENDAR_UPDATE_PENDING_INVITES", "CALENDAR_UPDATE_INVITE_LIST", "CALENDAR_UPDATE_EVENT_LIST" }) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
  end
  eventFrame:SetScript("OnEvent", function(_, event, ...) FC:OnCalendarEvent(event, ...) end)
  self:CheckCalendarInvites(true)
  if C_Timer and C_Timer.NewTicker then self.calendar.reminderTicker = C_Timer.NewTicker(60, function() FC:CheckCalendarReminders() end) end
  self:CheckCalendarReminders()
end

function FC:GetPendingInviteCount()
  if C_Calendar and type(C_Calendar.GetNumPendingInvites) == "function" then return self:SafeCall(C_Calendar.GetNumPendingInvites) end
  if type(CalendarGetNumPendingInvites) == "function" then return self:SafeCall(CalendarGetNumPendingInvites) end
  return nil
end

function FC:CheckCalendarInvites(silent)
  local count = self:GetPendingInviteCount()
  if count == nil then return end
  local old = self.calendar.pending
  self.calendar.pending = count
  self:SetInviteGlow(count > 0)
  if not silent and old ~= nil and count > old then
    self:Print(L.CALENDAR_INVITE .. (count > 1 and " (" .. count .. ")" or ""))
  end
end

function FC:OnCalendarEvent()
  if C_Timer and C_Timer.After then C_Timer.After(0.2, function() FC:CheckCalendarInvites(false); FC:CheckCalendarReminders() end) else FC:CheckCalendarInvites(false); FC:CheckCalendarReminders() end
end

function FC:CheckCalendarReminders()
  -- Calendar event enumeration differs between clients, so this feature is optional.
  if not (C_Calendar and type(C_Calendar.GetNumDayEvents) == "function" and type(C_Calendar.GetDayEvent) == "function") then return end
  local now = time()
  for dayOffset = 0, 1 do
    local dayInfo = date("*t", now + dayOffset * 86400)
    local count = self:SafeCall(C_Calendar.GetNumDayEvents, 0, dayInfo.day) or 0
    for index = 1, count do
      local event = self:SafeCall(C_Calendar.GetDayEvent, 0, dayInfo.day, index)
      local start = event and event.startTime
      if start and start.year and start.month and start.monthDay and start.hour and start.minute and event.inviteStatus then
        local startsAt = time({ year = start.year, month = start.month, day = start.monthDay, hour = start.hour, min = start.minute, sec = 0 })
        local remaining = startsAt - now
        for _, minutes in ipairs({ 15, 10, 5 }) do
          local key = (event.eventID or (event.title or "event") .. startsAt) .. ":" .. minutes
          if remaining <= minutes * 60 and remaining > minutes * 60 - 75 and not self.calendar.reminders[key] then
            self.calendar.reminders[key] = true
            self:Print(string.format(L.CALENDAR_REMINDER, event.title or L.TODO, minutes))
          end
        end
      end
    end
  end
end

function FC:OpenCalendar()
  local opened = false
  if type(ToggleCalendar) == "function" then self:SafeCall(ToggleCalendar); opened = true
  elseif type(CalendarFrame_Show) == "function" then self:SafeCall(CalendarFrame_Show); opened = true
  elseif CalendarFrame and type(CalendarFrame.Show) == "function" then self:SafeCall(CalendarFrame.Show, CalendarFrame); opened = true end
  if not opened then self:Print(L.CALENDAR_UNAVAILABLE) end
end
