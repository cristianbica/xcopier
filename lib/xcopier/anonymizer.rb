# frozen_string_literal: true

require "faker"

module Xcopier
  module Anonymizer
    module_function

    RULES = {
      /email/ => -> { Faker::Internet.email },
      /first_?name/ => -> { Faker::Name.first_name },
      /last_?name/ => -> { Faker::Name.last_name },
      /name/ => -> { Faker::Name.name },
      /phone/ => -> { Faker::PhoneNumber.phone_number },
      /address/ => -> { Faker::Address.full_address },
      /city/ => -> { Faker::Address.city },
      /country/ => -> { Faker::Address.country },
      /zip/ => -> { Faker::Address.zip_code },
      /(company|organization)/ => -> { Faker::Company.name }
    }.freeze

    def anonymize(name, value)
      RULES.each do |rule, block|
        return block.call if name.match?(rule)
      end
      value
    end
  end
end
