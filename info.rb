
# Create a new project 
$ rails new timetracker -d=postgresql --skip-test-unit

# Remove the directories: vendor, test, lib

### Edit database.yml which will end up with the following code:
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

development:
  <<: *default
  database: timetracker_development

test:
  <<: *default
  database: timetracker_test

production:
  <<: *default
  database: timetracker_production
  username: timetracker
  password: <%= ENV['TIMETRACKER_DATABASE_PASSWORD'] %>

# create the database:
$ rake db:create

## inside Gemfile

# add the following gems for testing
  gem 'guard'
  gem 'guard-livereload' # reloads the browser after saving a file
  gem 'guard-rspec' # runs the specs when the files are saved
  gem 'rspec-rails'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'shoulda-matchers'

# and puma server:
  gem 'puma'

# Remove Turbolinks from 3 places: Gemfile, application.js and application.html.erb

# Init guard:
$ guard init

# Install RSpec:
$ rails g rspec:install

## Iside spec/rails_helper.rb
# add the following require statements:
require 'spec_helper'
require 'rspec/rails'
require 'database_cleaner'
require 'capybara/rspec'

# replace the existing RSpec configuration with the following code:
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Rails.application.routes.url_helpers
  config.include Capybara::DSL
  config.include Devise::TestHelpers, type: :controller
  config.order = "random"

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end

## Create spec/features folder and account_creation_feature_spec.rb file and enter the specs code:

require 'rails_helper'

describe 'account creation' do
  it 'allows user to create account' do
    visit root_path
    click_link 'Create Account'

    # fill_in 'Name', with: 'Ryan'
    # fill_in 'Email', with: 'ryan@gmail.com'
    # fill_in 'Password', with: 'pw'
    # fill_in 'Password Confirmation', with: 'pw'
    fill_in 'Subdomain', with: 'test_subdomain'
    click_button 'Create Account'

    expect(page).to have_content('Signed up successfully')
  end
end

# run rspec with guard
$ guard
$ (enter)

# generate the Account model
$ rails g model Account subdomain owner_id:integer
$ rake db:migrate

## inside spec/models/account_spec.rb add the following code:
require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'validations' do
    it { should validate_presence_of :subdomain }
    # it { should validate_uniqueness_of :subdomain }

    it { should allow_value('bolandrm').for(:subdomain) }
    it { should allow_value('test').for(:subdomain) }

    it { should_not allow_value('www').for(:subdomain) }
    it { should_not allow_value('WWW').for(:subdomain) }
    it { should_not allow_value('.test').for(:subdomain) }
    it { should_not allow_value('test/').for(:subdomain) }

    it 'validates case insensitive uniqueness' do
      create(:account, subdomain: 'Test')
      expect(build(:account, subdomain: 'test')).to_not be_valid
    end
  end

  describe 'associations' do
    it 'has an owner'
  end
end


# after writing the Account model specs prepare the test database:
$ rake db:test:prepare

## inisde models/account.rb add the following code:
class Account < ActiveRecord::Base
  RESTRICTED_SUBDOMAINS = %w(www)

  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[\w\-]+\Z/i, message: 'contains invalid characters' },
                        exclusion: { in: RESTRICTED_SUBDOMAINS, message: 'restricted' }

  before_validation :downcase_subdomain

  private

  def downcase_subdomain
    self.subdomain = subdomain.try(:downcase)
  end
end

# inside routes.rb add the following code:
  root 'welcome#index'
  resources :accounts

# create controllers/welcome_controller.rb and add the following code:
class WelcomeController < ApplicationController
  def index
  end
end

# create views/welcome/index.html.erb and add the following code:
<%= link_to 'Create Account', new_account_path %>

# create controllers/accounts_controller.rb and add the following code:
class AccountsController < ApplicationController
  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to root_path, notice: 'Signed up successfully'
    else
      render :new
    end
  end

  private
  def account_params
    params.require(:account).permit(:subdomain)
  end
end

# create accounts/new.html.erb and add the code:
<h2>Create an Account</h2>

<%= form_for @account do |f| %>
  <p>
    <%= f.label :subdomain %>
    <%= f.text_field :subdomain %>
  </p>
  <%= f.submit %>
<% end %>

# inside layouts/application.html.erb add above <%= yield %>:
  <% flash.each do |name, msg| %>
    <%= content_tag :div, msg, id: "flash_#{name}" %>
  <% end %>

## add bootstrap
# inside Gemfile add:
gem 'bootstrap-sass'

# rename assets/stylesheets/application.css to application.scss and add:
@import 'bootstrap';
@import 'layout';

