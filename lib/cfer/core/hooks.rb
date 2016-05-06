module Cfer::Core
  module Hooks
    def pre_block
      self.class.pre_hooks.each do |hook|
        instance_eval &hook
      end
    end

    def post_block
      self.class.post_hooks.each do |hook|
        instance_eval &hook
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def before(&block)
        self.pre_hooks << block
      end

      def after(&block)
        self.post_hooks << block
      end

      def pre_hooks
        @pre_hooks ||= []
      end

      def post_hooks
        @post_hooks ||= []
      end

      def inherited(subclass)
        subclass.include Cfer::Core::Hooks
      end
    end
  end
end
