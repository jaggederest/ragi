#  Copyright (c) 2005 Snapvine, LLC. All rights reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF SNAPVINE, LLC
#    The copyright notice above does not evidence any
#    actual or intended publication of such source code.
#-------------------------------------------------------------------------------

require 'cgi'
require 'cgi/session'

module RAGI

  # This object provides access to session objects without the need for a cgi
  # object so that it can be used within the context of ragi.
  class Session < CGI::Session
    # Default options to be used by all session objects.  See +CGI::Session+
    # for a description of supported options.
    DEFAULT_OPTIONS = {}

    # Create a new session object or load an existing session object by id.
    #
    # +session_id+ is an id if we should load a preexisting session or
    # nil to create a new session
    #
    # +options+ provides a way to override the defaults stored in +DEFAULT_OPTIONS+.
    # See +CGI::Session+ for a descriptionn of supported options.
    def initialize(session_id, options = nil)
      RAGI.LOGGER.debug("creating ragi session with id=#{session_id}")

      standard_options = {
        # This tells the base class where to look in the request_hash
        "session_key" => "session_id",

        # Disable output
        "no_hidden" => true,
        "no_cookies" => true,
        
        # Create a new session iff there is not an existing session id
        "new_session" => (session_id == nil)
      }

      full_options = DEFAULT_OPTIONS.merge(standard_options)
      full_options.merge!(options) if options

      # Convert all keys to strings
      full_options.keys.each do |key|
        full_options[key.to_s] = full_options.delete(key) if key.class != String
      end

      request_hash = { "session_id" => session_id }
      super(request_hash, full_options)
    end

  end
end
