---
date: 2022-05-22T00:00:00-00:00
lastmod: 2022-05-22T00:00:00-00:00
show_reading_time: true
tags: ["nodejs", "vscode", "environment", "setup", "asdf", "venv", "nvm"]
featured_image: "/images/vscontainer.png"
title: "Dev environment in vscode using containers"
description: "How to use a docker image as environment for developing under vscode"
---


# Introduction

Usually programmers need to have multiple environments, when its attributions depends on maintaining
legacies programs.

## The problem

If you need some library or resource that only exist in a specific version, you'll need
to work with it, and due to this, you'll need to have multiple environments.

## Some approaches

To achieve this, you can try multiples approaches, like use a virtual machine (a virtual box, for
example). Another good approach, is having **virtual environments**, however, this approach is not
generic, hence it depends on tools built for each language, for example, to nodejs you can use
[nvm], to python, you can use [venv]. If you're under a linux distribution, you can, on your own,
use the `PATH` variable to use different versions.

Furthermore, many tools were created. One of them, was the [asdf], which is just a tool to manage
the program version locally, or globally.


# VsCode

The [vscode] is an editor built by Microsoft. This editor is built upon the [electron] framework,
and therefore, it is just like an browser listening to an specific port of your server/app.

Hence the vscode depends mainly of a server, they made some changes, and with those changes, by
now, in the version 1.67.2, the vscode server can be run in a different computer.

One of the main point that make vscode so popular, it is your modularity and its easiness to use.
And with so, the Microsoft team built some important [extensions] to complement this simple editor.

Some of those extensions, are to make it easier to connect with another servers, and doing so,
you can have extensions running under those servers and dealing the heavy load, while your client
computer just need to get the processed information and sending text to it.

Searching in the vscode **Extensions:Marketplace**, you can install the [Remote Development]
extension, which will give you the "ability" to connect to others servers using different
connections protocols.

Using the **SSH-Targets**, you can setup a server machine into gcloud, aws, or equivalent, and
connect with them using the ssh config file.

# Vscode - SSH

After setup the vscode server, you must to create a SSH file, like the example bellow.

> The file bellow assumes that you already configured an ssh key and stored it in the server.
> You can see more [here][1] about how to create and store keys.

```
Host default
  HostName 127.0.0.1
  User someuser
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile D:/someFolder/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

[Here][2] you can read more about the ssh server setup.


# Docker

[Docker][docker] is well known as a good way to maintain multiples programs, without worrying about
the platform which the program will be released.
According to the [docker] documentation:

<cite>
Docker is an open platform for developing, shipping, and running applications. Docker enables you
to separate your applications from your infrastructure so you can deliver software quickly.
With Docker, you can manage your infrastructure in the same ways you manage your applications
</cite>

Docker is also used as base for other tools, like [k8s]/[rancher].


# Vscode - Containers

With this said, you can with some work, create your own docker image and run it inside a container.
After this, you can connect using an ssh connection.

However, this approach will consume a lot of time to make the whole setup, and again, like said
before, the vscode teams tries to make it easier for us. Therefore, the team created a "container"
extension, which with some simple steps, allow you to have an **isolated specific environment**.


## So, how to make this setup?

First of all, you'll need the docker installed and running. Also, you'll need to install the
[extensions].

To create a new environment, you can follow the video bellow:

<iframe
    width="560"
    height="315"
    src="https://www.youtube-nocookie.com/embed/Uvf2FVS1F8k"
    title="YouTube video player"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen
/>


## A NodeJS setup environment

Folder structure:

```
.
├── .devcontainer
│   ├── devcontainer.json
│   └── Dockerfile
├── src
│   ├── build
│   │   └── index.js
│   ├── index.ts
│   ├── package.json
│   ├── package-lock.json
│   └── tsconfig.json
└── .vscode
    ├── extensions.json
    └── launch.json

