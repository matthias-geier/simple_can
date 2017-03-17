# simple_can

A simple authorization helper with basic strategy support

## Installation and Usage

```bash
  gem install simple_can
```

This gem provides a basic authorization helper which works by including it
in either module or class. Multi-inheritance (include in module which is
in following included into a class) works moderately well, but do not expect
miracles.

It's thread-safe, but can only support a single capability scope per thread!

```ruby
  require "simple_can"

  SimpleCan.strategy = SimpleCan::BasicStrategy

  class Blog
    include SimpleCan
  end
```

The basic strategy shipped with the system offers a read - write - manage
capability, where a reader can only read, a writer can read and write, and
a manager can read, write and manage.

So far so good.

```ruby
  class Entry < ActiveRecord::Base; end
  class User < ActiveRecord::Base; end

  class Blog
    include SimpleCan

    def read_entries
      Entry.limit(10)
    end

    def write_entry!(content_hash)
      Entry.create(content_hash)
    end

    def status
      status = {
        entry_count: Entry.count
      }
      status[:owner] = User.first if write?
      return status
    end

    def destroy!
      manage! # you should not be here!
      Entry.destroy_all
    end
  end
```

This bunch of code above shows all features of the library. Please note that
all of the convenience features are also available for class methods!

ActiveRecord is a popular ORM used in Rails. It's used here for convenience
as the database abstraction. Heed it no mind please, it has nothing to do
with the authorization helper.

The offered features are:

  * automatic method wrapping (**read_entries** will become **entries**,
    **write_entry!** will become **entry!**) making an !-method fail hard
    and a regular one weak by returning **:unauthorized**
  * convenience inline methods for checking or raising authorization
    (**manage!** will raise an error, **write?** will check only)

Setting the capability of the current user/process is done through a scoping
block or an accessor.

```ruby
  Blog.capability = "write"

  # or
  Blog.with_capability("write") do
    Blog.write? # is true here
  end
```

Putting it together in the example above will look like this.

```ruby
  # default is read access
  Blog.new.entries
  => [...]

  Blog.new.entry!(name: "foobar", text: "Old McDonald had a farm...")
  => SimpleCan::Unauthorized: unauthorized for entry! with read
     # stack trace here

  Blog.new.status
  => {entry_count: 25}

  Blog.capability = "manage"

  Blog.new.entry!(name: "foobar", text: "Old McDonald had a farm...")
  => <Entry name: "foobar", text: "Old McDonald had a farm...">

  Blog.destroy!
  => true

  Blog.new.status
  => {entry_count: 25, owner: "McDonald"}
```

The defined methods from the class/module body are NOT being removed. You can
still access them like any other.

## Running the tests

```bash
  bundle exec ruby -Ilib test/runner.rb
```

## License

See license file.
