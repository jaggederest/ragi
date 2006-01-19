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
# config.rb -- Default configurations.
#

require 'webrick/config'
require 'ragi/call_handler'

module RAGI
  
  DEFAULT_PORT = 4573

  module Config

    # for HTTPServer, HTTPRequest, HTTPResponse ...
    Standard = WEBrick::Config::General.dup.update(
      :Port           => RAGI::DEFAULT_PORT,
      :HandlerMap     => {}
    )

    Globals = {
      # Name of the box running the agi server, so that asterisk can find it
      # by default this will use your Ruby server's name
      "agiServer" => `hostname`.strip(),
      
      # Path to use for saving outgoing call files
      "outgoingCallPath" => 
        ENV['RAGI_OUT_CALL_PATH'] ? ENV['RAGI_OUT_CALL_PATH'] : "var/spool/asterisk/outgoing",

      # Path to use for saving wakeup call files
      "wakeupCallPath" =>
        ENV['RAGI_WAKEUP_CALL_PATH'] ? ENV['RAGI_WAKEUP_CALL_PATH'] : "var/spool/asterisk/wakeups",

      # Path to the built-in sound files relative to the SIP server.
      "sipSoundPath" => 
        ENV['RAGI_SIP_SOUND_PATH'] ? ENV['RAGI_SIP_SOUND_PATH'] : "var/lib/asterisk/sounds"
    }

  end
end
