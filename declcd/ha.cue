package declcd

import (
	"github.com/kharf/declcd/schema/component"
)

primaryProjectControllerDeployment: component.#Manifest & {
	content: spec: template: spec: affinity: podAntiAffinity: {
		requiredDuringSchedulingIgnoredDuringExecution: [{
			labelSelector: matchExpressions: [{
				key:      _shardKey
				operator: "In"
				values: ["primary"]
			}]
			topologyKey: "kubernetes.io/hostname"
		}]
	}
}
