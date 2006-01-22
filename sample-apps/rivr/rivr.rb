require 'ragi/callServer'
require 'app/logic'

class CallHandler < RAGI::CallHandler
  
  @con = @biz = nil;
  # initialize business logic
  
  def initialize
    @con = nil  
    @biz = BizLogic.new(self)
  end
  
  # various helper methods
  
  def handle(connection); @con = connection; @con.answer; @con.wait 1; end
  def hangup(sound = :thankYou); info "hanging up: #{sound.to_s}"; play sound; @con.hangUp; end
  def get(sound, max=10); @con.getData sound, 5000, max; end
  def info(message); RAGI.LOGGER.info message; end
  def record(message, beep=false) @con.recordFile message.to_s, 15, beep; end
  def play(sound); @con.playSound sound.to_s; end
  def background(sound); @con.background sound.to_s; end
  def digits(message); @con.sayDigits message; end
  def processCall(connection); @con.hangUp; end
    
end

class RIVR < CallHandler    
    
  # handle incoming call
  
  def processCall(connection)
    handle connection    
    @biz.processCall    
    @con.hangUp
  end
    
end

class Setup < CallHandler
  
  # handle incoming call
  
  def processCall(connection)
    handle connection
    setupSounds(@biz.sounds)
    @con.hangUp
  end
    
  def setupSounds(sounds); sounds.each { |sound| info "recording #{sound.to_s}"; record sound, true }; end
  
end

handlerMap = { "/rivr" => RIVR, "/setup" => Setup }  
RAGI::CallServer.new(:HandlerMap => handlerMap, :DefaultHandler => RIVR)