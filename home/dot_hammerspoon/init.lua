--
-- Ref: https://github.com/twpayne/dotfiles/blob/master/home/dot_hammerspoon/init.lua
--
hs.window.animationDuration = 0 -- disable animations
hs.grid.setGrid('12x12') -- allows us to place on quarters, thirds and halves

local grid = {
  rightTopHalf = '6,0 6x6',
  rightBottomHalf = '6,6 6x6',

  rightTopThird = '6,0 6x4',
  rightMiddleThird = '6,4 6x4',
  rightBottomThird = '6,8 6x4',

  rightFirstQuarter = '6,0 6x3',
  rightSecondQuarter = '6,3 6x3',
  rightThirdQuarter = '6,6 6x3',
  rightFourthQuarter = '6,9 6x3',

  leftThird = '0,0 4x12',
  leftTwoThirds = '0,0 8x12',
  middleThird = '4,0 4x12',
  rightThird = '8,0 4x12',
  rightTwoThirds = '4,0 8x12',

  leftThirdTopHalf = '0,0 4x6',
  leftTwoThirdsTopHalf = '0,0 8x6',
  middleThirdTopHalf = '4,0 4x6',
  rightThirdTopHalf = '8,0 4x6',
  rightTwoThirdsTopHalf = '4,0 8x6',

  leftThirdBottomHalf = '0,6 4x6',
  leftTwoThirdsBottomHalf = '0,6 8x6',
  middleThirdBottomHalf = '4,6 4x6',
  rightThirdBottomHalf = '8,6 4x6',
  rightTwoThirdsBottomHalf = '4,6 8x6',

  leftQuarter = '0,0 3x12',
  middleHalf = '3,0 6x12',
  rightQuarter = '9,0 3x12',

  bottomHalf = '0,6 12x6',
  leftHalf = '0,0 6x12',
  rightHalf = '6,0 6x12',
  topHalf = '0,0 12x6',

  fullScreen = '0,0 12x12',
  tenTwelfes = '1,1 10x10',

  leftTopHalf = '0,0 6x6',
  leftBottomHalf = '0,6 6x6',

  leftTopThird = '0,0 6x4',
  leftMiddleThird = '0,4 6x4',
  leftBottomThird = '0,8 6x4',

  leftFirstQuarter = '0,0 6x3',
  leftSecondQuarter = '0,3 6x3',
  leftThirdQuarter = '0,6 6x3',
  leftFourthQuarter = '0,9 6x3',
}

function moveFrontmostWindow(where)
  return function()
    local window = hs.window.frontmostWindow()
    local screen = window:screen()
    hs.grid.set(window, where, screen)
  end
end

function launchOrFocus(app)
  return function()
    hs.application.launchOrFocus(app)
  end
end

local function launchNewInstance(appName)
  return function()
    hs.execute('open -n -a "' .. appName .. '"')
  end
end

local executeScript = function(script)
  return function()
    hs.execute(script)
  end
end

-- Alt+R to open Spotlight
hs.hotkey.bind({"alt"}, "R", function()
  hs.eventtap.keyStroke({"cmd"}, "space")
end)

local bindings = {
  [{'alt'}] = {
    -- applications
    [';'] = launchOrFocus('GitKraken'),
    ['\''] = executeScript('/opt/homebrew/bin/code -n'),
    ['8'] = launchOrFocus('Ferdium'),
    ['c'] = launchNewInstance('Calculator'),
    ['d'] = executeScript('open $HOME/Downloads'),
    ['e'] = executeScript('open $HOME'),
    ['f'] = launchNewInstance('Firefox Developer Edition'),
    ['g'] = launchNewInstance('Google Chrome'),
    ['p'] = executeScript('open $HOME/Pictures'),
    ['w'] = launchOrFocus('Microsoft Remote Desktop Beta'),
    ['return'] = launchNewInstance('iTerm')
  },
  [{'alt', 'cmd'}] = {
    ['a'] = launchOrFocus('Activity Monitor'),
     -- window tiling using arrows to halfs of screen
    ['left'] = moveFrontmostWindow(grid.leftHalf),
    ['right'] = moveFrontmostWindow(grid.rightHalf),
    ['up'] = moveFrontmostWindow(grid.topHalf),
    ['down'] = moveFrontmostWindow(grid.bottomHalf),
  },
  [{'cmd'}] = {
    ['f1'] = moveFrontmostWindow(grid.fullScreen),
    ['f2'] = moveFrontmostWindow(grid.tenTwelfes),
  },
  [{'alt', 'cmd', 'ctrl', 'shift'}] = {
    -- dangerous: kill all Terminals
    ['return'] = executeScript('pkill -a iTerm')
  }
}

for modifier, keyActions in pairs(bindings) do
  for key, action in pairs(keyActions) do
    hs.hotkey.bind(modifier, tostring(key), action)
  end
end

local SkyRocket = hs.loadSpoon("SkyRocket")

sky = SkyRocket:new({
  -- Opacity of resize canvas
  opacity = 0.6,

  -- Which modifiers to hold to move a window?
  moveModifiers = {'alt'},

  -- Which mouse button to hold to move a window?
  moveMouseButton = 'left',

  -- Which modifiers to hold to resize a window?
  resizeModifiers = {'alt'},

  -- Which mouse button to hold to resize a window?
  resizeMouseButton = 'right',
})

--
-- Switch spaces in unison between 3 displays
--
hs.hotkey.bind({"alt"}, "1", function()
  hs.eventtap.keyStroke({"ctrl"}, "1")
  hs.eventtap.keyStroke({"ctrl"}, "4")
  hs.eventtap.keyStroke({"ctrl"}, "7")
end)

hs.hotkey.bind({"alt"}, "2", function()
  hs.eventtap.keyStroke({"ctrl"}, "2")
  hs.eventtap.keyStroke({"ctrl"}, "5")
  hs.eventtap.keyStroke({"ctrl"}, "8")
end)

hs.hotkey.bind({"alt"}, "3", function()
  hs.eventtap.keyStroke({"ctrl"}, "3")
  hs.eventtap.keyStroke({"ctrl"}, "6")
  hs.eventtap.keyStroke({"ctrl"}, "9")
end)


-- screenNumber = hs.menubar.new()
-- function spaceNumberDisplay(state)
--     -- will eventually displauy the current space number in the menubar
--     print(hs.spaces.activeSpaces())
--     screenNumber:setTitle(hs.spaces.activeSpaces())
-- end
-- spaceNumberDisplay()

--
-- Auto-reload config on change.
--
-- https://www.hammerspoon.org/go/©
--
function reloadConfig(files)
  doReload = false
  for _,file in pairs(files) do
      if file:sub(-4) == ".lua" then
          doReload = true
      end
  end
  if doReload then
      hs.reload()
  end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")
