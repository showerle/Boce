package main

import (
	_ "git.code.oa.com/trpc-go/trpc-config-tconf"
	_ "git.code.oa.com/trpc-go/trpc-filter/debuglog"
	_ "git.code.oa.com/trpc-go/trpc-filter/recovery"
	_ "git.code.oa.com/trpc-go/trpc-log-atta"
	_ "git.code.oa.com/trpc-go/trpc-metrics-m007"
	_ "git.code.oa.com/trpc-go/trpc-metrics-runtime"
	_ "git.code.oa.com/trpc-go/trpc-naming-polaris"
	_ "git.code.oa.com/trpc-go/trpc-opentracing-tjg"
	_ "git.code.oa.com/trpc-go/trpc-selector-cl5"

	trpc "git.code.oa.com/trpc-go/trpc-go"
	pb "git.code.oa.com/trpcprotocol/test/httpboce"

	_ "go.uber.org/automaxprocs"
)

type greeterServiceImpl struct{}

func main() {

	s := trpc.NewServer()

	pb.RegisterGreeterService(s, &greeterServiceImpl{})

	s.Serve()
}
