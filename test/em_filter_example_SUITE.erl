-module(em_filter_example_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([digit_query_returns_items/1,
         no_match_query_returns_empty/1,
         bad_json_returns_400/1]).

all() ->
    [digit_query_returns_items,
     no_match_query_returns_empty,
     bad_json_returns_400].

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(em_filter_example),
    Config.

end_per_suite(_Config) ->
    application:stop(em_filter_example),
    ok.

%%--------------------------------------------------------------------
%% digit_query_returns_items
%%
%% POST {"query":"1"} — expect HTTP 200 and at least one result
%% whose label contains "1" (matches 1, 10, 11, 12 … 19).
%%--------------------------------------------------------------------
digit_query_returns_items(_Config) ->
    Body = <<"{\"query\":\"1\"}">>,
    {ok, {{_, 200, _}, _, RespBody}} =
        httpc:request(post,
                      {"http://localhost:19201/agent/query",
                       [], "application/json",
                       binary_to_list(Body)},
                      [{timeout, 5000}], [{body_format, binary}]),
    #{<<"results">> := Items} = json:decode(RespBody),
    ?assert(is_list(Items)),
    ?assert(length(Items) > 0),
    HasOne = lists:any(fun(I) ->
        Label = maps:get(<<"label">>, I, <<>>),
        binary:match(Label, <<"1">>) =/= nomatch
    end, Items),
    ?assert(HasOne).

%%--------------------------------------------------------------------
%% no_match_query_returns_empty
%%
%% POST a query with no digits — none of the labels (1-20) match.
%%--------------------------------------------------------------------
no_match_query_returns_empty(_Config) ->
    Body = <<"{\"query\":\"zzz\"}">>,
    {ok, {{_, 200, _}, _, RespBody}} =
        httpc:request(post,
                      {"http://localhost:19201/agent/query",
                       [], "application/json",
                       binary_to_list(Body)},
                      [{timeout, 5000}], [{body_format, binary}]),
    #{<<"results">> := Items} = json:decode(RespBody),
    ?assertEqual([], Items).

%%--------------------------------------------------------------------
%% bad_json_returns_400
%%
%% POST invalid JSON — expect HTTP 400.
%%--------------------------------------------------------------------
bad_json_returns_400(_Config) ->
    {ok, {{_, 400, _}, _, _}} =
        httpc:request(post,
                      {"http://localhost:19201/agent/query",
                       [], "application/json",
                       "not valid json at all"},
                      [{timeout, 5000}], []).
