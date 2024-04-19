local common = require("lib/common")
local MDFPWM = require("lib/libMDFPWM")
local dfpwm = require("lib/dfpwm")

common.setPalette(settings.get("player.theme"))
common.bootstrap()

local bufferLeft
local bufferRight

-- peripherals
local leftSpeakersTable = settings.get("player.left") or shell.run("setup")
local rightSpeakersTable = settings.get("player.right") or shell.run("setup")


local leftSpeakers = {}
local rightSpeakers = {}
local speakers = {}
for _,speaker in pairs(leftSpeakersTable) do
  local function play()
    while not peripheral.call(speaker, "playAudio", bufferLeft) do
      os.pullEvent("speaker_audio_empty")
    end
  end
  local function stop()
    return peripheral.call(speaker, "stop")
  end
  table.insert(leftSpeakers, stop)
  table.insert(speakers, play)
end
for _,speaker in pairs(rightSpeakersTable) do
  local function play()
    while not peripheral.call(speaker, "playAudio", bufferRight) do
      os.pullEvent("speaker_audio_empty")
    end
  end
  local function stop()
    return peripheral.call(speaker, "stop")
  end
  table.insert(rightSpeakers, stop)
  table.insert(speakers, play)
end

--do
--local modems = { peripheral.find("modem", function(name, modem) return modem.isWireless() end) }
--modem=modems[1]
--end
for i,o in pairs({peripheral.find("modem")}) do
  if o.isWireless() then
    modem = o
    --error("found modem")
  end
end
local disk = peripheral.find("drive") or error("Please place the disk drive on top of the computer")
local xSize, ySize = term.getSize()

local runtime = 0
local seconds = 0
local title = "No Title"
local artist = "No Artist"
local album = "No Album"
local media = "disk"
local playing = true
local exited = false
local volume = 1
local volumeIncrement = 0.05
local exitRun = "setup"
local bitExact = settings.get("player.bitExact",false)

local scaledButtonY = math.floor(ySize*0.8)
local buttonWidth = 4
local rewindPos = 0
local pausePos = 0
local playPos = 0
local stopPos = 0
local forwardPos = 0

-- time bar settings
local totalLength = 30
local playedLength = 30 * (seconds / runtime)

local decoderLeft
local decoderRight
local function newDecoder()
  if bitExact then
    decoderLeft = dfpwm.make_intdecoder()
    decoderRight = dfpwm.make_intdecoder()
  else
    decoderLeft = dfpwm.make_decoder()
    decoderRight = dfpwm.make_decoder()
  end
end
local function parseDfpwm(song)
  local dat = {}
  local file = fs.open(song, "rb")
  local raw = file.readAll()
  file.close()
  dat.getSamples = function(sec)
    return string.sub(raw,(sec-1)*6000,sec*6000)
  end
  return dat
end
local function stopPlayback()
  parallel.waitForAny(table.unpack(leftSpeakers))
  parallel.waitForAny(table.unpack(rightSpeakers))
end

