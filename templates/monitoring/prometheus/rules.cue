package prometheus

import (
	"github.com/kharf/declcd/schema"
	"github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
)

#PrometheusRule: schema.#Manifest & {
	#Name:      string
	#Namespace: string
	content: v1.#PrometheusRule & {
		apiVersion: "monitoring.coreos.com/v1"
		kind:       "PrometheusRule"
		metadata: {
			name:      #Name
			namespace: #Namespace
		}
	}
}
