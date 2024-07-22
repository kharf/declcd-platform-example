package monitoring

import (
	"github.com/kharf/declcd/schema/component"
	"github.com/kharf/declcd-platform-example/templates/core"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/api/autoscaling/v2"
)

ns: component.#Manifest & {
	content: corev1.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: name: "monitoring"
	}
}

hpa: component.#Manifest & {
	content: v2.#HorizontalPodAutoscaler & {
		apiVersion: "autoscaling/v2"
		kind:       "HorizontalPodAutoscaler"
		metadata: {
			name:      "prometheus-stack-grafana"
			namespace: ns.content.metadata.name
		}
		spec: {
			scaleTargetRef: {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				name:       "prometheus-stack-grafana"
			}
			minReplicas: 3
			maxReplicas: 10
			metrics: [{
				type: "Resource"
				resource: {
					name: "cpu"
					target: {
						type:               "Utilization"
						averageUtilization: 50
					}
				}
			}]
		}
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
		version: "61.2.0"
	}
	crds: allowUpgrade: true
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

	patches: [
		core.#Deployment & {
			#Name:      "prometheus-stack-grafana"
			#Namespace: ns.content.metadata.name
			spec: {
				replicas: 2 @ignore(conflict)
			}
		},
	]
}
