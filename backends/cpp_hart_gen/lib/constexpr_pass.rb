# frozen_string_literal: true

module Idl
  class AstNode
    def constexpr?(symtab)
      if children.empty?
        true
      else
        children.all? { |child| child.constexpr?(symtab) }
      end
    end
  end
  class IdAst
    def constexpr?(symtab)
      sym = symtab.get(name)
      return true if sym.nil? # assume symbols that aren't found are locals
      return true if sym.is_a?(Type)
      return true if sym.template_val?
      return false if sym.value.nil? # assuming undefined syms are local (be sure to type check first!!)

      if sym.param?
        symtab.cfg_arch.params_with_value.any? { |p| p.name == text_value }
      elsif sym.template_value?
        true
      else
        !sym.type.global?
      end
    end
  end
  class PcAssignmentAst
    def constexpr?(symtab) = false
  end
  class FunctionCallExpressionAst
    def constexpr?(symtab)
      children.all? { |child| child.constexpr?(symtab) } && func_type(symtab).func_def_ast.constexpr?(symtab)
    end
  end
  class CsrFieldReadExpressionAst
    def constexpr?(symtab) = false
  end
  class CsrReadExpressionAst
    def constexpr?(symtab) = false
  end
  class CsrSoftwareWriteAst
    def constexpr?(symtab) = false
  end
  class CsrFunctionCallAst
    def constexpr?(symtab) = function_name == "address"
  end
  class CsrWriteAst
    def constexpr?(symtab) = false
  end
  class FunctionDefAst
    # @return [Boolean] If the function is possibly C++ constexpr (does not access CSRs or registers)
    def constexpr?(symtab)
      return false if builtin?
      return false if generated? # might actually know this in some cases...

      if templated?
        symtab = symtab.global_clone
        symtab.push(self)

        template_names.each_with_index do |tname, idx|
          symtab.add!(tname, Var.new(tname, template_types(symtab)[idx], template_index: idx, function_name: name))
        end
      end

      result = body.constexpr?(symtab)

      symtab.release if templated?

      result
    end
  end
end
