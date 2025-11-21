# Kubernetes on Windows – Hybrid Enterprise Lab (Nagadeep)

This repository is my **Windows-focused Kubernetes lab**, built to simulate a hybrid cluster where:
- Linux nodes run the control plane, ingress, metrics, CSI, core add‑ons.
- Windows worker nodes run OS‑bound workloads (IIS / .NET apps).
- Everything is deployed and validated from `C:\Users\Nagad>` on my Windows machine using Rancher Desktop.

The goal is **not just to run pods**, but to show how I think about:
- Hybrid scheduling (labels, taints, affinity for Windows nodes)
- Windows container images and build pipelines
- Storage patterns for Windows (HostPath vs CSI like Longhorn)
- Automation with Helm + PowerShell
- Basic observability and troubleshooting on Windows nodes

---

## 1. High‑Level Architecture

Conceptual model:

```text
[ Linux Control Plane ]
        |
        v
[ Linux Infra Nodes ]
    - Ingress (Traefik)
    - Metrics / Prometheus
    - CSI drivers (Longhorn / cloud CSI)
        |
        v
[ Windows Worker Nodes ]
    - Enterprise app pods (IIS / Windows images)
    - PVCs for app data (via CSI or local-path in lab)
```

Traffic path:  
**Client → Traefik (Linux) → ClusterIP Service → Windows Pods**

In my local lab, Rancher Desktop collapses these roles onto one node, but the **YAML and Helm chart are written as if this is a real hybrid cluster**.

An architecture diagram is also included in `diagrams/hybrid-architecture.png`.

---

## 2. Repo Layout

```text
k8s_windows_enterprise/
 ├── manifests/
 │    ├── namespaces/
 │    ├── deployments/
 │    ├── services/
 │    ├── ingress/
 │    ├── storage/
 │    └── security/
 ├── helm/enterprise-app/
 ├── scripts/
 ├── ci-cd/github-actions/
 ├── screenshots/
 ├── diagrams/
 └── Kubernetes_Windows_Enterprise_Final.docx
```

Key points:
- **Namespaces**: `platform` for infra (ingress), `apps` for workloads.
- **Deployment**: `windows-enterprise-app` (IIS‑based Windows container).
- **Service**: `ClusterIP` service fronting the Windows app.
- **Ingress**: Traefik Ingress routing host `enterprise.local` to the service.
- **Storage**:
  - `sc-local-path` + `pvc-hostpath` → local dev / Rancher Desktop.
  - `sc-longhorn` + `pvc-longhorn` → example CSI pattern for real clusters.
- **Security**: ServiceAccount + simple Role/RoleBinding + NetworkPolicy skeleton.
- **Helm**: templated deployment, service, ingress, optional HPA, values exposed for tuning.
- **Scripts**: PowerShell automation for bootstrap / validate / cleanup.

---

## 3. Windows Scheduling & Images

To make Windows workloads first‑class citizens:

- Nodes are expected to be labeled with `kubernetes.io/os=windows`.
- Workloads use:
  - `nodeSelector` → force `os=windows`
  - `tolerations` → allow tainted Windows pools
  - `nodeAffinity` → requiredDuringSchedulingIgnoredDuringExecution, to avoid accidental Linux placement.

Default image (demo):

```yaml
image:
  repository: mcr.microsoft.com/windows/servercore/iis
  tag: "windowsservercore-ltsc2022"
  pullPolicy: IfNotPresent
```

In a real environment I would:
- Replace this with our own application image based on a Windows Server Core base.
- Build it on Windows runners (GitHub Actions / Azure DevOps / GitLab runners).

---

## 4. Storage – HostPath vs CSI (Option C)

I intentionally show **two patterns**:

1. **HostPath / local-path (Lab / Rancher Desktop)**
   - `sc-local-path.yaml` + `pvc-hostpath.yaml`
   - Used for local demos only.
   - Backed by Rancher Desktop’s local‑path provisioner.

2. **CSI‑style example (Longhorn)**
   - `sc-longhorn.yaml` + `pvc-longhorn.yaml`
   - Represents how I would carve storage for Windows pods in a real on‑prem lab.
   - This is the right pattern for real clusters (AKS disk CSI, Longhorn, vSphere CNS‑CSI, etc.).

