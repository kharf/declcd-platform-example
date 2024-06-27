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
