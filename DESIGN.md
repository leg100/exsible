json schema
-----------

Meet the following requirements:

* easily validated with JSON schema validator
  * is a composable JSON schema, whereby task types can be separately defined from the task wrapper (good for plugins)
* easily decoded into:
  * a task "wrapper" struct: id, lifecycle rules, etc
  * a task type struct: args
* ID is unique
  * Guarantee uniqueness (e.g. thru strict keys)

Open questions:

* "tasks" parent key
* task wrapper object

Devices:

* register id as process name; don't store in struct
* infer type from __schema__ map key; don't store in struct

Process:

* validate against schema
* decode into tasks
* start all task processes synchronously
  * name them according to their id
* construct DAG
  * vertex contains only task/process id
  * add start vertex
  * add end vertex
* walk the DAG


