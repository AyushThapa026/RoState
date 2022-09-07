local Signal = require(script.Signal)
local Maid = require(script.Maid)

local FSM = {}
FSM.__index = FSM
FSM.__newindex = function(self, index, value)
    if not self.states[index] then
        self.states[index] = value
    else
        error(("[%s] is already a valid state"):format(index))
    end
end

function FSM.new(states)
    local self = setmetatable({
        states = states or {},

        __state = nil;
        __lastState = nil;
        
        OnStateChanged = Signal.new();
    }, FSM)

    return self
end

function FSM:GetState()
    return self.__state
end

function FSM:Is(state)
    return self.__state == state
end

function FSM:AddState(state)
    self.states[state] = true
end

function FSM:ChangeState(state)
    assert(self.states[state], "[FSM.ChangeState] State does not exist")

    self.__lastState = self.__state;
    self.__state = state;

    self.OnStateChanged:Fire(self.__lastState, self.__state) -- // new state, old state
end
  
  return FSM