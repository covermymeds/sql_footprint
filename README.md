# SqlFootprint [![Build Status](https://travis-ci.org/covermymeds/sql_footprint.svg?branch=master)](https://travis-ci.org/covermymeds/sql_footprint)

This gem allows you to keep a "footprint" of the sql queries that your application runs.
It's like logging all the sql you're executing except that we remove all the value parameters
and dedupe similar queries. This footprint should be valuable in determining if changes you've
made will significantly change the way you're querying the database.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sql_footprint', group: [:development, :test]
```

And then execute:

    $ bundle

## Usage

Typically, you would want to run this while you're running your specs.
For example w/ RSpec:
```ruby
RSpec.configure do |config|
  config.before(:suite) { SqlFootprint.start }
  config.after(:suite) { SqlFootprint.stop }
end
```

Minitest (in `test_helper.rb`) add the following:
```ruby
SqlFootprint.start
Minitest.after_run { SqlFootprint.stop }
```

You can also add a Custom rule to SqlAnonymizer before running `start`:
```ruby
RSpec.configure do |config|
  SqlFootprint::SqlAnonymizer.add_rule(/SELECT (.+) AS (.+)/, 'SELECT [redacted] AS [redacted]')
  config.before(:suite) { SqlFootprint.start }
  config.after(:suite) { SqlFootprint.stop }
end
```

#### Outputs
After running your specs you'll find a 'footprint.*.sql' file in your project.
Footprints are per-database. For example, if you're using DB1 AND DB2 in your app, you would end up with two footprint files. (footprint.db1.sql, footprint.db2.sql)

If you're using an in-memory database, you'll end up with `footprint.:memory:.sql`.

#### Excluding Setup Code

If you want to exclude queries that your tests generate for fixture data, you can use the ```.exclude``` method.  For example:
```ruby
before do
  SqlFootprint.exclude do
    Model.create!(args*) # this query will not be included in your footprint
  end
end
```

Or if you're using FactoryBot you could do something like this:
```ruby
RSpec.configure do |config|
  module FactoryKid
    def create(*args)
      SqlFootprint.exclude { FactoryBot.create(*args) }
    end
  end
  config.include FactoryKid
end
```

## Compatibility
- For Rails < 6.0 compatibility, please use v2.0.1.
- For Rails >= 6.0 compatibility, please use v3.0.0.

DO NOT run SqlFootprint in production!
