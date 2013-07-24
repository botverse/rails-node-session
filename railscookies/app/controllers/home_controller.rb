class HomeController < ApplicationController
  before_filter :authenticate_user!
  @@people = {
      'fonz@botverse.com' => 'jake@botverse.com',
      'jake@botverse.com' => 'fonz@botverse.com'
  }
  def index

    @to = @@people[current_user.email]
  end
end
