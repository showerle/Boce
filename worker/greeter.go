package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
	"time"

	// trpc "git.code.oa.com/trpc-go/trpc-go"
	pb "git.code.oa.com/trpcprotocol/test/httpboce"
)

var reslut []string  // worker拨测结果
var waitbocetime time.Duration = 1000 * time.Millisecond


// Boce方法
func (s *greeterServiceImpl) Boce(ctx context.Context, req *pb.HelloRequest, rsp *pb.HelloReply) error {
	question := req.Msg //获取入参值, 是一个字符串包类型的字符串数组
	//println("拨测任务是:" + question)
	question2slice := strings.Split(question, ", ")    //字符串转化成切片
	addr := question2slice[0]
	method := question2slice[1]
	url := question2slice[2]
    //fmt.Println(url)
	addr = strings.Trim(addr,"[")
	addr = strings.Trim(addr,"]")
	method = strings.Trim(method,"[")
	method = strings.Trim(method,"]")
	url = strings.Trim(url,"[")
	url = strings.Trim(url,"]")

	addr_ips := strings.Split(addr, " ")
	method_ips := strings.Split(method, " ")
	url_ips := strings.Split(url, " ")

	//fmt.Printf("%s\n", addr_ips)
	//fmt.Printf("%s\n", method_ips)
	//fmt.Printf("%s\n", url_ips)

	a := 0
	for i := range addr_ips {
		for k := range method_ips {
			if method_ips[k] == "GET" {

				reslut = append(reslut, string(GEThttp(ctx, addr_ips[i], url_ips[k])))
				//fmt.Println(a, "url:", url_ips[k])
				//fmt.Println(a, "body:", reslut[a])
				if url_ips[k][10:] == reslut[a] {
					fmt.Println("数组", a, ":BODY与url匹配")
					fmt.Println(url_ips[k][10:], reslut[a])
				}else {
					fmt.Println("数组", a, ":BODY与url不匹配")
					fmt.Println(url_ips[k][10:], reslut[a])
				}
				a += 1
			} else {
				reslut = append(reslut, string(HEADhttp(ctx, addr_ips[i], url_ips[k])))
				a += 1
			}
		}
	}
    //fmt.Println(reslut)
	rsp.Msg = fmt.Sprintf("%s", reslut)
	return nil
}


func GEThttp(ctx context.Context, addr string, url string)[]byte {
	client := &http.Client{}
	//fmt.Println("url:", url)
	startingTime := time.Now().UTC()  // 开始计时
	req, err := http.NewRequest("GET", "http://" + addr + url, nil)
	if err != nil {
		log.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()
	bodyText, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}
	endingTime := time.Now().UTC()  //计时结束

	var duration time.Duration = endingTime.Sub(startingTime)
    if duration >= waitbocetime {
    	return nil
	} else{
		if url[10:] == string(bodyText){
			fmt.Println( "拨测：BODY与url匹配")
		}else {
			fmt.Println("拨测：BODY与url不匹配")
		}
		//fmt.Println("body:", string(bodyText))
		return bodyText
	}

}

func HEADhttp(ctx context.Context, addr string, url string)[]byte {
	client := &http.Client{}
	req, err := http.NewRequest("HEAD", "http://" + addr + url, nil)
	if err != nil {
		log.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()
	bodyText, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}
	return bodyText
}