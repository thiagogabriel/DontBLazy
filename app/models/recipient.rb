class Recipient < ActiveRecord::Base
  belongs_to :user
  has_many :micropost_recipients, dependent: :destroy
  has_many :microposts, through: :micropost_recipients
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :phone, presence: true, length: { minimum: 8, maximum: 25 }
  validates :user_id, presence: true
  accepts_nested_attributes_for :micropost_recipients
end
