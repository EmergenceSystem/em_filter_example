%%%-------------------------------------------------------------------
%%% @doc em_filter_example supervisor.
%%%
%%% Supervises the em_filter_example_server gen_server.
%%% @end
%%%-------------------------------------------------------------------
-module(em_filter_example_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ServerSpec = #{
        id      => em_filter_example_server,
        start   => {em_filter_example_server, start_link, []},
        restart => permanent,
        type    => worker
    },
    {ok, {#{strategy => one_for_one, intensity => 3, period => 10},
          [ServerSpec]}}.
