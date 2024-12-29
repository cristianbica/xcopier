# frozen_string_literal: true

require "test_helper"

class PartialCopierTest < Minitest::Test
  class Copier
    include Xcopier::DSL

    argument :company_ids, :integer, list: true

    copy :companies, scope: -> { Company.where(id: arguments[:company_ids]) }
    copy :users, scope: -> { User.where(company_id: arguments[:company_ids]) }, chunk_size: 4
  end

  def test_copies_data
    prepare_databases(:db1, :db2)
    ApplicationRecord.establish_connection(:db1)

    company1 = Company.create!(name: "Test Company 1")
    company1_users = 5.times.map { |i| User.create!(name: "User 1#{i}", company: company1) }
    company2 = Company.create!(name: "Test Company 2")
    company2_users = 5.times.map { |i| User.create!(name: "User 2#{i}", company: company2) }
    company3 = Company.create!(name: "Test Company 3")
    5.times.map { |i| User.create!(name: "User 3#{i}", company: company3) }

    copier = Copier.new(company_ids: [company1.id, company2.id].join(" , "))
    copier.source = :db1
    copier.destination = :db2
    copier.run

    ApplicationRecord.establish_connection(:db2)
    assert_equal Company.all.ids.sort, [company1.id, company2.id].sort
    assert_equal User.all.ids.sort, (company1_users + company2_users).pluck(:id).sort
    assert_equal 2, User.where(name: ["User 10", "User 22"]).count
  end
end
