package main

import (
    "fmt"
    "github.com/go-redis/redis"
    "net/http"
    "os"
)

var redisURL string
var client *redis.Client

func getMessage() (string, error) {
  val, err := client.Get("message").Result()
  if err != nil {
    return "", err
  }
  return val, nil
}

func init() {
  redisURL = os.Getenv("REDIS_URL")
  if redisURL == "" {
     panic("env variable REDIS_URL is missing")
  }
  client = redis.NewClient(&redis.Options{
    Addr:     redisURL,
    Password: "",
    DB:       0,
  })

  err := client.Set("message", "Hello from Database!", 0).Err()
	if err != nil {
		panic(err)
	}
}

func main() {
    http.HandleFunc("/", func (w http.ResponseWriter, r *http.Request) {
        message, err := getMessage()
        if err != nil {
          http.Error(w, err.Error(), http.StatusInternalServerError)
          return
        }
        fmt.Fprintf(w, message)
    })

    http.ListenAndServe(":80", nil)
  }
