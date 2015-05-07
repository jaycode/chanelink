# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
# require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'integration_test_helper'

def float_equal(a, b)
  if a + 0.00001 > b and a - 0.00001 < b
    true
  else
    false
  end
end