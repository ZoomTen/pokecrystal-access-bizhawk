package dispatch

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
)

type PlatformDispatcher struct {
	speakCh chan string
	soundCh chan string
}

func NewPlatformDispatcher() *PlatformDispatcher {
	speakCh := make(chan string, 1000)
	soundCh := make(chan string, 1000)
	go speakPlayer(speakCh)
	go soundPlayer(soundCh)
	i := &PlatformDispatcher{
		speakCh: speakCh,
		soundCh: soundCh,
	}
	return i
}

var _ Dispatcher = (*PlatformDispatcher)(nil)

func (i *PlatformDispatcher) PushSpeak(s string) {
	i.speakCh <- s
}

func (i *PlatformDispatcher) PushSound(filename string) {
	i.soundCh <- filename
}

func speakPlayer(s chan string) {
	for a := range s {
		fmt.Println(a)
		cmd := exec.Command("espeak")
		cmd.Stdin = strings.NewReader(a)
		e := cmd.Run()
		if e != nil {
			fmt.Println(e)
		}
	}
}

func soundPlayer(s chan string) {
	for a := range s {
		go func(){
			fp, e := filepath.Abs("../" + a)
			if e != nil {
				fmt.Println(e)
				return
			}
			fmt.Println(fp)
			cmd := exec.Command("aplay", fp)
			e = cmd.Run()
			if e != nil {
				fmt.Println(e)
			}
		}()
	}
}
