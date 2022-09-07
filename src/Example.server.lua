stateData = {
    initial = "idle", -- // default is "none"; this is the value that is initialized
    events = {
        {name = "walk", from = "idle", to = "walking"},
        {name = "die", from = "any", to = "died"}, -- // a from state of "any" will allow this event to be called from any event
        {name = "stop", from = "any", to = "idle"}
    },
    callbacks = {
        {
            walking_leave = function() print("Stopped walking") end,
            walk_enter = function() print("Started walking") end,

            died_enter = function() print("Died") end,
        }
    }
}

local RoState = require(script.Parent)
local StateMachine = RoState.new(stateData)


StateMachine:OnStateEnter("walking"):Connect(function()
    print("Started walking")
end)

StateMachine:OnStateLeft("walking"):Connect(function()
    print("Stopped walking")
end)

StateMachine:OnStateEnter("died"):Connect(function()
    print("died")
end)

StateMachine.walk() -- // sets current state to "walking"
StateMachine.die(2) -- // sets current state to "died" after 2 seconds
