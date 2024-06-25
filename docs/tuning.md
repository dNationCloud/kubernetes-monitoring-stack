# Tuning

This page contains recommended parameters to set for the Thanos components to improve performance in terms of query time.
The following parameters have already been incorporated into the default HELM chart values,
and therefore are already included in the default Kubernetes monitoring installation.

## Query Frontend

```
queryFrontend:
  extraFlags:
  - --query-range.split-interval=12h 
  - --query-frontend.log-queries-longer-than=10s
  - --query-frontend.compress-responses
  - |-
    --query-range.response-cache-config="config":
      "max_size": "500MB"
      "max_size_items": 0
      "validity": 0s
    "type": "in-memory"
```
* Notes on the parameters for query frontend:
  * `query-range.split-interval` - splits a long query into multiple short queries to improve query time. Default=24h.
  * `query-frontend.log-queries-longer-than=10s` - log queries running longer than 10s, which helps to identify new querries, which should be improved)
  * `query-frontend.compress-responses` - compress HTTP responses, helps with query time
  * `query-range.response-cache-config` - cahcing is common solution to speed up response time(https://zapier.com/blog/five-recommendations-when-running-thanos-and-prometheus/)

## Compactor

```
compactor:
  retentionResolutionRaw: 2d
  retentionResolution5m: 10d
  retentionResolution1h: 15d
  extraFlags:
  - --compact.concurrency=3
  - --downsample.concurrency=3
```

* Notes on the parameters for compactor:
  * `retentionResolutionRaw` - how long to retain raw samples in bucket. Minimum is two days, because just after 40 hours 5m downsampled data are created.
  * `retentionResolution5m` - how long to retain samples of resolution 1 (5 minutes) in bucket. Setting this to 0d will retain samples of this resolution forever. One hour downsampled data are created only after 10 days, so this is minimum if you want also 1h downsampled data.
  * `retentionResolution1h` -  how long to retain samples of resolution 2 hour) in bucket.
  * `delete-delay` - make sure you have set this parameter. It is time before a block marked for deletion is deleted from bucket. Note that deleting blocks immediately can cause query failures, if store gateway still has the block loaded, or compactor is ignoring the deletion because it's compacting the block at the same time. Default=48h.
  * `compact.concurrency` - number of goroutines to use when compacting groups(https://zapier.com/blog/five-recommendations-when-running-thanos-and-prometheus/). Default=1.
  * `downsample.concurrency` - number of goroutines to use when downsampling block(https://zapier.com/blog/five-recommendations-when-running-thanos-and-prometheus/). Default=1.

## Query

```
query:
  extraFlags:
  - --query.auto-downsampling
  - --query.replica-label=prometheus_replica
```

* Notes on the parameters for query:
  * `query.auto-downsampling` - enable automatic adjustment (step / 5) to what source of data should be used in store gateways if no `max_source_resolution` param is specified. Default step for range queries is equal to 1s and it is only used when step is not set in UI. Can be changed by setting `--query.default-step` parameter. Hovewer, when you are using **Grafana** as your UI, the step is taken from `min_step`. The preferred options is to set HTTP URL/FORM parameter `max_source_resolution` to `auto`, which selects downsample resolution automatically based on the query.
  * `query.replica-label` - labels to treat as a replica indicator along which data is deduplicated.
