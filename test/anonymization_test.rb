# frozen_string_literal: true

require "test_helper"

class AnonymizationTest < Minitest::Test
  class Copier
    include Xcopier::DSL

    copy :companies, anonymize: true
    copy :users, anonymize: [:name]
  end

  def test_anonymizes_data
    prepare_databases(:db1, :db2)

    ApplicationRecord.establish_connection(:db1)
    company = Company.create!(name: "Test Company 1")
    user = User.create!(company: company, name: "User One", email: "test@domain.com", password: "complicated", last_login_at: Time.new(2000, 1, 1), locale: "fr")

    copier = Copier.new
    copier.source = :db1
    copier.destination = :db2
    copier.run

    ApplicationRecord.establish_connection(:db2)
    copied_company = Company.find(company.id)
    copied_user = User.find(user.id)

    refute_equal company.name, copied_company.name
    refute_equal company.address, copied_company.address
    refute_equal user.name, copied_user.name
    assert_equal user.email, copied_user.email
    assert_equal user.password, copied_user.password
    assert_equal user.last_login_at, copied_user.last_login_at
    assert_equal user.locale, copied_user.locale
  end
end
