# activate active record support

require 'rubygems'

require_gem 'activerecord'
require_gem 'activesupport'

# require our business model classes

require 'db/account'
require 'db/coupon'
require 'db/issuer'
require 'db/product'

require 'app/exceptions'
require 'app/config'

# require miscellanous infrastructure

require 'net/http' 
require 'cgi'

class BizModel
  
  # establish a database connection
  
  def initialize
    ActiveRecord::Base.establish_connection({
          :adapter  => Cfg.get.db_adapter, 
          :database => Cfg.get.db_name,
          :username => Cfg.get.db_user,
          :password => Cfg.get.db_password
    })
  end
  
  # check if any of the products is in stock
  
  def products_in_stock?(products)
    in_stock = false
    products.each_value {|p| in_stock = true if product_in_stock?(p) }
    return in_stock
  end
  
  # check if a single product is in stock
  
  def product_in_stock?(product)
    p = Product.find_by_name(product.to_s)
    return nil unless p
    coupons = Coupon.find_all_by_product_id_and_account_id_and_used(p.id, nil, 'N', :limit => 1) 
    return nil unless coupons
    return nil if coupons.length == 0    
    return coupons[0]
  end
  
  # consumes a voucher, and marks the coupon containing the voucher as
  # consumed by the account. validates all parameters before doing the
  # transaction, rolling it back if necessary ...
  
  def consume(accountNo, pin, product)
    
    account = find(accountNo, pin)
    
    raise Exceptions::BruteForce if account.attempts_today > 9
    raise Exceptions::BadCredentials unless account.pin == pin
    
    coupon = product_in_stock?(product)
    
    raise Exceptions::OutOfStock unless coupon
        
    begin
      Coupon.transaction(coupon, account) do
        coupon.account = account
        raise Exceptions::TransactionFailed if coupon.used != 'N'
        coupon.used = 'Y'
        coupon.used_on  = Time.now
        account.balance -= coupon.price
        raise Exceptions::TransactionFailed if account.balance < 0
        coupon.save!
        account.save!
      end
    rescue Exceptions::TransactionFailed
      coupon.voucher = nil
      raise Exceptions::VoucherAlreadyUsed if coupon.used != 'N'
      raise Exceptions::InsufficientBalance if (account.balance - coupon.price) < 0      
      raise Exceptions::TransactionFailed # reraise exception
    end
    
    return coupon.voucher
    
  end
  
  def find(accountNo, pin)    
    account = Account.find_by_number(accountNo)
    raise Exceptions::BadCredentials unless account    
    return account    
  end
  
  # API format for clickatell
  #
  # http://api.clickatell.com/http/sendmsg?api_id=xxxx&user=xxxx&password=xxxx&to=xxxx&text=xxxx 
  
  def notifyViaSMS(number, message, api, user, password)
    result = nil
    message = CGI.escape message
    request = "/http/sendmsg?api_id=#{api}&user=#{user}&password=#{password}&to=#{number}&text=#{message}&from=RIVR"     
    Net::HTTP.start( 'api.clickatell.com', 80 ) { |http| result = http.get(request).body }    
    return result    
  end 
  
  def validAccount?(accountNo, pinNo)        
    account = find(accountNo,pinNo)    

    if account.pin == pinNo
      account.logins += 1
    else
      account.attempts_today += 1 
      account.attempts_total += 1
    end
    
    account.last_login = Time.now
    account.save!
    
    raise Exceptions::BadCredentials unless account.pin == pinNo        
    return accountNo, pinNo
  end
  
end
