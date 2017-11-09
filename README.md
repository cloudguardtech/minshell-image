# minshell-image
![Docker Repository on Quay](https://quay.io/repository/cloudguardtech/min-shell/status "Docker Repository on Quay")

A minimum Alpine Container Image to work as a sidecar or initialization container for Kubernetes applications.

*Run a command with docker*

    $ docker run --rm cloudguardtech/min-shell ls -al

See `Dockerfile` to determine what has been added to the image.

**NOTE:** The image defaults to USER `app` and GROUP `app` and WORKDIR `/home/app`

There isn't very much magic here. Feel free to make your own minshell image with your vision for a minimum set of tools. If
`minshell-image` has enough for your work, please go ahead and use it!

## Use with Kubernetes

There are many times in the life of a Kubernetes DevOps developer or integrator where you need to perform some shell activity.
Ideally, you're using a minimal instance so you don't need to bloat your pod. The `min-shell` image attempts to stay small and
secure by leveraging alpine and adding as little as possible to remain useful.

*Typical uses include:*

* run a pre-initialization script to setup data before the main Pod containers start
* interact with Pod containers as a sidecar
* manage the lifecycle of Pods in a Kubernetes Job

### Example

In this example, you'll run a Kubernetes Job that will use curl to get read some data from the Kubernetes API and will then
update a semaphore file that will be picked up by another container who's job it is to clean up and exit.

This job pattern is useful when you want to use a container image without making any changes to perform anything outside of its
original design, but still need to do some manipulation or orchestration with it.

If you don't have a Kubernetes cluster available to you, go grab the latest minikube [here](https://github.com/kubernetes/minikube/releases)
and follow the instructions to install it.

To run minikube is simple:

    $ minikube start


Then, once its ready, you can start up the dashboard with `minikube dashboard`.

Next you'll run the example job.

    $ kubectl create -f example/job.yaml

The source looks like this:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: minshell-example
spec:
  template:
    metadata:
      name: minshell-example
    spec:
      volumes:
      - name: semaphore
        emptyDir: {}
        
      containers:
      - name: worker
        image: quay.io/cloudguardtech/min-shell:latest
        volumeMounts:
        - mountPath: /home/app/semaphore
          name: semaphore
        command: [ "/bin/bash" ]
        args:
        - -c
        - >
          KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) &&
          podname=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/default/pods |jq '.items[] .metadata.name' |grep -i minshell-example | sed -e 's/\"//g') &&
          podip=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/default/pods/$podname | jq '.status.podIP' | sed -e 's/\"//g') &&
          echo "$(date): The podname = $podname at IP $podip" &&
          touch semaphore/done
      - name: cleanup
        image: quay.io/cloudguardtech/min-shell:latest
        volumeMounts:
        - mountPath: /home/app/semaphore
          name: semaphore
        command: [ "/bin/bash" ]
        args:
        - -c
        - >
          echo "$(date): Waiting till the worker is done" &&
          while [ ! -f semaphore/done ]; do sleep 2; done &&
          echo "$(date):Worker is finished - time to clean up"
      restartPolicy: Never
```

1. This job first sets up a volume, `semaphore`, that the two containers in the Job can use to synchronize activity.
1. Next it creates `worker` a `min-shell` container with semaphore mounted and runs a short script that demonstrates using `curl`, `jq` and `sed` along with the Kubernetes API to do something.
1. Once the work is done, `worker` create a file in the shared `semaphore` volume and exits
1. The Pod also starts up the `cleanup` container at the same time as `worker` that also has a mount to `semaphore` which it monitors for the `done` file to exist before *'cleaning up'* and exiting


