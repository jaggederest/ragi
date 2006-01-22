class Cfg
  
  def initialize
    
    # each sound corresponds to an Asterisk sound file. You can run the setup
    # call handler to create these sounds in your local installation. See the
    # README for more details.
    
    @sounds   =   
                  [ 
                    :mobileNumber,        :mobileNumberAgain,   :tryAgain,    
                    :thankYou,            :provider_1,          :provider_2,                
                    :provider_3,          :provider_4,          :provider_1_1,     
                    :provider_1_2,        :provider_1_3,        :provider_2_1, 
                    :provider_2_2,        :provider_2_3,        :provider_3_1,   
                    :provider_3_2,        :provider_3_3,        :provider_4_1,         
                    :provider_4_2,        :provider_4_3,        :account,       
                    :pin,                 :invalidInput,        :outOfStock,          
                    :insufficientBalance, :badCredentials,      :voucherAlreadyUsed,  
                    :bruteForce,          :transactionFailed,   :systemError
                  ]
    
    # prefixes map various providers to products on sale. The application takes a 
    # given number, and uses the prefix to find out what products are applicable
    # for that number. Each product MUST also exist in the data model (i.e. there
    # is a row in the products table in which the name column contains the value
    # of the symbol below, one row for each symbol)
              
    @prefixes =   
                  {
                    '555' => { '1' => :provider_1_1,  '2' => :provider_1_2,   '3' => :provider_1_3  },     
                    '666' => { '1' => :provider_2_1,  '2' => :provider_2_2,   '3' => :provider_2_3  },       
                    '777' => { '1' => :provider_3_1,  '2' => :provider_3_2,   '3' => :provider_3_3  }, 
                    '888' => { '1' => :provider_4_1,  '2' => :provider_4_2,   '3' => :provider_4_3  }    
                  }
         
    # providers map phone numbers to a voice menu explaining the available products for that
    # type of phone number. The symbol must be a valid Asterisk sound file that is available
    # in your Asterisk installation
                
    @providers =  
                  {
                    '555' => :provider_1,
                    '666' => :provider_2,
                    '777' => :provider_3,
                    '888' => :provider_4,
                  }
              
    # miscellaneous configuration goes here ...
              
    @country_code = '+1'  
  
    @sms_api_id   = 'xxxxxx'
    @sms_user     = 'yyyyyy'
    @sms_password = 'zzzzzz'
  
    @db_adapter   = 'mysql'
    @db_name      = 'rivr'
    @db_user      = 'foo'
    @db_password  = 'bar'
              
  end

  # singleton

  private_class_method :new
  
  @@config = nil
  
  def Cfg.get
    @@config = new unless @@config
    @@config
  end
  
  # provide access to attributes
  
  attr_reader :sounds, :prefixes, :providers, :country_code,
              :sms_api_id, :sms_user, :sms_password,
              :db_adapter, :db_name, :db_user, :db_password
                 
end