package core

import (
	"github.com/kharf/declcd/schema"
	corev1 "github.com/kharf/cuepkgs/modules/k8s/k8s.io/api/core/v1"
	appsv1 "github.com/kharf/cuepkgs/modules/k8s/k8s.io/api/apps/v1"
)

#Namespace: schema.#Manifest & {
	#Name: string
	content: corev1.#Namespace & {
		apiVersion: string | *"v1"
		kind:       "Namespace"
		metadata: name: #Name
	}
}

#Service: schema.#Manifest & {
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

#Deployment: schema.#Manifest & {
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