Helm values expose:

```yaml
volume:
  enabled: true
  useLonghorn: false      # false → pvc-hostpath, true → pvc-longhorn
  storageClassName: local-path
  size: 1Gi
```

So I can talk in an interview about:
- Why HostPath is not production‑grade.
- How CSI solves scaling, resiliency and recovery for Windows workloads.

---

## 5. Deployment Flow (What I Actually Run)

From `C:\Users\Nagad>`:

```powershell
# 1) (Optional) Install tools
.\scripts\install-tools.ps1

# 2) Bootstrap lab
.\scriptsBootstrap.ps1

# 3) Validate cluster and app
.\scriptsValidate.ps1
```

**bootstrap.ps1** does:

- Switch context to Rancher Desktop.
- Create `platform` and `apps` namespaces.
- Apply StorageClasses + PVCs.
- Apply RBAC + NetworkPolicy.
- Install Traefik via Helm (namespace: `platform`).
- Deploy `enterprise-app` Helm chart into `apps`.

**validate.ps1** does:

- `kubectl get nodes -o wide`
- `kubectl get pods -n apps -o wide`
- `kubectl get svc -n apps`
- `kubectl get ingress -n apps`
- Picks one pod and runs `kubectl describe`.
- Attempts an HTTP call using `Invoke-WebRequest` (if `enterprise.local` is resolvable).

Screenshots in `screenshots/` capture real terminal output for these commands.

---

## 6. Exposed Tuning via Helm values

`helm/enterprise-app/values.yaml` exposes:

- `replicaCount`
- `image.*` (repo, tag, pullPolicy)
- `resources` (requests/limits)
- `livenessProbe` and `readinessProbe` defaults
- `nodeSelector`, `tolerations`, `affinity`
- `service.*`
- `ingress.*`
- `hpa.*` (disabled by default)
- `monitoring.windowsExporter.*`

This keeps the chart realistic and production‑shaped, but still simple enough to follow in an interview.

---

## 7. Troubleshooting Windows Nodes (What I’d Say in a Review)

A few real‑world things I call out when discussing Windows Kubernetes:

1. **Slow Windows image pulls**
   - Windows base images are large; first pull can be slow.
   - I usually pre‑warm images on node pools for critical workloads.

2. **CNI quirks**
   - Some CNIs have limited / newer support for Windows.
   - I always check the exact CNI and version matrix for Windows nodes.

3. **Metrics / HPA gaps**
   - `metrics-server` historically had issues scraping Windows metrics.
   - I often rely on Prometheus + windows_exporter + Prometheus Adapter for stable CPU/memory metrics.

4. **CSI & volume attach/detach**
   - Windows volume attach/detach behavior can differ from Linux.
   - For Longhorn / cloud CSI, I validate failover and node restart scenarios early.

5. **Networking & DNS**
   - Name resolution from Windows pods to services/ingress can fail if CoreDNS or overlay has issues.
   - `nslookup`, `Test-NetConnection` and logs from kube-proxy/containerd are key tools here.

6. **Log paths**
   - Windows log paths differ from Linux; log forwarders (Fluent Bit, etc.) often need dedicated config.

Having this section in README and in my head lets me answer the “what goes wrong?” questions like a real SRE, not someone who only did a happy‑path demo.

---

## 8. How I Present This to an Architect

When I walk this repo with a senior architect, I focus on:

- The **hybrid model** (Linux control plane + Windows worker nodes).
- How I enforce **Windows scheduling** via labels, taints, affinity.
- How I handle **storage** with both HostPath (lab) and CSI (Longhorn‑style) examples.
- How **Helm + PowerShell** give a repeatable, idempotent lab setup.
- Where I see **real‑world risks** (CNI, metrics, CSI, image sizes) and how I would mitigate them.

The code proves I can build it; the documentation and explanations show I can run and support it in a real environment.

## Windows-Specific Notes (Real-World)
- Windows container images are large and typically take **2–5 minutes** to pull on first run.
- Windows nodes require CNIs that explicitly support Windows (Flannel or OVN-K recommended).
- Ingress controllers almost always run on Linux nodes; Windows pods receive traffic through Service Endpoints.
- Privileged containers, hostPID, and hostNetwork are **not supported** on Windows nodes.
