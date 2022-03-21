# Creating your own plugin

During the development of Membrane we aim at designing fewer, but higher quality plugins. However we also kept extendability and reusability in mind. That's why it is easy for developers like you to create their own custom plugin, which satisfies their needs.

In this short guide we provide you with an overview of how to create your own Membrane plugin and how to integrate it into your project.

# Membrane plugin template

In order to create new plugin we recommended using the [template](https://github.com/membraneframework/membrane_template_plugin) which was made for this very purpose and which will be the base of your plugin.
It defines necessary dependencies as well as other project specs, e.g. formatting and guarantees you compliance with other Membrane components.

You can start creating a plugin by making your copy of the template. Go to the [github repo](https://github.com/membraneframework/membrane_template_plugin) and select `Use this template`. Then choose appropriate name for the project.

If you haven't already, we suggest you read [basic pipeline tutorial](TODO) to get familiar with Membrane's plugin structure. In any case, as you might have guessed the code of your plugin will go into `/lib` directory and the tests belong in the `/test` directory. 

# Utilizing your plugin in a project

When your plugin is ready for being integrated into another project you can simply add it as a dependency in `mix.exs` file of the target project like so:

```Elixir
defp deps do
    [
      ...
      {:your_membrane_plugin, git: "https://github.com/githubuser/your_membrane_plugin", tag: "0.1"} # dependency from github
      {:your_membrane_plugin, ">=0.0.0"} # dependency from [hex](https://hex.pm/)
      ...
    ]
end 
```

And just like this you have added your plugin to a project. 