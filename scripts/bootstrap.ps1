Write-Host ">>> [Bootstrap] Configuring Kubernetes hybrid lab on Windows..." -ForegroundColor Cyan

kubectl config use-context rancher-desktop

Write-Host ">>> Creating namespaces..." -ForegroundColor Cyan
kubectl apply -f .\manifests\namespaces\platform.yaml
kubectl apply -f .\manifests\namespaces\apps.yaml

Write-Host ">>> Applying storage classes and PVCs..." -ForegroundColor Cyan
kubectl apply -f .\manifests\storage\sc-local-path.yaml
kubectl apply -f .\manifests\storage\sc-longhorn.yaml
kubectl apply -f .\manifests\storage\pvc-hostpath.yaml
kubectl apply -f .\manifests\storage\pvc-longhorn.yaml

Write-Host ">>> Applying RBAC and NetworkPolicy..." -ForegroundColor Cyan
kubectl apply -f .\manifests\security\rbac-app-sa.yaml
kubectl apply -f .\manifests\security\networkpolicy-example.yaml

Write-Host ">>> Installing Traefik ingress via Helm (platform namespace)..." -ForegroundColor Cyan
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm upgrade --install ingress traefik/traefik -n platform --create-namespace

Write-Host ">>> Deploying enterprise app via Helm (apps namespace)..." -ForegroundColor Cyan
helm upgrade --install enterprise .\helm\enterprise-app -n apps --create-namespace

Write-Host ">>> Bootstrap complete." -ForegroundColor Green
