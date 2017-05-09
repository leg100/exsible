# Exsible

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exsible` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exsible, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exsible](https://hexdocs.pm/exsible).

## Design Decisions

### DSL

The deliberate omission of a DSL is due to my experiences with existing configuration management systems. Their DSL's have sought to build a compromise between the goals of expressivity and declarativeness (or readability). All too often, improving one is made at the expense of the others: the more declarative the less expressive; the the more expressive the less declarative and readable. Ansible and Terraform both aimed for the former at inception (a declarative lanaguage), before incrementally making it more expressive (i.e. control structures, string manipulation, etc).

Designing a language then that is both declarative and expressive is a difficult if not impossible task. Why not then separate the two concerns and use an expressive language to generate a declarative document? That is the approach that Exsible takes. Exsible itself only concerns itself with reading the declarative document, expressed in JSON. Generating the document is left to a separate project that decides on the programming language and approach to take. It may decide to provide a DSL or a library, or a whole framework. All that matters is that it outputs JSON that respects the Exsible schema.

This division of labour lends itself to the principle of doing one thing and one thing well. The articulation of the desired state of configuration is a dedicated task that'll be steadily improved upon, decoupled from the second problem: the construction of a directed graph of the configuration and the execution of that configuration. In fact, you can see how that task too could in future be further separated out. 

### Elixir

Elixir is not an obvious choice for a DevOps project. It would seem to be, like Erlang, targeted at developing daemons, or long-living fault-tolerant programmes at any rate. However, it does make it easy to write programmes that are both concurrent and parallelizable. That is important characteristic of the particular configuration management programme I have in mind: an orchestrator, like ansible or terraform, that communicates with many API's or servers concurrently.

I also like that it has metaprogramming abilities. This arguably lends itself to creating a powerful plugin abstraction, necessary for configuration management programmes that are called upon to support a plurality of systems.

### JSON

There is an unhealthy preoccupation with the look and expressiveness of serialization languages. This is due to a tendency to manually write documents in these languages, rather than generate them. The look is not irrelevant; it's important to be able to understand the structure when debugging. But it's not a primary concern; wide system support is, so is fast parsing and generation, and perahps ease of validating the structure against a schema. From my point of view, XML would have been acceptable, but JSON is more palatable and familiar to the likely audience.

In any case, don't write the JSON by hand! Or not beyond the simplest experimentation. I wouldn't consider it unusual for the size of the JSON document to venture into dozens or perhaps hundreds of megabytes. Only if generation and parsing speed became noticably slow would concern be warranted.


## Internals

### Stages

Once started, Exsible enumerates through a set of stages:

* Parse JSON
* Validate against schema
 * Required args are present
 * Args are correct data type
 * Args abide by logical rules (and/xor)
 * Reference args are not dangling
* Decode JSON into tasks
* Construct graph

### States

Each task is a FSM, moving through the following states:

:initialized -> :validated -> :ready -> :completed

### Tasks

A task is made up of the following properties:

* an ID unique to the document
* a type
* args specific to the task type
* attrs assigned after task has *run*
* tasks it depends upon (parents)
* tasks depending upon it (children)

The type and args are formed as a struct, with the __struct__ key identifying the type.

#### Arguments

Each task has zero or more arguments specific to its type. Each arg is a struct with the following properties:

* name (atom)
* required (bool)
* default (any)
* type (string)
* reference (bool)

These properties are defined at compile-time.

### JSON Schema

A JSON schema ensures the input is valid. The JSON schema is generated from the compile-time properties defined above.
