#  RAGI -- Ruby Asterisk Gateway Interface
#  See http://rubyforge.org/projects/ragi/ for more information.
#  Sponsored by SnapVine, Inc (www.snapvine.com)
#
#  Class:  SimonHandler
#  Description:  this call handler implements a simple memory game over the phone.
#

require 'ragi/call_handler'

class SimonHandler < RAGI::CallHandler
  APP_NAME = 'simon'
    
    # When the RAGI server connects from Asterisk over AGI to our app, it calls this method.	
    def dialup
      answer  # answer the call
      wait(1)  # give it 1 seconds to make sure the connection is established
      
      
      playAgain = true
      while (playAgain)
        instructions               # tell the caller how to play the game
        score = play_game           # start the game and play it, returning the score when done
        announce_score(score)         # tell them how they did
        playAgain = ask_play_again   # ask if they want to play again
      end
      say_goodbye
      hang_up  #end the call
    end
    
    def instructions
      play_sound("simon-welcome")
    end
    
    def play_game  
      
      intArray = [rand(10)]
      score = 0
      
      # test the user's memory on the current int array
      while memory_test(intArray)
        score += 1
        
        # grow the array by one digit   
        intArray << rand(10) # choose a number between 0 and 9 inclusive
        
        wait(1)
      end

      score
    end
    
    def memory_test(intArray)
      # say each number in the array
      intArray.each do |number|
        play_sound("simon-#{number}")  # there are sounds like simon-6.gsm
      end
      
      # listen for user key presses (number of presses should be == intArray.length)
      # Note:  give about 1 second per key press (intArray.length * 1500)
      resultStr = get_data("simon-beep", (intArray.length * 1500), intArray.length)
      
      # Check if what they entered matches the int array
      if (resultStr == intArray.join(""))  # note:  join converts from array to string
        return true   
      else
        play_sound("simon-gameover") 
        return false
      end  
    end
    
    def announce_score(score)
      if (score <= 9)
        play_sound("simon-score")
        play_sound("simon-#{score.to_s}")
      end
      if (score < 5)
        play_sound("simon-low")
      elsif (score < 10)
        play_sound("simon-medium")
      else
        play_sound("simon-high")
      end
    end
    
    def ask_play_again
      # Give the user three seconds to press a digit
      return (get_data("simon-again", 3000, 1).length > 0)
    end
    
    def say_goodbye
      play_sound("simon-goodbye")
    end
  end
