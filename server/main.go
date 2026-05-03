package main

import (
	"accesssrv/dispatch"
	"net/http"
)

func main() {
	i := dispatch.NewPlatformDispatcher()
	m := dispatch.NewServer(i)
	m.InitRoutes()
	srv := http.Server{
		Addr: ":61226",
		Handler: m.Mux,
	}
	srv.ListenAndServe()
}