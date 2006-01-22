class Coupon < ActiveRecord::Base
  belongs_to  :product
  belongs_to :account
  validates_presence_of :product  
  validates_associated :product
  validates_presence_of :voucher
  validates_presence_of :price      
  validates_presence_of :used  
  validates_uniqueness_of :voucher
  validates_length_of :voucher, :within => 10 .. 50  
  validates_numericality_of :price
  validates_numericality_of :voucher, :only_integer => true 
  validates_inclusion_of :used, :in => %w( Y N ), :message => "Y or N required" 
end
