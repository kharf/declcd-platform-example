package monitoring

import (
	"github.com/kharf/declcd/schema/component"
	corev1 "k8s.io/api/core/v1"
)

ns: component.#Manifest & {
	content: corev1.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: name: "monitoring"
	}
}

prometheusStack: component.#HelmRelease & {
	dependencies: [
		ns.id,
	]
	name:      "prometheus-stack"
	namespace: ns.content.metadata.name
	chart: {
		name:    "kube-prometheus-stack"
		repoURL: "https://prometheus-community.github.io/helm-charts"
		version: "59.1.0"
	}
	values: {
		prometheus: prometheusSpec: {
			serviceMonitorSelectorNilUsesHelmValues: false
			retention:                               "30d"
			scrapeInterval:                          "30s"
			storageSpec: volumeClaimTemplate: spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "500Mi"
			}
		}
	}
}
