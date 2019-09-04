package main

import (
    "html/template"
    "io/ioutil"
    "net/http"
    "os"
)

type Data struct {
    Message string
}

var apiURL string

func getMessage() (string, error) {
	resp, err := http.Get(apiURL)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	return string(body), err
}

func init() {
	apiURL = os.Getenv("API_URL")
	if apiURL == "" {
		panic("env variable API_URL is missing")
	}
}

func main() {
    tmpl := template.Must(template.ParseFiles("index.html"))
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        message, err := getMessage()
        if err != nil {
          http.Error(w, err.Error(), http.StatusInternalServerError)
          return
        }
        tmpl.Execute(w, Data{message})
    })
    http.ListenAndServe(":80", nil)
}
