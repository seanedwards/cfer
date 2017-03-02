Cfer::Core::Stack.extend_stack do
  def validate_stack!(hash)
    errors = []
    context = []
    _inner_validate_stack!(hash, errors, context)

    raise Cfer::Util::CferValidationError, errors unless errors.empty?
  end

  def _inner_validate_stack!(hash, errors = [], context = [])
    case hash
    when Hash
      hash.each do |k, v|
        _inner_validate_stack!(v, errors, context + [k])
      end
    when Array
      hash.each_index do |i|
        _inner_validate_stack!(hash[i], errors, context + [i])
      end
    when nil
      errors << {
        error: "CloudFormation does not allow nulls in templates",
        context: context
      }
    end
  end

  def validation_contextualize(err_ctx)
    err_ctx.inject("") do |err_str, ctx|
      err_str <<
        case ctx
        when String
          ".#{ctx}"
        when Numeric
          "[#{ctx}]"
        end
    end
  end
end

Cfer::Core::Stack.after(nice: 100) do
  begin
    validate_stack!(self)
  rescue Cfer::Util::CferValidationError => e
    Cfer::LOGGER.error "Cfer detected #{e.errors.size > 1 ? 'errors' : 'an error'} when generating the stack:"
    e.errors.each do |err|
      Cfer::LOGGER.error "* #{err[:error]} in Stack#{validation_contextualize(err[:context])}"
    end
    raise e
  end
end

