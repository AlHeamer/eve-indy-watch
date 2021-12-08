# frozen_string_literal: true

# ## Schema Information
#
# Table name: `corporations`
#
# ### Columns
#
# Name                                  | Type               | Attributes
# ------------------------------------- | ------------------ | ---------------------------
# **`id`**                              | `bigint`           | `not null, primary key`
# **`contract_sync_enabled`**           | `boolean`          |
# **`esi_contracts_expires_at`**        | `datetime`         |
# **`esi_contracts_last_modified_at`**  | `datetime`         |
# **`esi_expires_at`**                  | `datetime`         |
# **`esi_last_modified_at`**            | `datetime`         |
# **`icon_url_128`**                    | `text`             |
# **`icon_url_256`**                    | `text`             |
# **`icon_url_64`**                     | `text`             |
# **`name`**                            | `text`             | `not null`
# **`npc`**                             | `boolean`          |
# **`ticker`**                          | `text`             | `not null`
# **`url`**                             | `text`             |
# **`created_at`**                      | `datetime`         | `not null`
# **`updated_at`**                      | `datetime`         | `not null`
# **`alliance_id`**                     | `bigint`           |
# **`esi_authorization_id`**            | `integer`          |
#
# ### Indexes
#
# * `index_corporations_on_alliance_id`:
#     * **`alliance_id`**
# * `index_corporations_on_esi_authorization_id`:
#     * **`esi_authorization_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`alliance_id => alliances.id`**
# * `fk_rails_...`:
#     * **`esi_authorization_id => esi_authorizations.id`**
#
class Corporation < ApplicationRecord
  belongs_to :alliance, inverse_of: :corporations, optional: true
  belongs_to :esi_authorization, inverse_of: :corporation, optional: true

  has_one :api_alliance, class_name: 'Alliance', inverse_of: :api_corporation,
                              foreign_key: :api_corporation_id

  has_many :accepted_contractors, class_name: 'Contract', as: :acceptor, dependent: :restrict_with_exception
  has_many :characters, inverse_of: :corporation, dependent: :restrict_with_exception
  has_many :contract_events, inverse_of: :corporation, dependent: :restrict_with_exception
  has_many :issued_contracts, class_name: 'Contract', inverse_of: :issuer_corporation,
                              foreign_key: :issuer_corporation_id, dependent: :restrict_with_exception
  has_many :stations, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :structures, inverse_of: :owner, dependent: :restrict_with_exception

  scope :player, -> { where(npc: nil) }

  def available_esi_authorizations
    ESIAuthorization.includes(:character).joins(character: :corporation).where('corporation_id = ?', id).order('characters.name')
  end

  def sync_from_esi!
    Corporation::SyncFromESI.call(id)
  end

  def sync_contracts_from_esi!
    Corporation::SyncContractsFromESI.call(id)
  end

  def sync_contracts_from_esi_async
    Corporation::SyncContractsFromESIWorker.perform_async(id)
  end
end
