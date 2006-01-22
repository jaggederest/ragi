class Account < ActiveRecord::Base
  has_many  :coupons
  validates_presence_of :number
  validates_presence_of :pin
  validates_presence_of :balance 
  validates_presence_of :attempts_today
  validates_presence_of :attempts_total
  validates_presence_of :logins    
  validates_uniqueness_of :number  
  validates_numericality_of :balance
  validates_numericality_of :number, :only_integer => true
  validates_numericality_of :pin, :only_integer => true
  validates_numericality_of :attempts_today, :only_integer => true 
  validates_numericality_of :attempts_total, :only_integer => true 
  validates_numericality_of :logins, :only_integer => true      
  validates_length_of :number, :within => 10 .. 50
  validates_length_of :pin, :within => 4 .. 10
end
