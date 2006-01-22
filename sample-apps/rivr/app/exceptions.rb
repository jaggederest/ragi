module Exceptions

  class InsufficientBalance   < StandardError; end
  class BadCredentials        < StandardError; end
  class VoucherAlreadyUsed    < StandardError; end
  class OutOfStock            < StandardError; end
  class BruteForce            < StandardError; end
  class TransactionFailed     < StandardError; end
  class InvalidInput          < StandardError; end

end
