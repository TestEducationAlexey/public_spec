require_relative 'application_adapter'
ActiveModelSerializers.config.adapter = ApplicationAdapter
ActiveModelSerializers.config.key_transform = :underscore
