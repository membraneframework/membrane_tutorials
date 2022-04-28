# Create your own plugin

During the development of Membrane Framework we aim at designing fewer, but higher quality plugins. However, we also kept extendability and reusability in mind. That's why it is easy for developers like you to create their own custom plugin, which satisfies their needs.

In this short guide we provide you with an overview of how to create your own Membrane plugin and how to integrate it into your project.

## Membrane plugin template

To create a new plugin, we recommend using the [template](https://github.com/membraneframework/membrane_template_plugin) that has been made for this very purpose and which will be the base of your plugin.
It defines necessary dependencies as well as other project specs, e.g. formatting, and guarantees you compliance with other Membrane components.

You can start creating a plugin by making your copy of the template. Go to the [github repo](https://github.com/membraneframework/membrane_template_plugin) and select `Use this template`. Then choose an appropriate name for the project.

If you haven't already, we suggest you read [basic pipeline tutorial](/basic_pipeline/01.0_Introduction.md) to get familiar with Membrane's plugin structure. In any case, as you might have guessed the code of your plugin will go into `/lib` directory and the tests belong in the `/test` directory.

# Utilizing your plugin in a project

When your plugin is ready for being integrated into another project you can simply add it as a dependency in `mix.exs` as described [here](https://hexdocs.pm/mix/Mix.Tasks.Deps.html). Here's what it can look like:

```Elixir
defp deps do
    [
      ...
      {:your_membrane_plugin, git: "https://github.com/githubuser/your_membrane_plugin", tag: "0.1"} # dependency from github
      {:your_membrane_plugin, ">=0.1.0"} # dependency from [hex](https://hex.pm/)
      {:your_membrane_plugin, path: "path/to/your_plugin"} # dependency from local file
      ...
    ]
end 
```

And just like this, you have added your plugin to a project.
