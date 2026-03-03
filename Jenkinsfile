#### Namespace #########
apiVersion: v1
kind: Namespace
metadata:
  name: production
---

# Redis Secret
apiVersion: v1
kind: Secret
metadata:
  name: redis-secret
  namespace: production
type: Opaque
stringData:
  REDIS_PASSWORD: Password
---

# Redis Service

apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: production
spec:
  type: ExternalName
  externalName: ${REDIS_IP}
---

# API Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo
        args:
          - "-text=api connected"
        ports:
        - containerPort: 5678
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            memory: "256Mi"
            cpu: "300m"
        readinessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 10
          periodSeconds: 10
        env:
          - name: REDIS_HOST
            valueFrom:
              configMapKeyRef:
                name: api-config
                key: REDIS_HOST
          - name: REDIS_PORT
            valueFrom:
              configMapKeyRef:
                name: api-config
                key: REDIS_PORT
          - name: REDIS_PASSWORD
            valueFrom:
              secretKeyRef:
                name: redis-secret
                key: REDIS_PASSWORD
---

# API Service

apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: production
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 5678
---

# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: production
spec:
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:stable
        ports:
        - containerPort: 80
---

# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: production
spec:
  selector:
    app: frontend
  ports:
  - port: 80
---

# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
spec:
  rules:
  - host: app.local
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: frontend
            port: 
              number: 80
---

# HPA

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
---

# PodDisruptionBudget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api
---

# NetworkPolicy

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-traffic
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: frontend
      - podSelector:
          matchLabels:
            app: api

