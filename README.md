

bondage [![Code Climate](https://codeclimate.com/github/jorj1988/bondage.png)](https://codeclimate.com/github/jorj1988/bondage) [![Build Status](https://travis-ci.org/jorj1988/bondage.png?branch=master)](https://travis-ci.org/jorj1988/bondage)
====================

bondage is a bindings generator. It uses clang and ruby to process C++ classes into runtime reflectable methods.

for example:

```cpp
namespace Meat
{

/// \expose
class Pork
{
public:
  void saltiness();
};
}
```

Allows class reflection:
```cpp
// Prints "Pork"
for(const bondage::WrappedClass *cls : bondage::ClassWalker(Meat::bindings()))
  {
  std::cout << cls->type().name();
  }
```

And function reflection:
```cpp
// Prints "saltiness"
const bondage::WrappedClass *pork;
for (std::size_t i = 0; i < pork->functionCount(); ++i)
  {
  std::cout << stringClass->function(i).name();
  }
```

bondage uses [Reflect][1] to wrap functions, and requires some kind of wrapping backend (a script engine, for example) to provide function invocation.

Example
=======

A library for bondage processing can defined with:
```ruby
require "parser/Library.rb"

# Create a library called [Gen], in the relative folder [data/Gen]
lib = Library.new("Gen", "data/Gen")

# Include files for this library are located in the library folder [data/Gen], or [.]
lib.addIncludePath(".")

# The only file in the library is the [Generator.h] file.
lib.addFile("Generator.h")

# We could also add other exposed dependencies to the library here.
```

C++ bindings can then be generated using:
```ruby
# Create a parser to parse the data (passing it our library)
# the empty array specifies system includes
parser = Parser.new(lib, [])

# Create a visitor for the parser to interact with
visitor = ExposeAstVisitor.new(lib)

# Parse the library. This fills visitor with the data from our C++ files.
parser.parse(visitor)

# Create an exposer, this visits all classes in the C++, checks 
# if they should be exposed (either implicitly, or if asked - using the /// \expose command)
exposer = Exposer.new(visitor)

# Now we have all the data to write the bindings
libGen = CPP::LibraryGenerator.new()
libGen.generate(lib, exposer)

# libGen.header and libGen.source can now be used to write to file.
```

bondage also has a generator for Lua, which will generate class bindings on the lua side, which interacts with the bindings above. Lua bindings are generated using a very similar method:
```ruby
# first create a lua library generator
libGen = Lua::LibraryGenerator.new(
  Lua::DEFAULT_PLUGINS,     # plugins are used to generate extra class data - properties by default
  Lua::DEFAULT_CLASSIFIERS, # classifiers can process arguments passed to functions - converting indices
  "getFunction",            # a global lua function to get a native function
  TestPathResolver.new)     # a helper class to turn a class into a file path for requiring

# Generate the bindings
libGen.generate(lib, exposer)

# write the bindings (writes a file per class, and a library file)
libGen.write("c:\somedir\")

```

Code Tour
============



> Written with [StackEdit](https://stackedit.io/).


[1]: https://github.com/jorj1988/Reflect "Reflect"