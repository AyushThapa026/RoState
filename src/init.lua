--- Manages multiple states via events
-- Useful for coordinating multiple states
-- @classmod RoState
local Signal = require(script.Signal)
local Maid = require(script.Maid)
local Promise = require(script.Promise)

local RoState = {}
RoState.ClassName = "RoState"

--- Returns a new RoState object
-- @constructor RoState.new()
-- @treturn RoState

function RoState.new(stateData)
    assert(stateData.events, "[RoState.new] events are required to properly initialize RoState")
    local self = setmetatable({
        _initial = stateData.initial or "none";

        _state = nil;
        _lastState = nil;
        _callbacks = stateData.callbacks or {};
        _events = {};
        
        _signals = {Entered = Maid.new(), Left = Maid.new()}
    }, RoState)

    for _, event in pairs(stateData.events) do
        self:AddEvent(event.name, event.from, event.to);
    end
    self._state = self._initial

    return self
end

function RoState:__index(index)
    if RoState[index] then
        return RoState[index]
    elseif self._events[index] then
        return self._events[index]
    else
        error(("Attempt to index with nil value '%s'"):format(index), 2)
    end
end

function RoState:GetState()
    return self._state
end

function RoState:Is(state : string)
    return self._state == state
end

local function getOrCreateSignal(array, index)
    if not array[index] then
        array[index] = Signal.new()
    end
    return array[index]
end

function RoState:OnStateLeft(stateName)
    self._signals.Left[stateName] = getOrCreateSignal(self._signals.Left, stateName);

    return self._signals.Left[stateName]
end

function RoState:OnStateEnter(stateName)
    self._signals.Entered[stateName] = getOrCreateSignal(self._signals.Entered, stateName);

    return self._signals.Entered[stateName]
end

--- Add an event that can change state when called
function RoState:AddEvent(eventName : string, stateFrom : string, stateTo : string)
    assert(eventName and stateFrom and stateTo, "[RoState.AddEvent] eventName, stateFrom, and stateTo all must be valid")

    if not self._events[eventName] then
        self._events[eventName] = function(seconds : number)
            local function eventCalled()
                if (self._state == stateFrom) or stateFrom == "any" then
                    self._lastState = self._state
                    self._state = stateTo
    
                    self._signals.Entered[stateTo] = getOrCreateSignal(self._signals.Entered, stateTo);
                    self._signals.Left[stateFrom] = getOrCreateSignal(self._signals.Left, stateTo);
    
                    self._signals.Entered[stateTo]:Fire(self, eventName, stateFrom, stateTo)
                    self._signals.Left[stateFrom]:Fire(self, eventName, stateFrom, stateTo)
    
                    if self._callbacks[self._lastState .. "_leave"] then
                        self._callbacks[self._lastState .. "_leave"](self, eventName, stateFrom, stateTo)
                    end
                    
                    if self._callbacks[self._state .. "_enter"] then
                        self._callbacks[self._lastState .. "_enter"](self, eventName, stateFrom, stateTo)
                    end
                end
            end

            if seconds then
                Promise.delay(seconds):andThen(eventCalled)
            else
                eventCalled()
            end
            
        end
        self._events["get_" .. eventName] = function()
            return stateTo, stateFrom
        end
    else
        warn(("[RoState.%s] already exists"):format(eventName))
    end
end

function RoState:Can(event : string)
    if self._events[event] then
        local _, stateFrom = self._events["get_" .. event]()
        if stateFrom == self._state then
            return true
        end
    end
    return false
end

function RoState:GetTransitionMethods(state : string)
    state = state or self._state
    local events = {}
    for event, func in pairs(self._events) do
        if string.sub(event, 1, 4) == "get_" then
            local stateTo, stateFrom = func()
            if (stateFrom == state) or stateFrom == "any" then
                table.insert(events, string.sub(event, 5, #event))
            end
        end
    end
    return events
end

function RoState:Destroy()
    self._signals.Entered:DoCleaning()
    self._signals.Left:DoCleaning()

    table.clear(self._callbacks);
    table.clear(self.events);
    table.clear(self)
    self = nil;
end

return RoState