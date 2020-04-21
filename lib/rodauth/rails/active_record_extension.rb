module Rodauth
  module Rails
    # Connects & disconnects Sequel in lockstep with ActiveRecord.
    module ActiveRecordExtension
      def establish_connection(*)
        super.tap do
          Rodauth::Rails.sequel_disconnect
        end
      end

      def retrieve_connection(*)
        super.tap do
          # When purging, ActiveRecord connects to the master database, so we
          # avoid connecting Sequel in this case.
          next if connection_pool.spec.config[:database] != Rodauth::Rails.activerecord_config.fetch("database")

          Rodauth::Rails.sequel_connect
        end
      end

      def clear_all_connections!(*)
        super.tap do
          Rodauth::Rails.sequel_disconnect
        end
      end

      def remove_connection(*)
        super.tap do
          Rodauth::Rails.sequel_disconnect
        end
      end
    end
  end
end
