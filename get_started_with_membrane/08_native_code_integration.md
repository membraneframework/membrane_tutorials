# Native code integration

In Membrane we try to make use of Elixir goodness as often as possible. However, sometimes it is necessary to write some native code, for example to integrate with existing C libraries. To achieve that, we use _natives_, which are either [NIFs](http://erlang.org/doc/man/erl_nif.html) or [C nodes](http://erlang.org/doc/man/ei_connect.html). Both of them have their tradeoffs:
- NIFs don't introduce significant overhead, but in case of failure they can even crash entire VM,
- CNodes are isolated and can be supervised like Elixir processes, but they are slower due to the inter-process communication.

That's why we use them only when necessary and created some tools to make dealing with them easier. For interoperability with C and C++, we use [Bundlex](https://github.com/membraneframework/bundlex) and [Unifex](https://github.com/membraneframework/unifex). For calling Rust, we use [Rustler](https://github.com/rusterlium/rustler).

## [Bundlex](https://github.com/membraneframework/bundlex)

To simplify and unify the process of writing and compiling natives, we use our own build tool - [Bundlex](https://github.com/membraneframework/bundlex). It is a multi-platform tool that provides a convenient way of compiling and accessing natives from Elixir code.
For more information, see [Bundlex's GitHub page](https://github.com/membraneframework/bundlex).

## [Unifex](https://github.com/membraneframework/unifex)

Process of creating natives is not only difficult but also quite arduous, because it requires using cumbersome Erlang APIs, and thus a lot of boilerplate code. To make it more pleasant, we created [Unifex](https://github.com/membraneframework/unifex), a tool that is responsible for generating interfaces between C or C++ libraries and Elixir on the base of short `.exs` configuration files. An important feature of Unifex is that you can write the C/C++ code once and use it either as a NIF or as a C node.

A quick introduction to Unifex is available [here](https://hexdocs.pm/unifex/creating_unifex_nif.html).

