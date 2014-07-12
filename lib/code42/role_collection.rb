module Code42
  class RoleCollection
    include Enumerable

    def initialize(roles = [])
      @roles = roles
    end

    def each(&block)
      @roles.each do |role|
        if block_given?
          block.call role
        else
          yield role
        end
      end
    end

    def attributes
      map(&:attributes)
    end

    def serialize
      map(&:serialize)
    end

    def includes_id?(id)
      map(&:id).include? id
    end

    def includes_name?(name)
      map(&:name).include? name
    end

    def empty?
      @roles.empty?
    end
  end
end
