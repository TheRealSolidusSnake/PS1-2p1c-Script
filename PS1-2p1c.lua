-- 2p1c script (Made with FF9 2p1c in mind; should work for other games? (Don't see why it wouldn't but mileage may vary)

local SWITCH_IN_FRAMES = 30

-- Raw device prefixes (Player 1 and 2)
local RAW_P1 = "X1 "
local RAW_P2 = "X2 "

-- HUD colors
local COLOR_P1 = 0xFFFFFFFF -- white
local COLOR_P2 = 0xFF00FF00 -- green

------------------------------------------------------------

-- Controller schema (BizHawk PSX button names found in Configuration/API)
local SCHEMA = joypad.get() or {}

local function has_p1(suffix) return SCHEMA["P1 " .. suffix] ~= nil end
local function pick_suffix(raws)
  for _, s in ipairs(raws) do
    if has_p1(s) then return s end
  end
  return nil
end

local SUF = {
  Up     = pick_suffix({ "D-Pad Up", "Up" }),
  Down   = pick_suffix({ "D-Pad Down", "Down" }),
  Left   = pick_suffix({ "D-Pad Left", "Left" }),
  Right  = pick_suffix({ "D-Pad Right", "Right" }),
  Select = pick_suffix({ "Select" }),
  Start  = pick_suffix({ "Start" }),
  Tri    = pick_suffix({ "△", "Triangle" }),
  Cross  = pick_suffix({ "X", "Cross", "✕" }),
  Square = pick_suffix({ "□", "Square" }),
  Circle = pick_suffix({ "O", "Circle" }),
  L1     = pick_suffix({ "L1" }),
  L2     = pick_suffix({ "L2" }),
  R1     = pick_suffix({ "R1" }),
  R2     = pick_suffix({ "R2" }),
}

local RAW = {
  Up="DpadUp", Down="DpadDown", Left="DpadLeft", Right="DpadRight",
  Back="Back", Start="Start",
  Y="Y", A="A", X="X", B="B",
  LB="LeftShoulder", LT="LeftTrigger", RB="RightShoulder", RT="RightTrigger",
}

local function raw_press(phys, prefix, name)
  local v = phys[prefix .. name]
  if type(v) == "number" then return v ~= 0 end
  return v == true
end

local function make_ports_released()
  local out = {}
  for k, v in pairs(SCHEMA) do
    if type(k) == "string" and (k:match("^P1%s") or k:match("^P2%s")) then
      out[k] = (type(v) == "number") and 0 or false
    end
  end
  return out
end

local function set_p1(out, suffix, press)
  if not suffix then return end
  out["P1 " .. suffix] = press and true or false
end

-- We check frame count for controller swap here
event.oninputpoll(function()
  local pollFrame = emu.framecount() + 1
  local active = (math.floor(pollFrame / SWITCH_IN_FRAMES) % 2 == 0) and 1 or 2
  local framesLeft = SWITCH_IN_FRAMES - (pollFrame % SWITCH_IN_FRAMES)

  -- Refresh "schema" if controller config changes
  SCHEMA = joypad.get() or SCHEMA

  local physInput = input.get()
  if not physInput or next(physInput) == nil then return end

  local prefix = (active == 1) and RAW_P1 or RAW_P2

  -- Force BOTH ports released first - prevents sticking/leakage if PSX ports are unbound, felt laggy otherwise
  local out = make_ports_released()

  -- Write the active controller inputs to P1
  set_p1(out, SUF.Up,     raw_press(physInput, prefix, RAW.Up))
  set_p1(out, SUF.Down,   raw_press(physInput, prefix, RAW.Down))
  set_p1(out, SUF.Left,   raw_press(physInput, prefix, RAW.Left))
  set_p1(out, SUF.Right,  raw_press(physInput, prefix, RAW.Right))
  set_p1(out, SUF.Select, raw_press(physInput, prefix, RAW.Back))
  set_p1(out, SUF.Start,  raw_press(physInput, prefix, RAW.Start))

  set_p1(out, SUF.Tri,    raw_press(physInput, prefix, RAW.Y))
  set_p1(out, SUF.Cross,  raw_press(physInput, prefix, RAW.A))
  set_p1(out, SUF.Square, raw_press(physInput, prefix, RAW.X))
  set_p1(out, SUF.Circle, raw_press(physInput, prefix, RAW.B))

  set_p1(out, SUF.L1, raw_press(physInput, prefix, RAW.LB))
  set_p1(out, SUF.L2, raw_press(physInput, prefix, RAW.LT))
  set_p1(out, SUF.R1, raw_press(physInput, prefix, RAW.RB))
  set_p1(out, SUF.R2, raw_press(physInput, prefix, RAW.RT))

  joypad.set(out)

  -- HUD so you know who is active or not
  local color = (active == 1) and COLOR_P1 or COLOR_P2
  gui.text(2, 2, "P" .. active, color)
  gui.text(2, 12, framesLeft .. "f", color)
end)
