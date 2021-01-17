class ThrowError(T) < Exception
  getter value : T

  def initialize(@value : T)
  end
end

def catch(value : T) forall T
  begin
    yield
  rescue error : ThrowError(T)
    if error.value == value
      return
    else
      raise error
    end
  end
end

def throw(value)
  raise ThrowError.new(value)
end

# This is similar to `raise(Exception)` except that it doesn't compute a callstack.
def raise(exception : ThrowError(T)) : NoReturn forall T
  unwind_ex = Pointer(LibUnwind::Exception).malloc
  unwind_ex.value.exception_class = LibC::SizeT.zero
  unwind_ex.value.exception_cleanup = LibC::SizeT.zero
  unwind_ex.value.exception_object = exception.as(Void*)
  unwind_ex.value.exception_type_id = exception.crystal_type_id
  __crystal_raise(unwind_ex)
end