# inside assets/javascripts/application.js, above  //= require_tree .  add:
//= require bootstrap

# create assets/stylesheets/layout.scss and add:
body {
  padding-top: 20px;
}

#flash-notice {
  @extend .alert;
  @extend .alert-success;
}
#flash-error {
  @extend .alert;
  @extend .alert-danger;
}
#flash-warning {
  @extend .alert;
  @extend .alert-warning;
}

# inside application.html.erb inside the body tags replace the existing code with:
<header class="container">
  <nav class="navbar navbar-default">
    <div class="navbar-header">
      <%= link_to 'Time Tracker', root_path, class: 'navbar-brand' %>
    </div>
  </nav>
</header>

<div class="container">
  <% flash.each do |name, msg| %>
    <%= content_tag :div, msg, id: "flash_#{name}" %>
  <% end %>
  
  <div class="row">
    <%= yield %>
  </div>
</div>

# inside welcome/index.html.rb add:
<div class="col-md-12">
  <div class="jumbotron">
    <h1>Time Tracker</h1>
    <p>Track your time with most awesome time tracking ever app.</p>
    <p><%= link_to 'Create Account', new_account_path, class: 'btn btn-primary btn-lg' %></p>
  </div>
</div>

# inside Gemfile add:
gem 'simple_form'

# run:
$ rails generate simple_form:install --bootstrap

# restart server

# inside views/accounts/new.html.erb, replace the existing code with:
<div class="col-md-6 col-md-offset-3 panel panel-default">
  <div class="panel-body">
    <h2>Create an Account</h2>

    <%= simple_form_for @account do |f| %>
      <%= f.input :subdomain %>
      <!-- <span class="input-group-addon">.timetracker.dev</span>   -->
      <%= f.button :submit, class: 'btn btn-primary' %>
    <% end %>
  </div>
</div>


# inside account_creation_feature_spec.rb uncomment the fill_in lines

## inside account_rspec.rb
# add directly after describe 'validations':
    it { should validate_presence_of :owner }
# inside describe 'associations' replace the code with:
it { should belong_to :owner }

# create spec/models/user_spec.rb and add:
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }

  end

  describe 'associations' do

  end
end

# add to Gemfile:
gem 'devise'

# run devise generator:
$ rails g devise:install

# generate devise model:
$ rails g devise User

## inside migration file devise_create_users.rb 
# comment out the ## Trackable secion
# on top add a string field for name
t.string :name

# migrate the database
$ rake db:migrate
# migrate the test database
$ rake db:test:prepare

# iniside initializers/devise.rb change the password min. length from 8 to 2 for testing and development purpose:
  config.password_length = 2..72

## inside models/user.rb 
# remove :registerable and :trackable devise modules
# also add:
validates :name, presence: true

# inside models/account.rb add:
belongs_to :owner, class_name: 'User'
validates :owner, presence: true

# inside spec/factories/accounts.rb replace the existing code with:
FactoryGirl.define do
  factory :account do
    sequence(:subdomain) { |n| "subdomain#{n}" }
    association :owner, factory: :user
  end
end

# inside spec/factories/users.rb replace the existing code with:
FactoryGirl.define do
  factory :user do
    name 'Ryan'
    sequence(:email) { |n| "email#{n}@gmail.com" }
    password 'pw'
  end
end

# inside models/account.rb add the line:
  accepts_nested_attributes_for :owner

## inside accounts_controller.rb
# replace the code of new method with:
    @account = Account.new
    @account.build_owner
# replace the code of account_params with:
    params.require(:account).permit(:subdomain, owner_attributes: [:name, :email, :password, :password_confirmation])

# inside views/accounts/new.html.erb replace the existing code with:
<div class="col-md-6 col-md-offset-3 panel panel-default">
  <div class="panel-body">
    <h2>Create an Account</h2>

    <%= simple_form_for @account do |f| %>
      <%= f.fields_for :owner do |o| %>
        <%= o.input :name %>
        <%= o.input :email %>
        <%= o.input :password %>
        <%= o.input :password_confirmation %>
      <% end %>    
  
      <%= f.input :subdomain %>
      <!-- <span class="input-group-addon">.timetracker.dev</span>   -->
      <%= f.button :submit, class: 'btn btn-primary' %>
    <% end %>
  </div>
</div>

# add inside Gemfile:
gem 'pry'

# the following code can be inserted inside spec files as a breakpoint to track down errors:
binding.pry

## when in debug mode:
$ page
# list the methods of page
$ ls page -m
# check page text
$ page.text

# inside account_creation_feature_spec.rb, replace capital 'C' with lower case 'c' in "Password Confirmation"