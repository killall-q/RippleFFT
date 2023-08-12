function Initialize()
  mFFT, rips = {}, {}
  isDot = SKIN:GetVariable('IsDot') == '1'
  deltaMin = tonumber(SKIN:GetVariable('DeltaMin'))
  deltaCoef = 1000 / (1 - deltaMin) -- coefficient to range FFT delta between 0 and 1
  bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
  durMin = tonumber(SKIN:GetVariable('DurationMin'))
  durMax = tonumber(SKIN:GetVariable('DurationMax'))
  durRange = durMax - durMin
  rMin = tonumber(SKIN:GetVariable('RadiusMin'))
  rMax = tonumber(SKIN:GetVariable('RadiusMax'))
  rRange = rMax - rMin
  local growth = tonumber(SKIN:GetVariable('Growth'))
  rLimit = rMax + math.max(growth * durMax, 0)
  growthPct = growth / rLimit
  local thick = tonumber(SKIN:GetVariable('Thick'))
  local blur = tonumber(SKIN:GetVariable('Blur'))
  blurPct = math.min(thick / 2, blur) / rLimit
  thickPct = math.max(thick - blur * 2, 0) / rLimit
  gapW = (tonumber(SKIN:GetVariable('Width')) - rMax * 2) / (bands - 1)
  travel = tonumber(SKIN:GetVariable('Height')) - rMax * 2
  color = GetColor(SKIN:GetVariable('Color'))
  isLocked = false -- lock hiding of mouseover controls
  if bands > 1 and not SKIN:GetMeasure('mFFT1') then
    GenMeasures()
    SKIN:Bang('!Refresh')
    return
  end
  for b = 0, bands - 1 do
    mFFT[b], rips[b] = SKIN:GetMeasure('mFFT'..b), {}
    for d = 0, 180 do
      rips[b][d] = 0
    end
  end
  os.remove(SKIN:GetVariable('@')..'Measures.inc')
  SetChannel(SKIN:GetVariable('Channel'))
  SetOrder(tonumber(SKIN:GetVariable('Order')), true)
  SKIN:Bang('[!SetOption Mode'..(isDot and 1 or 0)..' SolidColor FF0000][!SetOption Mode'..(isDot and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption DeltaMinSlider X '..(deltaMin * 500)..'r][!SetOption DeltaMinVal Text '..(deltaMin * 100)..'%][!SetOption SensSlider X '..(tonumber(SKIN:GetVariable('Sens')) * 0.9)..'r][!SetOption DurationRange X '..(durMin / 2)..'r][!SetOption DurationRange W '..(durRange / 2)..'][!SetOption DurationMaxSlider X '..(durRange / 2)..'r][!SetOption DurationMinVal Text "'..string.format('%.2f', durMin / 60)..' s"][!SetOption DurationMaxVal Text "'..string.format('%.2f', durMax / 60)..' s"][!SetOption RadiusRange X '..(rMin / 2)..'r][!SetOption RadiusRange W '..(rRange / 2)..'][!SetOption RadiusMaxSlider X '..(rRange / 2)..'r][!SetOption GrowthSlider X '..(50 + growth * 5)..'r][!SetOption ThickSlider X '..(thick * 2 - 2)..'r][!SetOption BlurSlider X '..(blur * 2 - 2)..'r]')
  if SKIN:GetVariable('ShowSet') == '1' then
    ShowSettings()
    SKIN:Bang('!WriteKeyValue Variables ShowSet 0 "#@#Settings.inc"')
  end
end

function Update()
  local iter = 2
  for b = 0, bands - 1 do
    local FFT = mFFT[b]:GetValue()
    for d = durMax, 0, -1 do
      -- Store FFT delta before decimal point, FFT value after decimal point
      rips[b][d] = d == 0 and FFT or d == 1 and (deltaMin < FFT - rips[b][0] and math.floor((FFT - rips[b][0]) * deltaCoef) + math.min(FFT, 0.999) or 0) or rips[b][d - 1]
      local delta = math.floor(rips[b][d]) * 0.001
      if d ~= 0 and 0 < delta and d < delta * durRange + durMin then
        local alpha, sizePct = math.max(1 - d / (delta * durRange + durMin), 0) * 255, (delta * rRange + rMin) / rLimit + growthPct * d
        SKIN:Bang('[!SetOption Render Shape'..iter..' "Ellipse '..(rMax + gapW * b)..','..((1 - rips[b][d] % 1) * travel + rMax)..','..rLimit..'|Extend Attr|Fill RadialGradient1 Grad'..iter..'"][!SetOption Render Grad'..iter..' "0,0|'..color..'0;'..sizePct..'|'..color..alpha..';'..(sizePct - blurPct)..(isDot and '' or '|'..color..alpha..';'..(sizePct - blurPct - thickPct)..'|'..color..'0;'..(sizePct - blurPct * 2 - thickPct))..'"]')
        iter = iter + 1
      end
    end
  end
  SKIN:Bang('!SetOption Render Shape'..iter..' ""')
end

function ShowHover()
  if SKIN:GetMeter('Handle'):GetW() > 0 then return end
  SKIN:Bang('!SetOption Render Hover "Stroke Color 80808050"')
end

function ShowSettings()
  local render = SKIN:GetMeter('Render')
  SKIN:Bang('[!SetOption Handle W '..math.max(render:GetW(), 260)..'][!SetOption Handle H '..math.max(render:GetH(), 368)..'][!SetOption Render Hover "Stroke Color 00000001"][!MoveMeter 12 12 ModeLabel][!MoveMeter 83 87 ChannelBG][!ShowMeterGroup Set]')
end

function HideSettings()
  if isLocked then return end
  SKIN:Bang('[!MoveMeter -260 -370 ModeLabel][!MoveMeter -260 -370 ChannelBG][!HideMeterGroup Set][!SetOption Render Hover "Stroke Color 00000001"]')
end

function GenMeasures()
  local file = io.open(SKIN:GetVariable('@')..'Measures.inc', 'w')
  for b = 1, bands - 1 do
    file:write('[mFFT'..b..']\nMeasure=Plugin\nPlugin=AudioLevel\nParent=mFFT0\nType=Band\nBandIdx='..b..'\nGroup=mFFT\n')
  end
  file:close()
end

function GetColor(color)
  -- Convert color to RGB and strip alpha component
  if not color:find(',') then
    color = color:gsub('%x%x', function(s) return tonumber(s, 16)..',' end)
  end
  return color:match('%d+[,%s]+%d+[,%s]+%d+')..','
end

function SetMode(n)
  if isDot == (n == 1) then return end
  SKIN:Bang('[!SetOption Mode'..(isDot and 1 or 0)..' SolidColor 505050E0][!SetOption Mode'..(isDot and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Mode'..(n or 0)..' SolidColor FF0000][!SetOption Mode'..(n or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!WriteKeyValue Variables IsDot '..(n or 0)..' "#@#Settings.inc"]')
  isDot = n == 1
end

function SetDeltaMin(n, m)
  if m then
    deltaMin = math.min(math.floor(m * 0.21) * 0.01, 0.2)
  elseif 0 <= deltaMin + n and deltaMin + n <= 0.2 then
    deltaMin = math.floor((deltaMin + n) * 100 + 0.5) * 0.01
  else return end
  deltaCoef = 1000 / (1 - deltaMin)
  SKIN:Bang('[!SetOption DeltaMinSlider X '..(deltaMin * 500)..'r][!SetOption DeltaMinVal Text '..(deltaMin * 100)..'%][!WriteKeyValue Variables DeltaMin '..deltaMin..' "#@#Settings.inc"]')
end

function SetSens(n, m)
  local sens = tonumber(SKIN:GetVariable('Sens'))
  if m then
    sens = math.min(math.floor(m * 0.11) * 10, 100)
  elseif 0 <= sens + n and sens + n <= 100 then
    sens = math.floor((sens + n) * 0.1 + 0.5) * 10
  else return end
  SKIN:Bang('[!SetOption mFFT0 Sensitivity '..sens..'][!SetOption SensSlider X '..(sens * 0.9)..'r][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Settings.inc"]')
end

function SetChannel(n)
  local name = {[0]='Left','Right','Center','Subwoofer','Back Left','Back Right','Side Left','Side Right'}
  if n == 'Stereo' then
    -- Split bands between L and R channels
    for b = 0, bands / 2 - 1 do
      SKIN:Bang('[!SetOption mFFT'..b..' Channel L][!SetOption mFFT'..b..' BandIdx '..(bands - b * 2 - 2)..']')
    end
    for b = bands / 2, bands - 1 do
      SKIN:Bang('[!SetOption mFFT'..b..' Channel R][!SetOption mFFT'..b..' BandIdx '..(b * 2 - bands - 2)..']')
    end
  else
    SKIN:Bang('!SetOptionGroup mFFT Channel '..n)
    for b = 0, bands - 1 do
      SKIN:Bang('!SetOption mFFT'..b..' BandIdx '..b)
    end
  end
  SKIN:Bang('[!SetOption ChannelSet Text "'..(name[tonumber(n)] or n)..'"][!SetVariable Channel '..n..'][!WriteKeyValue Variables Channel '..n..' "#@#Settings.inc"]')
end

function SetBands()
  isLocked = false
  local set = math.floor(tonumber(SKIN:GetVariable('Set')) or 0)
  if set <= 0 then return end
  SKIN:Bang('[!WriteKeyValue Variables Bands '..set..' "#@#Settings.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Settings.inc"][!Refresh]')
end

function SetOrder(n, init)
  if n ~= tonumber(SKIN:GetVariable('Order')) or init and n == 1 then
    for b = 0, bands / 2 - 1 do
      mFFT[b], mFFT[bands - b - 1] = mFFT[bands - b - 1], mFFT[b]
    end
  end
  SKIN:Bang('[!SetOption Order'..(n == 1 and 'Right' or 'Left')..' SolidColor 505050E0][!SetOption Order'..(n == 1 and 'Right' or 'Left')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Order'..(n == 1 and 'Left' or 'Right')..' SolidColor FF0000][!SetOption Order'..(n == 1 and 'Left' or 'Right')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetVariable Order '..n..'][!WriteKeyValue Variables Order '..n..' "#@#Settings.inc"]')
end

function SetVar(var, min)
  isLocked = false
  local set = math.floor(tonumber(SKIN:GetVariable('Set')) or 0)
  if set < min then return end
  if var == 'Width' then
    gapW = (set - rMax * 2) / (bands - 1)
  elseif var == 'Height' then
    travel = set - rMax * 2
  end
  SKIN:Bang('[!SetOption '..var..'Set Text "'..set..' px"][!SetVariable '..var..' "#Set#"][!WriteKeyValue Variables '..var..' '..set..' "#@#Settings.inc"]')
  SKIN:Bang('[!SetOption Render Shape "Rectangle '..(rMax / 2)..','..(rMax / 2)..',(#Width#-'..rMax..'),(#Height#-'..rMax..')|Fill Color 00000001|StrokeWidth '..rMax..'|Extend Hover"]')
end

function SetRadius(n, m)
  local r = { Min = rMin, Max = rMax }
  local limit = m * 6 < r.Min + r.Max and 'Min' or 'Max'
  local val = 0
  if n == 0 then
    val = math.min(math.floor(m * 0.31) * 10, 300)
  elseif 0 <= r[limit] + n and r[limit] + n <= 300 then
    val = math.floor((r[limit] + n) * 0.1 + 0.5) * 10
  end
  if (limit == 'Min' and r.Max <= val) or (limit == 'Max' and val <= r.Min) then return end
  if limit == 'Min' then
    rMin = val
    rRange = r.Max - val
  else
    rMax = val
    rRange = rMax - r.Min
    local growth = tonumber(SKIN:GetVariable('Growth'))
    rLimit = rMax + math.max(growth * durMax, 0)
    growthPct = growth / rLimit
    local thick = tonumber(SKIN:GetVariable('Thick'))
    local blur = tonumber(SKIN:GetVariable('Blur'))
    blurPct = math.min(thick / 2, blur) / rLimit
    thickPct = math.max(thick - blur * 2, 0) / rLimit
    gapW = (tonumber(SKIN:GetVariable('Width')) - rMax * 2) / (bands - 1)
    travel = tonumber(SKIN:GetVariable('Height')) - rMax * 2
  end
  SKIN:Bang('[!SetOption RadiusRange X '..(rMin / 2)..'r][!SetOption RadiusRange W '..(rRange / 2)..'][!SetOption RadiusMaxSlider X '..(rRange / 2)..'r][!SetOption Render Shape "Rectangle '..(rMax / 2)..','..(rMax / 2)..',(#Width#-'..rMax..'),(#Height#-'..rMax..')|Fill Color 00000001|StrokeWidth '..rMax..'|Extend Hover"][!SetOption Radius'..limit..'Val Text "'..val..' px"][!WriteKeyValue Variables Radius'..limit..' '..val..' "#@#Settings.inc"]')
end

function SetDuration(n, m)
  local dur = { Min = durMin, Max = durMax }
  local limit = m * 3.6 < dur.Min + dur.Max and 'Min' or 'Max'
  local val = 0
  if n == 0 then
    val = math.min(math.floor(m * 0.19) * 10, 180)
  elseif 0 <= dur[limit] + n and dur[limit] + n <= 180 then
    val = math.floor((dur[limit] + n) * 0.1 + 0.5) * 10
  end
  if (limit == 'Min' and dur.Max <= val) or (limit == 'Max' and val <= dur.Min) then return end
  if limit == 'Min' then
    durMin = val
    durRange = dur.Max - durMin
  else
    durMax = val
    durRange = durMax - dur.Min
    local growth = tonumber(SKIN:GetVariable('Growth'))
    rLimit = rMax + math.max(growth * durMax, 0)
    growthPct = growth / rLimit
    local thick = tonumber(SKIN:GetVariable('Thick'))
    local blur = tonumber(SKIN:GetVariable('Blur'))
    blurPct = math.min(thick / 2, blur) / rLimit
    thickPct = math.max(thick - blur * 2, 0) / rLimit
  end
  SKIN:Bang('[!SetOption DurationRange X '..(durMin / 2)..'r][!SetOption DurationRange W '..(durRange / 2)..'][!SetOption DurationMaxSlider X '..(durRange / 2)..'r][!SetOption Duration'..limit..'Val Text "'..string.format('%.2f', val / 60)..' s"][!WriteKeyValue Variables Duration'..limit..' '..val..' "#@#Settings.inc"]')
end

function SetGrowth(n, m)
  local growth = tonumber(SKIN:GetVariable('Growth'))
  if m then
    growth = math.min(math.floor(m * 0.21) - 10, 10)
  elseif -10 <= growth + n and growth + n <= 10 then
    growth = growth + n
  else return end
  rLimit = rMax + math.max(growth * durMax, 0)
  growthPct = growth / rLimit
  SKIN:Bang('[!SetOption GrowthSlider X '..(50 + growth * 5)..'r][!SetOption GrowthVal Text '..growth..'][!SetVariable Growth '..growth..'][!WriteKeyValue Variables Growth '..growth..' "#@#Settings.inc"]')
end

function SetThick(n, m)
  local thick = tonumber(SKIN:GetVariable('Thick'))
  local blur = tonumber(SKIN:GetVariable('Blur'))
  if m then
    thick = math.min(math.floor(m * 0.5) + 1, 50)
  elseif 1 <= thick + n and thick + n <= 50 then
    thick = thick + n
  else return end
  blurPct = math.min(thick / 2, blur) / rLimit
  thickPct = math.max(thick - blur * 2, 0) / rLimit
  SKIN:Bang('[!SetOption ThickSlider X '..(thick * 2 - 2)..'r][!SetOption ThickVal Text "'..thick..' px"][!SetVariable Thick '..thick..'][!WriteKeyValue Variables Thick '..thick..' "#@#Settings.inc"]')
end

function SetBlur(n, m)
  local thick = tonumber(SKIN:GetVariable('Thick'))
  local blur = tonumber(SKIN:GetVariable('Blur'))
  if m then
    blur = math.min(math.floor(m * 0.25) + 1, 25)
  elseif 1 <= blur + n and blur + n <= 25 then
    blur = blur + n
  else return end
  blurPct = math.min(thick / 2, blur) / rLimit
  thickPct = math.max(thick - blur * 2, 0) / rLimit
  SKIN:Bang('[!SetOption BlurSlider X '..(blur * 2 - 2)..'r][!SetOption BlurVal Text "'..blur..' px"][!SetVariable Blur '..blur..'][!WriteKeyValue Variables Blur '..blur..' "#@#Settings.inc"]')
end

function SetColor()
  isLocked = false
  local set = SKIN:GetVariable('Set')
  if set == '' then return end
  color = GetColor(set)
  SKIN:Bang('[!SetOption ColorSet Text "'..set..'"][!SetVariable Color "'..set..'"][!WriteKeyValue Variables Color "'..set..'" "#@#Settings.inc"]')
end
