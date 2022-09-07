stateData = {
    initial = "idle", -- // default is "none"; this is the value that is initialized
    events = {
        {name = "walk", from = "idle", to = "walking"},
        {name = "die", from = "any", to = "died"}, -- // a from state of "any" will allow this event to be called from any event
        {name = "stop", from = "any", to = "idle"},
    },
    callbacks = {
        walking_leave = function() print("left walking callback") end,
        walk_enter = function() print("walk enter callback") end,
        died_enter = function() print("died entered callback") end,
        died_leave = function() print("came back to life?") end,
    }
}

local RoState = require(script.Parent)
local StateMachine = RoState.new(stateData)

StateMachine:OnStateEnter("idle"):Connect(function()
    print("Idle state entered")
end)

StateMachine.walk() -- // sets current state to "walking"
print(StateMachine:GetTransitionMethods("walking")) -- // Returns a table populated with potential events that can be called from "walking". In this case that is "die" and "stop"
StateMachine.die() -- // sets current state to "died"
StateMachine.stop(2) -- // sets current state to "idle" after 2 seconds (this will cause died_leave to be called and the signal returned by StateMachine:OnStateEnter("idle") to be fired in this scenario)
