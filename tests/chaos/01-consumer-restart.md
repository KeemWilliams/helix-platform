# Staging Chaos Experiment: Consumer Restart

## Objective

Verify that the platform can recover from a sudden loss of orchestrator consumer pods (n8n/LangGraph) without dropping webhook events or entering an unrecoverable state.
**Expected SLO Impact:** Max queue processing delay of < 5 minutes. Zero dropped events.

## Preconditions

- Staging environment is healthy (`kubectl -n platform get pods` shows all Running).
- Queue depth is currently low/stable.
- Owner @platform-owner is actively monitoring the test.

## Execution Steps

### 1. Establish Baseline Load

Start a simulated load of 5 webhook events per second.

```bash
./tests/smoke/load-gen.sh --rate 5 --duration 300
```

### 2. Inject Failure (Pod Delete)

Simulate a node loss or OOMKill by aggressively terminating the consumer pods halfway through the load test.

```bash
kubectl -n platform delete pods -l 'app in (n8n, langgraph)' --grace-period=0 --force
```

### 3. Monitor Recovery

Observe the queue depth metric and consumer restart alerts.

```bash
# Watch queue depth climb, then drain
watch -n 5 "kubectl -n monitoring exec deploy/prometheus -- prometheus-query 'sum(nats_stream_msgs_pending)'"

# Confirm new pods spin up
kubectl -n platform get pods -l 'app in (n8n, langgraph)' -w
```

## Success Criteria

- [ ] ConsumerRestartSpike alert fires in AlertManager (validation of observability).
- [ ] QueueBacklogHigh alert fires if drain takes > 5m (validation of SLA).
- [ ] All injected events are eventually processed successfully (verify db counts).
- [ ] Queue drains back to baseline within 5 minutes of pod recovery.

## Rollback Plan

If consumer pods fail to recover or enter CrashLoopBackOff:

1. Halt the load generator.
2. Manually restart the devtron application sync:

   ```bash
   kubectl -n argocd patch application platform-manifests --type merge -p '{"operation": {"sync": {}}}'
   ```

3. If database saturation occurred, restart PgBouncer:

   ```bash
   kubectl -n platform rollout restart deploy/pgbouncer
   ```

4. Page the on-call SRE if staging remains degraded for > 15m.
