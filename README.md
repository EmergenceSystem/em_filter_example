# em_filter_example

A minimal [em_filter](https://github.com/EmergenceSystem/em_filter) agent — the
smallest complete example of a filter that joins the Emergence mesh and answers
queries.

The handler is a tiny digit-match number filter: it holds the integers 1-20
(each with one arithmetic fact) and returns the ones whose label matches the
query, as [Embryo](https://github.com/EmergenceSystem/Embryo) results. Swap the
handler for anything that returns a result list and you have your own agent.

## How it fits the network

On start (`em_filter_example_app`) the agent:

1. starts an **em_pop gossip node** (`pop_port`, default 9200) and announces a
   capability vector, so `em_disco` / Emquest discover it;
2. serves **`POST /agent/query`** (`query_port`, default 9201) via
   `em_filter_http`, which calls the handler and returns
   `{"results": [...], "signer_id": "...", "signature": "..."}`.

Since `em_filter` 1.4 every response is **signed** with the node's ed25519
identity, using a keypair that is created and persisted automatically on first
run. The Emergence mesh runs with `require_signatures = true`, so an agent built
on an older `em_filter` that does not sign is dropped. This example therefore
pins `em_filter` **1.4.2**.

## Run it locally

Prerequisites: an `em_disco` seed and an `Emquest` gateway running locally
(see their READMEs). Then:

    rebar3 shell

With the default `config/sys.config` the agent seeds the local disco at
`localhost:9100` and binds its query port on `9201`. Issue a query through
Emquest (for example `1`) and the matching numbers appear as result cards,
served by this agent and discovered purely through gossip.

## Configuration (`config/sys.config`)

| Key          | Default                   | Description                           |
|--------------|---------------------------|---------------------------------------|
| `pop_port`   | `9200`                    | em_pop gossip port                    |
| `query_port` | `9201`                    | HTTP port serving `POST /agent/query` |
| `pop_seeds`  | `[{"localhost", 9100}]`   | bootstrap gossip peers                |

## Where to go next

- [em_filter](https://github.com/EmergenceSystem/em_filter) — the agent API and HTML helpers.
- [Emquest](https://github.com/EmergenceSystem/Emquest) — the web gateway / query interface.
- [em_disco](https://github.com/EmergenceSystem/em_disco) — the discovery / bootstrap seed.
