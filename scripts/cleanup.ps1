Write-Host ">>> [Cleanup] Removing enterprise workloads..." -ForegroundColor Cyan

helm uninstall enterprise -n apps
helm uninstall ingress -n platform

kubectl delete ns apps --ignore-not-found
kubectl delete ns platform --ignore-not-found

Write-Host ">>> Cleanup complete." -ForegroundColor Green
