package monitoring

import (
	"github.com/kharf/declcd/schema"
)

prometheusStack: schema.#HelmRelease & {
	dependencies: [
		ns.id,
	]
	name:      "prometheus-stack"
	namespace: ns.content.metadata.name
	chart: {
		name:    "kube-prometheus-stack"
		repoURL: "https://prometheus-community.github.io/helm-charts"
		version: "58.2.1"
	}
	values: {
		prometheus: prometheusSpec: {
			serviceMonitorSelectorNilUsesHelmValues: false
			retention:                               "30d"
			scrapeInterval:                          "30s"
			storageSpec: volumeClaimTemplate: spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: 100Gi
			}
		}
	}
}
