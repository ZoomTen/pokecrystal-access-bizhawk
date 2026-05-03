package dispatch

import "net/http"

type Dispatcher interface {
	PushSpeak(s string)
	PushSound(filename string)
}

type Server struct {
	Mux *http.ServeMux
	dispatcher Dispatcher
}
