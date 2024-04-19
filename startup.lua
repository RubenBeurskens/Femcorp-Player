require("lib/common").bootstrap()

term.clear()
term.setCursorPos(1,1)
if _G.debugMode then
  term.write("Starting in debug mode, please wait...")
  term.setCursorPos(1,2)
else
  term.write("Starting, please wait...")
  term.setCursorPos(1,2)
end


local sha256 = require("lib/sha256").digest

local function hashString(x)
  local hexTable = sha256(x)
  return hexTable:toHex()
end

print(shell.getRunningProgram())
if shell.getRunningProgram() == "disk/startup.lua" then
  -- running as updater
  local list = fs.list("/")
  for i,o in pairs(list) do
    if not o == "disk" then
      fs.delete(shell.resolve(o))
    end
  end

  shell.run("copy disk/* /")
  local disk = peripheral.find("drive")
  disk.eject()
  reboot()
end
term.setCursorPos(1,2)
term.clearLine()
sleep(0.5)

if not settings.get("debug",false) then
  shell.run("player")
else
  local timeBegin = os.epoch("utc")
  io.write("\n")

  local width,_ = term.getSize()
  local _,lineToWrite = term.getCursorPos()

  local emptyLine = string.rep(" ", width)

  while true do
    local time = os.epoch("utc")-timeBegin
    term.setCursorPos(1,lineToWrite)
    io.write(emptyLine)
    term.setCursorPos(1,lineToWrite)
    io.write("Press any key to enter debug shell ("..math.max(0,2-math.ceil(time/1000))..")...")

    local ev
    parallel.waitForAny(function()
      ev = os.pullEvent("key")
    end,sleep)

    if time > 2000 then
      shell.run("player")
      break
    end

    if ev then
      term.setCursorPos(1,1)
      term.clear()
      print("Entering shell...")
      sleep(0.25)
      term.setCursorPos(1,1)
      term.clear()
      break
    end
  end
end
