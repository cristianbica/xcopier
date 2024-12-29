# frozen_string_literal: true

require_relative "lib/xcopier/version"

Gem::Specification.new do |spec|
  spec.name = "xcopier"
  spec.version = Xcopier::VERSION
  spec.authors = ["Cristian Bică"]
  spec.email = ["cristian.bica@gmail.com"]

  spec.summary = "Xcopier is a tool to copy data from one database to another."
  spec.description = "Xcopier is a tool to copy data from one database to another. It is designed to be used in a development environment to copy data from a production database to a local database (e.g., to test a data migration or data fix) allowing you to override and/or anonymize the data."
  spec.homepage = "https://github.com/cristianbica/xcopier"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cristianbica/xcopier"
  spec.metadata["changelog_uri"] = "https://github.com/cristianbica/xcopier/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile gemfiles Appraisals .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"

  spec.add_development_dependency "appraisal"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
