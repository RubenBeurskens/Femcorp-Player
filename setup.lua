local speakers = {peripheral.find("speaker")}
local dfpwm = require("cc.audio.dfpwm")
local common = require("lib/common")
local selection = require("/lib/selection")

common.setPalette(settings.get("player.theme"))
common.bootstrap()

if not speakers[1] then
  error("Please place speakers connected to the computer")
end

local function playNote(speaker)
  local decoder = dfpwm.make_decoder()
  for chunk in io.lines("audio/pling.dfpwm", 16 * 1024) do
    local buffer = decoder(chunk)

    while not speaker.playAudio(buffer,3) do
        os.pullEvent("speaker_audio_empty")
    end
  end
end
local oldRed = term.getPaletteColor(colors.red)
local oldCyan = term.getPaletteColor(colors.cyan)
local oldBlue = term.getPaletteColor(colors.blue)



drawSideBar = common.drawSideBar
printCentered = common.printCentered

term.clear()
term.setCursorPos(3,1)
term.setTextColor(colors.white)
local leftSpeaker
local rightSpeaker
local xSize,ySize = term.getSize()

local function leftSpeakerSetup()
  drawSideBar("left")
  for i,o in pairs(speakers) do
    local function soundHandler()
      while true do
        playNote(o)
        sleep(2)
      end
    end
    local function keyHandler()
      local event, key, is_held = os.pullEvent("key")
      if key == keys.space then
        leftSpeaker = peripheral.getName(o)
      end
    end
    parallel.waitForAny(soundHandler,keyHandler)
    o.stop()
    if leftSpeaker then return end
  end
end

local function rightSpeakerSetup()
  drawSideBar("right")
  for i,o in pairs(speakers) do
    local function soundHandler()
      while true do
        playNote(o)
        sleep(2)
      end
    end
    local function keyHandler()
      local event, key, is_held = os.pullEvent("key")
      if key == keys.space then
        rightSpeaker = peripheral.getName(o)
      end
    end
    parallel.waitForAny(soundHandler,keyHandler)
    o.stop()
    if rightSpeaker then return end
  end
end

local function drawTooltip()
  printCentered("Please press space if the",-2)
  printCentered("indicated speaker is playing.",-1)
  printCentered("Press any other button to",-0)
  printCentered(" skip to the next speaker",1)
end

drawTooltip()

while not leftSpeaker do
  leftSpeakerSetup()
end
term.clear()
drawTooltip()
while not rightSpeaker do
  rightSpeakerSetup()
end

-- reset back to old colors
term.clear()
--term.setPaletteColor(colors.red,oldRed)
--term.setPaletteColor(colors.cyan,oldCyan)
--term.setPaletteColor(colors.blue,oldBlue)

term.setCursorPos(1,1)

--print("Configured the left speaker to " .. leftSpeaker )
--print("Configured the right speaker to " .. rightSpeaker )

settings.set("player.left",{leftSpeaker})
settings.set("player.right",{rightSpeaker})
settings.save()

common.resetPalette()

term.setCursorPos(1,1)
term.write("Please select your desired theme")
term.setCursorPos(1,3)

term.setPaletteColor(colors.blue, 0x0098eb)
term.setPaletteColor(colors.red, 0xff4242)
term.setPaletteColor(colors.pink, 0xf676ff)
term.setPaletteColor(colors.orange, 0xff993e)
term.setPaletteColor(colors.green, 0x2ff972)
term.setPaletteColor(colors.lightBlue, 0xF5A9B8)
term.setPaletteColor(colors.lightGray, 0x9B4F96)
term.setPaletteColor(colors.lime, 0xFFD800)

term.setPaletteColor(colors.black, 0x000000)
term.setPaletteColor(colors.white, 0xFFFFFF)

local choice = selection()
choice:addChoice("blue","Blue",colors.white,colors.blue)
choice:addChoice("red","Red",colors.white,colors.red)
choice:addChoice("pink","Pink",colors.white,colors.pink)
choice:addChoice("orange","Orange",colors.white,colors.orange)
choice:addChoice("green","Green",colors.white,colors.green)
choice:addChoice("flag_trans","Flag: trans",colors.white,colors.lightBlue)
choice:addChoice("flag_bi","Flag: bi",colors.white,colors.lightGray)
choice:addChoice("flag_pan","Flag: pan",colors.white,colors.lime)

term.setCursorPos(1,ySize)
term.write("Select the theme with your arrow keys")

local selected = choice:draw()

settings.set("player.theme",selected)

term.clear()
term.setCursorPos(1,1)
print("Please set up any remote modules with the ID " .. os.getComputerID() .. " and press any key to continue")
os.pullEvent("key")

settings.save()

common.resetPalette()

shell.run("player")
