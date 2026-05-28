%%%-------------------------------------------------------------------
%%% @doc em_filter_example OTP application.
%%%
%%% Starts the em_filter_example_sup supervisor (which owns the
%%% em_filter_example_server gen_server), then wires the em_pop
%%% gossip node and the Cowboy HTTP listener via em_filter_http.
%%%
%%% Configuration keys (application env):
%%%   pop_port   — em_pop UDP gossip port  (default 9200)
%%%   query_port — Cowboy HTTP query port  (default 9201)
%%%   pop_seeds  — list of {Host, Port} seed peers (default [])
%%% @end
%%%-------------------------------------------------------------------
-module(em_filter_example_app).
-behaviour(application).

-export([start/2, stop/1]).

%%====================================================================
%% Application callbacks
%%====================================================================

start(_StartType, _StartArgs) ->
    case em_filter_example_sup:start_link() of
        {ok, Pid} ->
            ok = start_pop_and_http(),
            {ok, Pid};
        Error ->
            Error
    end.

stop(_State) ->
    catch cowboy:stop_listener(em_filter_example_query_listener),
    catch em_pop_sup:stop_node(em_filter_example),
    ok.

%%====================================================================
%% Internal
%%====================================================================

start_pop_and_http() ->
    PopPort   = application:get_env(em_filter_example, pop_port,   9200),
    QueryPort = application:get_env(em_filter_example, query_port, 9201),
    Seeds     = application:get_env(em_filter_example, pop_seeds,  []),
    Vec = em_filter_vec:from_capabilities(
              [<<"search">>, <<"erlang">>, <<"example">>]),
    catch em_pop_sup:stop_node(em_filter_example),
    catch cowboy:stop_listener(em_filter_example_query_listener),
    {ok, PopPid} = em_pop_sup:start_node(em_filter_example, #{
        port            => PopPort,
        query_port      => QueryPort,
        vector          => Vec,
        max_peers       => 100,
        gossip_interval => 5_000
    }),
    lists:foreach(
        fun({H, P}) -> catch em_pop_node:add_peer(PopPid, H, P) end,
        Seeds),
    Dispatch = cowboy_router:compile([
        {'_', [{"/agent/query", em_filter_http,
                #{server => em_filter_example_server}}]}
    ]),
    {ok, _} = cowboy:start_clear(em_filter_example_query_listener,
                                  [{port, QueryPort}],
                                  #{env => #{dispatch => Dispatch}}),
    logger:notice("[em_filter_example] gossip port ~w  query port ~w",
                  [PopPort, QueryPort]),
    ok.
