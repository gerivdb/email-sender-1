module demo

go 1.21

replace bridges => ../

require bridges v0.0.0-00010101000000-000000000000

require (
	github.com/fsnotify/fsnotify v1.7.0 // indirect
	golang.org/x/sys v0.4.0 // indirect
)
