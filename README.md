TODOs:
- [ ] option to truncate the destination tables
- [ ] do not fetch data if it will be overritten or anonymized
- [ ] merge overrides and anonymizations
- [ ] add a rails generator

# Xcopier

Xcopier is a tool to copy data from one database to another. It is designed to be used in a development environment to copy data from a production database to a local database for testing purposes allowing you to overide and/or anonymize the data.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add xcopier --group=development
```

## Usage

Create a file (e.g. `app/libs/company_copier.rb`) and define a class that includes `Xcopier::DSL`:

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
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cristianbica/xcopier.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
