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

require 'uri'
require 'ragi/call_connection'

module RAGI

  # == Overview
  # 
  # This class is the base class for all RAGI call handler objects. To create 
  # a call handler, derive a class from this class with the suffix "Handler" 
  # and place it in the file app/handlers/<name>_handler.rb. 
  #
  # == Actions
  #
  # All public 
  # methods on the class are by default exposed as actions to the callserver. 
  # An action can be called by passing a URL like 
  #
  #   agi://<server>/<handler>/<action>
  #
  # to asterisk. If the action is not specified, then the call server will 
  # choose one of the two following default actions:
  #
  #   dialout - for connections initiated by the call server
  #   dialup - for connections initiated from outside
  #
  # == Helpers
  #
  # Helpers are modules that can be loaded as mixins into the call handlers. 
  # As mixins the implementation of these modules will have access to all the
  # state of the call handler including the session, params, connection, etc.
  #
  # To include a helper, declare it with a line like this in your call handler:
  #
  #    helper :FooBar
  #
  # The call handler will mixin a module named FooBarHelper, loading the file 
  # foo_bar_helper.rb if necessary. The standard location for such helper 
  # files is app/helper.
  #
  # == Parameters
  #
  # There are a variety of ways that parameters can be passed to a call 
  # handler. Each of these variables is available through the params hash. 
  # To retrieve a value from the params hash:
  #
  #     @params['Foo']
  # 
  # For a call coming in over RAGI you can retrieve AGI session variables. 
  # These are the variables passed to teh connection when it is established. 
  # For example, to reference the caller ID:
  #
  #     @params[RAGI::CALLERID]
  #
  # You can also retrieve query parameters from the AGI URL. For instance, if 
  # the AGI URL is something like /foo/bar?widget=gizbot, you can retrieve the 
  # widget value:
  #
  #     if @params[:widget] == 'gizbot' then
  #
  # If the call was initiated through RAGI::place_call, you can access the
  # parameters passed to the initiate call. For instance, if you initiate call 
  # looks like this:
  #
  #     RAGI.place_call('2065551212', '/foo/bar',
  #                             :hash_params => { :param => 123,
  #                                "foo" => "bar" })
  #
  # You can reference these parameters like this:
  #
  #     if @params[:param] == 123 && @params["foo"] == "bar" then
  #
  # Finally, when you redirect to another handler or process a subhandler, all
  # the parameters for your call handler are passed along with any additional
  # parameters you can specify. For instance, this redirect call:
  #
  #     redirect(:handler => :foo_bar,
  #                 :param => 123,
  #                 "foo" => "bar")
  #
  # You can reference these parameters like this:
  #
  #     if @params[:param] == 123 && @params["foo"] == "bar" then
  #  
  # == Sessions
  #
  # A session object is created for each RAGI connection.  This session can
  # be used to share data across multiple calls or between the RAGI server
  # and a web server.
  #
  #     self.session[:foo] = :bar
  #
  # Later you can retrieve the contents, for example:
  #
  #     if(self.session[:foo] == :bar) then
  #
  # == Redirection
  #
  # A call handler can redirect to another call handler. When you redirect, 
  # controll of the call is passed to the other call handler when you exit 
  # your call handler. The session, parameters and connection objects remain 
  # the same. You can specify handlers & actions for the redirection. If the 
  # handler is not specified then the existing handler is reused. In addition, 
  # you can specify additional parameters to be added for the redirected call 
  # handler.
  #
  #     redirect(:handler => :foo,
  #                 :action => :bar,
  #                 :param => 123,
  #                 "foo" => "bar")
  #
  # Handlers & actions can be referenced by symbol or string. Handlers can 
  # also reference an explicit class or a class instance.
  
  class CallHandler
    #-----------------------------------------------------------------------------
    # Accessors
    #-----------------------------------------------------------------------------
    attr_accessor :connection, :redirect_route

    def session
      @connection ? @connection.session : nil
    end

    #-----------------------------------------------------------------------------
    # PUBLIC INSTANCE METHODS
    #-----------------------------------------------------------------------------

    # call this method to redirect to another handler. after calling this 
    # method you should return to the caller. You will not receive 
    # control of the call back when this handler is complete.

    def redirect(options)
      @redirect_route = @route.dup.update(options)
    end

    # call this method to call another handler from within your handler. when 
    # the other handler has finished control will be returned to the caller.

    def process(options)
      route = @route.dup.update(options)

      if CallHandler.match_class(self.class, route[:handler]) then
        RAGI::LOGGER.warn("Warning, creating new instance of handler #{route[:handler]}.")
      end

      CallHandler.process(route, @connection)
    end

    #-----------------------------------------------------------------------------
    # PUBLIC CLASS METHODS
    #-----------------------------------------------------------------------------

    # call this method to attach helpers to your call handler. Helpers are 
    # defined and located in much the same way as helpers on 
    # ActiveController objects.

    def self.helper(*args)
      args.flatten.each do |arg|
        case arg
        when Module
          add_template_helper(arg)
        when String, Symbol
          file_name  = arg.to_s.underscore + '_helper'
          class_name = file_name.camelize
          
          begin
            require_dependency(file_name)
          rescue LoadError => load_error
            requiree = / -- (.*?)(\.rb)?$/.match(load_error).to_a[1]
            msg = (requiree == file_name) ? "Missing helper file helpers/#{file_name}.rb" : "Can't load file: #{requiree}"
            raise LoadError.new(msg).copy_blame!(load_error)
          end
          
          add_template_helper(class_name.constantize)
        else
          raise ArgumentError, 'helper expects String, Symbol, or Module argument'
        end
      end
    end

    # Based on the specified URN, determine the handler & action to use for 
    # the incoming call.

    def self.route(path)
      route = {}

      uri = URI.parse(path)

      path = uri.path
      path = path[1..-1] if path[0] = '/'
      
      # todo: deal with paths like foo/bar/1
      if path.index '/' then
        route[:handler] = path[0..path.index('/')-1]
        route[:action] = path[path.index('/')+1..-1]
      else
        route[:handler] = path
        route[:action] = :dialup
        # todo: check the connection object to see if this is a dialout connection
      end
      # todo: extract uri.query into parameters on the route
      route
    end
    
    # Based on the specified route, load and initialize a handler. we then 
    # call the appropriate action based on the route. if the handler specifies 
    # that we should redirect, then do that.

    def self.process(route, connection)
      handler = nil

      while route do
        
        # check to see if the handler actually needs to be created

        if !handler ||
            !match_class(handler.class, route[:handler]) then

          # to create the handler we either create an instance of the 
          # referenced class or we have to load a dependency and create the 
          # class referenced.

          case route[:handler]
          when Class
            handler = route[:handler].new
          when String, Symbol
            file_name  = route[:handler].to_s.underscore + '_handler'
            class_name = file_name.camelize
          
            begin
              require_dependency(file_name)
            rescue LoadError => load_error
              requiree = / -- (.*?)(\.rb)?$/.match(load_error).to_a[1]
              msg = (requiree == file_name) ? "Missing handler file handlers/#{file_name}.rb" : "Can't load file: #{requiree}"
              raise LoadError.new(msg).copy_blame!(load_error)
            end
          
            handler = class_name.constantize.new
          else
            # todo: test support for passing handler as an instance
            handler = route[:handler]
          end
          handler.init_session(route, connection)
        end

        handler.send(route[:action])
        
        # if a redirection route was set, then we should loop
        route = handler.redirect_route
        handler.redirect_route = nil
      end
    end

    #-----------------------------------------------------------------------------
    # CONNECTION HELPERS
    #-----------------------------------------------------------------------------

    # We mirror all the methods of the callConnection object
    def method_missing(meth, *attrs, &block)
      if @connection.respond_to?(meth)
        @connection.__send__(meth, *attrs, &block)
      else
        super
      end
    end

    #-----------------------------------------------------------------------------
    # INTERNAL METHODS
    #-----------------------------------------------------------------------------
    
    # InitSession is called by the framework to initialize a new call handler 
    # as it gets constructed. This method should never be called from outside 
    # the framework.

    def init_session(route, connection)
      @route = route
      @connection = connection
      @redirect_route = nil
      @call_status = connection.get_call_status

      # Load parameters from the connection
      @params = connection.params.dup
      
      # Extract and add the hash data
      hashData = connection.get_hash_data
      if hashData then
        hashData.each do |name, val|
          @params[name] = val
        end
      end
      
      # Add parameters from the route object
      route.reject { |name, val| [:handler, :action].include? name }.each do |name, val|
        @params[name] = val
      end
    end

    # Add the template module into us

    def self.add_template_helper(mod)
      self.class_eval "include #{mod}"
    end

    # Normalizes the class name passed in. For strings and symbols this will 
    # add the '_handler' string if it is not already present then camelize the 
    # string ('foo_handler' => 'FooHandler'). For classes this will simply 
    # ask the class it's name

    def self.normalize_class_name(obj)
      case obj
      when Class
        obj.to_s
      when String, Symbol
        obj = obj.to_s
        if !obj.downcase.include? 'handler' then
          obj  = obj.to_s.underscore + '_handler'
        end
        obj.camelize
      end
    end

    # Compare two normalized classes to see if they are the same. The following 
    # should all return as equivalent:
    #
    #   FooBarHelper
    #   "FooBar"
    #   :foo_bar
    #   "foo_bar"

    def self.match_class(a,b)
      normalize_class_name(a) == normalize_class_name(b)
    end
  end
end
