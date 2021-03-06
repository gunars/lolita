module Lolita
  module Authorization
    def public_user?
      !current_user.is_a? Admin::SystemUser if logged_in?
    end

    def system_user?
      !public_user? if logged_in?
    end
  end
  
  class Config
    # Lolita's configuration tool
    # all configuration is in YAML file located config/lolita.yml
    # Lolita's config you can access via Lolita.config or $lolita_config
    # Example:
    #   ----YAML----
    #     production:
    #       foo:
    #         baz:
    #           one: 1
    #           two: 2
    #       gmail:
    #         key: 8349032809890zxczxc
    #   ----CODE----
    #   Lolita.config.foo :baz, :one
    #   > 1
    #   Lolita.config.foo
    #   > {'baz' => {'one' => 1, 'two' => 2}}
    #

    attr_accessor :conf

    def initialize
      self.conf = YAML::parse_file("#{RAILS_ROOT}/config/lolita.yml").select("/#{RAILS_ENV}")[0].transform
    end

    def method_missing(key,*args)
      eval "self.conf['#{key}']#{args ? args.collect{|a| "['#{a}']"}.join : ""}"
    end

    def update *args
      return false unless args.size > 1
      eval "self.conf#{args[0,args.size-1].collect{|a| "['#{a}']"}.join} = args[args.size-1]"
      true
    end

  end

  def config
    $lolita_config
  end
  module_function :config
end