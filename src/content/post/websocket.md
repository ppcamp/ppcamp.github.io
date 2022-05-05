---
date: 2021-12-31T00:00:00-00:00
lastmod: 2021-12-31T00:00:00-00:00
show_reading_time: true
tags: ["golang", "websocket"]
title: "Websocket"
description: "A simple websocket approach using gorilla library in Go"
featured_image: "/images/go-websocket-2.png"
mermaid: true
---


# What's websocket?

[Websocket] is a technology that is used to swap messages between two or more
peers without create a HTTP request connection every time.
It's usually used to create real-time [web applications], social network feeds,
[PWA] and push notifications, chats, etc. In Ubuntu based distributions, for
example, you can use a websocket server that will have a thread to every amount
of time, refresh some data and trigger a new event, making system-calls to the
[notify-send](http://vaskovsky.net/notify-send/linux.html) program, which will
show you a notification in your desktop. In `notify-send` you also can
[change the icons](https://askubuntu.com/a/189262).

```sh
# Install notify-send if you don't have it yet
sudo apt-get install libnotify-bin

# Send a message
# notify-send [OPTIONS...] "TITLE" "MESSAGE"
notify-send "Some Title" "Some message"
```

Which produces the following float message:

{{< figure src="/images/go-websocket-1.png" >}}

In youtube you'll find great explanations videos about websocket, bellow you can
check one of them


{{< youtube url="https://www.youtube.com/embed/i5OVcTdt_OU?start=134" >}}


# Why you should use websocket?

According to the book [Websocket LightWeight Client-Server Communications]:

> WebSocket gives you the ability to use an upgraded HTTP request (Chapter 8 covers
> the particulars), and send data in a message-based way, similar to UDP and with all
> the reliability of TCP. This means a single connection, and the ability to send data
> back and forth between client and server with negligible penalty in resource utiliza‐
> tion. You can also layer another protocol on top of WebSocket, and provide it in a
> secure way over TLS. Later chapters dive deeper into these and other features such as
> heartbeating, origin domain, and more.

In this same book, the author claims that using a [long polling] technique will
overhead your server resources.
Basically, the flow that exemplifies the [long polling] is described as

{{<mermaid>}}
sequenceDiagram
  Client->>Server: Start a request and await until response
  Server-->>Client: Server respond
  Client->>Server: Close the current request and start a new one
{{</mermaid>}}

Another way of achieving this is to control the refresh rate in the client side
by using `tickers` and basic requests, for example, imagine that you wanna make
a social media feed.

{{<mermaid>}}
flowchart TD;
  A([Client]) --> |start a ticker-loop| B{Ticker}
  B -- triggered --> C[Make request to server]
  B -- no --- B
  C --> E[Get response]
  E --> |enqueue a new request| B
  G([User]) --> |can stop the polling by removing| J[Remove the ticker call]
{{</mermaid>}}

To implement this you can, from time to time, make `GET`
requests in a simple code using the `setTimeout` approach[^1].

```js
const refresh = {
  'REFRESH_TIME_MS': 3e3, // 3s
  'refresh_handler': null,
  'stop': async function () {
    clearInterval(this.refresh_handler);
  },
  'start': async function () {
    // fetching data
    // Default options are marked with *
    const response = await fetch(url, {
      method: 'POST', // *GET, POST, PUT, DELETE, etc.
      mode: 'cors', // no-cors, *cors, same-origin
      cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
      credentials: 'same-origin', // include, *same-origin, omit
      headers: {
        'Content-Type': 'application/json'
        // 'Content-Type': 'application/x-www-form-urlencoded',
      },
      redirect: 'follow', // manual, *follow, error
      referrerPolicy: 'no-referrer', // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
      body: JSON.stringify(data) // body data type must match "Content-Type" header
    });

    console.log('Got data');

    // enqeue a new call to refresh fn
    this.refresh_handler = setInterval(refresh, this.REFRESH_TIME_MS);

    return response;
  }
}

// make requests from time to time
refresh.start()

// clear the object from the queue (stop polling)
// refresh.stop()
```


Anyway, basically, when using a websocket connection you'll be able to:
- keep a connection alive, without overhead your server
- send biderectional messages anytime, giving you a connection "based on events"[^2]
- due to the item above, you basically have a **real-time** environment.
- [low latency](https://stackoverflow.com/questions/44898882/why-to-use-websocket-and-what-is-the-advantage-of-using-it)


However, the websocket approach will force you to have **more goroutines open**
in a *Golang* environment.

![websocket connections meme](https://qph.fs.quoracdn.net/main-qimg-56548855e60ebb055d328e4400a1b916.webp)


Basically, at this point, I'm assuming that you
already searched about websockets, and you do know that every technology has a
treadoff[^3].


What I'm trying to say is:

> "Don't use a hammer for a screw"

Let's talk about the code itself.

# Part 1

In this part, I plan to reach the project described in the
[Websocket LightWeight Client-Server Communications] book until chapter 4.
The code itself can be found in this [link][tag-book-ch3].

## HTML/Client view

The author gave to us a basic html, which uses
[Bootstrap v3.2.0] ([link](https://github.com/ppcamp/go-websocket/blob/book-ch3/public/index.html)). Since that I ain't focusing on web/client, I won't rewrite it
into [Bootstrap v5.0](https://getbootstrap.com/docs/5.0/getting-started/introduction/).
However, if you have some free time, take a look into it.

With the HTML/Client code in hands, you'll need to make the server part.

## Server

The server uses the [gorilla] library. In the project, you can find some samples
about how to implement a websocket server. In this project, I took the
[chat example](https://github.com/gorilla/websocket/tree/master/examples/chat)
as a base to delop the code.

Here is the folder structure until now:

```
.
├── public
│   └── index.html
├── README.md
└── src
    ├── cmd
    │   └── main.go
    ├── go.mod
    ├── go.sum
    ├── internal
    │   ├── app
    │   │   └── run.go
    │   ├── config
    │   │   ├── app.go
    │   │   ├── date.go
    │   │   ├── flags.go
    │   │   └── log.go
    │   └── controllers
    │       ├── home.go
    │       └── websocket.go
    └── pkg
        ├── helpers
        │   ├── log.go
        │   └── websocket.go
        ├── models
        ├── repository
        ├── services
        │   └── websocket
        │       ├── client.go
        │       ├── events.go
        │       ├── model.go
        │       └── server.go
        └── utils
            ├── must.go
            └── string.go
```

In the main **func** I use the [cli](https://github.com/urfave/cli)
to read the environment variables and create
helpers to the binary.

**file:** *src/cmd/main.go*
```go
package main

import (
	"github.com/urfave/cli/v2"
	"os"
	"src/internal/app"
	"src/internal/config"
)

func main() {
	application := cli.NewApp()
	application.Name = "go-websocket"
	application.Description = "A Golang simple websocket server"
	application.Usage = "go-websocket server || go-websocket client 'name'"
	application.Flags = config.Flags
	application.Action = app.Run
	application.Run(os.Args)
}
```

The flags/env variables are defined in the file *src/internal/config/flags.go*.

> To make a tutorial more concise, I won't show all files. I'll focusing only
> in the websocket part.

At first, we need to expose a Http connection, that later will be **"Upgraded"**
into a *Websocket connection*.

First of all, we need to create the server logic.

{{<mermaid>}}
flowchart TD;
  C([Some Client]) --> |request a new HTTP connection| S([Server])
  S --> T[/Transform HTTP into WebSocket/]
  T --> J[/Create a new client and register it into the/]
  J --> H((Hub))
  C -- sends a wss message to the --> H
  H --> |broadcast| C1([Client#1])
  H --> |broadcast| C2([Client#2])
  H --> |broadcast| C3([Client#3])
  H --> |broadcast| CN([Client#N])
{{</mermaid>}}


**file:** *src/internal/app/run.go*
```go
package app

import (
	"log"
	"net/http"
	"src/internal/config"
	"src/internal/controllers"
	"src/pkg/services/websocket"

	"github.com/urfave/cli/v2"
)

func Run(_ *cli.Context) error {
	config.SetupLoggers()

	ws := websocket.NewServer()
	go ws.Start()
	wrap := func(w http.ResponseWriter, r *http.Request) { controllers.Websocket(ws, w, r) }

	http.HandleFunc("/", controllers.Home)
	http.HandleFunc("/ws", wrap)

	err := http.ListenAndServe(config.App.Address, nil)
	if err != nil {
		log.Fatalln(err)
	}
	return nil
}
```

---

The **websocket.NerServer** return to us an object, that is actually, the server
itself, the "main" hub.

**file:** *src/pkg/services/websocket/events|model.go*

```go
package websocket

type SocketEventType string

const (
	Message      SocketEventType = "message"
	Notification SocketEventType = "notification"
	NickUpdate   SocketEventType = "nick_update"
)

const (
	OpChangeNick = "/nick"
)



type SocketMessage struct {
	Type     SocketEventType `json:"type"`
	Id       string          `json:"id"`
	Nickname string          `json:"nickname"`
	Message  *string         `json:"message"`
}
```

---
### Clients

The clients are defined in the

**file:** *src/pkg/services/websocket/client.go*


```go
package websocket

import (
	"bytes"
	"fmt"
	"src/pkg/helpers"
	"src/pkg/utils"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var logClient = helpers.NewModuleLogger("WebSocketClient")

const (
	writeWait      = 10 * time.Second    // Time allowed to Write a message
	pongWait       = 60 * time.Second    // Time allowed to Read the next pong
	pingPeriod     = (pongWait * 9) / 10 // Send pings to peer with this period
	maxMessageSize = bytes.MinRead       // Maximum message size (in bytes)
)

type Client struct {
	socket *websocket.Conn

	Uuid    string
	Nick    string
	addr    string
	Message chan string
	hub     *Server
}

func NewClient(socket *websocket.Conn, server *Server) *Client {
	addr := socket.RemoteAddr()
	uuid := utils.Must(uuid.NewRandom()).(uuid.UUID)
	nick := fmt.Sprintf("AnonymousUser%d", server.UsersLength())

	return &Client{
		Uuid:    strings.Replace(uuid.String(), "-", "", -1),
		socket:  socket,
		hub:     server,
		Message: make(chan string),
		Nick:    nick,
		addr:    utils.Must(helpers.WebsocketAddress(addr)).(string),
	}
}

```

Like in the [book], we'll implement the function of change nick

```go
func (c *Client) changeNick(msg string) {
	contentArray := strings.Split(msg, " ")
	if len(contentArray) >= 2 {
		old := c.Nick
		c.Nick = contentArray[1]
		message := fmt.Sprintf("Client %s changed to %s", old, c.Nick)

    // Broadicasting the message to the clients. It'll be explained later on
		c.hub.Send(NickUpdate, &c.Uuid, &c.Nick, message)
	}
}
```


Differently of the NodeJS implementation, which we don't need to worry about the
inner methods and communication, in Golang we need to, therefore, it's necessary
to create to methods, one of them will be responsable for
**read a message channel and write the data into the current peer**, the other
one, will be responsable to
**read the received websocket message and send it to the HUB**

```go
// read Opens a thread that will be listening to the
// websocket. It'll be responsible to send the messages got into the Server/hub
func (c *Client) read() {
	defer func() {
		c.hub.UnregisterClient(c)
		c.socket.Close()
	}()

  // set the maximum amount of bytes that will be allowed to read from the
  // websocket. If it's greater than this, it'll close the connection
	c.socket.SetReadLimit(maxMessageSize)

  // set the maximum amount of time that is acceptable to receive the answer from
  // the client
	c.socket.SetReadDeadline(time.Now().Add(pongWait))

  // set the function when receive a pong.
  // the websocket sent ping and receive pong messages from time to time
  // to check if the client is still connected
  // when we receive a pong message, we'll reset the reading deadline, to allow
  // the client to still send messages.
	c.socket.SetPongHandler(func(string) error { c.socket.SetReadDeadline(time.Now().Add(pongWait)); return nil })

	for {
		_, message, err := c.socket.ReadMessage()
		if err != nil {
      // note that I ain't checking the type of the error here, but you can
      // use the websocket.IsUnexpectedCloseError(err, ...errorsArray)
      // function to validate it
			c.socket.WriteMessage(websocket.TextMessage, []byte("Fail to read message"))
			return
		}
		msg := string(message)

		// Client/Socket operations
		if utils.StartsWith(msg, OpChangeNick) {
			c.changeNick(msg)
		} else {
			c.hub.Send(Message, &c.Uuid, &c.Nick, msg)
		}
	}
}
```

By now, we are able to receive any messages sent from the html page (client).
However, we aren't sent messages to the client yet. To make this, we need to
spawn the write thread.

```go
// write the messages read from the message channel
// and write it into the socket. This method close the socket connection
// when some errors occurs, therefore, it'll raise an error in the read,
// which will unregister the client
func (c *Client) write() {
  // the ticker will be used to check if we still have connection with the
  // websocket client
	ticker := time.NewTicker(pingPeriod)

  defer func() {
		ticker.Stop()
		c.socket.Close()
	}()


	for {
		select {

		case message, ok := <-c.Message:
      // we receive a message from the HUB to be sent to the current user
			if !ok {
				logClient.WithField("client", c.Uuid).Warn("The server closed the channel")
				c.socket.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

      // the maximum amount of time to write the message into the websocket client
			c.socket.SetWriteDeadline(time.Now().Add(writeWait))
			err := c.socket.WriteMessage(websocket.TextMessage, []byte(message))
			if err != nil {
				logClient.WithField("client", c.Uuid).Warn(err)
				return
			}

		case <-ticker.C:
      // in the current loop, the channel who send a message was the ticker
      // in this case, we'll send a ping to check if the client (html page) are
      // still connected. For example, if we close our browser tab, the conn
      // will be lost, and when the server send the ping, it'll raise an error
      // and then, will remove the client from our hub and free the memory and
      // goroutines.
			c.socket.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.socket.WriteMessage(websocket.PingMessage, nil); err != nil {
				logClient.WithField("client", c.Uuid).
					WithError(err).
					Warn("A ping message was sent and the client didn't respond. Removing the client...")
				return
			}
		}
	}
}
```

The start function is just a method to spawn those functions concurrently.

```go
// Start two goroutines to handle with read and write to the websocket clients
// connected
func (c *Client) Start() {
	go c.read()
	go c.write()

	logClient.WithField("client", c.Uuid).Info("Started")
}

// Close the Message channel used to swap messages between clients and server
// management
func (c *Client) Close() {
	logClient.WithField("client", c.Uuid).Info("Closed")
	close(c.Message)
}

// Locals gets the client local port
func (c *Client) Locals() *string { return &c.addr }

// Id gets the client unique id
func (c *Client) Id() *string { return &c.Uuid }
```

---

### Server

**file:** *src/pkg/services/websocket/server.go*

Now, getting back to the **Server** implementation,
we need to define the `Start` method, which is spawned by the `Run`.


```go
package websocket

import (
	"encoding/json"
	"src/pkg/helpers"
	"src/pkg/utils"

	"github.com/sirupsen/logrus"
)

type Server struct {
	clients map[*string]*Client

	// messages that will be sent to the others (all)
	broadcast chan string

	// register a new client
	register chan *Client

	// unregister a client
	unregister chan *Client

	log *logrus.Entry
}

// NewServer create and returns a new websocket server
func NewServer() *Server {
	return &Server{
		clients:    make(map[*string]*Client),
		broadcast:  make(chan string),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		log:        helpers.NewModuleLogger("WebSocketServer"),
	}
}

```


```go
func (s *Server) addClient(c *Client) {
	s.clients[c.Id()] = c
}

func (s *Server) removeClient(c *Client) {
	if _, ok := s.clients[c.Id()]; ok {
		delete(s.clients, c.Id())
		c.Close()
	}
}

func (s *Server) RegisterClient(c *Client) {
	s.log.Infof("client %s registered", *c.Id())
	s.register <- c
}
func (s *Server) UnregisterClient(c *Client) {
	s.log.Infof("client %s removed", *c.Id())
	message := c.Nick + " has disconnected"
	s.unregister <- c
	s.Send(Notification, &c.Uuid, &c.Nick, message)
}

// Start the websocket server
// TODO: must implement a stop to the server
//
// Example:
//	ws := websocket.NewServer()
//	go ws.Start()
func (s *Server) Start() {
	for {
		select {
		case client := <-s.register:
			s.addClient(client)

		case client := <-s.unregister:
			s.removeClient(client)

		case message := <-s.broadcast:
			// broadcast to clients
			for name := range s.clients {
				select {
				case s.clients[name].Message <- message:
				default:
					s.removeClient(s.clients[name])
				}
			}
		}
	}
}

func (s *Server) Send(t SocketEventType, clientId, nick *string, message string) {
	obj := utils.Must(json.Marshal(SocketMessage{t, *clientId, *nick, &message})).([]byte)
	s.broadcast <- string(obj)
}

func (s *Server) UsersLength() int { return len(s.clients) }

```

---

### Serving the html page

Finally, we need to serve the html to the user connect into it.

**file:** *src/internal/controllers/home.go*
```go
package controllers

import (
	"log"
	"net/http"
	"src/internal/config"
)

func Home(w http.ResponseWriter, r *http.Request) {
	log.Println(r.URL)

	if r.URL.Path != "/" {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	http.ServeFile(w, r, config.App.PublicFolder)
}

```

## Results

The results can be seen in the image below

{{< figure src="/images/go-websocket-2.png" >}}


## Conclusions

With this tutorial I expect that you can have a clear understanding of how
to implement websocket, when use, and the treadoffs of using it.

Feel free to send me a message improving this code or making some appointments
about my text.

{{<thanks>}}


<!--                            Footnotes
-->

[^1]: [Here](https://brianchildress.co/simple-polling-using-settimeout/), or
[here](https://btholt.github.io/complete-intro-to-realtime/settimeout)
you can see a good way to visualise it.
You must avoid use the `setInterval` because it can, sometimes, block your
main thread. Furthermore, it may force your program to keep open, even if you
closed your app 'cause it'll stay in the threadpool/mainloop. Check it out
[here](https://weblogs.asp.net/bleroy/setinterval-is-moderately-evil), or
[here](https://dev.to/akanksha_9560/why-not-to-use-setinterval--2na9#:~:text=In%20case%20of%20time%20intensive,clearInterval%20function%20to%20stop%20it.) to read more about it.

[^2]: [Websocket for push notifications](https://stackoverflow.com/questions/31035467/for-a-push-notification-is-a-websocket-mandatory/31042439#31042439)

[^3]: [When use a http or a websocket](https://blogs.windows.com/windowsdeveloper/2016/03/14/when-to-use-a-http-call-instead-of-a-websocket-or-http-2-0/)


<!--                          Links
-->

[Websocket LightWeight Client-Server Communications]: https://www.google.com.br/books/edition/WebSocket/BpaJCgAAQBAJ?hl=en&gbpv=0
[book]: https://www.google.com.br/books/edition/WebSocket/BpaJCgAAQBAJ?hl=en&gbpv=0
[long polling]: https://www.pubnub.com/blog/http-long-polling/
[project]: https://github.com/ppcamp/go-websocket
[tag-book-ch3]: https://github.com/ppcamp/go-websocket/tree/book-ch3
[Bootstrap v3.2.0]: https://getbootstrap.com/docs/versions/
[gorilla]: https://github.com/gorilla/websocket
[PWA]: https://www.reactpwa.com/docs/en/feature-pwa.html
[websocket]: https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API
[web applications]: https://developers.google.com/web/ilt/pwa/introduction-to-progressive-web-app-architectures