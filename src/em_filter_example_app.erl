%%%-------------------------------------------------------------------
%%% @doc Example/test agent demonstrating the em_filter agent API.
%%%
%%% Generates random embryos that contain or are contained by the
%%% query value. Tracks how many queries it has handled and
%%% accumulates the history of values seen across queries.
%%%
%%% === Capability cascade ===
%%%
%%%   base_capabilities/0 extends em_filter:base_capabilities().
%%%
%%% Handler contract: handle/2 (Body, Memory) -> {Result, NewMemory}.
%%% Memory schema: #{count => integer(), values => [binary()]}.
%%% @end
%%%-------------------------------------------------------------------
-module(em_filter_example_app).
-behaviour(application).

-export([start/2, stop/1]).
-export([handle/2, base_capabilities/0]).

%%====================================================================
%% Capability cascade
%%====================================================================

-spec base_capabilities() -> [binary()].
base_capabilities() ->
    em_filter:base_capabilities() ++ [<<"example">>, <<"test">>, <<"random">>].

%%====================================================================
%% Application behaviour
%%====================================================================

start(_StartType, _StartArgs) ->
    io:format("[em_filter_example] Starting example agent~n"),
    em_filter:start_agent(random_filter, ?MODULE, #{
        capabilities => base_capabilities(),
        memory       => ets
    }),
    {ok, self()}.

stop(_State) ->
    em_filter:stop_agent(random_filter).

%%====================================================================
%% Agent handler
%%====================================================================

handle(Body, Memory) when is_binary(Body) ->
    Value  = extract_value(Body),
    Count  = maps:get(count,  Memory, 0),
    Values = maps:get(values, Memory, []),
    io:format("[em_filter_example] query #~p: ~p~n", [Count + 1, Value]),
    Embryos   = generate_random_embryos(binary_to_list(Value), 10, []),
    NewMemory = Memory#{
        count  => Count + 1,
        values => [Value | Values]
    },
    {Embryos, NewMemory};
handle(Other, Memory) ->
    io:format("[em_filter_example] Invalid body: ~p~n", [Other]),
    {[], Memory}.

%%====================================================================
%% Internal helpers
%%====================================================================

-spec extract_value(binary()) -> binary().
extract_value(Body) ->
    try json:decode(Body) of
        Map when is_map(Map) ->
            case maps:get(<<"value">>, Map, maps:get(<<"query">>, Map, Body)) of
                V when is_binary(V) -> V;
                _                   -> Body
            end;
        _ ->
            Body
    catch
        _:_ -> Body
    end.

generate_random_embryos(_Value, 0, Acc) ->
    lists:reverse(Acc);
generate_random_embryos(Value, Count, Acc) ->
    Num    = integer_to_list(rand:uniform(100)),
    NewAcc = case string_contains(Num, Value) orelse string_contains(Value, Num) of
        true ->
            Url    = list_to_binary("http://example/" ++ Num),
            Embryo = #{
                <<"properties">> => #{
                    <<"url">>    => Url,
                    <<"resume">> => list_to_binary(Num)
                }
            },
            [Embryo | Acc];
        false ->
            Acc
    end,
    generate_random_embryos(Value, Count - 1, NewAcc).

string_contains(_String, "")       -> false;
string_contains(String, SubString) -> string:str(String, SubString) > 0.
