-- machine.moon
-- SFZILabs 2021

defaults = (Object, Props) ->
    Object[i] = v for i, v in pairs Props when nil == Object[i]

Machine = nil

class State
    new: (@Name, @Runner) => @Hooks = {}
    init: (...) =>
        @exit (...) ->
            if @Substate
                @Substate\exitCurrent ...

        @Runner ...

        @entry (V,...) ->
            if S = @Substate
                if Initial = S.InitialState
                    S\transition Initial, ...

    setParent: (@Machine) => @Data = @Machine.Data
    
    initial: => @Machine\initial @

    substate: (@States) =>
        @Substate = Machine States: @States, Data: @Data, Submachine: true

    entry: (Fn) => table.insert @Hooks, onEnter: Fn
    exit: (Fn) => table.insert @Hooks, onExit: Fn

    onEnter: (Prev, ...) =>
        return if @Active
        return if Prev == @
        @Active = true
        for H in *@Hooks
            if H.onEnter
                H.onEnter @, Prev, ...

    onExit: (Next, ...) =>
        return unless @Active
        return if Next == @
        @Active = false
        for H in *@Hooks
            if H.onExit
                H.onExit @, ...

    on: (Event, GuardOrState, State) =>
        assert GuardOrState, ':on expects a guard or a state!'
        T = Name: Event, State: GuardOrState
        if 'function' == type GuardOrState
            assert State, ':on expects a state after a guard!'
            T.Guard = GuardOrState
            T.State = State

        table.insert @Hooks, T

    input: (Event, ...) =>
        for H in *@Hooks
            if H.Name == Event
                if H.Guard
                    if H.Guard @
                        return @transition H.State, ...
                else return @transition H.State, ...

        if @Substate
            Change = @Substate\input Event, ...
            return if Change

        -- error "Unhandled event #{Event} in #{@Name}"

    transition: (NewState, ...) =>
        @Machine\transition NewState

class Machine
    new: (Config = {}) =>
        defaults Config, States: {}, Data: {}
        @States = {}
        
        @Data = Config.Data

        @Root = not Config.Submachine
        for Name, Runner in pairs Config.States
            @addState State Name, Runner

        assert @InitialState, 'No state declared as default!'
        @transition @InitialState unless Config.Submachine

    addState: (S, ...) =>
        assert not @States[S.Name], 'cannot have duplicate states!'
        @States[S.Name] = S
        with S
            \setParent @
            \init ...

    input: (Event, ...) =>
        assert type(Event) == 'string', ':input expects a state!'
        @State\input Event, ...

    exitCurrent: (New) => -- New -> Old
        with Old = @State
            @State = nil
            \onExit New if Old

    transition: (StateName, ...) =>
        S = @States[StateName]
        assert S, ':transition couldnt find state '..StateName
        return if S == @State

        Current = @exitCurrent S
        
        with S
            @State = S
            \onEnter Current, ...

    initial: (S) => @InitialState = S.Name
