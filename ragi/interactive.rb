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

# Author: Dean Mao, contact me at deanmao@gmail.com

require 'irb'
require 'irb/workspace'
require 'ragi/call_server'
require 'ragi/call_initiate'

#
# Create a script that contains the following:
# --------------------------------
# require 'ragi/interactive'
# RAGI::InteractiveTest.start
# --------------------------------
# 
# When run, you'll be at an irb prompt with InteractiveTest class as the context.
# When you phone someone with the phone command, it will put you in that handler's
# context when the user picks up the phone.  Use forward/back to cycle between 
# call contexts.
# 
#

module RAGI
  class ContextNotFoundError < StandardError; end
  
  class SimpleThreadServer < WEBrick::SimpleServer
    def SimpleThreadServer.start(&block)
      Thread.new do block.call
      end
    end
  end
  
  class InteractiveTest
    def self.start
      CallServer.new(:ServerType => SimpleThreadServer, :DefaultHandler => InteractiveHandler)
      IRB.setup(nil)
      @@workspaces = []
      @@irb = IRB::Irb.new()
      self.context = self
      
      IRB.conf[:IRB_RC].call(@@irb.context) if IRB.conf[:IRB_RC]
      IRB.conf[:MAIN_CONTEXT] = @@irb.context
      
      Kernel.at_exit { self.cleanup }
      
      trap("SIGINT") do
        @@irb.signal_handle
      end
      
      catch(:IRB_EXIT) do
        @@irb.eval_input
      end
    end
    
    def self.cleanup
      @@workspaces.each do |workspace|
        if workspace.main.instance_of?(CallHandler)
          workspace.main.hang_up
        end
      end
    end
    
    def self.phone(phone_number)
      if @@workspaces.find {|w| w.main.to_s == phone_number} == nil
        RAGI::CallInitiate.place_call(phone_number.to_s, "12345678901", "/", { :phone_number => phone_number.to_s}, nil, "1", nil, nil, nil, nil, "localhost")
      else
        puts "There is already a context open for #{phone_number}!\n"
      end
    end
    
    def self.context=(handler)
      workspace = IRB::WorkSpace.new(handler)
      @@workspaces.push(workspace)
      self.workspace = workspace
    end
    
    def self.workspace=(workspace)
      puts "Switching to context: #{workspace.main.to_s}\n"
      @@irb.context.workspace = workspace
    end
    
    def self.destroy_context(phone_number)
      workspace = @@workspaces.find {|w| w.main.to_s == phone_number}
      if @@workspaces.delete(workspace) != nil
        puts "Destroyed context #{phone_number}"
      else
        raise ContextNotFoundError.new
      end
    end
    
    # cycles forward one context
    def self.forward
      index = @@workspaces.index(@@irb.context.workspace)
      if @@workspaces.size > 1 && index != nil
        workspace = @@workspaces[(index + 1) % @@workspaces.size]
        self.workspace = workspace
      end
    end
    
    # cycles backward one context
    def self.back
      index = @@workspaces.index(@@irb.context.workspace)
      if @@workspaces.size > 1 && index != nil
        workspace = @@workspaces[(index - 1) % @@workspaces.size]
        self.workspace = workspace
      end
    end
    
    def self.reset_context
      self.workspace = @@workspaces.find {|w| w.main.to_s == self.to_s}
    end
    
    def self.to_s
      return "Main AGI Context"
    end
  end


  class InteractiveHandler < CallHandler
    APP_NAME = 'interactive'
    attr_reader :phone_number
    
    def dialup
      @phone_number = @params[:phone_number]
      answer
      wait(1)
      puts "Caller has picked up the phone!\n"
      InteractiveTest.context = self
      @thread = Thread.current
      Thread.stop
    end
    
    # We mirror all the methods of the InteractiveTest class so that you can 
    # switch between contexts during a call
    def method_missing(meth, *attrs, &block)
      if InteractiveTest.respond_to?(meth)
        InteractiveTest.__send__(meth, *attrs, &block)
      else
        super
      end
    end
    
    def hang_up
      @connection.hang_up
      @thread.run
      InteractiveTest.reset_context
      InteractiveTest.destroy_context(@phone_number)
    end
    
    def to_s
      return @phone_number
    end
  end
end
