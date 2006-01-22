class Issuer < ActiveRecord::Base
  has_many  :products, :order => "name"
  validates_presence_of :name
  validates_length_of :name, :within => 4 .. 50
  validates_uniqueness_of :name
end
