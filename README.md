# Ro-State

Ro-State is a simple roblox lua state machine that I wrote to handle states simply and elegantly.

## Description

When writing code that requires multiple states it can get both challenging and tedious to have to navigate around conditionals. It is ideal to have the right code running at the right time. State machines are one way to tackle this problem. With finite state machines there can only be one state at any given time. Utilizing a state machine can greatly simplify the flow of your code.

### Getting Started

#### Example Code
```lua
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
```
## API
Disclaimer: Anything in all capitals represents the name of 

* `StateMachine:AddEvent(eventName : string, stateFrom : string, stateTo : string)`   - Adds an event to the StateMachine
* `StateMachine[EVENT_NAME]()`                                                        - Causes the StateMachine to attempt to run EVENT_NAME
* `StateMachine[get_EVENT_NAME]()`                                                    - Returns information about EVENT_NAME (i.e stateFrom, stateTo)

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

