apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${runner_name}
  namespace: ${namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${runner_name}
  template:
    metadata:
      labels:
        app: ${runner_name}
    spec:
      serviceAccountName: ${sa_name}
      containers:
        - name: github-runner
          image: myoung34/github-runner:latest
          env:
            - name: REPO_URL
              value: "${github_url}"
            - name: RUNNER_NAME
              value: "${runner_name}"
            - name: RUNNER_TOKEN
              value: "${github_token}"
            - name: RUNNER_LABELS
              value: "${runner_labels}"
            - name: RUNNER_GROUP
              value: "${runner_group}"
          volumeMounts:
            - name: docker
              mountPath: /var/run/docker.sock
      volumes:
        - name: docker
          hostPath:
            path: /var/run/docker.sock