TODOs:
- [ ] option to truncate the destination tables
- [ ] do not fetch data if it will be overritten or anonymized
- [ ] merge overrides and anonymizations

# Xcopier

Xcopier is a tool to copy data from one database to another. It is designed to be used in a development environment to copy data from a production database to a local database for testing purposes allowing you to overide and/or anonymize the data.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add xcopier --group=development
```

## Usage

Create a file (e.g. `app/libs/company_copier.rb`) and define a class that includes `Xcopier::DSL`.
You could also use the generator provided by this gem (`bundle exec rails genereate xcopier:copier company`).

```ruby
class CompanyCopier
  include Xcopier::DSL

  # you can use here a symbol to reference a connection defined in database.yml
  #  or a hash with connection details
  #  or a string with a connection url
  source :production
  destination :development

  argument :company_ids, :integer, list: true

  copy :companies, scope: -> { Company.where(id: arguments[:company_ids]) }
  copy :users, scope: -> { User.where(company_id: arguments[:company_ids]) }, chunk_size: 100
end
```

Then run the copier:

```bash
bundle exec xcopier company --company-ids 1,2
```

The above will load your app, instantiate the `CompanyCopier` class and run the `copy` method for the `companies` and `users` tables.

You could also do this from a Rails console:

```ruby
CompanyCopier.new(company_ids: [1, 2]).run
# or give the argument as a string and it will be parsed
CompanyCopier.new(company_ids: "1,2").run
```

### Arguments

The DSL includes an `argument` directive. It's purpose is to provide copier arguments to be used in queries to copy data. It supports typecasting for the following types: string, integer, time, date, boolean. You can also specify if the argument is a list by setting the `list` option to `true`.

Example:

```ruby
argument :str, :string
argument :str_list, :string, list: true
argument :int, :integer
argument :int_list, :integer, list: true
argument :time, :time # it will parse the time using Time.parse
argument :date, :date # it will parse the date using Date.parse
argument :bool, :boolean # it will recognize as truthy the values: "1", "yes", "true", true

copier.new(str: "string", str_list: "string1,string2", int: "1", int_list: "1,2", time: "2020-01-01 12:00", date: "2020-01-01
", bool: "true")

copier.arguments[:str] # => "string"
copier.arguments[:str_list] # => ["string1", "string2"]
copier.arguments[:int] # => 1
copier.arguments[:int_list] # => [1, 2]
copier.arguments[:time] # => Time.parse("2020-01-01 12:00")
copier.arguments[:date] # => Date.parse("2020-01-01")
copier.arguments[:bool] # => true
```

Example:

```ruby

copy :companies, anonymize: true

copy :users,
     model: User, # this is not actually needed, it will be inferred from the name
     scope: -> { User.all }, # this is also not needed as .all on the model is the default
     chunk_size: 500, # this is the default value
     overrides: {
       email: ->(email) { email.gsub(/@/, "+#{SecureRandom.hex(4)}@") },
       password: "password",
       last_login_at: -> (last_login_at, attributes) { attributes[:created_at] + 1.minute }
     },
     anonymize: %w(first_name last_name street_address)
```

### Copy Operations

The `copy` directive is to instruct the copier what to copy. It accepts the following options:
- `name`
   - a name for the copy operation (usually the table name)
   - will be used to determine the model if not given
- `model`
  - the model to use for the copy operation
  - if not given it will be inferred from the `name`
- `scope`
  - a lambda that returns the records to be copied
  - if not given it will copy all records using the `model.all`
- `chunk_size`
  - the number of records to copy at once
  - default value is `500`
- `overrides`
  - rules to transform the data before writing
  - it is a hash where the key is the column name and the replacement is the value
  - the value can be a lambda that returns the new value
  - the lambda can receive no arguments or a single argument with the original value or two arguments with the original value and a hash of the record
- `anonymize`
  - where to try to anonymize the data
  - can be `true` to anonymize all columns or a list of columns to anonymize
  - more on the anonymization in the next section
  - anonymization is not done for columns that have an override
  - anonymization is done in the [`Xcopier::Anonymizer`](https://github.com/cristianbica/xcopier/blob/master/lib/xcopier/anonymizer.rb) class, is based on the column name and uses the [faker](https://rubygems.org/gems/faker) gem
  - :warning: anonymization is not guaranteed to be secure and has currently a limited implementation
  - feel free to adjust it in your app (`Xcopier::Anonymizer::RULES` is a mutable hash where the key is a regex to match the column and the value is a lambda that returns the anonymized value) or contribute to this gem


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cristianbica/xcopier.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
