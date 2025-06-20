package conflict

import (
	"sync"

	"github.com/fsnotify/fsnotify"
)

// RealTimeDetector uses fsnotify and channels for real-time conflict detection.
type RealTimeDetector struct {
	watcher *fsnotify.Watcher
	Events  chan Conflict
	Errors  chan error
	stop    chan struct{}
	wg      sync.WaitGroup
}

func NewRealTimeDetector() (*RealTimeDetector, error) {
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}
	r := &RealTimeDetector{
		watcher: w,
		Events:  make(chan Conflict, 10),
		Errors:  make(chan error, 1),
		stop:    make(chan struct{}),
	}
	return r, nil
}

func (r *RealTimeDetector) Watch(path string) error {
	err := r.watcher.Add(path)
	if err != nil {
		return err
	}
	r.wg.Add(1)
	go func() {
		defer r.wg.Done()
		for {
			select {
			case event := <-r.watcher.Events:
				if event.Op&fsnotify.Remove != 0 {
					r.Events <- Conflict{
						Type:         PathConflict,
						Severity:     1,
						Participants: []string{event.Name},
						Metadata:     map[string]interface{}{"reason": "file removed"},
					}
				}
			case err := <-r.watcher.Errors:
				r.Errors <- err
			case <-r.stop:
				return
			}
		}
	}()
	return nil
}

func (r *RealTimeDetector) Close() error {
	close(r.stop)
	r.wg.Wait()
	return r.watcher.Close()
}
