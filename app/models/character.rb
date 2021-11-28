# ## Schema Information
#
# Table name: `characters`
#
# ### Columns
#
# Name                        | Type               | Attributes
# --------------------------- | ------------------ | ---------------------------
# **`id`**                    | `bigint`           | `not null, primary key`
# **`esi_expires_at`**        | `datetime`         | `not null`
# **`esi_last_modified_at`**  | `datetime`         | `not null`
# **`name`**                  | `text`             | `not null`
# **`portrait_url_128`**      | `text`             |
# **`portrait_url_256`**      | `text`             |
# **`portrait_url_512`**      | `text`             |
# **`portrait_url_64`**       | `text`             |
# **`created_at`**            | `datetime`         | `not null`
# **`updated_at`**            | `datetime`         | `not null`
# **`alliance_id`**           | `bigint`           |
# **`corporation_id`**        | `bigint`           | `not null`
#
# ### Indexes
#
# * `index_characters_on_alliance_id`:
#     * **`alliance_id`**
# * `index_characters_on_corporation_id`:
#     * **`corporation_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`alliance_id => alliances.id`**
# * `fk_rails_...`:
#     * **`corporation_id => corporations.id`**
#
class Character < ApplicationRecord
  belongs_to :alliance, inverse_of: :characters, optional: true
  belongs_to :corporation, inverse_of: :characters

  has_one :user, inverse_of: :character

  has_many :esi_authorizations, inverse_of: :character, dependent: :destroy

  def sync_from_esi!
    Character::SyncFromESI.call(id)
  end
end
