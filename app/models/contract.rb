# frozen_string_literal: true

# ## Schema Information
#
# Table name: `contracts`
#
# ### Columns
#
# Name                              | Type               | Attributes
# --------------------------------- | ------------------ | ---------------------------
# **`id`**                          | `bigint`           | `not null, primary key`
# **`accepted_at`**                 | `datetime`         |
# **`acceptor_type`**               | `string`           |
# **`assignee_type`**               | `string`           | `not null`
# **`availability`**                | `text`             | `not null`
# **`buyout`**                      | `decimal(, )`      |
# **`collateral`**                  | `decimal(, )`      |
# **`completed_at`**                | `datetime`         |
# **`days_to_complete`**            | `integer`          |
# **`end_location_type`**           | `string`           |
# **`esi_expires_at`**              | `datetime`         | `not null`
# **`esi_items_exception`**         | `jsonb`            |
# **`esi_items_expires_at`**        | `datetime`         |
# **`esi_items_last_modified_at`**  | `datetime`         |
# **`esi_last_modified_at`**        | `datetime`         | `not null`
# **`expired_at`**                  | `datetime`         | `not null`
# **`for_corporation`**             | `boolean`          |
# **`issued_at`**                   | `datetime`         | `not null`
# **`price`**                       | `decimal(, )`      |
# **`reward`**                      | `decimal(, )`      |
# **`start_location_type`**         | `string`           |
# **`status`**                      | `text`             | `not null`
# **`title`**                       | `text`             |
# **`type`**                        | `text`             | `not null`
# **`volume`**                      | `decimal(, )`      |
# **`created_at`**                  | `datetime`         | `not null`
# **`updated_at`**                  | `datetime`         | `not null`
# **`acceptor_id`**                 | `bigint`           |
# **`assignee_id`**                 | `bigint`           | `not null`
# **`end_location_id`**             | `bigint`           |
# **`issuer_corporation_id`**       | `bigint`           | `not null`
# **`issuer_id`**                   | `bigint`           | `not null`
# **`start_location_id`**           | `bigint`           |
#
# ### Indexes
#
# * `index_contracts_on_acceptor`:
#     * **`acceptor_type`**
#     * **`acceptor_id`**
# * `index_contracts_on_assignee`:
#     * **`assignee_type`**
#     * **`assignee_id`**
# * `index_contracts_on_end_location`:
#     * **`end_location_type`**
#     * **`end_location_id`**
# * `index_contracts_on_issuer_corporation_id`:
#     * **`issuer_corporation_id`**
# * `index_contracts_on_issuer_id`:
#     * **`issuer_id`**
# * `index_contracts_on_start_location`:
#     * **`start_location_type`**
#     * **`start_location_id`**
# * `index_contracts_on_status`:
#     * **`status`**
# * `index_contracts_on_title`:
#     * **`title`**
# * `index_contracts_on_type`:
#     * **`type`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`issuer_corporation_id => corporations.id`**
# * `fk_rails_...`:
#     * **`issuer_id => characters.id`**
#
class Contract < ApplicationRecord
  self.inheritance_column = nil

  has_paper_trail ignore: %i[updated_at esi_expires_at esi_last_modified_at esi_items_exception esi_items_expires_at esi_items_last_modified_at],
                  versions: { class_name: 'ContractVersion' }

  belongs_to :acceptor, polymorphic: true, optional: true
  belongs_to :assignee, polymorphic: true
  belongs_to :end_location, polymorphic: true, optional: true
  belongs_to :issuer, class_name: 'Character', inverse_of: :issued_contracts
  belongs_to :issuer_corporation, class_name: 'Corporation', inverse_of: :issued_contracts
  belongs_to :start_location, polymorphic: true, optional: true

  has_one :end_solar_system, through: :end_location, source: :solar_system
  has_one :start_solar_system, through: :start_location, source: :solar_system

  has_many :events, class_name: 'ContractEvent', inverse_of: :contract, dependent: :destroy
  has_many :items, class_name: 'ContractItem', inverse_of: :contract, dependent: :destroy

  scope :courier, -> { where(type: 'courier') }
  scope :expired, -> { outstanding.where('expired_at <= ?', Time.zone.now) }
  scope :finished, -> { where(status: 'finished') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :item_exchange, -> { where(type: 'item_exchange') }
  scope :outstanding, -> { where(status: 'outstanding') }

  def courier?
    type == 'courier'
  end

  def item_exchange?
    type == 'item_exchange'
  end

  def sync_items_from_esi!
    Contract::SyncItemsFromESI.call(self)
  end

  def sync_items_from_esi_async
    Contract::SyncItemsFromESIWorker.perform_async(id, issuer_id)
  end

  def esi_items_exception_class_name
    esi_items_exception&.fetch('json_class')
  end

  def esi_items_synced?
    esi_items_exception_class_name.nil? && esi_items_last_modified_at.present?
  end

  def esi_items_unsynced?
    esi_items_last_modified_at.blank? && !esi_items_inaccessible? && !esi_items_unavailable? && type != 'courier'
  end

  def esi_items_inaccessible?
    esi_items_exception_class_name == 'ESI::Errors::ForbiddenError'
  end

  def esi_items_rate_limited?
    esi_items_exception_class_name == 'ESI::Errors::ErrorLimitedError'
  end

  def esi_items_unavailable?
    esi_items_exception_class_name == 'ESI::Errors::NotFoundError'
  end
end
