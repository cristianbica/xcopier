# frozen_string_literal: true

require "test_helper"

class OverridingTest < Minitest::Test
  class Copier
    include Xcopier::DSL

    copy :companies
    copy :users,
         overrides: {
           name: -> { Faker::Name.name },
           email: ->(email) { Faker::Internet.email(domain: email.split("@").last) },
           password: ->(_, attributes) { Digest::MD5.hexdigest(attributes["email"]) },
           last_login_at: Time.new(2020, 1, 1),
           locale: "en"
         }
  end

  def test_overrides_data
    prepare_databases(:db1, :db2)

    ApplicationRecord.establish_connection(:db1)
    company = Company.create!(name: "Test Company 1")
    user = User.create!(company: company, name: "User One", email: "test@domain.com", password: "complicated", last_login_at: Time.new(2000, 1, 1), locale: "fr")
    ApplicationRecord.remove_connection

    copier = Copier.new
    copier.source = :db1
    copier.destination = :db2
    copier.run

    ApplicationRecord.establish_connection(:db2)
    copied_user = User.find(user.id)

    refute_equal user.name, copied_user.name
    refute_equal user.email, copied_user.email
    assert_equal user.email.split("@").last, copied_user.email.split("@").last
    refute_equal user.password, copied_user.password
    assert_equal Digest::MD5.hexdigest(user.email), copied_user.password
    refute_equal user.last_login_at, copied_user.last_login_at
    assert_equal Time.new(2020, 1, 1), copied_user.last_login_at
    refute_equal user.locale, copied_user.locale
    assert_equal "en", copied_user.locale
  end
end
