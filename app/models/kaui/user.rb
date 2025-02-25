require 'killbill_client'

module Kaui
  class User < ApplicationRecord
    devise :killbill_authenticatable, :killbill_registerable

    # Managed by Devise
    attr_accessor :password

    # Called by Devise to perform authentication
    # Throws KillBillClient::API::Unauthorized on failure
    def self.find_permissions(options)
      do_find_permissions(options)
    end

    # Called by CanCan to perform authorization
    # Throws KillBillClient::API::Unauthorized on failure
    def permissions
      User.do_find_permissions :session_id => kb_session_id
    end

    # Verify the Kill Bill session hasn't timed-out (ran as part of Warden::Proxy#set_user)
    def authenticated_with_killbill?
      begin
        subject = KillBillClient::Model::Security.find_subject :session_id => kb_session_id
        result = subject.is_authenticated
        return result
      rescue Errno::ECONNREFUSED => e
        false
      rescue KillBillClient::API::Unauthorized => e
        false
      end
    end

    def root?
      Kaui.root_username == kb_username
    end

    private

    def self.do_find_permissions(options = {})
      KillBillClient::Model::Security.find_permissions options
    end
  end
end
