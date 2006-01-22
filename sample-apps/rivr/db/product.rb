class Product < ActiveRecord::Base
  belongs_to :issuer
  validates_associated :issuer
  validates_presence_of :issuer
  validates_presence_of :name
  validates_presence_of :price  
  validates_length_of :name, :within => 4 .. 50
  validates_uniqueness_of :name
  validates_numericality_of :price
end
