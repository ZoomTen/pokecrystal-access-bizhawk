package dispatch

import (
	"fmt"
	"path/filepath"
	"runtime"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

var (
	tolkDLL         = windows.MustLoadDLL("Tolk.dll")
	procTolkOutput  = tolkDLL.MustFindProc("Tolk_Output")
	procTolkLoad    = tolkDLL.MustFindProc("Tolk_Load")
	procTolkTrySAPI = tolkDLL.MustFindProc("Tolk_TrySAPI")
	winmm      = windows.MustLoadDLL("winmm.dll")
	playSound  = winmm.MustFindProc("PlaySoundW")
)

const (
    SND_SYNC     = 0x0000
    SND_ASYNC    = 0x0001
    SND_FILENAME = 0x20000
)

func PlayWAV(path string) error {
    p, err := windows.UTF16PtrFromString(path)
    if err != nil {
        return err
    }
    r, _, _ := playSound.Call(uintptr(unsafe.Pointer(p)), 0, SND_FILENAME|SND_SYNC)
    if r == 0 {
        return fmt.Errorf("PlaySoundW failed")
    }
    return nil
}

func Tolk_TrySAPI(trySAPI bool) {
	var val uintptr
	if trySAPI {
		val = 1
	}
	procTolkTrySAPI.Call(val)
}

func Tolk_Load() {
	procTolkLoad.Call()
}

func Tolk_Output(str string, interrupt bool) (bool, error) {
	ptr, err := syscall.UTF16PtrFromString(str)
	if err != nil {
		return false, err
	}

	var interruptVal uintptr
	if interrupt {
		interruptVal = 1
	}

	r1, _, _ := procTolkOutput.Call(
		uintptr(unsafe.Pointer(ptr)),
		interruptVal,
	)
	return r1 != 0, nil
}

type PlatformDispatcher struct {
	speakCh chan string
	soundCh chan string
}

var _ Dispatcher = (*PlatformDispatcher)(nil)

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

func (i *PlatformDispatcher) PushSpeak(s string) {
	i.speakCh <- s
}

func (i *PlatformDispatcher) PushSound(filename string) {
	i.soundCh <- filename
}

func speakPlayer(s chan string) {
	runtime.LockOSThread()
	Tolk_TrySAPI(true)
	Tolk_Load()
	for a := range s {
		fmt.Println(a)
		Tolk_Output(a, false)
	}
}

func soundPlayer(s chan string) {
	for a := range s {
		go func(){
			runtime.LockOSThread()
			fmt.Println(a)
			fp, e := filepath.Abs("../" + a)
			if e != nil {
				fmt.Println(e)
				return
			}
			fmt.Println(fp)
			PlayWAV(fp)
	}()
}}
