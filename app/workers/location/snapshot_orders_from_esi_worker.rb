class Location < ApplicationRecord
  class SnapshotOrdersFromESIWorker < ApplicationWorker
    sidekiq_options retries: 3, lock: :until_executed

    def perform(location_id)
      time =
        if (10_000_000..11_000_000) === location_id
          Location::SnapshotOrdersFromESI.call(Region.find(location_id))
        else
          Location::SnapshotOrdersFromESI.call(Structure.find(location_id))
        end

      unless time
        debug("No orders found for #{location_id}")
        return
      end

      location = Location.find(location_id)
      location.markets.each do |market|
        unless market.active?
          debug("Market #{market.log_name} is not active")
          next
        end

        market.calculate_type_statistics_async(time)
      end
    end
  end
end
