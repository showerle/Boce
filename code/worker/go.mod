module git.code.oa.com/HttpBoce

go 1.12

replace git.code.oa.com/trpcprotocol/test/httpboce => ./stub/git.code.oa.com/trpcprotocol/test/httpboce

require (
	git.code.oa.com/trpc-go/trpc-config-tconf v0.1.8
	git.code.oa.com/trpc-go/trpc-filter/debuglog v0.1.3
	git.code.oa.com/trpc-go/trpc-filter/recovery v0.1.2
	git.code.oa.com/trpc-go/trpc-go v0.7.0
	git.code.oa.com/trpc-go/trpc-log-atta v0.1.12
	git.code.oa.com/trpc-go/trpc-metrics-m007 v0.4.4
	git.code.oa.com/trpc-go/trpc-metrics-runtime v0.2.3
	git.code.oa.com/trpc-go/trpc-naming-polaris v0.2.12
	git.code.oa.com/trpc-go/trpc-opentracing-tjg v0.1.8
	git.code.oa.com/trpc-go/trpc-selector-cl5 v0.2.0
	git.code.oa.com/trpcprotocol/test/httpboce v0.0.0-00010101000000-000000000000
	go.uber.org/automaxprocs v1.4.0
)
