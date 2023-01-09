require File.expand_path('../../../../spec/helper', __FILE__)
spec_require 'redis'

spec_precondition 'Redis is running' do
  cache = Redis.new
  "OK" == cache.set('testkey', 'testval')
end

class SpecSession < Ramaze::Controller
  map '/'
  engine :None

  def index
    'No session here'
  end

  def init
    session[:counter] = 0
  end

  def view
    session[:counter]
  end

  def increment
    session[:counter] += 1
  end

  def decrement
    session[:counter] -= 1
  end

  def reset
    session.clear
  end
end

Ramaze::Cache.options.session = Ramaze::Cache::Redis

describe 'Sessions with Ramaze::Cache::Redis' do
  behaves_like :rack_test

  should 'initiate session as needed' do
    get '/'
    last_response.body.should == 'No session here'
    last_response['Set-Cookie'].should == nil

    get('/init')
    last_response.body.should == '0'

    1.upto(10) do |n|
      get('/increment').body.should == n.to_s
    end

    get('/reset')
    get('/view').body.should == ''
    get('/init').body.should == '0'

    -1.downto(-10) do |n|
      get('/decrement').body.should == n.to_s
    end
  end
end
