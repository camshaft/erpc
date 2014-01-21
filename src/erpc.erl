-module(erpc).

-export([start_link/3]).
-export([call/4]).
-export([call_async/6]).

start_link(Name, Interface, Options) ->
  %% TODO supervise interfaces
  %% TODO store pid for interface instance
  case Interface:start_link(Options) of
    {ok, Pid} ->
      set_pid(Name, Pid, Interface),
      {ok, Pid};
    ok ->
      set_pid(Name, Interface),
      {ok, Name}
  end.

call(Name, Module, Function, Arguments) ->
  Ref = erlang:make_ref(),
  ok = call_async(Name, Module, Function, Arguments, self(), Ref),
  receive
    {Status, Value, Ref} ->
      {Status, Value}
  end.

call_async(Name, Module, Function, Arguments, Sender, Ref) ->
  case get_pid(Name) of
    {ok, Pid, Interface} ->
      Interface:call(Pid, Module, Function, Arguments, Sender, Ref);
    {ok, Interface} ->
      Interface:call(Module, Function, Arguments, Sender, Ref);
    _ ->
      {error, {noproc, Name}}
  end.

%% TODO store in ets table
get_pid(Name) ->
  get(Name).

%% TODO store in ets table
set_pid(Name, Pid, Interface) ->
  put(Name, {ok, Pid, Interface}).
set_pid(Name, Interface) ->
  put(Name, {ok, Interface}).
