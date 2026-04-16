class LocalesController < ApplicationController
  def update
    locale = params.require(:locale).to_s

    if I18n.available_locales.map(&:to_s).include?(locale)
      cookies[:locale] = { value: locale, expires: 1.year.from_now }
    end

    redirect_back fallback_location: root_path
  end
end
