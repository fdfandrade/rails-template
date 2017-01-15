class ApplicationController < ActionController::Base
  before_filter :set_gettext_locale
  protect_from_forgery with: :exception

  def hello
    render html: "hello, world!"
  end
end
