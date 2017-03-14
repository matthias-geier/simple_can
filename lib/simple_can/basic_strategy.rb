module SimpleCan
  module BasicStrategy
    extend self

    ROLES = %w(read write manage).freeze
    REV_ROLES = ROLES.map.with_index.to_h.freeze

    def test(role, capability)
      capability = 0 if capability.nil?
      capability >= to_capability(role)
    end

    def roles
      ROLES
    end

    def fail(_role, _name)
      :unauthorized
    end

    def to_capability(role)
      return if role.nil?
      REV_ROLES[role]
    end
  end
end
