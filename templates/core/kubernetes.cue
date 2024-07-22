package core

import (
	"github.com/kharf/declcd/schema/component"
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#Namespace: component.#Manifest & {
	#Name: string
	content: corev1.#Namespace & {
		apiVersion: string | *"v1"
		kind:       "Namespace"
		metadata: name: #Name
	}
}

#Service: component.#Manifest & {
	#Name:      string
	#Namespace: string
	content: corev1.#Service & {
		apiVersion: string | *"v1"
		kind:       "Service"
		metadata: {
			name:      #Name
			namespace: #Namespace
		}
	}
}

#Deployment: component.#Manifest & {
	#Name:      string
	#Namespace: string
	content: appsv1.#Deployment & {
		apiVersion: string | *"apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      #Name
			namespace: #Namespace
		}
	}
}

#ServiceAccount: component.#Manifest & {
	#Name:      string
	#Namespace: string
	content: corev1.#Service & {
		apiVersion: string | *"v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      #Name
			namespace: #Namespace
		}
	}
}

#Role: component.#Manifest & {
	#Name:      string
	#Namespace: string
	#Rules: [...{
		apiGroups: [...string]
		resources: [...string]
		verbs: [...string]
	}]
	content: {
		apiVersion: string | *"rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      #Name
			namespace: #Namespace
		}
		rules: #Rules
	}
}

#RoleBinding: component.#Manifest & {
	#Name:      string
	#Namespace: string
	#Role: {
		kind: string
		name: string
	}
	#Subject: {
		kind:      string | *"ServiceAccount"
		name:      string
		namespace: string
	}
	content: {
		apiVersion: string | *"rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      #Name
			namespace: #Namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     #Role.kind
			name:     #Role.name
		}
		subjects: [
			{
				kind:      #Subject.kind
				name:      #Subject.name
				namespace: #Subject.namespace
			},
		]
	}
}
