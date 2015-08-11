# encoding: utf-8

module WebpackRails
  module Logger
    def self.log(message)
      Rails.logger.debug message
    end
  end
end
