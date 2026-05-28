%%%-------------------------------------------------------------------
%%% @doc em_filter_example handler — digit-match number filter.
%%%
%%% Contains twenty items, one for each integer 1-20.
%%% Each item has a label (the number as a binary string) and a value
%%% describing one arithmetic property. No URL field: results render
%%% as generic cards in emquest.
%%%
%%% query/1 scores items by counting how many times the query binary
%%% appears as a substring of the item label, plus individual byte
%%% matches. Items with score 0 are excluded.
%%%
%%% Example: query <<"1">>
%%%   matches: 1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(em_filter_example_handler).
-export([query/1, handle/2]).

%%====================================================================
%% Public API
%%====================================================================

%% @doc Return scored items whose label contains the query string.
-spec query(binary()) -> [map()].
query(<<>>) -> [];
query(QueryBinary) ->
    Q      = string:trim(binary_to_list(QueryBinary)),
    QB     = list_to_binary(Q),
    Scored = [{digit_score(QB, I), I} || I <- items()],
    Sorted = lists:sort(fun({A, _}, {B, _}) -> A > B end, Scored),
    [I#{<<"score">> => S} || {S, I} <- Sorted, S > 0].

%% @doc em_filter handle/2 contract (stateless).
-spec handle(binary(), term()) -> {binary(), term()}.
handle(QueryBinary, Memory) ->
    Items  = query(QueryBinary),
    Result = iolist_to_binary(json:encode(Items)),
    {Result, Memory}.

%%====================================================================
%% Corpus — integers 1-20, ASCII-only values
%%====================================================================

-spec items() -> [map()].
items() ->
    [
        #{<<"label">> => <<"1">>,
          <<"value">> => <<"Multiplicative identity: n * 1 = n">>},
        #{<<"label">> => <<"2">>,
          <<"value">> => <<"Smallest prime; only even prime number">>},
        #{<<"label">> => <<"3">>,
          <<"value">> => <<"First odd prime; triangular number (1+2=3)">>},
        #{<<"label">> => <<"4">>,
          <<"value">> => <<"2^2 — smallest composite number">>},
        #{<<"label">> => <<"5">>,
          <<"value">> => <<"Prime; sum of first two primes (2 + 3)">>},
        #{<<"label">> => <<"6">>,
          <<"value">> => <<"First perfect number: 1 + 2 + 3 = 6">>},
        #{<<"label">> => <<"7">>,
          <<"value">> => <<"Prime; number of days in a week">>},
        #{<<"label">> => <<"8">>,
          <<"value">> => <<"2^3 — first cube greater than 1">>},
        #{<<"label">> => <<"9">>,
          <<"value">> => <<"3^2 — smallest odd composite number">>},
        #{<<"label">> => <<"10">>,
          <<"value">> => <<"Base of the decimal system; 2 * 5">>},
        #{<<"label">> => <<"11">>,
          <<"value">> => <<"Smallest two-digit prime; repunit palindrome">>},
        #{<<"label">> => <<"12">>,
          <<"value">> => <<"Highly composite: divisors 1,2,3,4,6,12">>},
        #{<<"label">> => <<"13">>,
          <<"value">> => <<"Prime; emirp (13 reversed = 31, also prime)">>},
        #{<<"label">> => <<"14">>,
          <<"value">> => <<"2 * 7; smallest even number that is not a sum of two primes">>},
        #{<<"label">> => <<"15">>,
          <<"value">> => <<"3 * 5; triangular number (1+2+3+4+5)">>},
        #{<<"label">> => <<"16">>,
          <<"value">> => <<"2^4 — base of hexadecimal counting">>},
        #{<<"label">> => <<"17">>,
          <<"value">> => <<"Prime; Fermat prime (2^(2^2) + 1)">>},
        #{<<"label">> => <<"18">>,
          <<"value">> => <<"2 * 3^2; digit sum always divisible by 9">>},
        #{<<"label">> => <<"19">>,
          <<"value">> => <<"Prime; Cuban prime">>},
        #{<<"label">> => <<"20">>,
          <<"value">> => <<"4 * 5; base of vigesimal (Mayan) numeral system">>}
    ].

%%====================================================================
%% Scoring — binary substring counting
%%====================================================================

%% score = 3 x full-query occurrences in label + 1 x per-byte occurrences
-spec digit_score(binary(), map()) -> non_neg_integer().
digit_score(Q, Item) ->
    Label = maps:get(<<"label">>, Item, <<>>),
    Full  = count_bin(Q, Label),
    Chars = lists:sum([count_bin(<<C>>, Label) || <<C>> <= Q]),
    3 * Full + Chars.

%% Count non-overlapping occurrences of Pat in Bin.
-spec count_bin(binary(), binary()) -> non_neg_integer().
count_bin(_Pat, <<>>) -> 0;
count_bin(Pat, Bin) ->
    case binary:match(Bin, Pat) of
        nomatch ->
            0;
        {Start, Len} ->
            RestStart = Start + Len,
            Rest = binary:part(Bin, RestStart, byte_size(Bin) - RestStart),
            1 + count_bin(Pat, Rest)
    end.
