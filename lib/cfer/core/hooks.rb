module Cfer::Core
  # Provides support for hooking into resource types, and evaluating code before or after properties are set
  module Hooks
    def pre_block
      eval_hooks self.class.pre_hooks
    end

    def post_block
      eval_hooks self.class.post_hooks
    end

    private def eval_hooks(hooks)
      hooks.sort { |a, b| (a[:nice] || 0) <=> (b[:nice] || 0) }.each do |hook|
        Docile.dsl_eval(self, &hook[:block])
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def before(options = {}, &block)
        self.pre_hooks << options.merge(block: block)
      end

      def after(options = {}, &block)
        self.post_hooks << options.merge(block: block)
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
