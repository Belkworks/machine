
# Machine
*A state machine written in MoonScript*  

**Importing with [Neon](https://github.com/Belkworks/NEON)**:
```lua
Machine = NEON:github('belkworks', 'machine')
```

## API

### Creating a Machine
`Machine(Options) -> Machine`  
Creates a new **Machine**.  
`Options` is an object with two keys:  
- `States`: An map of `string -> state constructor`
- `Data`: A shared scratch pad for the machine
```lua
machine = Machine({
    States = {
        Idle = function(state)
            -- idle state constructor here
        end,
        Working = function(state)
            -- working state constructor here
        end
    },
    Data = {
        Something = 123
    }
})
```
The above snippet defines a machine with two state, `Idle` and `Working`.

### State API
A state's behavior is defined in its state constructor.  
All of the states logic should be defined here.  

The reference to the scratch pad is at `state.Data`.
```lua
Idle = function(state)
    state.Data.test = 123
end
```

**initial**: `state:initial() -> nil`  
Sets the state as the machine's initial state.  
This is the state the machine will start in.  
Every machine **MUST** have an initial state.
```lua
Idle = function(state)
    state:initial()
end
```

**on**: `state:on(event, guard?, next) -> nil`  
Define a state transition rule.  
Upon hearing `event`, the machine will transition to the state with the name given by `next`.  
If `guard` is defined, `guard` is called with the event parameters.  
If `guard` returns a truthy value, the transition occurs.  
Otherwise, the next matching rule is tried.  
There can be multiple rules on the same event, and they are executed in order of registration.  
If an event has no matches, it is passed to the state's sub-Machine (if it has one)
```lua
Idle = function(state)
    state:initial()
    -- transition to Working when we hear work
    state:on('work', 'Working')
    
    -- this will never be reached (above always succeeds)
    state:on('work', 'What?')
end
```
With guards:
```lua
shouldWork = function(...)
    return math.random(0, 1) == 1 
end
Idle = function(state)
    state:initial()
    -- go to Working if shouldWork passes
    state:on('work', shouldWork, 'Working')
    
    -- go to Wait if the above rule fails
    state:on('work', 'Wait') 
end
```

**entry**: `state:entry(function) -> nil`  
Add `function` as an entry hook to the state.  
Whenever the state is entered, `function` will be called.  
The hook will receive its state, the exiting state, and any parameters involved in the state change.  
There can be many entry hooks in a state.
```lua
Idle = function(state)
    state:initial()
    state:entry(function(prev, ...)
        print('idle') -- prints every time the machine is in Idle
    end)
end
```

**exit**: `state:exit(function) -> nil`  
Like **entry**, but adds a hook for state exit.  
The hook will receive its state, the future state, and any parameters involved in the state change.
```lua
Idle = function(state)
    state:initial()
    state:exit(function(next, ...)
        print('not idle') -- prints every time the machine leaves Idle
    end)
end
```

**substate**: `state:substate(states) -> nil`  
Create a sub-Machine with the given `states`.  
Note that the `Data` parameter is omitted.  
This is because sub-Machines share a reference to its parent's state.  
Calling this function again will overwrite any old sub-Machine.  
sub-Machines can have sub-Machines in any state.  
Transition rules in substates only apply when its parent state is the active state.  
Additionally, substates can only transition within themselves.
```lua
Idle = function(state)
    state:initial()
    state:substate({
        Awake = function(sub)
            -- substates need an initial call too!
            sub:initial()
            sub:substate(morestates) -- completely fine
            sub:on('sleep', 'Asleep')
        end
        Asleep = function(sub)
            sub:on('wake', 'Awake')
        end
    })
end
```

**event**: `state:event(function) -> nil`  
Add `function` as a hook for events that do not cause a transition.  
There can be many event hooks.
```lua
Idle = function(state)
    state:event(function(event, ...)
        print(event, 'wasnt handled!')
    end
end
```

**transition**: `state:transition(newState, ...) -> State`  
Performs a state transition to the state named `newState`.  
Passes `...` as the transition parameters.  
Returns the new state of the Machine.  
**NOTE**: It is preferable to use `state:on` to define transitions.
```lua
Idle = function(state)
    state:entry(function()
        -- wait a while
        state:transition('Working')
    end)
end
```

**input**: `state:input(event, ...) -> State?`  
Runs all rules for `event` until it runs out or one causes a state transition.  
Also passes input to it's sub-Machine, if it exists.  
Returns the new state if the Machine transitions.  
**NOTE**: It is preferable to run events using the `machine:input` method described below.
```lua
Idle = function(state)
    state:entry(function()
        -- wait a while
        state:input('work')
    end)
end
```

### Machine API

**input**: `machine:input(event, ...) -> State?`  
Run an event through the machine.  
Calls `state:input(event, ...)` on the **current state**.  
Returns the new state of the Machine, if a state transition occurred.
```lua
machine:input('work')
```

**transition**: `machine:transition(newState, ...) -> State`  
Force a state transition to the state named `newState` in the Machine.  
**NOTE**: It is preferable to cause transitions using `state:on` rules.
```lua
machine:transition('Idle')
```

## Full Example

```lua
machine = Machine({
    States = {
        Open = function(state)
            state:on('close', 'Closed')
            state:entry(function() print('opened') end)
        end,
        Closed = function(state)
            state:initial()

            state:entry(function() print('closed') end)
            state:exit(function() print('going to open') end)

            state:on('open', 'Open')

            state:substate({
                Idle = function(sub)
                    sub:on('start', 'Cooking')
                    sub:entry(function() print('idle') end)
                    sub:initial()
                end,

                Cooking = function(sub)
                    sub:entry(function() print('cooking now') end)
                    sub:exit(function() print('not cooking') end)
                    sub:on('stop', 'Idle')
                end
            })
        end
    }
})

X:input('start')
X:input('open')
```

This example prints the following output:

```
closed
idle
cooking now
not cooking
going to open
opened
```
