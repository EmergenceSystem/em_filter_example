-module(em_filter_example_app).
-behaviour(application).
-behaviour(cowboy_handler).

%% Application callbacks
-export([start/2, stop/1]).

%% Cowboy handler callbacks
-export([init/2, terminate/3]).

%% Application behavior
start(_StartType, _StartArgs) ->
    {ok, Port} = em_filter:find_port(),
    FilterUrl = lists:concat(["http://localhost:", integer_to_list(Port), "/query"]),
    io:format("Filter registered: ~s~n", [FilterUrl]),
    em_filter_sup:start_link(random_filter, ?MODULE, Port).

stop(_State) ->
    ok.

%% Cowboy handler behavior
init(Req0, State) ->
    {ok, Body, Req} = cowboy_req:read_body(Req0),
    io:format("Received body: ~p~n", [Body]),
    EmbryoList = generate_embryo_list(Body),
    Response = #{embryo_list => EmbryoList},
    EncodedResponse = jsone:encode(Response),
    Req2 = cowboy_req:reply(200,
        #{<<"content-type">> => <<"application/json">>},
        EncodedResponse,
        Req
    ),
    {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
    ok.

generate_embryo_list(JsonBinary) ->
    io:format("Call ~p~n", [JsonBinary]),
    try jsone:decode(JsonBinary) of
        SearchMap when is_map(SearchMap) ->
            % Extraire spécifiquement la valeur de la clé "value"
            Value = case maps:get(<<"value">>, SearchMap, undefined) of
                undefined -> "";
                ValBin -> binary_to_list(ValBin)
            end,
            io:format("Search value: ~p~n", [Value]),
            generate_random_embryos(Value, 10, []);
        _ ->
            []
    catch
        _:Error ->
            io:format("Error decoding JSON: ~p~n", [Error]),
            []
    end.

generate_random_embryos(_Value, 0, Acc) ->
    lists:reverse(Acc);
generate_random_embryos(Value, Count, Acc) ->
    % Génération d'un nombre aléatoire entre 1 et 100
    RandomNumber = rand:uniform(100),
    RandomNumberStr = integer_to_list(RandomNumber),
    
    NewAcc = case string_contains(RandomNumberStr, Value) orelse string_contains(Value, RandomNumberStr) of
        true ->
            Url = lists:concat(["http://example/", RandomNumberStr]),
            Embryo = #{
                properties => #{
                    <<"url">> => list_to_binary(Url),
                    <<"resume">> => list_to_binary(RandomNumberStr)
                }
            },
            io:format("Match found: ~p~n", [RandomNumberStr]),
            [Embryo | Acc];
        false ->
            Acc
    end,
    
    generate_random_embryos(Value, Count - 1, NewAcc).

% Fonction pour vérifier si une chaîne en contient une autre
string_contains(String, SubString) ->
    case {String, SubString} of
        {_, ""} -> false;  % Si la sous-chaîne est vide, renvoyer false
        _ -> string:str(String, SubString) > 0
    end.
