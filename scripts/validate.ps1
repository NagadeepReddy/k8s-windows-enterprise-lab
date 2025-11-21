Write-Host ">>> [Validate] Checking cluster state..." -ForegroundColor Cyan

Write-Host ">>> Waiting a few seconds for pods to settle..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ">>> Nodes:" -ForegroundColor Green
kubectl get nodes -o wide

Write-Host ">>> Pods in apps namespace:" -ForegroundColor Green
kubectl get pods -n apps -o wide

Write-Host ">>> Services in apps namespace:" -ForegroundColor Green
kubectl get svc -n apps

Write-Host ">>> Ingress in apps namespace:" -ForegroundColor Green
kubectl get ingress -n apps

Write-Host ">>> Describing one enterprise pod:" -ForegroundColor Green
$pod = (kubectl get pods -n apps -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $pod -n apps

Write-Host ">>> Simple HTTP test using Invoke-WebRequest (if DNS is configured)..." -ForegroundColor Green
try {
  Invoke-WebRequest http://enterprise.local/ -UseBasicParsing | Select-Object -First 1 | Out-Null
  Write-Host "HTTP request to enterprise.local succeeded (basic check)." -ForegroundColor Green
} catch {
  Write-Host "HTTP request to enterprise.local failed (expected if DNS/hosts not set)." -ForegroundColor Yellow
}