4 directories, 9 files
```

`devcontainer.json`

```json
// For format details, see https://aka.ms/devcontainer.json. For config options, see the README at:
// https://github.com/microsoft/vscode-dev-containers/tree/v0.234.0/containers/javascript-node
{
        "name": "Node.js",
        "build": {
                "dockerfile": "Dockerfile",
                // Update 'VARIANT' to pick a Node version: 18, 16, 14.
                // Append -bullseye or -buster to pin to an OS version.
                // Use -bullseye variants on local arm64/Apple Silicon.
                "args": { "VARIANT": "18-buster" }
        },

        // Set *default* container specific settings.json values on container create.
        "settings": {},

        // Add the IDs of extensions you want installed when the container is created.
        "extensions": [
                "dbaeumer.vscode-eslint",
                "ms-vscode.vscode-typescript-tslint-plugin",
                "esbenp.prettier-vscode",
                "VisualStudioExptTeam.vscodeintellicode",
                "mhutchie.git-graph"
        ],

        // Use 'forwardPorts' to make a list of ports inside the container available locally.
        // "forwardPorts": [],

        // Use 'postCreateCommand' to run commands after the container is created.
        // "postCreateCommand": "yarn install",

        // Comment out to connect as root instead. More info: https://aka.ms/vscode-remote/containers/non-root.
        "remoteUser": "node",
        "features": {
                "git": "latest"
        }
}
```

`.devcontainer/Dockerfile`

```Dockerfile
# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.234.0/containers/javascript-node/.devcontainer/base.Dockerfile

# [Choice] Node.js version (use -bullseye variants on local arm64/Apple Silicon): 18, 16, 14, 18-bullseye, 16-bullseye, 14-bullseye, 18-buster, 16-buster, 14-buster
ARG VARIANT="18-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:0-${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment if you want to install an additional version of node using nvm
# ARG EXTRA_NODE_VERSION=10
# RUN su node -c "source /usr/local/share/nvm/nvm.sh && nvm install ${EXTRA_NODE_VERSION}"

# [Optional] Uncomment if you want to install more global node modules
# RUN su node -c "npm install -g <your-package-list-here>"
```

`.vscode/extensions.json`


```json
{
    "recommendations": [
        "ms-vscode-remote.remote-containers",
        "ms-azuretools.vscode-docker",
        "visualstudioexptteam.vscodeintellicode",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-typescript-tslint-plugin",
        "mhutchie.git-graph"
    ]
}
```


`.vscode/launch.json`

```json
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "type": "pwa-node",
            "request": "launch",
            "name": "Launch Program",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "program": "${workspaceFolder}/src/index.js"
        }
    ]
}
```


`src/index.ts`

```ts
const a: number = 5;
const b: number = 1;

export function hello(who: string): string {return `Hello ${who}`;}

