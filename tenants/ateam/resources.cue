package ateam

import (
	"github.com/kharf/declcd-platform-example/templates/core"
	"github.com/kharf/declcd-platform-example/declcd"
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

roleBinding: core.#RoleBinding & {
	dependencies: [
		role.id,
		declcd.ateamTenantServiceAccount.id,
	]
	#Name:      _ateamName
	#Namespace: ateamNs.#Name
	#Role: {
		kind: role.content.kind
		name: role.#Name
	}
	#Subject: {
		name:      declcd.ateamTenantServiceAccount.#Name
		namespace: declcd.ateamTenantServiceAccount.#Namespace
	}
}
