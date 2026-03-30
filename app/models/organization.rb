class Organization < ApplicationRecord
  has_many :events, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :location, presence: true
end