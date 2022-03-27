items:
  - version: 45
    metadata:
      name: system/plan/linux
    dockerDaemonScheduler:
      defaultDindResources:
        limits:
          cpu: 2500m
          memory: 7168Mi
    extends:
      - system/plan/default
    description: Linux runtime environment for BASIC plan
    isDefault: true
  - version: 1
    metadata:
      agent: true
      trial:
        endingAt: 1647462903797
        reason: Codefresh hybrid runtime
        started: 1646253303817
      name: oleg.sergiyuk@codefresh.io@oleg-cluster.us-east-1.eksctl.io/run
      changedBy: codefresh-oleg
      creationTime: '2022/03/02 20:35:05'
    runtimeScheduler:
      cluster:
        clusterProvider:
          accountId: 612c9a543ba6265134394298
          selector: oleg.sergiyuk@codefresh.io@oleg-cluster.us-east-1.eksctl.io
        namespace: runner
        serviceAccount: codefresh-engine
      annotations: {}
    dockerDaemonScheduler:
      cluster:
        clusterProvider:
          accountId: 612c9a543ba6265134394298
          selector: oleg.sergiyuk@codefresh.io@oleg-cluster.us-east-1.eksctl.io
        namespace: runner
        serviceAccount: codefresh-engine
      annotations: {}
      userAccess: true
      defaultDindResources:
        requests: ''
      pvcs:
        dind:
          storageClassName: dind-local-volumes-runner-runner
    extends:
      - system/default/hybrid/k8s_low_limits
    description: >-
      Runtime environment configure to cluster:
      oleg.sergiyuk@codefresh.io@oleg-cluster.us-east-1.eksctl.io and namespace:
      runner
    accountId: 612c9a543ba6265134394298

