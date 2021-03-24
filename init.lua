local defaults
defaults = function(Object, Props)
  for i, v in pairs(Props) do
    if nil == Object[i] then
      Object[i] = v
    end
  end
end
local Machine = nil
local State
do
  local _class_0
  local _base_0 = {
    init = function(self, ...)
      self:exit(function(...)
        if self.Substate then
          return self.Substate:exitCurrent(...)
        end
      end)
      self:Runner(...)
      return self:entry(function(V, ...)
        do
          local S = self.Substate
          if S then
            do
              local Initial = S.InitialState
              if Initial then
                return S:transition(Initial, ...)
              end
            end
          end
        end
      end)
    end,
    setParent = function(self, Machine)
      self.Machine = Machine
      self.Data = self.Machine.Data
    end,
    initial = function(self)
      return self.Machine:initial(self)
    end,
    substate = function(self, States)
      self.States = States
      self.Substate = Machine({
        States = self.States,
        Data = self.Data,
        Submachine = true
      })
    end,
    entry = function(self, Fn)
      return table.insert(self.Hooks, {
        onEnter = Fn
      })
    end,
    exit = function(self, Fn)
      return table.insert(self.Hooks, {
        onExit = Fn
      })
    end,
    onEnter = function(self, Prev, ...)
      if self.Active then
        return 
      end
      if Prev == self then
        return 
      end
      self.Active = true
      local _list_0 = self.Hooks
      for _index_0 = 1, #_list_0 do
        local H = _list_0[_index_0]
        if H.onEnter then
          H.onEnter(self, Prev, ...)
        end
      end
    end,
    onExit = function(self, Next, ...)
      if not (self.Active) then
        return 
      end
      if Next == self then
        return 
      end
      self.Active = false
      local _list_0 = self.Hooks
      for _index_0 = 1, #_list_0 do
        local H = _list_0[_index_0]
        if H.onExit then
          H.onExit(self, ...)
        end
      end
    end,
    on = function(self, Event, GuardOrState, State)
      assert(GuardOrState, ':on expects a guard or a state!')
      local T = {
        Name = Event,
        State = GuardOrState
      }
      if 'function' == type(GuardOrState) then
        assert(State, ':on expects a state after a guard!')
        T.Guard = GuardOrState
        T.State = State
      end
      return table.insert(self.Hooks, T)
    end,
    input = function(self, Event, ...)
      local _list_0 = self.Hooks
      for _index_0 = 1, #_list_0 do
        local H = _list_0[_index_0]
        if H.Name == Event then
          if H.Guard then
            if H.Guard(self) then
              return self:transition(H.State, ...)
            end
          else
            return self:transition(H.State, ...)
          end
        end
      end
      if self.Substate then
        local Change = self.Substate:input(Event, ...)
        if Change then
          return 
        end
      end
    end,
    transition = function(self, NewState, ...)
      return self.Machine:transition(NewState)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, Name, Runner)
      self.Name, self.Runner = Name, Runner
      self.Hooks = { }
    end,
    __base = _base_0,
    __name = "State"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  State = _class_0
end
do
  local _class_0
  local _base_0 = {
    addState = function(self, S, ...)
      assert(not self.States[S.Name], 'cannot have duplicate states!')
      self.States[S.Name] = S
      do
        local _with_0 = S
        _with_0:setParent(self)
        _with_0:init(...)
        return _with_0
      end
    end,
    input = function(self, Event, ...)
      assert(type(Event) == 'string', ':input expects a state!')
      return self.State:input(Event, ...)
    end,
    exitCurrent = function(self, New)
      do
        local Old = self.State
        self.State = nil
        if Old then
          Old:onExit(New)
        end
        return Old
      end
    end,
    transition = function(self, StateName, Enter, ...)
      if Enter == nil then
        Enter = true
      end
      local S = self.States[StateName]
      assert(S, ':transition couldnt find state ' .. StateName)
      local Current = self:exitCurrent(S)
      do
        local _with_0 = S
        self.State = S
        if Enter then
          _with_0:onEnter(Current, ...)
        end
        return _with_0
      end
    end,
    initial = function(self, S)
      self.InitialState = S.Name
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, Config)
      if Config == nil then
        Config = { }
      end
      defaults(Config, {
        States = { },
        Data = { }
      })
      self.States = { }
      self.Data = Config.Data
      self.Root = not Config.Submachine
      for Name, Runner in pairs(Config.States) do
        self:addState(State(Name, Runner))
      end
      assert(self.InitialState, 'No state declared as default!')
      if not (Config.Submachine) then
        return self:transition(self.InitialState, true)
      end
    end,
    __base = _base_0,
    __name = "Machine"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Machine = _class_0
  return _class_0
end
