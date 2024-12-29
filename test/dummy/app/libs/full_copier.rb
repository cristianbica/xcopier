# frozen_string_literal: true

class FullCopier
  include Xcopier::DSL

  argument :company_ids, :integer, list: true

  copy :companies, scope: -> { Company.where(id: arguments[:company_ids]) }
  copy :users, scope: -> { User.where(company_id: arguments[:company_ids]) }, chunk_size: 100
end
