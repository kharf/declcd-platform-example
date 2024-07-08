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
