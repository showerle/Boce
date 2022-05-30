package main_test

import (
	"context"
	"flag"
	"log"
	"os"
	"reflect"
	"testing"
	"time"

	"git.code.oa.com/trpc-go/trpc-go/client"

	_ "git.code.oa.com/trpc-go/trpc-go/http"
	_ "git.code.oa.com/trpc-go/trpc-selector-cl5"

	trpc "git.code.oa.com/trpc-go/trpc-go"
	pb "git.code.oa.com/trpcprotocol/test/httpboce"
)

var (
	greeterClientProxy pb.GreeterClientProxy

	ctx           = context.Background()
	timeout       = flag.Duration("timeout", time.Second*0, "request timeout")
	network       = flag.String("network", "", "network")
	target        = flag.String("target", "", "target address, like ip://ip:port, cl5://mid:cid")
	svrConfigPath = flag.String("conf", "./trpc_go.yaml", "config file path")
)

func TestMain(m *testing.M) {
	flag.Parse()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// 默认使用配置文件中配置
	err := trpc.LoadGlobalConfig(*svrConfigPath)
	if err == nil {
		for _, cfg := range trpc.GlobalConfig().Client.Service {
			client.RegisterClientConfig(cfg.Callee, cfg)
		}
	}

	// 如果配置文件未提供，默认使用如下选项
	opts := []client.Option{
		client.WithProtocol("trpc"),
		client.WithNetwork("tcp4"),
		//client.WithTarget("ip://127.0.0.1:8000"),
		client.WithTimeout(time.Second * 2),
	}

	// 如果命令行选项由指定，覆盖上述选项
	if *timeout != time.Second*0 {
		opts = append(opts, client.WithTimeout(*timeout))
	}
	if *network != "" {
		opts = append(opts, client.WithNetwork(*network))
	}
	if *target != "" {
		opts = append(opts, client.WithTarget(*target))
	}

	greeterClientProxy = pb.NewGreeterClientProxy(opts...)
	os.Exit(m.Run())
}

func Test_Greeter_Boce(t *testing.T) {

	tests := []struct {
		name    string
		req     *pb.HelloRequest
		wantRsp *pb.HelloReply
		wantErr bool
	}{
		{"1-default", &pb.HelloRequest{}, &pb.HelloReply{}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := greeterClientProxy.Boce(ctx, tt.req)
			if tt.wantErr != (err != nil) {
				t.Errorf("wantErr = %v, err = %v, req:%s, rsp:%s", tt.wantErr, err, tt.req.String(), tt.wantRsp.String())
			}
			if !tt.wantErr && err == nil {
				if !reflect.DeepEqual(got, tt.wantRsp) {
					t.Errorf("got = %s, want = %s", got.String(), tt.wantRsp.String())
				}
			}
		})
	}
}