local function play()
  while true do
    sleep(1)
    seconds = 1
    if disk.isDiskPresent() then
      if disk.getAudioTitle() and playing then
        media = "disk"
        -- Ingame Music Disk
        local fields = common.split(disk.getAudioTitle(),"-")

        title = fields[2]
        artist = fields[1]
        album = "Minecraft Music Discs"
        runtime = 0
        seconds = 0
        playing = true
        disk.playAudio()
        while disk.getAudioTitle() do
          if not playing then
            disk.stopAudio()
          end
          sleep(2)
        end
      elseif fs.isDir("disk/") and playing then
        local dir = fs.list("disk/")
        local file
        local type
        for i,o in pairs(dir) do
          local parts = common.split(o,".")
          --error(textutils.serialise(parts))
          if parts[#parts] == "mdfpwm" then
            file = "/disk/" .. o
            type = "mdfpwm"
          elseif parts[#parts] == "dfpwm" then
            file = "/disk/" .. o
            type = "dfpwm"
          end
        end

        if type == "mdfpwm" then
          local h = fs.open(file,"rb")
          local metadata = MDFPWM.meta(h)
          local song = MDFPWM.parse(h)
          h.close()
          media = "floppy"
          title = metadata.title
          artist = metadata.artist
          album = metadata.album
          runtime = metadata.len
          playing = true
          newDecoder()
          while true do
            while playing do
              bufferLeft = decoderLeft(song.getSample(seconds).left)
              bufferRight = decoderRight(song.getSample(seconds).right)
              if not bitExact then
                for i,o in pairs(bufferLeft) do
                 bufferLeft[i] = o * volume
                end
                for i,o in pairs(bufferRight) do
                  bufferRight[i] = o * volume
                end
              end

              parallel.waitForAll(table.unpack(speakers))

              seconds = seconds + 1
              if seconds <= 1 then
                sleep(2)
                stopPlayback()
                newDecoder()
                local h
                local metadata
                local song
              end
            end
          sleep(0.2)
        end
        elseif type == "dfpwm" then
          media = "dfpwm"
          newDecoder()
          title = file
          artist = ""
          album = ""
          runtime = math.ceil(fs.getSize(file)/6000)
          local song = parseDfpwm(file)
          while true do
            while playing do
              buffer = decoderLeft(song.getSamples(seconds))

              -- volume
              if not bitExact then
                for i,o in pairs(buffer) do
                 buffer[i] = o * volume
                end
              end
              bufferLeft = buffer
              bufferRight = buffer
              parallel.waitForAll(table.unpack(speakers))

              seconds = seconds + 1
              if seconds <= 1 then
                -- end of song
                sleep(2)
                parallel.waitForAny(table.unpack(leftSpeakers))
                parallel.waitForAny(table.unpack(rightSpeakers))
                newDecoder()
                local h
                local metadata
                local song
              end
            end
          sleep(0.2)
          end
        end
      end
    else
      runtime = 1
      seconds = 0
      playing = false
    end
    sleep(1)
  end
end
local function drawDisplay()
  while true do
    if exited then
      return
    end

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    common.printCentered(album,-4)
    common.printCentered(title,-1,2)
    term.setTextColor(colors.lightGray)
    common.printCentered(artist)
    common.drawSideBar("left")
    common.drawSideBar("right")
    -- time bar
    local totalLength = 30
    local playedLength = 30 * (seconds / runtime)
    -- time bar
    for i=1,totalLength do
      noSpace = false
      term.setTextColor(colors.black)
      term.setCursorPos(xSize / 2 - totalLength / 2 + i, 12)
      if i > playedLength then
        term.setBackgroundColor(colors.gray)
      elseif (i - 1) < playedLength and (i + 1) > playedLength then
        term.setBackgroundColor(colors.blue)
        term.setTextColor(colors.gray)
        noSpace = true
        term.write("\127")
      else
        term.setBackgroundColor(colors.blue)
      end

      if not noSpace then
        term.write(" ")
      end
      term.setTextColor(colors.white)
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)

    -- time display
    local runtimeMinutes = math.floor(runtime / 60)
    local playedMinutes = math.floor(seconds / 60)
    term.setCursorPos(xSize / 2 - totalLength / 2 + 2,13)
    term.write(playedMinutes .. ":" .. string.format("%02d",seconds - playedMinutes * 60))
    term.setCursorPos(xSize / 2 - totalLength / 2 + totalLength - 4,13)
    term.write(runtimeMinutes .. ":" .. string.format("%02d",runtime - runtimeMinutes * 60))

    -- Control Buttons

    local xOffset = -1

    -- rewind
    rewindPos = xSize / 2 - 5 * 2 + xOffset
    term.setCursorPos(rewindPos,15)
    term.setBackgroundColor(colors.blue)
    term.write("    ")
    term.setCursorPos(rewindPos,16)
    term.write(" \17\17 ")
    term.setCursorPos(rewindPos,17)
    term.write("    ")

    -- pause
    pausePos = xSize / 2 - 5 * 1 + xOffset
    term.setCursorPos(pausePos,15)
    term.setBackgroundColor(colors.blue)
    term.write("    ")
    term.setCursorPos(pausePos,16)
    term.write(" || ")
    term.setCursorPos(pausePos,17)
    term.write("    ")

    -- play
    playPos = xSize / 2 - 5 * 0 + xOffset
    term.setCursorPos(playPos,15)
    term.setBackgroundColor(colors.blue)
    term.write("    ")
    term.setCursorPos(playPos,16)
    term.write(" \138\16 ")
    term.setCursorPos(playPos,17)
    term.write("    ")

    -- stop
    stopPos = xSize / 2 - 5 * -1 + xOffset
    term.setCursorPos(stopPos,15)
    term.setBackgroundColor(colors.blue)
    term.write("    ")
    term.setCursorPos(stopPos,16)
    term.write(" \138\133 ")
    term.setCursorPos(stopPos,17)
    term.write("    ")

    -- fast forward
    forwardPos = xSize / 2 - 5 * -2 + xOffset
    term.setCursorPos(forwardPos,15)
    term.setBackgroundColor(colors.blue)
    term.write("    ")
    term.setCursorPos(forwardPos,16)
    term.write(" \16\16 ")
    term.setCursorPos(forwardPos,17)
    term.write("    ")

    -- setup button
    term.setCursorPos(xSize,1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.write("\21")

    -- eject button
    term.setCursorPos(1,ySize)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.write("\30")

     -- volume controls
    if not bitExact then
      term.setCursorPos(1,1)
      term.setTextColor(colors.white)
      term.write("-  +")

      term.write("  " .. volume * 100 .. "%")
    end
    -- bitexact button
    term.setCursorPos(xSize,ySize)
    if bitExact == true then
      term.setTextColor(colors.red)
    elseif bitExact == false then
      term.setTextColor(colors.gray)
    end
    term.write("\20")
    sleep(0.05)
  end
end

local function buttonHandler()
  while true do
    if exited then
      return
    end
    local event, button, x, y = os.pullEvent("mouse_click")
    local timeBarBegin = (xSize / 2 - totalLength / 2)
    local timeBarEnd = (xSize / 2 - totalLength / 2 + totalLength)
    if y == 12 and x > timeBarBegin and x < timeBarEnd then
      local position = math.ceil(x - timeBarBegin) + 1
      local percentage = position / totalLength
    end

    if y == 1 and x == xSize then
      -- setup button
      exited = true
    end
    if not bitExact then
      if y == 1 and x == 1 then
        -- volume down
        if volume - volumeIncrement > 0 then
          volume = volume - volumeIncrement
        elseif volume - volumeIncrement < 0 then
          volume = 0
        end
      end

      if y == 1 and x == 4 then
        -- volume up
        if volume + volumeIncrement <= 1 then
          volume = volume + volumeIncrement
        elseif volume + volumeIncrement > 3 then
          volume = 3
        end
      end
    end
    if y == 15 or y == 16 or y == 17 then
      -- media buttons row
      if x > rewindPos and x < (rewindPos + buttonWidth) then
        if seconds - 3 > 0 then
          seconds = seconds - 3 -- skip back
        end
      elseif x > pausePos and x < (pausePos + buttonWidth) then
        parallel.waitForAny(table.unpack(leftSpeakers))
        parallel.waitForAny(table.unpack(rightSpeakers))
        playing = false
      elseif x > playPos and x < (playPos + buttonWidth) then
        playing = true
        newDecoder()
        --sleep(2)
      elseif x > stopPos and x < (stopPos + buttonWidth) then
        playing = false
        seconds = 0
        parallel.waitForAny(table.unpack(leftSpeakers))
        parallel.waitForAny(table.unpack(rightSpeakers))
        newDecoder()
      elseif x > forwardPos and x < (forwardPos + buttonWidth) then
        if seconds + 2 < runtime then
          seconds = seconds + 2 -- skip forward
        end
      end
    end

    -- bit exact button
    if x == xSize and y == ySize then
      --Use not instead of if
      --TODO
      bitExact = not bitExact
      newDecoder()
      settings.set("player.not bitExact",not bitExact)
      settings.set("player.bitExact",bitExact)
      settings.save()
    end

    -- eject button
    if x == 1 and y == ySize then
      disk.ejectDisk()
      os.queueEvent("disk_eject")
    end
  end
end

local function secondTicker()
  -- temporary??
  while true do
    if exited then
      return
    end
    sleep(1)
    if playing and media == "disc" then
      seconds = seconds + 1
    end
    if seconds > runtime - 2 then
      --sleep(2)
      seconds = 0
      if media == "mdfpwm" then
        newDecoder()
      end
    end
  end
end

local function diskEjectListener()
  while true do
    os.pullEvent("disk_eject")
    playing = false
    seconds = 0
    parallel.waitForAny(table.unpack(leftSpeakers))
    parallel.waitForAny(table.unpack(rightSpeakers))
    title = "No Title"
    artist = "No Artist"
    album = "No Album"
    runtime = 0
    newDecoder()
  end
end

local function diskListener()
  while true do
    os.pullEvent("disk")
    exited = true
    exitRun = "player" -- yes, it *is* restarting the program on a new disk
  end
end

local function statusSender()
  while true do
    if modem then
      modem.transmit(50000,50000,{title = title, artist = artist, album = album, seconds = seconds,runtime = runtime, volume = volume, playing = playing, id = os.getComputerID(), computationalVolume = not bitExact})
    end
    sleep(0.5)
  end
end

local function inputsReceiver()
  while true do
    if modem then
      modem.open(os.getComputerID())
      local event, side, ch, rch, msg, dist = os.pullEvent("modem_message")
      if msg == "pause" then
        parallel.waitForAny(table.unpack(leftSpeakers))
        parallel.waitForAny(table.unpack(rightSpeakers))
        playing = false
      elseif msg == "play" then
        playing = true
        newDecoder()
      elseif msg == "stop" then
        playing = false
        seconds = 0
        parallel.waitForAny(table.unpack(leftSpeakers))
        parallel.waitForAny(table.unpack(rightSpeakers))
        newDecoder()
      elseif msg == "volup" then
        if not bitExact then
          -- volume up
          if volume + volumeIncrement <= 1 then
            volume = volume + volumeIncrement
          elseif volume + volumeIncrement > 3 then
            volume = 3
          end
        end
      elseif msg == "voldown" then
        if not bitExact then
          if volume - volumeIncrement > 0 then
            volume = volume - volumeIncrement
          elseif volume - volumeIncrement < 0 then
            volume = 0
          end
        end
      elseif msg == "skipforward" then
        if seconds + 2 < runtime then
          seconds = seconds + 2 -- skip forward
        end
      elseif msg == "skipback" then
        if seconds - 3 > 0 then
          seconds = seconds - 3 -- skip back
        end
      end
    else -- No modem found
      while true do
        sleep(1) -- Avoid sleeping for too long as this may error.
      end
    end
  end
end

while true do
  parallel.waitForAny(drawDisplay,buttonHandler,secondTicker,play,diskListener,diskEjectListener,statusSender,inputsReceiver)
  if exited then
      shell.run(exitRun)
      return
    end
    sleep()
end