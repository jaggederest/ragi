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

module RAGI
  # This class is useful for writing unit tests
  class TestSocket
    
    def initialize(params, messages)
      @params = params
      @messages = messages
      @inParams = true
      @currentIndex = 0
    end

    def self.Exec(cmd, params)
      [ "EXEC #{cmd} #{params}", "200 result=0"]
    end

    def self.GetData(soundfile, result)
      ["GET DATA #{soundfile} 2000", "200 result=#{result} (timeout)"]
    end

    def self.StreamFile(soundfile, escapeDigits, initialOffset, result, endpos)
      ["STREAM FILE #{soundfile} \"#{escapeDigits}\" #{initialOffset}", 
        "200 result=#{result} endpos=#{endpos}"]
    end

    def self.PlaySound(soundfile)
      [ "EXEC playback #{soundfile}", "200 result=0"]
    end

    def self.SayNumber(number)
      SayNumberFull(number, " \"*#\"")
    end

    def self.SayNumberFull(number, escapeDigits)
      [ "SAY NUMBER #{number} \"#{escapeDigits}\"", "200 result=0"]
    end

    def self.HangUp()
      [ "HANGUP", "200 result=0"]
    end

    def print(msg)
      if @inParams
        raise StandardError, "Should not receive commands until parameters are parse"
      end

      if (!@messages[@currentIndex])
        raise StandardError, "Too many messages received\nMessage =#{msg}= received"
      end

      if (msg != @messages[@currentIndex][0])
        raise StandardError, "Unexpected message received\nMessage =#{msg}= received\nExpected =#{@messages[@currentIndex][0]}"
      end
    end

    def gets
      if (@inParams) then
        if (@currentIndex < @params.length) then
          key = @params.keys[@currentIndex]
          val =  "#{key}: #{@params[@params.keys[@currentIndex]]}"
          @currentIndex += 1
        else
          @currentIndex = 0
          @inParams = false
          val = ''
        end
      else
        if (@currentIndex < @messages.length) then
          val = @messages[@currentIndex][1]
          @currentIndex += 1
        else
          raise StandardError, "Unexpected messages past end of test case"
          @currentIndex = 0
          val = '\n'
        end
      end
      val
    end
  end
end
