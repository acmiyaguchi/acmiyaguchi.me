---
layout: post
title: Running a sidecar container in Kubernetes and Airflow 1.15.x
date: 2021-09-09T15:55:00-08:00
category: Engineering
tags:
  - airflow
  - kubernetes
---

I've been updating an [Airflow
job](https://github.com/mozilla/telemetry-airflow/pull/1343) that runs a
[prio-processor](https://github.com/mozilla/prio-processor) container. The
`prio-processor` container implements a [privacy-preserving aggregation system
called Prio](https://crypto.stanford.edu/prio/) which uses zero-knowledge proofs
and multi-party compution to give strong guarantees on privacy and robustness.
The container implements a workflow that utilizes Google Cloud Storage buckets
for communicating between servers on different hosts.

I implemented the Airflow job on an ephemeral Kubernetes cluster. Airflow can
spin up Kubernetes cluster on Google Kubernetes Engine (GKE), in which the
`KubernetesPodOperator` executes jobs via docker containers. Setting up a
long-living cluster would be helpful to avoid the startup/shutdown overhead, but
setting up a cluster requires intervention from the folks in operations. This
setup sufficed for much of the development work, which had many iterations.

However, a new version of the `prio-processor` container required a MinIO
service to be online. Instead of interacting with Google Cloud Storage directly,
the container proxies all requests through a [MinIO
gateway](https://docs.min.io/docs/minio-gateway-for-s3.html). The proxy proved
to be difficult to implement with the KubernetesPodOperator on Airflow 1.15.x
because it requires two containers to communicate in the same pod.

The ideal solution is to have a long-lived cluster where the MinIO container is
made available to pods as a service. However, Airflow does not provide the
necessary primitives to enable services on an ephemeral cluster. In addition, it
has neigh impossible to use pod spec templates because Airflow developers
decided not to backport the functionality from 2.0.

I settled on using the
[`pod_mutation_hook`](https://airflow.apache.org/docs/apache-airflow/stable/kubernetes.html)
to modify all pod definitions globally. Pod mutation allows for some interesting
(and ultimately hacky) behavior. Here, I add two side-car containers to create a
Minio proxy that lives for the duration of the job.

1. Allow containers to share the same process namespace and ports. Sharing the
   process namespace allows one container to see the processes running in
   another container.
1. Add MinIO as a side-car container (available to other containers running on
   the same node)
1. Add a third "reaper" container that watches the process namespace for a
   certain program name, then kill the MinIO process.
1. Run the main script and execute `exec -a <name> sleep 10` to notify the
   reaper container.

```python
from copy import deepcopy

from kubernetes.client import models as k8s
from kubernetes.client.models import V1Container, V1Pod

def pod_mutation_hook(pod: V1Pod):
    """Modify all Kubernetes pod definitions when run with the pod operator.
    Changes to this function will require a cluster restart to pick up.
    Functionality here can be moved closer to the pod definition in Airflow 2.x.
    https://github.com/kubernetes-client/python/blob/master/kubernetes/docs/V1Pod.md
    """

    # Check that we're running a prio-processor job, and spin up a side-car
    # container for proxying gcs buckets. All other jobs will be unaffected.
    # This whole mutation would be unnecessary if there were a long-lived minio
    # service available to the pod's network.
    if pod.metadata.labels["job-kind"] == "prio-processor":
        pod.spec.share_process_namespace = True
        # there is only one container within the pod, so lets append a few more

        # Add a new container to the spec to run minio. We will run a gcs
        # gateway and proxy all traffic through it. This allows the container to
        # use the mc tool and s3a spark adapter and makes it cloud-provider
        # agnostic. See https://github.com/mozilla/prio-processor/pull/119 for
        # the reason behind the pinned image.
        minio_container = deepcopy(pod.spec.containers[0])
        minio_container.image = "minio/minio:RELEASE.2021-06-17T00-10-46Z"
        minio_container.args = ["gateway", "gcs", "$(PROJECT_ID)"]
        minio_container.name = "minio"
        pod.spec.containers.append(minio_container)

        # Search for a new process named `minio-done` and kill the minio
        # container above. This can be done using `exec -a minio-done sleep 10`
        # which will will create a process available in the shared namespace for
        # 10 seconds. We use a ubuntu image so we can utilize pidof and pkill.
        pkill_container = deepcopy(pod.spec.containers[0])
        pkill_container.image = "ubuntu:focal"
        pkill_container.args = [
            "bash",
            "-c",
            "until pidof minio-done; do sleep 1; done; pkill -SIGINT -f minio",
        ]
        pkill_container.name = "reaper"
        pod.spec.containers.append(pkill_container)
```

Implementation took a while since it required iterating on the idea in 10-20
minute cycles. The reaper process is required because the MinIO container would
continue to run forever, despite the main container exiting. Ultimately, I took
advantage that containers can share the same process namespace as a way to
communicate. A shared process namespace allows for a watchdog where the reaper
can run `pkill` once a particular process name appears globally. I had also
tried a file mount for communicating, but it was challenging to specify a shared
volume between containers.

The Airflow job required minimal code changes. I added a new `job-kind` label,
and the use of `exec` to create a named process that could be used to reap.

```python
def prio_processor_subdag(
    dag, default_args, gcp_conn_id, service_account, server_id, env_vars
):
    return SubDagOperator(
        subdag=kubernetes.container_subdag(
            parent_dag_name=dag.dag_id,
            child_dag_name=f"processor_{server_id}",
            default_args=default_args,
            gcp_conn_id=gcp_conn_id,
            service_account=service_account,
            server_id=server_id,
            arguments=["bash", "-c", "bin/process; exec -a minio-done sleep 10"],
            env_vars=env_vars,
        ),
        task_id=f"processor_{server_id}",
        dag=dag,
    )
```

This was an interesting pattern to explore, but not the best way for the job to
go into production due to the number of moving parts. Overall though, this has
been a great primer into some of the finer details of running Kubernetes (and
Airflow) in obscure, unintended ways.

<img src="assets/2021-09-09/vespa-sidecar.png" alt="a motorcycle sidecar">
<i><a href="https://commons.wikimedia.org/wiki/File:Vespa_sidecar.png">
    <b>Figured:</b> an actual motorcycle sidecar, from wikipedia commons</a></i>
