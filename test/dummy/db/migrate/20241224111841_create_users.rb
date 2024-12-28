# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.belongs_to :company, null: false
      t.string :name
      t.string :email
      t.string :password
      t.datetime :last_login_at
      t.string :locale

      t.timestamps
    end
  end
end
