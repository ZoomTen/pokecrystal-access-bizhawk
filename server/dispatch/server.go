package dispatch

import (
	"io"
	"net/http"
)

func NewServer(d Dispatcher) *Server {
	return &Server{
		Mux: http.NewServeMux(),
		dispatcher: d,
	}
}

func (s *Server) InitRoutes() {
	s.Mux.HandleFunc("POST /speak", s.speak)
	s.Mux.HandleFunc("POST /sound", s.sound)
}

func (s *Server) speak(w http.ResponseWriter, r *http.Request) {
	b, e := io.ReadAll(r.Body)
	if e != nil { return }
	defer r.Body.Close()

	what := string(b)
	s.dispatcher.PushSpeak(what)
	w.WriteHeader(http.StatusOK)
}

func (s *Server) sound(w http.ResponseWriter, r *http.Request) {
	b, e := io.ReadAll(r.Body)
	if e != nil { return }
	defer r.Body.Close()

	which := string(b)
	s.dispatcher.PushSound(which)
	w.WriteHeader(http.StatusOK)
}