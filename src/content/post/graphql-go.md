---
date: 2021-11-05T00:00:00-00:00
lastmod: 2021-11-10T20:42:44-03:00
show_reading_time: true
tags: ["graphql", "go", "graphql-go", "controllers", "project structure"]
featured_image: "/images/graphql-go_1.png"
title: "Graphql go"
description: "A simple Golang idiomatic GraphQL approach"
---

# What's this so well know graphql?

Go'tcha, I won't discuss about this at all LoL.

Take a look in those articles below:

- https://www.moesif.com/blog/technical/graphql/REST-vs-GraphQL-APIs-the-good-the-bad-the-ugly/
- https://blog.logrocket.com/why-you-shouldnt-use-graphql/
- https://www.apollographql.com/docs/react/data/operation-best-practices/
- https://graphql.org/
- https://www.youtube.com/watch?v=epKhPB9PJqY&ab_channel=Simplilearn


But, personally, what I think about it:

Good points:
- It can be interesting when the amount of data of each request is relevant (mobile/lightweight apps)
- It can be interesting doing to the reuse of existent resolvers for our types (you'll see an example in this [project])
- It's easier to the backend developer to handle with the errors (without worring about status codes, padronized response bodies and go on)
- It's interesting to have a panel where you can see all available types/queries/mutations and its descriptions

Bad points:
- It's "a pain in the ass" be limited about the folder structure to the resolver and types (due to the "cyclic problem")
- If you mess it up when doing the type, you can allow a huge query that can be used, which will took very processing time.
- Compared to the default http, problably you'll need much more resources in your application.



# Project

To better understand what's the biggest bennefits and how to use a graphql
approach I'll show, in the next sections, how I developed a simple graphql
server.

To be more intuitive I'll follow a flux defined by me self, if you got lost in
some part you can just use the [project] and check it out the full code.

**NOTE** that I won't explain every little detail, I'll give focus on some
of my thoughts during the deployment.

## Project structure

At first, I've tried the "components" folder structure, I mean, I've tried to
split the handlers into each specific folder, however, due to the "resolvers"
you'll problably get stuck when you tried to create a field that's actually
another type and has it's own resolve. This will cause a cyclic import problem
and, since golang [doesn't have a fancy](https://medium.com/@ishagirdhar/import-cycles-in-golang-b467f9f0c5a0)
way to bypass this like [NestJs],
i think that's the not best practice and furthermore, I'll changed it in the
future for something like:


By know, the handlers [^1] of this code is something like this:

<pre>
controllers
├── app
│   ├── builder.go
│   ├── handlers.go
│   ├── query.go
│   └── types.go
└── user
    ├── builder.go
    ├── handlers.go
    ├── mutation_createUser.go
    ├── mutation_editUser.go
    ├── mutation_login.go
    ├── query.go
    └── types.go
</pre>

And I'll change it to be more like this (which i think that will solve the
cyclic dependency):

<pre>
controllers
├── resolvers
├── types
├── handlers
└── build.go
</pre>


Let's skip this small talk and get in into the point.

## Hows the project currently

By now, the project has the following folder structure:

<pre>
.
├── cmd
│   ├── endpoints.go
│   ├── main.go
│   └── middleware.go
├── go.mod
├── go.sum
└── internal
    ├── config
    │   ├── app.go
    │   ├── cli_flags.go
    │   ├── content_type.go
    │   ├── database.go
    │   ├── date.go
    │   └── setup.go
    ├── controllers
    │   ├── app
    │   │   ├── builder.go
    │   │   ├── handlers.go
    │   │   ├── query.go
    │   │   └── types.go
    │   └── user
    │       ├── builder.go
    │       ├── handlers.go
    │       ├── mutation_createUser.go
    │       ├── mutation_editUser.go
    │       ├── mutation_login.go
    │       ├── query.go
    │       └── types.go
    ├── helpers
    │   ├── controller
    │   │   ├── decorators.go
    │   │   ├── errors.go
    │   │   ├── handler.go
    │   │   ├── protect.go
    │   │   ├── request_base.go
    │   │   ├── request_transaction.go
    │   │   └── response.go
    │   ├── graphql
    │   │   └── manager.go
    │   └── validators
    │       ├── bind.go
    │       ├── init.go
    │       └── validate_birthdate.go
    ├── models
    │   ├── login
    │   │   └── payloads.go
    │   ├── payloads.go
    │   └── user
    │       ├── entities.go
    │       └── payloads.go
    ├── repository
    │   ├── migrations
    │   │   ├── 000001_create_users_table.down.sql
    │   │   └── 000001_create_users_table.up.sql
    │   ├── mocks
    │   │   ├── mock.go
    │   │   ├── mock_status.go
    │   │   └── mock_user.go
    │   ├── status
    │   │   ├── statusCurrently.go
    │   │   └── transaction.go
    │   ├── storage.go
    │   ├── transactions.go
    │   └── user
    │       ├── transaction.go
    │       └── user.go
    ├── services
    │   └── jwt
    │       ├── errors.go
    │       ├── handler_refresh.go
    │       ├── jwt.go
    │       ├── middleware.go
    │       └── payload.go
    └── utils
        ├── date.go
        ├── must.go
        ├── struct.go
        └── type.go

21 directories, 58 files
</pre>


Let's dive in.

## CMD

In this folder/package, we have all methods used by the main function, which
includes registering http middlewares and endpoints and go on.

To manage all app variables I'm using the [cli] and yes, I won't be doing many
handwriting job, I mean, if already exists a naive solution, **WHY SHOULD I**
**TAKE THE HARDER WAY?**.

Of course, sometimes you just need 1 variable and,
get a package just to this won't be justified. However, that's not the case
here. I wan't to have full control of my variables and have the possibility
of change each one of them without needing to rebuild all my project.
So, my **main.go** is:

```go
package main

import (
	"os"

	"github.com/ppcamp/go-graphql-with-auth/internal/config"
	postgres "github.com/ppcamp/go-graphql-with-auth/internal/repository"
	"github.com/sirupsen/logrus"
	"github.com/urfave/cli/v2"
)

func main() {
	app := cli.NewApp()
	app.Name = "go-graphql-user"
	app.Usage = "Build the file and execute it and then, make some graphql calls"
	app.Flags = config.Flags
	app.Action = run
	app.Run(os.Args)
}

func run(c *cli.Context) error {
	config.Setup()

	// if config.App.Migrate {
	// 	migrate := migrations.SetupMigrations(c.App.Name, config.Database.Url)
	// 	err := migrate.Up()
	// 	if err != nil {
	// 		logrus.WithError(err).Fatal("failed to migrate the data")
	// 	}
	// }

	storage, err := postgres.NewStorage()
	if err != nil {
		logrus.Fatal("couldn't connect to databaseql")
	}

	r := SetupEngine(storage)
	r.Run(config.App.Address)
	return nil
}
```

The first question that you should be doing is: WHY this code is commented and
yes, I didn't finished 😁

The points that you should pay attention is the **config.Flags** and the **run**
function.

In the run function I'll be instantiating every service that will need to be
passed through our endpoints and some stuffs like that, e.g, our database.

To build our server, I'm using the [gin] framework. Again, **DO I NEED TO USE**
**GIN?** NO, but i'll.

The **middleware.go** is simple to unterstand, so I'll skip it.

## Endpoints

In the **endpoints.go** is where I declare my router/http server and it's
endpoints.

The main part of this function is the **schema** and the **controllers**.

The *userController* and the *appController*, like I told before, problably need
to be replaced by I single unique controller that will have all handlers.


```go
package main

import (
	"github.com/gin-contrib/gzip"
	"github.com/gin-gonic/gin"
	"github.com/ppcamp/go-graphql-with-auth/internal/config"
	"github.com/ppcamp/go-graphql-with-auth/internal/controllers/app"
	"github.com/ppcamp/go-graphql-with-auth/internal/controllers/user"
	"github.com/ppcamp/go-graphql-with-auth/internal/helpers/graphql"
	postgres "github.com/ppcamp/go-graphql-with-auth/internal/repository"
	"github.com/ppcamp/go-graphql-with-auth/internal/services/jwt"
)

func SetupEngine(storage postgres.Storage) *gin.Engine {
	router := gin.New()

	// middlewares
	registerMiddlewares(router)

	// handlers
	schema := graphql.NewSchemaManager()
	userController := user.NewUserControllerBuilder(storage)
	appController := app.NewAppController(storage)

	// Endpoints unprotected
	schema.RegisterQuery("users", userController.QueryUsers())
	schema.RegisterMutation("createUser", userController.CreateUser())
	schema.RegisterMutation("login", userController.Login())

	// Endpoints protected
	schema.RegisterAuthenticatedQuery("app", appController.QueryAppStatus())
	schema.RegisterAuthenticatedMutation("updateUser", userController.EditUser())

	// register
	router.Any("/graphql", schema.Handler())

	return router
}

func registerMiddlewares(router *gin.Engine) {
	middleware := NewMiddleware()

	// Return 500 on panic
	router.Use(gin.Recovery())
	router.Use(gzip.Gzip(gzip.DefaultCompression))

	// Response as JSON every c.Error in requests handler
	router.Use(middleware.Errors)

	// Handle OPTIONS and set default headers like CORS and Content-Type
	router.Use(middleware.Options)
	router.NoRoute(middleware.NotFound)
	router.NoMethod(middleware.MethodNotAllowed)

	// register a middleware to get all JWT auth
	authMiddleware := jwt.NewJwtMiddleware(
		config.App.JWTExp, []byte(config.App.JWTSecret))
	router.Use(authMiddleware.Middleware)
}
```

The **schema** is a class [^2] that's work like a wrapper to the actual graphql
package.

Record that i have two diferent types for **queries** and **mutations**. And
later, you'll understand why.


# Internal packages

In this package I'll defined the scoped packages to this project.
In the **config** package, are all our global [^3] variables that we'll use
in the other packages.

### Logs

You already noted that I really like to use packages 😆. So, here comes another
one to you. Remember when we called the **config.Setup** in our main?
So, here it's.

In this function, we setup our loggers (by the way, I'm using
the [logrus] package).

```go
func Setup() {
	logrus.SetFormatter(&logrus.JSONFormatter{PrettyPrint: App.LogPrettyPrint})
	level, err := logrus.ParseLevel(App.LogLevel)

	if err != nil {
		logrus.WithError(err).Fatal("parsing log level")
	}

	logrus.SetLevel(level)

	logrus.WithFields(logrus.Fields{
		"AppConfig":      App,
		"DatabaseConfig": Database,
	}).Info("Environment variables")

}
```

Why use logrus?

- Logrus cames with a bunch of tools that make our life easier, like change the
  log level (sending all levels bellow to /dev/null) hiding the logs below.
- Print variables/errors easily
- Chaining functions
- and anothers features


### Utils and models

Again, I think that you have some knowledge about golang before reading this
article, of course, you can learn it before, and make some minor tests.
Take a look at https://goplay.tools/.

Basically, those are just packages that define some object/struct and some
generic function that aren't truly correlated to the controllers.

However, i think that's necessary that you understand this:

When you saw something like:

```go
json:"field,omitempty" db:"field" binding:"omitempty,min=3"
```

It means that the package will be marshalized/unmarshilzed basing on this
"field" key and, it can not to be in the object. And, when using the [sqlx] pkg,
it'll use the field as ":field" in the sql/internal marshaller.

The binding are actually, a [validator]. In this case, it won't allow a field
with 3 or less characters, however, due to omitempty, it allows you to don't
send this field and, therefore, won't throw an error validation in this case.


## Repositories and database connections

The **repository** package was build in this way to allow you an easy way to
mock this repository for tests (I do recommend the [testify] library).


## Services/jwt

Since we won't have control of the request due to the handler wrapper, I'll
use a middleware that will register all headers in the request context for each
received request.

And, when we need to get the token we just validate if there's one in the
content.

## Controllers

I won't explain detailed each one of the files here, since they are very simple
to understand. Let's move on.


# helpers

AND HERE IT IS. THE MAIN PACKAGE. THE SOUL OF THIS PROJECT LoL.

In this package i define the main subpackages used by the other functions.

## validators

In the **bind.go** I convert the graphql map into structs, and validate its
fields.

```go
package validators

import (
	"github.com/ppcamp/go-graphql-with-auth/internal/utils"
	"github.com/sirupsen/logrus"
)

func ShouldBind(dict map[string]interface{}, obj interface{}) error {
	err := utils.Bind(dict, obj)
	if err != nil {
		logrus.WithError(err).Fatal("It shouldn't throw an error")
	}

	return Validator.Struct(obj)
}
```
Which is really nice, since after convert, we don't need to worry about
miswrite some field or need to validate every little field manually or mapping
it manually. I think you already note the power here right?


{{< figure src="https://starwarsblog.starwars.com/wp-content/uploads/2018/06/be-more-vader-tall.jpg">}}

Do you remember that we are using the [gin]? The function above it was built
basing on **gin.Context.ShouldBind**.

```go
package validators

import (
	"reflect"
	"strings"

	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"
)

var Validator *validator.Validate

func init() {
	setupValidator()
}

func setupValidator() {
	// if Validator == nil {
	// 	Validator = validator.New()
	// 	Validator.SetTagName("binding")
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		Validator = v
		Validator.RegisterTagNameFunc(func(fld reflect.StructField) string {
			name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
			if name == "-" {
				return ""
			}
			return name
		})

		Validator.RegisterValidation("birthdate", birthdateValidation)
	}
}
```


Furthermore, we can just get the [gin] [validator] instance and register our
new validation function and, even more, we can register a new TagNameFunc,
which, if you need in the future, it can be used to get the json field name
instead of the struct field name.


```go
package validators

import (
	"fmt"

	"github.com/go-playground/validator/v10"
)

func MapErrorsToMessages(err error) (errors []string) {
	for _, err := range err.(validator.ValidationErrors) {
		errors = append(
			errors,
			fmt.Sprintf("Field %v failed validation for %v", err.Field(), err.Tag()))
	}
	return
}
```

Just for example, I've create a birthdateValidation and register it into
validator.

```go
package validators

import (
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/ppcamp/go-graphql-with-auth/internal/utils"
)

var birthdateValidation validator.Func = func(fl validator.FieldLevel) bool {
	birthdate, ok := fl.Field().Interface().(time.Time)
	if ok {
		return utils.IsAValidBirthDate(birthdate)
	}
	return false
}

// How to use?
// type Some struct {
//  Field time.Time `json:"field,omitempty" binding:"birthdateValidation"`
// }
```


## controllers

In this package I define a decorator pattern inside a handler. This give me
more control and flexibility. It's like inserting a middleware between the
actual handler and the function itself.

Basically, in the **request_base.go**, **request_transaction.go** and
**response.go**, I define types and its equivalent interfaces (which will give)
us the possibility of mocking those objects without needing to create a mocking
server and registering all endpoints all over again. Awesome right?

{{< figure src="https://www.cinemaemserie.com.br/wp-content/uploads/2013/11/Barney.jpg">}}

Besides, using this approach we can create and manage the transaction basing
on the response (commiting or don't). Furthermore, we encapsulate the jwt
getter to our middleware and we do the validations and parsing.

To be more clear, I'll post in bellow the whole flux of getting an user query.

```go
// endpoints.go

userController := user.NewUserControllerBuilder(storage)

// a public query (without token)
schema.RegisterQuery("users", userController.QueryUsers())
```

```go
// handlers.go

// [QUERY] user
func (t *UserControllerBuilder) QueryUsers() *graphql.Field {
	return &graphql.Field{
		Type:        graphql.NewList(userType),
		Description: "Get all users",

		Args: graphql.FieldConfigArgument{
			"nick": &graphql.ArgumentConfig{
				Type: graphql.String,
			},
			"email": &graphql.ArgumentConfig{
				Type: graphql.String,
			},
			"id": &graphql.ArgumentConfig{
				Type: graphql.Int,
			},
			"skip": &graphql.ArgumentConfig{
				Type: graphql.Int,
			},
			"take": &graphql.ArgumentConfig{
				Type: graphql.Int,
			},
		},

		Resolve: func(p graphql.ResolveParams) (interface{}, error) {
			return t.handler.Request(p, &usermodels.UserQueryPayload{}, NewQueryUserController())
		},
	}
}
```

Note the call to our defined controller decorator. This will parse the args and
send them to the actual handler. And, basing on the type of
NewQueryUserController, will create (or don't), the transaction.

```go
// query.go

type QueryUserController struct {
	controller.TransactionControllerImpl
}

func (c *QueryUserController) Execute(pl interface{}) (result controller.ResponseController) {
	result = controller.NewResponseController()
	filter := pl.(*usermodels.UserQueryPayload)

	users, err := c.Transaction.FindUsers(filter)
	result.SetError(err)
	result.SetResponse(users)
	return
}

func NewQueryUserController() controller.TransactionController {
	return &QueryUserController{}
}
```

Note that by now, the filter it's already parsed and valid and, if we return
some error in the result, the transacion won't be commited.

I bet that you liked, 'cause I did 😎.


## finally, the graphql package

You should be asking: WHY YOU DID A PACKAGE JUST FOR WRAPPING THE GRAPHQL-GO?.
It's just keep the more simplier that it can be.

We starting by defining some internal fields and our schema manager.

```go
package graphql

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/graphql-go/graphql"
	"github.com/graphql-go/handler"
	"github.com/ppcamp/go-graphql-with-auth/internal/helpers/controller"
)

type Schema struct {
	queries   graphql.Fields
	mutations graphql.Fields

	authQueries   graphql.Fields
	authMutations graphql.Fields
}

func NewSchemaManager() *Schema {
	return &Schema{
		queries:       graphql.Fields{},
		mutations:     graphql.Fields{},
		authQueries:   graphql.Fields{},
		authMutations: graphql.Fields{},
	}
}

func (s *Schema) RegisterQuery(fieldName string, fieldValue *graphql.Field) {
	s.queries[fieldName] = fieldValue
}

func (s *Schema) RegisterMutation(fieldName string, fieldValue *graphql.Field) {
	s.mutations[fieldName] = fieldValue
}

func (s *Schema) RegisterAuthenticatedQuery(fieldName string, fieldValue *graphql.Field) {
	s.authQueries[fieldName] = fieldValue
}

func (s *Schema) RegisterAuthenticatedMutation(fieldName string, fieldValue *graphql.Field) {
	s.authMutations[fieldName] = fieldValue
}
```

Basically, in the [graphql-go] we don't have a way to increase this queries
when they already has been added to the object [^4].

By creating a simple object that will be the father and, consequently the root
object and, changing it's resolver to a single one that will only validate
if the token is valid or don't, we can write something like this:

```go
func (s *Schema) registerAuthQueries() {
	if len(s.authQueries) > 0 {
		var me = graphql.NewObject(
			graphql.ObjectConfig{
				Name:        "MeQuery",
				Description: "Type to encapsulate all authenticated queries",
				Fields:      s.authQueries,
			},
		)

		s.queries["me"] = &graphql.Field{
			Type:        me,
			Description: "Run some query with jwt auth",
			Resolve:     controller.AuthorizedOnly,
		}
	}
}

func (s *Schema) registerAuthMutations() {
	if len(s.authMutations) > 0 {
		var me = graphql.NewObject(
			graphql.ObjectConfig{
				Name:        "MeMutation",
				Description: "Type to encapsulate all authenticated queries",
				Fields:      s.authMutations,
			},
		)

		s.mutations["me"] = &graphql.Field{
			Type:        me,
			Description: "Run some mutation with jwt auth",
			Resolve:     controller.AuthorizedOnly,
		}
	}
}
```

Where the **controller.AuthorizedOnly** is defined in our beautifull helper.

```go
package controller

import (
	"github.com/graphql-go/graphql"
	"github.com/ppcamp/go-graphql-with-auth/internal/services/jwt"
)

func AuthorizedOnly(p graphql.ResolveParams) (interface{}, error) {
	_, err := jwt.GetSession(p.Context)
	if err != nil {
		return nil, err
	} else {
		return graphql.Field{}, err
	}
}
```


**FINALLY** we need to register our handlers and pass our [gin] Context into the
[graphql-go] (graphql.ResolveParams)

```go
func (s *Schema) getSchemas() graphql.Schema {
	s.registerAuthQueries()
	s.registerAuthMutations()

	// Schema
	schema, err := graphql.NewSchema(graphql.SchemaConfig{
		Query: graphql.NewObject(graphql.ObjectConfig{
			Name:        "Query",
			Description: "All elements that can be fetched",
			Fields:      s.queries,
		}),
		Mutation: graphql.NewObject(graphql.ObjectConfig{
			Name:        "Mutation",
			Description: "All functions that make some change in API",
			Fields:      s.mutations,
		}),
	})

	if err != nil {
		log.Fatalf("failed to create new schema, error: %v", err)
	}

	return schema
}

// Handler is a closure that will wrap the schema and return a proper gin
// handler
func (s *Schema) Handler() gin.HandlerFunc {
	schema := s.getSchemas()

	h := handler.New(&handler.Config{
		Schema:   &schema,
		Pretty:   true,
		GraphiQL: true,
		// Playground: true,
	})

	return func(c *gin.Context) {
		h.ContextHandler(c, c.Writer, c.Request)
	}
}

```

# Conclusions

In the end, you need to put in the balance if is it really necessary to
implement the graphql approach. In my cause, there's only one case that I should
have used instead of RESTfull API until now.

I didn't finished the project yet and I don't know if I'll,
but let me told you what needs to be done:

- Add the [migration] into the startup routine
- refactor the controllers module
- create new type/resolve/repository for books (a user has books)
- create unitary tests.


If I made some mistake, or if you have some suggestion, ping me in the
discussion below or send me a message.

The full project can be found [here][project].

Best regards,

@ppcamp


### Another links

- https://www.apollographql.com/docs/studio/explorer/


<!-- Footnotes -->

[^1]: Handlers are the name for all methods/packages that controls the request/
response

[^2]: I'm calling **class**, however, it's just a struct with some methods
assigned to it

[^3]: Actually, those variables are packaged scoped.

[^4]: At least, i didn't found.




<!-- LINKS -->

[NestJs]: https://docs.nestjs.com/fundamentals/circular-dependency
[cli]: https://github.com/urfave/cli
[project]: https://github.com/ppcamp/go-graphql-with-auth
[gin]: https://github.com/gin-gonic/gin
[logrus]: https://github.com/sirupsen/logrus
[sqlx]: http://jmoiron.github.io/sqlx/
[validator]: https://github.com/go-playground/validator
[testify]: https://github.com/stretchr/testify
[graphql-go]: https://github.com/graphql-go/graphql
[migration]: https://github.com/golang-migrate/migrate