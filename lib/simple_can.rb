require "simple_can/basic_strategy"

module SimpleCan
  THREAD_VAR = "simple_can.capability"

  class << self; attr_accessor :strategy; end

  class Unauthorized < StandardError; end

  def self.included(mod)
    mod.strategy_set!

    meta = class << mod; self; end
    meta.send(:alias_method, :orig_method_added, :method_added)
    meta.send(:alias_method, :orig_singleton_method_added,
      :singleton_method_added)
    mod.extend(ClassMethods)

    strategy.roles.each do |role|
      [meta, mod].each do |scope|
        scope.send(:define_method, "#{role}?") do
          mod.strategy_set!
          SimpleCan.strategy.test(role, mod.capability)
        end
        scope.send(:define_method, "#{role}!") do
          mod.strategy_set!
          next if SimpleCan.strategy.test(role, mod.capability)
          raise SimpleCan::Unauthorized, "unauthorized with #{role}"
        end
      end
    end
  end

  module ClassMethods
    def strategy_set!
      raise "strategy missing" if SimpleCan.strategy.nil?
    end

    def method_added(method)
      orig_method_added(method)
      add_method_to(self, method)
    end

    def singleton_method_added(method)
      orig_singleton_method_added(method)
      add_method_to((class << self; self; end), method)
    end

    def add_method_to(scope, method)
      strategy_set!

      klass = self
      method = method.to_s
      role, name, do_raise = SimpleCan.strategy.roles.reduce(nil) do |acc, r|
        acc || method.match(/^#{r}_(.+(!)|.+)$/)&.captures&.unshift(r)
      end
      return if name.nil?
      scope.send(:define_method, name) do |*args, &blk|
        can = SimpleCan.strategy.test(role, klass.capability)
        if !can && !do_raise.nil?
          raise SimpleCan::Unauthorized, "unauthorized for #{name} with #{role}"
        elsif !can
          if respond_to?("fail_#{name}")
            return send("fail_#{name}")
          else
            return SimpleCan.strategy.fail(role, name)
          end
        else
          return send(method, *args, &blk)
        end
      end
    end

    def capability=(role)
      strategy_set!
      Thread.current[THREAD_VAR] = SimpleCan.strategy.to_capability(role)
    end

    def capability
      Thread.current[THREAD_VAR]
    end

    def with_capability(role)
      self.capability = role
      yield
    ensure
      self.capability = nil
    end
  end
end
