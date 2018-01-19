# DbSanitiser

Sanitise a database to eliminate personal or sensitive information.

The validation of the sanitisation is opinionated - it expects every table and
column to either be sanitised or explicitly ignored. This removes the burden for
developers to remember to sanitise tables or columns as they are added.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'db_sanitiser', git: 'git@github.com:Futurelearn/db_sanitiser'
```

And then execute:

    $ bundle

## Usage

The gem provides 3 methods that you can use, each of which take a config file as an argument:

* `DbSanitiser.sanitise` - run the sanitisation
* `DbSanitiser.validate` - validate that all tables and columns are accounted for
* `DbSanitiser.dry_run` - print what the results of sanitisation would be

These methods can be integrated into an app using Rake tasks. In a Rails app, it
is also recommended to make sure that you don't accidentally sanitise your
production database:

```
namespace :db_sanitiser do
  task environment_check: [:environment] do
    fail "Sanitising in production is THE LAST THING WE WANT TO HAPPEN!" if Rails.env.production?
  end

  task validate: [:environment_check] do
    DbSanitiser.validate(Rails.root.join('config/db_sanitiser.rb'))
  end

  task sanitise: [:environment_check, :validate] do
    DbSanitiser.sanitise(Rails.root.join('config/db_sanitiser.rb'))
  end

  task dry_run: [:environment_check] do
    DbSanitiser.dry_run(Rails.root.join('config/db_sanitiser.rb'), STDOUT)
  end
end
```

Create a config file at the location you've chosen above with the declarations of the table to sanitise, like so:

```
sanitise_table 'table1' do
  sanitise 'column1', string('Hi') # This will sanitise the column as a fixed string value
  sanitise 'column2', 'NOW()' # This will sanitise the column by running the expression as part of the SQL update
  ignore 'column3'
end

# You can sanitise the same table multiple times, and optionally pass a `where` clause to limit the rows the sanitisation will run against
sanitise_table 'table1' do
  where 'super_secret': true # the `where` clause will accept all ActiveRecord::Base#where arguments
  sanitise 'column1', string('super secret')
  sanitise 'column2', string('super secret')
  sanitise 'column3', string('super secret')
end

# You can delete the contents of a table
delete_all 'table2'
```

There is no method to completely ignore a table during the sanitisation process. This is because a column could be added that requires sanitisation and it would be silently ignored. To ignore a table, call `sanitise_table` with no calls to `sanitise`:

```
sanitise_table 'table_to_ignore' do
  ignore 'column1', 'column2'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/db_sanitiser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DbSanitiser project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/db_sanitiser/blob/master/CODE_OF_CONDUCT.md).
