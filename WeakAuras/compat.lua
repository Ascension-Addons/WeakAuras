local ipairs = ipairs
local pairs = pairs
local abs, ceil, floor = math.abs, math.ceil, math.floor

local GetInstanceInfo = GetInstanceInfo
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers

if not noop then
	function noop()
	end
end

if not ipairs_reverse then
	function ipairs_reverse(table)
		local function Enumerator(table, index)
			index = index - 1;
			local value = table[index];
			if value ~= nil then
				return index, value;
			end
		end
		return Enumerator, table, #table + 1;
	end
end

if not tInvert then
	function tInvert(tbl)
		local inverted = {};
		for k, v in pairs(tbl) do
			inverted[v] = k;
		end
		return inverted;
	end
end

if not Round then
	function Round(value)
		if value < 0 then
			return ceil(value - .5);
		end
		return floor(value + .5);
	end
end

if not tIndexOf then
	function tIndexOf(tbl, item)
		for i, v in ipairs(tbl) do
			if item == v then
				return i;
			end
		end
	end
end

if not IsInGroup then
	function IsInGroup()
		return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
	end
end

if not IsInRaid then
	function IsInRaid()
		return GetNumRaidMembers() > 0
	end
end

if not GetNumSubgroupMembers then
	function GetNumSubgroupMembers()
		return GetNumPartyMembers()
	end
end

if not GetNumGroupMembers then
	function GetNumGroupMembers()
		return IsInRaid() and GetNumRaidMembers() or GetNumPartyMembers()
	end
end

if not SmoothStatusBarMixin then
	if not Lerp then
		function Lerp(startValue, endValue, amount)
			return (1 - amount) * startValue + amount * endValue;
		end
	end

	if not Clamp then
		function Clamp(value, min, max)
			if value > max then
				return max;
			elseif value < min then
				return min;
			end
			return value;
		end
	end

	if not Saturate then
		function Saturate(value)
			return Clamp(value, 0, 1);
		end
	end

	local TARGET_FRAME_PER_SEC = 60;
	if not DeltaLerp then
		function DeltaLerp(startValue, endValue, amount, timeSec)
			return Lerp(startValue, endValue, Saturate(amount * timeSec * TARGET_FRAME_PER_SEC));
		end
	end

	if not FrameDeltaLerp then
		function FrameDeltaLerp(startValue, endValue, amount, elapsed)
			return DeltaLerp(startValue, endValue, amount, elapsed);
		end
	end

	local g_updatingBars = {};

	local function IsCloseEnough(bar, newValue, targetValue)
		local min, max = bar:GetMinMaxValues();
		local range = max - min;
		if range > 0 then
			return abs((newValue - targetValue) / range) < .00001;
		end

		return true;
	end

	local function ProcessSmoothStatusBars(self, elapsed)
		for bar, targetValue in pairs(g_updatingBars) do
			local effectiveTargetValue = Clamp(targetValue, bar:GetMinMaxValues());
			local newValue = FrameDeltaLerp(bar:GetValue(), effectiveTargetValue, .25, elapsed);

			if IsCloseEnough(bar, newValue, effectiveTargetValue) then
				g_updatingBars[bar] = nil;
				bar:SetValue(effectiveTargetValue);
			else
				bar:SetValue(newValue);
			end
		end
	end

	CreateFrame("Frame"):SetScript("OnUpdate", ProcessSmoothStatusBars)

	SmoothStatusBarMixin = {};

	function SmoothStatusBarMixin:ResetSmoothedValue(value) --If nil, tries to set to the last target value
		local targetValue = g_updatingBars[self];
		if targetValue then
			g_updatingBars[self] = nil;
			self:SetValue(value or targetValue);
		elseif value then
			self:SetValue(value);
		end
	end

	function SmoothStatusBarMixin:SetSmoothedValue(value)
		g_updatingBars[self] = value;
	end

	function SmoothStatusBarMixin:SetMinMaxSmoothedValue(min, max)
		self:SetMinMaxValues(min, max);

		local targetValue = g_updatingBars[self];
		if targetValue then
			local ratio = 1;
			if max ~= 0 and self.lastSmoothedMax and self.lastSmoothedMax ~= 0 then
				ratio = max / self.lastSmoothedMax;
			end

			g_updatingBars[self] = targetValue * ratio;
		end

		self.lastSmoothedMin = min;
		self.lastSmoothedMax = max;
	end
end