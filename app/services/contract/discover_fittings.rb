# frozen_string_literal: true

class Contract < ApplicationRecord
  class DiscoverFittings < ApplicationService
    def initialize(contract)
      super

      @contract = contract
    end

    def call
      ship_ids = contract.items.joins(type: :group).where('groups.category_id = ?', SHIP_CATEGORY_ID).pluck(:type_id)
      candidates = fittings.includes(:items).where(type_id: ship_ids, contract_matching_enabled: true)
      contract.transaction do
        matches = candidates.map do |fitting, a|
          match_count = Fitting::MatchContract.call(fitting, contract)

          next unless match_count > 0

          cf = contract.contract_fittings.find_or_initialize_by(fitting_id: fitting.id)
          cf.quantity = match_count
          cf.save!
        end

        debug "Discovered #{matches.count} matching fitting(s) for contract #{contract.id}"
      end
    end

    private

    SHIP_CATEGORY_ID = 6

    attr_reader :contract

    def fittings
      contract.assignee.fittings
    end
  end
end