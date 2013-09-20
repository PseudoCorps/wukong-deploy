module Wukong
  module Deploy

    # Attaches to the hooks provided by the Wukong::Load::Syncer class
    # to write data to Vayacondios.
    module ArchiveSyncerOverride

      # Saves the syncer as a stash in Vayacondios.
      def before_sync
        super()
        Wukong::Deploy.vayacondios_client.set(vayacondios_topic, nil, self)
      end

      # Announces a successful sync and updates the last sync state
      # and time.
      def after_sync
        super()
        Wukong::Deploy.vayacondios_client.announce(vayacondios_topic, success: success?, files: files)
        Wukong::Deploy.vayacondios_client.set!(vayacondios_topic, "last", { state: (success? ? 1 : 0), time: Time.now.utc.to_i })
      end

      # Announces an error during a sync and updates the last sync
      # state and time.
      def on_error error
        super(error)
        Wukong::Deploy.vayacondios_client.announce(vayacondios_topic, success: false, error: error.class, message: error.message)
        Wukong::Deploy.vayacondios_client.set!(vayacondios_topic, "last", { state: 0, time: Time.now.utc.to_i })
      end
      
      # Returns the Vayacondios topic for this ArchiveSyncer.
      #
      # @return [String] the Vayacondios topic
      def vayacondios_topic
        "listeners.sync-archive-#{name}"
      end

      # Returns a representation of this ArchiveSyncer suitable for a
      # Vayacondios stash.
      #
      # @return [Hash]
      def to_vayacondios
        {
          name:      name,
          split:     settings[:split],
          lines:     settings[:lines],
          bytes:     settings[:bytes],
          ordered:   settings[:ordered],
          metadata:  settings[:metadata],
        }
      end

      module HandlerOverride

        # The topic for this Handler.
        #
        # Delegates to ArchiveSyncer#vayacondios_topic.
        #
        # @return [String]
        def vayacondios_topic
          syncer.vayacondios_topic
        end

        # Announce the file was processed.
        #
        # @param [Pathname] original
        def after_process original
          super(original)
          Wukong::Deploy.vayacondios_client.announce(vayacondios_topic, {
            success: true,
            path:    relative_path_of(original, settings[:input]),
            size:    File.size(original),
          })
        end

        # Announce an error in processing a file.
        #
        # @param [Pathname] original
        # @param [Error] error
        def on_error original, error
          super(original, error)
          Wukong::Deploy.vayacondios_client.announce(vayacondios_topic, {
            success: false,
            path:    relative_path_of(original, settings[:input]),
            error:   error.class,
            message: error.message
          })
        end
        
      end
    end
  end
end
