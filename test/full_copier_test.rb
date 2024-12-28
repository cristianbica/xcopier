# frozen_string_literal: true

require "test_helper"

class FullCopierTest < Minitest::Test
  class Copier
    include Xcopier::DSL

    copy :companies
    copy :users, chunk_size: 4
  end

  def test_copies_all_data_with_url_config
    prepare_databases(
      "sqlite3:tmp/sqlite3.sqlite3",
      "sqlite3:tmp/sqlite4.sqlite3"
    )

    ApplicationRecord.establish_connection("sqlite3:tmp/sqlite3.sqlite3")
    company1 = Company.create!(name: "Test Company 1")
    company1_users = 5.times.map { |i| User.create!(name: "User 1#{i}", company: company1) }
    company2 = Company.create!(name: "Test Company 2")
    company2_users = 5.times.map { |i| User.create!(name: "User 2#{i}", company: company2) }
    # disconnect from the database to force sqlite to write to disk
    ApplicationRecord.remove_connection

    copier = Copier.new
    copier.source = "sqlite3:tmp/sqlite3.sqlite3"
    copier.destination = "sqlite3:tmp/sqlite4.sqlite3"
    copier.run

    ApplicationRecord.establish_connection("sqlite3:tmp/sqlite4.sqlite3")
    assert_equal Company.all.ids.sort, [company1.id, company2.id].sort
    assert_equal User.all.ids.sort, (company1_users + company2_users).pluck(:id).sort
    assert_equal 2, User.where(name: ["User 10", "User 22"]).count
  end

  def test_copies_all_data
    prepare_databases(:sqlite1, :sqlite2)

    ApplicationRecord.establish_connection(:sqlite1)
    company1 = Company.create!(name: "Test Company 1")
    company1_users = 5.times.map { |i| User.create!(name: "User 1#{i}", company: company1) }
    company2 = Company.create!(name: "Test Company 2")
    company2_users = 5.times.map { |i| User.create!(name: "User 2#{i}", company: company2) }
    # disconnect from the database to force sqlite to write to disk
    # ApplicationRecord.remove_connection

    copier = Copier.new
    copier.source = :sqlite1
    copier.destination = :sqlite2
    copier.run

    ApplicationRecord.establish_connection(:sqlite2)
    assert_equal Company.all.ids.sort, [company1.id, company2.id].sort
    assert_equal User.all.ids.sort, (company1_users + company2_users).pluck(:id).sort
    assert_equal 2, User.where(name: ["User 10", "User 22"]).count
  end


end