console.log("Some code test ", a + b);
console.log(hello("world"));
```

`src/package.json`

```json
{
  "name": "src",
  "version": "1.0.0",
  "description": "Just a simple nodejs",
  "main": "index.js",
  "type": "commonjs",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "build": "npx tsc",
    "start": "node build/index.js"
  },
  "keywords": [
    "vscode",
    "container",
    "environment"
  ],
  "author": "ppcamp",
  "license": "ISC",
  "devDependencies": {
    "typescript": "^4.6.4"
  }
}
```

`src/tsconfig.json`

```json
{
  "compilerOptions": {
    /* Visit https://aka.ms/tsconfig.json to read more about this file */

    /* Projects */
    // "incremental": true,                              /* Enable incremental compilation */
    // "composite": true,                                /* Enable constraints that allow a TypeScript project to be used with project references. */
    // "tsBuildInfoFile": "./",                          /* Specify the folder for .tsbuildinfo incremental compilation files. */
    // "disableSourceOfProjectReferenceRedirect": true,  /* Disable preferring source files instead of declaration files when referencing composite projects */
    // "disableSolutionSearching": true,                 /* Opt a project out of multi-project reference checking when editing. */
    // "disableReferencedProjectLoad": true,             /* Reduce the number of projects loaded automatically by TypeScript. */

    /* Language and Environment */
    "target": "es2016",                                  /* Set the JavaScript language version for emitted JavaScript and include compatible library declarations. */
    // "lib": [],                                        /* Specify a set of bundled library declaration files that describe the target runtime environment. */
    // "jsx": "preserve",                                /* Specify what JSX code is generated. */
    // "experimentalDecorators": true,                   /* Enable experimental support for TC39 stage 2 draft decorators. */
    // "emitDecoratorMetadata": true,                    /* Emit design-type metadata for decorated declarations in source files. */
    // "jsxFactory": "",                                 /* Specify the JSX factory function used when targeting React JSX emit, e.g. 'React.createElement' or 'h' */
    // "jsxFragmentFactory": "",                         /* Specify the JSX Fragment reference used for fragments when targeting React JSX emit e.g. 'React.Fragment' or 'Fragment'. */
    // "jsxImportSource": "",                            /* Specify module specifier used to import the JSX factory functions when using `jsx: react-jsx*`.` */
    // "reactNamespace": "",                             /* Specify the object invoked for `createElement`. This only applies when targeting `react` JSX emit. */
    // "noLib": true,                                    /* Disable including any library files, including the default lib.d.ts. */
    // "useDefineForClassFields": true,                  /* Emit ECMAScript-standard-compliant class fields. */

    /* Modules */
    "module": "commonjs",                                /* Specify what module code is generated. */
    //  "rootDir": "./",                                  /* Specify the root folder within your source files. */
    // "moduleResolution": "node",                       /* Specify how TypeScript looks up a file from a given module specifier. */
    // "baseUrl": "./",                                  /* Specify the base directory to resolve non-relative module names. */
    // "paths": {},                                      /* Specify a set of entries that re-map imports to additional lookup locations. */
    // "rootDirs": [],                                   /* Allow multiple folders to be treated as one when resolving modules. */
    // "typeRoots": [],                                  /* Specify multiple folders that act like `./node_modules/@types`. */
    // "types": [],                                      /* Specify type package names to be included without being referenced in a source file. */
    // "allowUmdGlobalAccess": true,                     /* Allow accessing UMD globals from modules. */
    // "resolveJsonModule": true,                        /* Enable importing .json files */
    // "noResolve": true,                                /* Disallow `import`s, `require`s or `<reference>`s from expanding the number of files TypeScript should add to a project. */

    /* JavaScript Support */
    // "allowJs": true,                                  /* Allow JavaScript files to be a part of your program. Use the `checkJS` option to get errors from these files. */
    // "checkJs": true,                                  /* Enable error reporting in type-checked JavaScript files. */
    // "maxNodeModuleJsDepth": 1,                        /* Specify the maximum folder depth used for checking JavaScript files from `node_modules`. Only applicable with `allowJs`. */

    /* Emit */
    // "declaration": true,                              /* Generate .d.ts files from TypeScript and JavaScript files in your project. */
    // "declarationMap": true,                           /* Create sourcemaps for d.ts files. */
    // "emitDeclarationOnly": true,                      /* Only output d.ts files and not JavaScript files. */
    // "sourceMap": true,                                /* Create source map files for emitted JavaScript files. */
    // "outFile": "./",                                  /* Specify a file that bundles all outputs into one JavaScript file. If `declaration` is true, also designates a file that bundles all .d.ts output. */
    "outDir": "./build",                                   /* Specify an output folder for all emitted files. */
    // "removeComments": true,                           /* Disable emitting comments. */
    // "noEmit": true,                                   /* Disable emitting files from a compilation. */
    // "importHelpers": true,                            /* Allow importing helper functions from tslib once per project, instead of including them per-file. */
    // "importsNotUsedAsValues": "remove",               /* Specify emit/checking behavior for imports that are only used for types */
    // "downlevelIteration": true,                       /* Emit more compliant, but verbose and less performant JavaScript for iteration. */
    // "sourceRoot": "",                                 /* Specify the root path for debuggers to find the reference source code. */
    // "mapRoot": "",                                    /* Specify the location where debugger should locate map files instead of generated locations. */
    // "inlineSourceMap": true,                          /* Include sourcemap files inside the emitted JavaScript. */
    // "inlineSources": true,                            /* Include source code in the sourcemaps inside the emitted JavaScript. */
    // "emitBOM": true,                                  /* Emit a UTF-8 Byte Order Mark (BOM) in the beginning of output files. */
    // "newLine": "crlf",                                /* Set the newline character for emitting files. */
    // "stripInternal": true,                            /* Disable emitting declarations that have `@internal` in their JSDoc comments. */
    // "noEmitHelpers": true,                            /* Disable generating custom helper functions like `__extends` in compiled output. */
    // "noEmitOnError": true,                            /* Disable emitting files if any type checking errors are reported. */
    // "preserveConstEnums": true,                       /* Disable erasing `const enum` declarations in generated code. */
    // "declarationDir": "./",                           /* Specify the output directory for generated declaration files. */
    // "preserveValueImports": true,                     /* Preserve unused imported values in the JavaScript output that would otherwise be removed. */

    /* Interop Constraints */
    // "isolatedModules": true,                          /* Ensure that each file can be safely transpiled without relying on other imports. */
    // "allowSyntheticDefaultImports": true,             /* Allow 'import x from y' when a module doesn't have a default export. */
    "esModuleInterop": true,                             /* Emit additional JavaScript to ease support for importing CommonJS modules. This enables `allowSyntheticDefaultImports` for type compatibility. */
    // "preserveSymlinks": true,                         /* Disable resolving symlinks to their realpath. This correlates to the same flag in node. */
    "forceConsistentCasingInFileNames": true,            /* Ensure that casing is correct in imports. */

    /* Type Checking */
    "strict": true,                                      /* Enable all strict type-checking options. */
    // "noImplicitAny": true,                            /* Enable error reporting for expressions and declarations with an implied `any` type.. */
    // "strictNullChecks": true,                         /* When type checking, take into account `null` and `undefined`. */
    // "strictFunctionTypes": true,                      /* When assigning functions, check to ensure parameters and the return values are subtype-compatible. */
    // "strictBindCallApply": true,                      /* Check that the arguments for `bind`, `call`, and `apply` methods match the original function. */
    // "strictPropertyInitialization": true,             /* Check for class properties that are declared but not set in the constructor. */
    // "noImplicitThis": true,                           /* Enable error reporting when `this` is given the type `any`. */
    // "useUnknownInCatchVariables": true,               /* Type catch clause variables as 'unknown' instead of 'any'. */
    // "alwaysStrict": true,                             /* Ensure 'use strict' is always emitted. */
    // "noUnusedLocals": true,                           /* Enable error reporting when a local variables aren't read. */
    // "noUnusedParameters": true,                       /* Raise an error when a function parameter isn't read */
    // "exactOptionalPropertyTypes": true,               /* Interpret optional property types as written, rather than adding 'undefined'. */
    // "noImplicitReturns": true,                        /* Enable error reporting for codepaths that do not explicitly return in a function. */
    // "noFallthroughCasesInSwitch": true,               /* Enable error reporting for fallthrough cases in switch statements. */
    // "noUncheckedIndexedAccess": true,                 /* Include 'undefined' in index signature results */
    // "noImplicitOverride": true,                       /* Ensure overriding members in derived classes are marked with an override modifier. */
    // "noPropertyAccessFromIndexSignature": true,       /* Enforces using indexed accessors for keys declared using an indexed type */
    // "allowUnusedLabels": true,                        /* Disable error reporting for unused labels. */
    // "allowUnreachableCode": true,                     /* Disable error reporting for unreachable code. */

    /* Completeness */
    // "skipDefaultLibCheck": true,                      /* Skip type checking .d.ts files that are included with TypeScript. */
    "skipLibCheck": true                                 /* Skip type checking all .d.ts files. */
  }
}
```

# Conclusions

With all those points, we now have, not only, but a good way to handle with several isolated
environments without worrying about the configurations, and without need some heavy tools.
Since that each [docker] instance consumes less resources than the other tools.

Anyway, that was just a simple article to study the vscode container extensions and show the power
of this beautiful editor.

{{<thanks>}}

<!-- LINKS -->
[nvm]: https://github.com/nvm-sh/nvm
[venv]: https://docs.python.org/3/library/venv.html
[asdf]: https://asdf-vm.com/
[vscode]: https://github.com/microsoft/vscode
[electron]: https://www.electronjs.org/apps
[extensions]: https://marketplace.visualstudio.com/search?term=microsoft&target=VSCode&category=All%20categories&sortBy=Installs
[Remote Development]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
[1]: https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/
[2]: https://code.visualstudio.com/docs/remote/ssh-tutorial
[docker]: https://www.docker.com/get-started/
[k8s]: https://kubernetes.io/
[rancher]: https://rancher.com/
[vscode-containers]: https://code.visualstudio.com/learn/develop-cloud/containers