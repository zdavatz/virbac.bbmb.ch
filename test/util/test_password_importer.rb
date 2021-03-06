#!/usr/bin/env ruby
#  -- de.oddb.org -- 16.05.2007 -- hwyss@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require "minitest/autorun"
require 'flexmock/test_unit'
require 'flexmock'
require 'bbmb/util/password_importer'

module BBMB
  module Util
    class TestPasswortImporter < Minitest::Test
      include FlexMock::TestCase
      def setup
        @password = flexmock('cell')
        @email = flexmock('cell')
        @customer_class = flexstub(Model::Customer)
        @customer = flexmock('customer')
        @row = [ "                                ",
          Time.local(2002, 4, 11, 10, 36), "Mxxxx", @password, "Wxxxxxxxxxx 65",
          nil, nil, nil, "CHE",nil, @email, 999999, nil, nil, 3113,
          "Rxxxxxx", "Cxxxxx", nil, "0x xxx xx xx",nil, nil, "0x xxx xx xx",
          "Dr. med. vet.", 1, "de", 1, nil, 2,1,4,1,2,6,1,1,3
        ]
        BBMB.auth = flexmock('yus-server')
        @session = flexmock('yus_session')
        BBMB.auth.should_receive(:login).with('root', 'unguessable', 'ch.bbmb')\
          .times(1).and_return(@session)
        BBMB.config = config = flexmock('config')
        config.should_receive(:auth_domain).and_return('ch.bbmb')
        config.should_ignore_missing
        @importer = PasswordImporter.new('root', 'unguessable')
      end
      def teardown
        BBMB.config = nil
      end
      def test_import_record__no_password
        @row[3] = nil
        @row[10] = nil
        assert_nil @importer.import_record(@row)
      end
      def test_import_record__empty_password
        @password.should_receive(:to_s).with('utf8').times(1).and_return('')
        @email.should_receive(:to_s).with('utf8').and_return('user@domain.tld')
        assert_nil @importer.import_record(@row)
      end
      def test_import_record__no_user
        @email.should_receive(:to_s).with('utf8').and_return('user@domain.tld')
        @password.should_receive(:to_s).with('utf8').times(1).and_return('sekrit')
        @customer_class.should_receive(:find_by_customer_id).times(1)\
          .and_return(nil)
        assert_nil @importer.import_record(@row)
      end
      def test_import_record__non_matching_email
        @password.should_receive(:to_s).with('utf8').times(1).and_return('sekrit')
        @customer_class.should_receive(:find_by_customer_id).times(1)\
          .and_return(@customer)
        @customer.should_receive(:email).and_return(nil)
        @email.should_receive(:to_s).with('utf8').and_return('user@domain.tld')
        assert_nil @importer.import_record(@row)
      end
      def test_import_record__success
        @password.should_receive(:to_s).with('utf8').times(1).and_return('sekrit')
        @customer_class.should_receive(:find_by_customer_id).times(1)\
          .and_return(@customer)
        @customer.should_receive(:email).and_return('user@domain.tld')
        @email.should_receive(:to_s).with('utf8').and_return('user@domain.tld')
        @session.should_receive(:set_password)\
          .with('user@domain.tld', 'ccbc53f4464604e714f69dd11138d8b5')\
          .times(1).and_return(Time.now)
        @session.should_receive(:grant)\
          .with('user@domain.tld', 'login', 'ch.bbmb.Customer')\
          .times(1).and_return(Time.now)
        assert_instance_of(Time, @importer.import_record(@row))
      end
      def test_postprocess
        BBMB.auth.should_receive(:logout).with(@session).times(1).and_return {
          assert true }
        @importer.postprocess(@session)
      end
    end
  end
end
