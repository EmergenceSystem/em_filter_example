-module(em_filter_example_app).
-behaviour(application).

-export([start/2, stop/1]).
-export([handle/1]).

%%--------------------------------------------------------------------
%% Application behaviour
%%--------------------------------------------------------------------

start(_StartType, _StartArgs) ->
    io:format("[em_filter_example] Starting random filter~n"),
    em_filter:start_filter(random_filter, ?MODULE).

stop(_State) ->
    em_filter:stop_filter(random_filter).

%%--------------------------------------------------------------------
%% Filter handler
%%--------------------------------------------------------------------

handle(Body) when is_binary(Body) ->
    Value      = extract_value(Body),
    generate_random_embryos(binary_to_list(Value), 10, []);
handle(Other) ->
    io:format("[em_filter_example] >>> Invalid body: ~p~n", [Other]),
    [].

%%--------------------------------------------------------------------
%% Internal helpers
%%--------------------------------------------------------------------

%% Extracts the search value from the body.
%% If the body is a JSON object, looks for "value" or "query" keys.
%% Otherwise treats the raw binary as the value directly.
-spec extract_value(binary()) -> binary().
extract_value(Body) ->
    try json:decode(Body) of
        Map when is_map(Map) ->
            case maps:get(<<"value">>, Map, maps:get(<<"query">>, Map, Body)) of
                V when is_binary(V) -> V;
                _                   -> Body
            end;
        %% Scalar JSON value (number, string…) — use the raw body as-is.
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

%% Returns true if SubString is a non-empty substring of String.
string_contains(_String, "")       -> false;
string_contains(String, SubString) -> string:str(String, SubString) > 0.
