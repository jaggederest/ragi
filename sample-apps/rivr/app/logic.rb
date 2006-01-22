require 'rubygems'

require_gem 'activerecord'
require_gem 'activesupport'

require 'app/config'
require 'app/model'
require 'app/exceptions'

# split business logic away from RAGI logic

class BizLogic
  
  attr_reader :sounds
  
  def initialize(delegated = nil)
    @delegate = delegated    
    @bizmodel = BizModel.new      
  end
      
  # handle an incoming call
  
  def processCall
    prefix, number = getInput { checkValidNumber Cfg.get.prefixes }
    iNo = internationalize Cfg.get.country_code, number
    product = chooseProduct Cfg.get.prefixes[prefix], Cfg.get.providers[prefix]
    
    hangup :thankYou unless product
    
    accountNo, pin = getInput { checkAccount }
    voucher = @bizmodel.consume(accountNo, pin, product)
   
    @bizmodel.notifyViaSMS(iNo, "Your recharge code for #{number} is #{voucher}. Have a nice day!", 
                            Cfg.get.sms_api_id, Cfg.get.sms_user, Cfg.get.sms_password) if voucher 
  
    hangup :thankYou
    
  # handle exceptions by letting the user know what went wrong, then hanging up
  # is there a cleaner way?
  rescue Exceptions::InsufficientBalance
    hangup :insufficientBalance
  rescue Exceptions::OutOfStock
    hangup :outOfStock
  rescue Exceptions::BadCredentials  
    hangup :badCredentials
  rescue Exceptions::VoucherAlreadyUsed
    hangup :voucherAlreadyUsed
  rescue Exceptions::BruteForce
    hangup :bruteForce
  rescue Exceptions::TransactionFailed
    hangup :transactionFailed
  rescue Exceptions::InvalidInput
    hangup :invalidInput
  rescue Exception => e
    info "Exception: #{e.message}\n#{e.backtrace}"
    hangup :systemError
  end
    
  # choose a number from a menu. tell the user if we are out of stock
  
  def chooseProduct(products, sound, attempts=3)
    return nil unless @bizmodel.products_in_stock?(products)
    begin 
      key = get sound, 1
      product = products[key] 
      if products.key? key        
        if @bizmodel.product_in_stock?(product)
          play product
          return product
        else
          attempts -= 1
          play :outOfStock
        end
      end
    end until attempts <= 0   
    return nil  
  end

  # make sure the supplied number is valid prefix
  
  def checkValidNumber(validPrefixes, number = :mobileNumber, numberAgain = :mobileNumberAgain)
    areacode = nil
    num = get number, 10
    validPrefixes.each_key { |prefix| ; areacode = prefix if num.starts_with? prefix}
    raise Exceptions::InvalidInput unless areacode
    raise Exceptions::OutOfStock unless @bizmodel.products_in_stock?(Cfg.get.prefixes[areacode])
    check = get numberAgain, 10
    raise Exceptions::InvalidInput unless num == check
    raise Exceptions::InvalidInput unless num.length == 10
    return areacode, num
  end

  # ensure that we have the correct account number and pin
  
  def checkAccount(account = :account, pin = :pin)
    accountNo = get account, 20
    pinNo = get pin, 4
    accountNo, pinNo = @bizmodel.validAccount? accountNo, pinNo
    return accountNo, pinNo
  end

  # Ensure data entry meets arbitrary conditions defined in an attached block
  # the block has to return a pair of values, the first of which is tested
  # to be not nil. Takes a parameter, attempts, which defaults to three 
  # to obtain a non nil result value from user input.
  
  def getInput(sound = :tryAgain, attempts=3)
    begin
      attempts -= 1
      a_key, a_value = yield
      play sound unless a_key
    rescue Exceptions::InvalidInput
      retry unless attempts <= 0
    end until a_key || attempts <= 0
    raise Exceptions::InvalidInput if attempts <= 0
    raise Exceptions::InvalidInput unless a_key
    return a_key, a_value
  end
  
  # dispatch 'unknown' methods back to rivr
  
  def method_missing(method, *args)
    @delegate.send method, *args
  end
  
  # 'internationalize' numbers
  # assumes valid areacodes start with '0'
  
  def internationalize(country_code, number)
    number = number.to_s
    return nil unless number.starts_with?('0')
    return nil unless number.length == 10
    number = number[1 .. -1]
    number = country_code + number.to_s    
  end
end
