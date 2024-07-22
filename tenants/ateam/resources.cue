package ateam

import (
	"github.com/kharf/declcd-platform-example/templates/core"
)

_ateamName: "ateam"

ateamNs: core.#Namespace & {
	#Name: _ateamName
}

role: core.#Role & {
	dependencies: [
		ateamNs.id,
	]
	#Name:      _ateamName
	#Namespace: ateamNs.#Name
	#Rules: [
		{
			apiGroups: ["*"]
			resources: ["*"]
			verbs: ["*"]
		},
	]
}
