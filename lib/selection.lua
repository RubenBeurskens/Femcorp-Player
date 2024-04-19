local expect = require("cc.expect")

return function()
  return {
    choices = {},
    default = nil,
    defaultFgColor = colors.white,
    defaultBgColor = colors.black,

    addChoice = function(self,id,name,fgColor,bgColor)
      expect(1, self, "table")
      expect(2, id, "string")
      expect(3, name, "string")
      expect(4, fgColor, "number", "nil")
      expect(5, bgColor, "number", "nil")

      if #self.choices > 19 then error("Cannot have more than 19 choices.") end

      table.insert(self.choices, {id=id,name=name,fgColor=fgColor,bgColor=bgColor})
    end,

    setDefaultTextColor = function(self,color)
      expect(1, self, "table")
      expect(2, color, "number")

      self.defaultFgColor = color
    end,

    setDefaultBackgroundColor = function(self,color)
      expect(1, self, "table")
      expect(2, color, "number")

      self.defaultBgColor = color
    end,

    setDefault = function(self,id)
      expect(1, self, "table")
      expect(2, id, "string")

      local found = false
      for k,v in ipairs(self.choices) do
        if v.id == id then
          found = true
          break
        end
      end

      if not found then
        error("selection: setDefault: could not find choice with id \""..id.."\"")
      end

      self.default = id
    end,

    setOrder = function(self, ids)
      expect(1, self, "table")
      expect(2, ids, "table")

      if #ids ~= #self.choices then
        error("selection: setOrder: choice length and sort table length has to be the same")
      end

      local newChoices = {}

      for i = 1, #ids do
        local found = false
        for j = 1, #self.choices do
          if self.choices[j].id == ids[i] then
            table.insert(newChoices, self.choices[j])
            found = true
            break
          end
        end
        if not found then
          error("id " .. ids[i] .. " not found in choices")
        end
      end

      self.choices = newChoices
    end,

    draw = function(self)
      expect(1, self, "table")

      local prevTextColor = term.getTextColor()
      local prevBGColor = term.getBackgroundColor()

      local scrollPos
      if self.default then
        for i,v in ipairs(self.choices) do
          if v.id == self.default then
            scrollPos = i
            break
          end
        end
      end
      scrollPos = scrollPos or 1

      local function redraw()
        term.clear()

        for i=1,#self.choices do
          local choice = self.choices[i]
          term.setCursorPos(1, i)

          if choice.id == self.choices[scrollPos].id then
            term.setTextColor(choice.fgColor or colors.white)
            term.setBackgroundColor(choice.bgColor or colors.blue)
          else
            term.setTextColor(self.defaultFgColor)
            term.setBackgroundColor(self.defaultBgColor)
          end
          term.write(" "..choice.name.." ")
        end

        term.setTextColor(prevTextColor)
        term.setBackgroundColor(prevBGColor)
      end

      redraw()

      while true do
        local event, key = os.pullEvent("key")

        if key == keys.up then
          if scrollPos > 1 then
            scrollPos = scrollPos - 1
            redraw()
          end
        elseif key == keys.down then
          if scrollPos < #self.choices then
            scrollPos = scrollPos + 1
            redraw()
          end
        elseif key == keys.enter then
          return self.choices[scrollPos].id
        end

        redraw()
      end
    end
  }
end
