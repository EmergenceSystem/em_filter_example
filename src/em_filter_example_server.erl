%%%-------------------------------------------------------------------
%%% @doc em_filter_example gen_server.
%%%
%%% Registered as `em_filter_example_server'. Handles HTTP query
%%% requests from em_filter_http by delegating to
%%% em_filter_example_handler:query/1.
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(em_filter_example_server).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2,
         handle_info/2, terminate/2, code_change/3]).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    {ok, undefined}.

handle_call({http_query, Query}, _From, State) ->
    Reply = try
        Items  = em_filter_example_handler:query(Query),
        Result = iolist_to_binary(json:encode(Items)),
        {ok, Result}
    catch E:R ->
        logger:error("[em_filter_example] handler error ~p:~p", [E, R]),
        {error, handler_failed}
    end,
    {reply, Reply, State};
handle_call(_Req, _From, State) ->
    {reply, {error, unknown_call}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
