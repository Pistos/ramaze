# -*- coding: utf-8 -*-
#          Copyright (c) 2008 rob@rebeltechnologies.nl
# All files in this distribution are subject to the terms of the MIT license.

require File.expand_path('../../../../spec/helper', __FILE__)

spec_precondition 'Process.fork should be supported' do
  if RUBY_DESCRIPTION.include?('jruby')
    should.flunk 'These tests use Process.fork which does not work on jruby'
  end
end

require 'ramaze/log/syslog'

describe 'Syslog' do

  # close the syslog, if it was open for some reason before we
  # start a test.
  before do
    Syslog.close if Syslog.opened?
  end

  it 'should default initialize correctly' do
    syslog = Ramaze::Logger::Syslog.new
    ::Syslog.opened?.should == true
    ::Syslog.ident.should   == $0
    ::Syslog.options.should == ( ::Syslog::LOG_PID | ::Syslog::LOG_CONS )
    ::Syslog.facility.should == ::Syslog::LOG_USER
  end

  it 'should handle non default initialization' do
    syslog = Ramaze::Logger::Syslog.new( 'ramaze_syslog_test',
                                                   ::Syslog::LOG_NDELAY | ::Syslog::LOG_NOWAIT,
                                                   ::Syslog::LOG_DAEMON )
    ::Syslog.opened?.should == true
    ::Syslog.ident.should   == 'ramaze_syslog_test'
    ::Syslog.options.should == ( ::Syslog::LOG_NDELAY | ::Syslog::LOG_NOWAIT )
    ::Syslog.facility.should == ::Syslog::LOG_DAEMON
  end

  # We test the actual logging using a trick found in te test code of the
  # syslog module.  We create a pipe, fork a child, reroute the childs
  # stderr to the pipe. Then we open the logging using LOG_PERROR, so all
  # log messages are written to stderror.  In the parent we read the messages
  # from the pipe and compare them to what we expected.
  def test_log_msg( type, priority, msg )
    logpipe = IO::pipe
    child = fork {
      logpipe[0].close
      STDERR.reopen(logpipe[1])
      syslog = Ramaze::Logger::Syslog.new( 'ramaze_syslog_test',
                                                    ::Syslog::LOG_PID | ::Syslog::LOG_NDELAY | ::Syslog::LOG_PERROR,
                              ::Syslog::LOG_USER )
      syslog.send priority, msg
      Process.exit!( 0 )
    }
    logpipe[1].close
    Process.waitpid(child)
    label = case priority
            # when 'debug', 'info', 'error'
            #   priority
            when :dev
              'debug'
            when :warn
              'warning'
            else
              priority.to_s
            end
    logpipe[0].gets.slice(/ramaze.*/).should == "ramaze_syslog_test[#{child}] <#{label.capitalize}>: #{msg}"
  end

  it 'should handle debug' do
    test_log_msg :direct, :debug, "Hello Debug World"
  end

  it 'should handle dev' do
    test_log_msg :direct, :dev, "Hello Dev World"
  end

  it 'should handle info' do
    test_log_msg :direct, :info, 'Hello Info World!'
  end

  it 'should handle warn' do
    test_log_msg :direct, :warn, 'Hello Warn World!'
  end

  it 'should handle error' do
    test_log_msg :direct, :error, 'Hello Error World!'
  end

  it 'should escape % sequences' do
    test_log_msg :direct, :info, "Hello Cruel |évil| 戈 REAL %s World"
  end
end
