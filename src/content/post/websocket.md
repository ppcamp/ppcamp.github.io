---
date: 2021-12-31T00:00:00-00:00
lastmod: 2021-12-31T00:00:00-00:00
show_reading_time: true
tags: ["golang", "websocket"]
title: "Websocket"
mermaid: true
---

**Post under deployment**


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
  A([Client]) --> |start a ticker-loop| B{Ticker};
  B --> |triggered| C[Make request to server];
  B --> |no| D((Do nothing))
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
[Websocket LightWeight Client-Server Communications] book. The code itself
can be found in this [link][tag-book-ch3].

## HTML/Client view

Basic html header to use [Bootstrap v3.2.0] ([link](https://github.com/ppcamp/go-websocket/blob/book-ch3/public/index.html)).

With the HTML/Client code in hands, you'll need to make the server part.

## Server

The server uses the [gorilla] library. In the project, you can find some samples
about how to implement a websocket server. In this project, I took the
[chat example](https://github.com/gorilla/websocket/tree/master/examples/chat)
as a base to developed code.

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

In the main fn I use the [cli] to read the environment variables and create
helpers to the binary.

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
[long polling]: https://www.pubnub.com/blog/http-long-polling/
[project]: https://github.com/ppcamp/go-websocket
[tag-book-ch3]: https://github.com/ppcamp/go-websocket/tree/book-ch3
[Bootstrap v3.2.0]: https://getbootstrap.com/docs/versions/
[gorilla]: https://github.com/gorilla/websocket