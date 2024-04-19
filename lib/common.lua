    common = {}
local bigfont = require("lib/bigfont")

function common.split (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end

function common.drawSideBar(side)
  local xSize, ySize = term.getSize()
  
  if side == "left" then
    x = 1
  elseif side == "right" then
    x = xSize
  end
  for i=2,4 do
    term.setBackgroundColor(colors.red)
    term.setCursorPos(x,i)
    term.write(" ")
    term.setBackgroundColor(colors.black)
  end
  for i=4,6 do
    term.setBackgroundColor(colors.blue)
    term.setCursorPos(x,i)
    term.write(" ")
    term.setBackgroundColor(colors.black)
  end
  for i=7,ySize - 6 do
    term.setBackgroundColor(colors.cyan)
    term.setCursorPos(x,i)
    term.write(" ")
    term.setBackgroundColor(colors.black)
  end
  for i=ySize - 5,ySize - 3 do
    term.setBackgroundColor(colors.blue)
    term.setCursorPos(x,i)
    term.write(" ")
    term.setBackgroundColor(colors.black)
  end
  for i=ySize - 2,ySize - 1 do
    term.setBackgroundColor(colors.red)
    term.setCursorPos(x,i)
    term.write(" ")
    term.setBackgroundColor(colors.black)
  end
end

function common.resetPalette()
  for _,v in pairs(colors) do
    if type(v) == "number" then
      term.setPaletteColor(v, term.nativePaletteColor(v))
    end
  end
end

function common.setPalette(theme)
  if not theme or theme == "blue" then
    term.setPaletteColor(colors.red, 0x004163)
    term.setPaletteColor(colors.cyan, 0x0098eb)
    term.setPaletteColor(colors.blue, 0x0282c7)
  elseif theme == "red" then
    term.setPaletteColor(colors.red, 0x661a1a) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0xff4242) -- bright
    term.setPaletteColor(colors.blue, 0xb32e2e) -- darker (30%)
  elseif theme == "pink" then
    term.setPaletteColor(colors.red, 0x622f66) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0xf676ff) -- bright
    term.setPaletteColor(colors.blue, 0xac53b3) -- darker (30%)
  elseif theme == "flag_trans" then
    term.setPaletteColor(colors.red, 0x5BCEFA) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0xFFFFFF) -- bright
    term.setPaletteColor(colors.blue, 0xF5A9B8) -- darker (30%)
  elseif theme == "orange" then
    term.setPaletteColor(colors.red, 0x663d19) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0xff993e) -- bright
    term.setPaletteColor(colors.blue, 0xb36b2b) -- darker (30%)
  elseif theme == "green" then
    term.setPaletteColor(colors.red, 0x13642e) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0x2ff972) -- bright
    term.setPaletteColor(colors.blue, 0x21ae50) -- darker (30%)
  elseif theme == "flag_bi" then
    term.setPaletteColor(colors.red, 0x0038A8) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0x9B4F96) -- bright
    term.setPaletteColor(colors.blue, 0xD60270) -- darker (30%)
  elseif theme == "flag_pan" then
    term.setPaletteColor(colors.red, 0x21B1FF) -- most dark (60%)
    term.setPaletteColor(colors.cyan, 0xFFD800) -- bright
    term.setPaletteColor(colors.blue, 0xFF218C) -- darker (30%)
  end
end

function common.printCentered(str,yOffset,size)
  local xSize, ySize = term.getSize()
  size = size or 1
  yOffset = yOffset or 0
  if #str * 3 > xSize - 5 then
    size = 1
  end
  if size == 1 then
    term.setCursorPos(xSize / 2 - #str / 2 + 1, ySize / 2 + yOffset)
    term.write(str)
  elseif size == 2 then
    term.setCursorPos(xSize / 2 - #str * 3 / 2 + 1, ySize / 2 + yOffset * 3)
    bigfont.bigPrint(str)
  end
end

function common.bootstrap()
  local oldError = error
  _G.debugMode = settings.get("debug",false)

  -- overwrite error function to handle gracefully
  _G.error = function(o, level)
    if level == 3 then return end
    local xSize, ySize = term.getSize()
    term.setBackgroundColor(colors.magenta)
    term.setTextColor(colors.white)
    term.setCursorPos(4,4)
    term.clear()
    bigfont.bigPrint("Whoops!")
    term.setCursorPos(4,8)

    term.write("Something went wrong, here's some details:")
    term.setCursorPos(4,10)
    local w = window.create(term.native(),4,10,xSize - 8, xSize - 4 - 10)
    w.setBackgroundColor(colors.magenta)
    w.setTextColor(colors.white)
    w.clear()
    local oldTerm = term.native()
    term.redirect(w)
    print(o)
    term.redirect(oldTerm)
    term.setCursorPos(4,ySize - 2)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.magenta)
    term.write("Press any button to exit")
    os.pullEvent("key")
    if not debugMode then os.shutdown() else os.queueEvent("terminate") end
  end
  if debugMode then
    _G.error = oldError
  end
  -- make terminating impossible
  if not debugMode then os.pullEvent = os.pullEventRaw end
end

return common
