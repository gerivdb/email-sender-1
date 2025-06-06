module email_sender

go 1.23.9

require (
	github.com/email-sender/tools v0.0.0
	github.com/gomarkdown/markdown v0.0.0-20250311123330-531bef5e742b
	github.com/google/uuid v1.1.2
	github.com/gorilla/mux v1.8.1
	github.com/mattn/go-sqlite3 v1.14.28
	github.com/pdfcpu/pdfcpu v0.11.0
	github.com/prometheus/client_golang v1.17.0
	github.com/qdrant/go-client v1.8.0
	github.com/redis/go-redis/v9 v9.9.0
	github.com/saintfish/chardet v0.0.0-20230101081208-5e3ef4b5456d
	github.com/schollz/progressbar/v3 v3.18.0
	github.com/spf13/cobra v1.9.1
	github.com/stretchr/testify v1.10.0
	go.uber.org/zap v1.27.0
	golang.org/x/mod v0.17.0
	golang.org/x/text v0.25.0
	gopkg.in/yaml.v3 v3.0.1
)

require (
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/hhrutter/lzw v1.0.0 // indirect
	github.com/hhrutter/pkcs7 v0.2.0 // indirect
	github.com/hhrutter/tiff v1.0.2 // indirect
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/mattn/go-runewidth v0.0.16 // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.4 // indirect
	github.com/mitchellh/colorstring v0.0.0-20190213212951-d06e56a500db // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/prometheus/client_model v0.4.1-0.20230718164431-9a2bf3000d16 // indirect
	github.com/prometheus/common v0.44.0 // indirect
	github.com/prometheus/procfs v0.11.1 // indirect
	github.com/rivo/uniseg v0.4.7 // indirect
	github.com/spf13/pflag v1.0.6 // indirect
	github.com/stretchr/objx v0.5.2 // indirect
	go.uber.org/multierr v1.10.0 // indirect
	golang.org/x/crypto v0.38.0 // indirect
	golang.org/x/image v0.27.0 // indirect
	golang.org/x/net v0.25.0 // indirect
	golang.org/x/sys v0.33.0 // indirect
	golang.org/x/term v0.32.0 // indirect
	google.golang.org/genproto v0.0.0-20200526211855-cb27e3aa2013 // indirect
	google.golang.org/grpc v1.47.0 // indirect
	google.golang.org/protobuf v1.34.1 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
)

replace github.com/email-sender/tools => ./development/managers/tools
