package rules

import (
	"github.com/kharf/declcd-platform-example/templates/monitoring/prometheus"
	"github.com/kharf/declcd-platform-example/infrastructure/monitoring"
)

kubernetesRules: prometheus.#PrometheusRule & {
	dependencies: [
		monitoring.prometheusStack.id,
	]
	#Name:      "kubernetes-rules"
	#Namespace: "monitoring"
	content: {
		spec: groups: [{
			name: "pods.failing"
			rules: [{
				alert: "UnreadyPods"
				expr:  "sum(label_join(kube_pod_container_status_running{namespace!~\"kube-.*\"}, \"origin_namespace\", \",\", \"namespace\")) by (container, origin_namespace) - sum(label_join(kube_pod_container_status_ready{namespace!~\"kube-.*\"}, \"origin_namespace\", \",\", \"namespace\")) by (container, origin_namespace) > 0"
				for:   "5m"
				labels: {
					severity:  "fatal"
					namespace: "monitoring"
				}
				annotations: {
					message:     "**{{ .container }}** in **{{ .origin_namespace }}**  has **{{  }}** unready pod(s)"
					runbook_url: "https://github.com/MediaMarktSaturn/campaign-orchestration-gitops/blob/main/docs/runbook.md\\#UnreadyPods"
				}
			}, {
				alert: "CrashingPods"
				expr:  "(label_join(rate(kube_pod_container_status_restarts_total[5m]), \"origin_namespace\", \",\", \"namespace\") * 60 * 5) > 0"
				for:   "5m"
				labels: {
					severity:  "fatal"
					namespace: "monitoring"
				}
				annotations: {
					message:     "**{{ .pod }}** in **{{ .origin_namespace }}** was restarting **{{ printf \"%.2f\"  }} times** during the last 5 minutes."
					runbook_url: "https://github.com/MediaMarktSaturn/campaign-orchestration-gitops/blob/main/docs/runbook.md\\#CrashingPods"
				}
			}, {
				alert: "UnstartablePods"
				expr:  "sum by(pod, origin_namespace) (label_join(kube_pod_status_phase{phase=~\"Pending|Failed\"}, \"origin_namespace\", \",\", \"namespace\")) > 0"
				for:   "5m"
				labels: {
					severity:  "fatal"
					namespace: "monitoring"
				}
				annotations: {
					message:     "**{{ .pod }}** in **{{ .origin_namespace }}** has **{{  }}** unstartable pod(s)"
					runbook_url: "https://github.com/MediaMarktSaturn/campaign-orchestration-gitops/blob/main/docs/runbook.md\\#UnstartablePods"
				}
			}]
		}]
	}
}
