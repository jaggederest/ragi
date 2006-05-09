#
# RAGI - Ruby classes for implementing an AGI server for Asterisk
# The BSD License for RAGI follows.
#
# Copyright (c) 2005, SNAPVINE LLC (www.snapvine.com)
# All rights reserved.

# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#    * Neither the name of SNAPVINE nor the names of its contributors
#       may be used to endorse or promote products derived from this software 
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Class: callInitiate.rb
# This class provides a convenient way to place outbound calls through Asterisk.
# When answered, calls initiated with callInitiate are redirected back to a 
# RAGI callHandler for processing
#

require 'cgi'
require 'yaml'
require 'fileutils'

module RAGI
  class UsageError < StandardError; end
  class CmdNotFoundError < StandardError; end
  class ApplicationError < StandardError; end
  
  DEFAULT_CALL_OPTIONS = {
    :caller_id => "10",
    :max_retries => 0,
    :retry_time => 5,
    :wait_time => 45
  }
    
  class << self

    # The place_call method allows the caller to initiate a call to a given 
    # phonenumber, handling it with the specified URN. In addition, the caller 
    # can specify additional parameters:
    #
    # :caller_id        - a string containing the caller id to use, e.g. 
    #                         "8005551212".  There is no name, just a number.
    #
    # :hash_params - a hash containing parameters that will be made available 
    #                         to the call handler
    #
    # :call_date        - specify the time the call should occur, specify nil 
    #                         to make the call occur immediately
    #
    # :unique_id       - optional uniqueID useful if you need to delete a 
    #                         scheduled call later.
    #
    # :max_retries   - how many times to retry if the call doesn't go through
    #
    # :retry_time     - time to wait between tries in seconds
    #
    # :wait_time      - time to wait in seconds for the call to answer, 
    #                        inclusive of time spent connecting to the PSTN 
    #                        termination provider.
    
    def place_call(phone_number, urn, options = {})
      options = DEFAULT_CALL_OPTIONS.clone.update(options)
      
      options[:agi_server] ||= RAGI::globalConfig["agiServer"]

      RAGI::CallInitiate.place_call(phone_number, 
                                    options[:caller_id],
                                    urn,
                                    options[:hash_params],
                                    options[:call_date], 
                                    options[:unique_id],
                                    options[:max_retries],
                                    options[:retry_time],
                                    options[:wait_time],
                                    options[:set_vars],
                                    options[:agi_server])
    end
  end

  class CallInitiate

    # This function is called by RAGI.place_call to actually do the work.
	def self.place_call(phoneNumber, callerID, urn, hashData, callDate, uniqueID, maxRetries, retryTime, waitTime, extraChannelVars, agiServer)
      
      placeCallNow = false
      if (callDate == nil)
        placeCallNow = true
        callDate = Time.now
      end
      
      if (urn[0..0] != '/') then
        raise ApplicationError, "Relative URNs cannot be used (found #{urn})"
      end
      
      RAGI.LOGGER.debug("Initiating call with agi server: #{agiServer}")
      
      fileName = getfilename(phoneNumber, callDate, uniqueID)
      
      wakeupFile = File.join(RAGI::globalConfig["wakeupCallPath"], fileName.to_s)
      outgoingFile = File.join(RAGI::globalConfig["outgoingCallPath"], fileName.to_s)
      callfile = File.new(fileName.to_s, "w+")
      
      s = ""
      s << ";This file was generated by RAGI's callInitiate class\r\n"
      s << ";File generated date: #{Time.now.strftime('%m-%d-%Y at %H:%M -- %A')}\r\n"
      s << ";Call date: #{Time.new.strftime('%m-%d-%Y at %H:%M -- %A')}\r\n\r\n"
      s << "Channel: Local/outbound@dialout\r\n"
      s << "Callerid: <#{callerID}>\r\n"
      s << "MaxRetries: #{maxRetries}\r\n"
      s << "RetryTime: #{retryTime}\r\n"
      s << "WaitTime: #{waitTime}\r\n"
      s << "Context: dialout\r\n"
      s << ";magic extension for outbound calls via RAGI callInitiate\r\n"
      s << "Extension: outbound-handler\r\n"
      s << "Priority: 1\r\n"
      
      #put in the fundamental call handling variables
      s << "SetVar: CallInitiate_phonenumber=#{phoneNumber}\r\n"
      s << "SetVar: CallInitiate_callerid=#{callerID}\r\n"
      
      s << "\r\nSetVar: AGI_URL=#{urn}\r\n"
      s << "\r\nSetVar: AGI_SERVER=#{agiServer}\r\n"
      
      if (extraChannelVars)
        extraChannelVars.each do |name, value| 
          s << "\r\nSetVar: #{name}=#{value}\r\n"
        end
      end
      
      marshalData = CGI.escape(YAML.dump(hashData))
      
      s << "\r\nSetVar: CallInitiate_hashdata=#{marshalData}\r\n\r\n"
      
      callfile.print(s)  
      
      #Note:  asterisk call files need these terminating line feeds or else it crashes.
      callfile.print("\r\n\r\n\r\n")  
      callfile.close
      
      # Setup permissions so that asterisk can read this thing no matter what...
      File.chmod(0777, fileName)
      if (placeCallNow == true)
        FileUtils.mv fileName, outgoingFile #place call now
        # todo Can't rely on the file still being there.  Asterisk may have grabbed it
        File.chmod(0777, outgoingFile)	
      else
        FileUtils.mv fileName, wakeupFile #schedule call for later
        File.chmod(0777, wakeupFile)
      end
	end
	
	def self.delete_call(phoneNumber, callDate, uniqueID)
      #assert:  callDate is not nil
      fileName = getfilename(phoneNumber, callDate, uniqueID)
      wakeupFile = File.join(RAGI::globalConfig["wakeupCallPath"], fileName)
      FileUtils.rm wakeupFile, :force => true 
	end
    
	# Returns the hashtable representation of str if string is encoded by hashEncode
	def self.decode_call_params(hashStr)
      if hashStr then
        YAML.load(CGI.unescape(hashStr))
      end
    end
    
    private    
	def self.getfilename(phoneNumber, callDate, uniqueID)
      "#{callDate.strftime('%H%M')}.#{phoneNumber}.#{uniqueID}.call"
	end
  end
end
