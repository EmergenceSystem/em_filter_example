%%%-------------------------------------------------------------------
%%% @doc em_filter_example handler — keyword-scored semantic search.
%%%
%%% Contains fifteen hardcoded articles across three topics:
%%%   - Erlang / OTP / BEAM runtime
%%%   - EmergenceSystem project (emquest, em_filter, em_pop, em_disco)
%%%   - Semantic search algorithms (vector, cosine, similarity)
%%%
%%% query/1 scores items by keyword match and returns those with
%%% score > 0, sorted descending.
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(em_filter_example_handler).
-export([query/1, handle/2]).

%%====================================================================
%% Public API
%%====================================================================

%% @doc Return scored items matching QueryBinary, sorted best-first.
-spec query(binary()) -> [map()].
query(QueryBinary) ->
    Words  = tokenise(QueryBinary),
    Scored = [{score(Words, I), I} || I <- items()],
    Sorted = lists:sort(fun({A, _}, {B, _}) -> A > B end, Scored),
    [I#{<<"score">> => S} || {S, I} <- Sorted, S > 0].

%% @doc em_filter handle/2 contract (Memory is stateless for this handler).
-spec handle(binary(), term()) -> {binary(), term()}.
handle(QueryBinary, Memory) ->
    Items  = query(QueryBinary),
    Result = iolist_to_binary(json:encode(Items)),
    {Result, Memory}.

%%====================================================================
%% Corpus
%%====================================================================

-spec items() -> [map()].
items() ->
    [
        %% ── Erlang / OTP / BEAM ─────────────────────────────────────
        #{<<"label">>  => <<"Erlang Programming Language">>,
          <<"url">>    => <<"https://www.erlang.org">>,
          <<"value">>  => <<"Concurrent, fault-tolerant functional "
                            "language for building scalable systems">>},

        #{<<"label">>  => <<"OTP Design Principles">>,
          <<"url">>    => <<"https://erlang.org/doc/design_principles/des_princ.html">>,
          <<"value">>  => <<"The Open Telecom Platform framework for "
                            "building robust distributed Erlang systems">>},

        #{<<"label">>  => <<"BEAM Virtual Machine">>,
          <<"url">>    => <<"https://erlang.org/doc/efficiency_guide/introduction.html">>,
          <<"value">>  => <<"Erlang runtime with preemptive scheduling "
                            "and per-process garbage collection">>},

        #{<<"label">>  => <<"Cowboy HTTP Server">>,
          <<"url">>    => <<"https://ninenines.eu/docs/en/cowboy/2.12/guide/">>,
          <<"value">>  => <<"Small and fast HTTP server for Erlang and "
                            "OTP applications, used by em_filter">>},

        #{<<"label">>  => <<"GenServer Behaviour — Erlang OTP">>,
          <<"url">>    => <<"https://erlang.org/doc/man/gen_server.html">>,
          <<"value">>  => <<"OTP generic server behaviour for building "
                            "client-server Erlang processes">>},

        %% ── EmergenceSystem project ──────────────────────────────────
        #{<<"label">>  => <<"EmergenceSystem GitHub">>,
          <<"url">>    => <<"https://github.com/EmergenceSystem">>,
          <<"value">>  => <<"Distributed semantic search platform using "
                            "population protocol gossip and Erlang OTP">>},

        #{<<"label">>  => <<"emquest — Semantic Search Interface">>,
          <<"url">>    => <<"https://github.com/EmergenceSystem/emquest">>,
          <<"value">>  => <<"Emquest semantic search dispatcher with SSE "
                            "streaming and LLM query expansion">>},

        #{<<"label">>  => <<"em_filter — Agent Framework">>,
          <<"url">>    => <<"https://github.com/EmergenceSystem/em_filter">>,
          <<"value">>  => <<"Erlang OTP framework for building em_pop-aware "
                            "semantic search agents and filters">>},

        #{<<"label">>  => <<"em_pop — Population Protocol">>,
          <<"url">>    => <<"https://github.com/EmergenceSystem/em_pop">>,
          <<"value">>  => <<"Gossip-based peer discovery for the "
                            "EmergenceSystem distributed search network">>},

        #{<<"label">>  => <<"em_disco — Super-Node">>,
          <<"url">>    => <<"https://github.com/EmergenceSystem/em_disco">>,
          <<"value">>  => <<"Bootstrap super-node for EmergenceSystem "
                            "peer discovery using em_pop gossip">>},

        %% ── Semantic search algorithms ───────────────────────────────
        #{<<"label">>  => <<"Semantic Search">>,
          <<"url">>    => <<"https://en.wikipedia.org/wiki/Semantic_search">>,
          <<"value">>  => <<"Search based on meaning rather than keywords, "
                            "using vector embeddings and similarity">>},

        #{<<"label">>  => <<"Vector Similarity Search">>,
          <<"url">>    => <<"https://en.wikipedia.org/wiki/Nearest_neighbor_search">>,
          <<"value">>  => <<"Finding nearest neighbours in high-dimensional "
                            "vector spaces for semantic matching">>},

        #{<<"label">>  => <<"Cosine Similarity">>,
          <<"url">>    => <<"https://en.wikipedia.org/wiki/Cosine_similarity">>,
          <<"value">>  => <<"Metric for measuring similarity between two "
                            "vectors based on the angle between them">>},

        #{<<"label">>  => <<"Word Embeddings">>,
          <<"url">>    => <<"https://en.wikipedia.org/wiki/Word_embedding">>,
          <<"value">>  => <<"Dense vector representations of words capturing "
                            "semantic meaning and relationships">>},

        #{<<"label">>  => <<"Information Retrieval">>,
          <<"url">>    => <<"https://en.wikipedia.org/wiki/Information_retrieval">>,
          <<"value">>  => <<"Finding documents matching an information need "
                            "from a collection using search and ranking">>}
    ].

%%====================================================================
%% Scoring
%%====================================================================

%% score = 2 × (words matching label) + 1 × (words matching value)
-spec score([string()], map()) -> non_neg_integer().
score(Words, Item) ->
    Label = string:lowercase(unicode:characters_to_list(
                maps:get(<<"label">>, Item, <<>>))),
    Value = string:lowercase(unicode:characters_to_list(
                maps:get(<<"value">>, Item, <<>>))),
    LabelHits = length([W || W <- Words,
                             string:find(Label, W) =/= nomatch]),
    ValueHits = length([W || W <- Words,
                             string:find(Value, W) =/= nomatch]),
    2 * LabelHits + ValueHits.

%% Tokenise: lowercase, split on whitespace, drop empties.
-spec tokenise(binary()) -> [string()].
tokenise(Bin) ->
    Lower = string:lowercase(unicode:characters_to_list(Bin)),
    [W || W <- string:lexemes(Lower, " \t\n\r,.;:!?"), W =/= ""].
