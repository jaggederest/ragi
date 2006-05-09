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

require 'webrick/config'
require 'webrick/log'
require 'webrick/server'
require 'ragi/call_handler'
require 'ragi/call_connection'
require 'ragi/config'
require 'thread'

module RAGI
  VERSION = "1.0.0"

  @globalConfig = nil

  def self.LOGGER
    @logger ||= WEBrick::Log::new
    @logger
  end

  def self.LOGGER=(logger)
    @logger = logger
  end

  def self.globalConfig
    # This assignment will make a dup
    @globalConfig ||= RAGI::Config::Globals
    @globalConfig
  end

  def self.globalConfig=(newConfig)
    @globalConfig = newConfig.dup()
  end
  
  class CallServer
    @incomingcallsocket = nil

    # 4573 = asterisk AGI
    # RAGI::CallHandler - default handler
    
    def initialize(config = {}, default = RAGI::Config::Standard)
      @config = default.dup.update(config)
      @config[:Logger] ||= WEBrick::Log::new
      @config[:ParentStopCallback] = @config[:StopCallback] if @config[:StopCallback]
      @config[:StopCallback] = method('shutdown_done')

      RAGI.LOGGER = @config[:Logger]

      @mutex = Mutex.new
      @signal = ConditionVariable.new
      @running = true

      if (@incomingcallsocket == nil)
        RAGI.LOGGER.info("#{self.class.name}: default-handler=#{@config[:DefaultHandler].to_s} port=#{@config[:Port]}")
        @incomingcallsocket = WEBrick::GenericServer.new( @config )  
          
        begin
          @incomingcallsocket.start do |sock|
            # code to executed in a thread
            begin
              cc = CallConnection.new(sock)
            
              route = {
                :handler => @config[:DefaultHandler],
                :action => :dialup
              }
            
              # the default call handler comes from config environment.rb
            
              if (cc.agi_url != nil && cc.agi_url != '/')  
                route = CallHandler.route(cc.agi_url)
              end
              RAGI.LOGGER.info("#{self.class.name}: processing call with #{route[:handler].to_s}")
              
              CallHandler.process(route, cc)

              # todo: Catch exceptions and say something to the user
              # before we disconnect them.  Something like this maybe:
              #
              # rescue StandardError => err
              #  if (cc) then
              #   cc.play_sound('tc/std/sorry-error')
              #   cc.hang_up()
              #  end
              #  raise
              # end
            ensure
              cc.close if cc
            end
          end
          RAGI.LOGGER.info("#{self.class.name}: server shutdown port=#{@config[:Port]}")
          
        rescue StandardError => err
          RAGI.LOGGER.error("#{err.message}")
          RAGI.LOGGER.error(err.backtrace.join("\n"))
        end
        
      end
    end    

    def shutdown
      @incomingcallsocket.shutdown
    end

    def shutdown_done
      RAGI.LOGGER.debug("#{self.class.name}: Shutdown complete")

      @config[:ParentStopCallback].call if @config[:ParentStopCallback]
      @mutex.synchronize do
        @running = false
        @signal.signal
      end
    end
    
    def join
      @mutex.synchronize do
        if @running
          @signal.wait(@mutex)
        end
      end      
    end      
  end
end
