class ApplicationController < ActionController::Base
  # Disable CSRF strict origin check for local HTTP deployments
  protect_from_forgery with: :exception
  self.forgery_protection_origin_check = false

  include Authentication
  before_action :set_locale
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def set_locale
    locale = params[:locale].presence || cookies[:locale].presence || I18n.default_locale
    locale = locale.to_s
    I18n.locale = I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale
    cookies[:locale] = { value: I18n.locale, expires: 1.year.from_now }
  end
end
