package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	env := os.Getenv("LAB_ENV")
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "hello from uniphore lab, env=%s\n", env)
	})
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200) })
	http.ListenAndServe(":8080", nil)
}
