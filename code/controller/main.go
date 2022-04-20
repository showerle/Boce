package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"
	"strings"

	"git.code.oa.com/trpc-go/trpc-go/client"

	pb "git.code.oa.com/trpcprotocol/test/httpboce" //需要把被调服务的协议生成文件pb.go的git地址push到git
)

type ResultList struct {
	Addr   string `json:"addr"`
	URL    string `json:"url"`
	Method string `json:"method"`
	Code   int    `json:"code"`
	Body   string `json:"body"`
}

type Post struct {
	TaskUUID   string     `json:"task_uuid"`
	Rtx        string     `json:"rtx"`
	ResultList []ResultList `json:"result_list"`
}

// Response储存题库返回结果
type Response struct {
	AddrList []string `json:"addr_list"` // 添加一个`json:" "`标签指定其它的名称，否则各个字段名称默认使用结构体的名称
	Errno    int      `json:"errno"`
	Error    string   `json:"error"`
	TaskUUID string   `json:"task_uuid"`
	URLList  []struct {
		Method string `json:"method"`
		URL    string `json:"url"`
	} `json:"url_list"`
}

var question Response // 题库返回的题目
var ques_AddrList []string
var ques_TaskUUID string
var ques_URLList_method []string
var ques_URLList_url []string

var post Post
var result_list []ResultList  //字符串数组
var amount = 10000

func main() {

	boce()

	proxy := pb.NewGreeterClientProxy() //创建一个客户端调用代理
	information := fmt.Sprintf("%s, %s, %s", ques_AddrList, ques_URLList_method, ques_URLList_url)
	req := &pb.HelloRequest{Msg: information}                                                      // 填充请求的参数
	rsp, err := proxy.Boce(context.Background(), req, client.WithTarget("ip://127.0.0.1:8080"))    // 调用目标地址为前面启动的服务监听的地址
	if err != nil {
		log.Fatalf("拨测失败: %v", err)
		return
	}

	result := rsp.Msg   //返回body的数组，这里需要做数据转换
	//fmt.Println(result)

	output := strings.Trim(result, "[")
	output = strings.Trim(result, "]")
	output = strings.Trim(result, "[")
	//fmt.Printf("%s\n", output)
	output_list := strings.Split(output, " ")
	fmt.Printf("%s\n", output_list[0])
	fmt.Printf("%s\n", output_list[99])

	//for i := range output_list{
	//	fmt.Printf("%s\n", output_list[i])
	//}


	shangbao(output_list)
}

// 向题库发起请求获取题目
func boce() {
	fmt.Println("正在向题库获取题目, 请求数量为：", amount)
	client := &http.Client{}
	req, err := http.NewRequest("GET", "http://9.134.111.140:17710/mini3/task_bank/task/showerli/"+strconv.Itoa(amount), nil)
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

	errQuestion := json.Unmarshal(bodyText, &question)
	if errQuestion != nil {
		fmt.Println(errQuestion.Error())
	}

	// 把返回的题目都储存到字符串数组里面
	ques_TaskUUID = question.TaskUUID
	for _, v := range question.AddrList {
		ques_AddrList = append(ques_AddrList, v)
	}

	for _, v := range question.URLList {
		ques_URLList_method = append(ques_URLList_method, v.Method)
		ques_URLList_url = append(ques_URLList_url, v.URL)
	}
}

// 将结果上报给题库
func shangbao(body []string) {
	println("********正在将结果上报给题库********")
	i := 0
	for _, addr := range ques_AddrList { // 遍历每一个address
		for k, url := range ques_URLList_url { // 遍历每一个url
			//fmt.Println(url)
			//fmt.Println(body[i])
			data := ResultList{addr, url, ques_URLList_method[k], 200, body[i] }
			result_list = append(result_list, data)
			i += 1
		}
	}

	post = Post{TaskUUID: ques_TaskUUID, Rtx: "showerli", ResultList: result_list}
	//fmt.Println(post)
	post2json, err := json.Marshal(&post)
	if err != nil {
		fmt.Println("生成json字符串错误")
	}
	//fmt.Println(string(post2json))
	reader := bytes.NewReader(post2json)
	client := &http.Client{}
	req, err := http.NewRequest("POST", "http://9.135.152.178:8000/judge/v1/report", reader)
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
	bytes.Trim(bodyText, string('æ'))
	fmt.Printf("%s\n", bodyText)
}
