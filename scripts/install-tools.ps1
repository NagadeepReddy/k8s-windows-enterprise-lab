Write-Host ">>> Installing Kubernetes tooling on Windows (requires Chocolatey)..." -ForegroundColor Cyan

choco install kubernetes-cli -y
choco install kubernetes-helm -y

Write-Host ">>> kubectl version (client):" -ForegroundColor Green
kubectl version --client

Write-Host ">>> helm version:" -ForegroundColor Green
helm version
