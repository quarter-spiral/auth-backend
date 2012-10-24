# Fixing the RBX freeze thingie.
# This is a 1:1 copy from actionpack-3.2.8 / lib/action_view/template.rb
# All I had to do is comment out line 39

class ActionView::Template
  def compile(view, mod) #:nodoc:
    encode!
    method_name = self.method_name
    code = @handler.call(self)

    # Make sure that the resulting String to be evalled is in the
    # encoding of the code
    source = <<-end_src
      def #{method_name}(local_assigns, output_buffer)
        _old_virtual_path, @virtual_path = @virtual_path, #{@virtual_path.inspect};_old_output_buffer = @output_buffer;#{locals_code};#{code}
      ensure
        @virtual_path, @output_buffer = _old_virtual_path, _old_output_buffer
      end
    end_src

    if source.encoding_aware?
      # Make sure the source is in the encoding of the returned code
      source.force_encoding(code.encoding)

      # In case we get back a String from a handler that is not in
      # BINARY or the default_internal, encode it to the default_internal
      source.encode!

      # Now, validate that the source we got back from the template
      # handler is valid in the default_internal. This is for handlers
      # that handle encoding but screw up
      unless source.valid_encoding?
        raise WrongEncodingError.new(@source, Encoding.default_internal)
      end
    end

    begin
      mod.module_eval(source, identifier, 0)
      #ObjectSpace.define_finalizer(self, Finalizer[method_name, mod])
    rescue Exception => e # errors from template code
      if logger = (view && view.logger)
        logger.debug "ERROR: compiling #{method_name} RAISED #{e}"
        logger.debug "Function body: #{source}"
        logger.debug "Backtrace: #{e.backtrace.join("\n")}"
      end

      raise ActionView::Template::Error.new(self, {}, e)
    end
  end
end
