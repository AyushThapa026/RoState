local RunService = game:GetService("RunService")
--- Manages multiple states via events
-- Useful for coordinating multiple states
--[[
    stateData = {
        initial = "idle", -- // default is "none"; this is the value that is initialized
        events = {
            {name = "walk", from = "idle", to = "walking"},
            {name = "die", from = "any", to = "died"}, -- // a from state of "any" will allow this event to be called from any event
            {name = "stop", from = "any", to = "idle"}
        },
        callback = {
            {
                walking_leave = function() print("Stopped walking") end,
                walk_enter = function() print("Started walking") end,

                die_enter = function() print("Died") end,
            }
        }
    }

    local RoState = require(PATH_HERE)
    local StateMachine = RoState.new(stateData),

    StateMachine.walk() -- // sets current state to "walking"
    print(StateMachine:GetState()) -- returns "walking"
--]]
-- @classmod RoState

local Signal = require(script.Signal)
local Maid = require(script.Maid)
local Promise = require(script.Promise)

local RoState = {}
RoState.__index = RoState
RoState.ClassName = "RoState"

-- // Definitions
local DEFERRED_YIELD = true

--- Returns a new RoState object
-- @constructor RoState.new()
-- @treturn RoState
function RoState.new(stateData)
    assert(stateData.events, "[RoState.new] events are required to properly initialize RoState")
    local self = setmetatable({
        events = stateData.events;

        _initial = stateData.initial or "none";
        _state = nil;
        _lastState = nil;

        _callbacks = stateData.callbacks or {};

        _queue = {};
        
        signals = {Entered = Maid.new(), Left = Maid.new()}
    }, RoState)

    for _, event in pairs(self.events) do
        self:AddEvent(event.name, event.from, event.to);
    end
    self._state = self._initial

    return self
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
    self.signals.Left[stateName] = getOrCreateSignal(self.signals.Left, stateName);

    return self.signals.Left[stateName]
end

function RoState:OnStateEnter(stateName)
    self.signals.Entered[stateName] = getOrCreateSignal(self.signals.Entered, stateName);

    return self.signals.Entered[stateName]
end

--- Add an event that can change state when called
function RoState:AddEvent(eventName : string, stateFrom : string, stateTo : string)
    assert(eventName and stateFrom and stateTo, "[RoState.AddEvent] eventName, stateFrom, and stateTo all must be valid")

    if not self[eventName] then
        self[eventName] = function(seconds : number)

            local function eventCalled()
                if (self._state == stateFrom) or stateFrom == "any" then
                    self._lastState = self._state
                    self._state = stateTo
    
                    self.signals.Entered[stateTo] = getOrCreateSignal(self.signals.Entered, stateTo);
                    self.signals.Left[stateFrom] = getOrCreateSignal(self.signals.Left, stateTo);
    
                    self.signals.Entered[stateTo]:Fire(self, eventName, stateFrom, stateTo)
                    self.signals.Left[stateFrom]:Fire(self, eventName, stateFrom, stateTo)
    
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
        self["get" .. eventName] = function()
            return stateFrom, stateTo
        end
    else
        warn(("[RoState.%s] already exists"):format(eventName))
    end
end

function RoState:Can(event : string)
    if self[event] then
        local _, stateFrom = self["get" .. event]()
        if stateFrom == self._state then
            return true
        end
    end
    return false
end

function RoState:Destroy()
    self.signals.Entered:DoCleaning()
    self.signals.Left:DoCleaning()

    table.clear(self._callbacks);
    table.clear(self.events);
    table.clear(self)
    self = nil;
end

return RoState