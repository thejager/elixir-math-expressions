defmodule Expression do
  defstruct identifier: nil, type: nil, args: []

  def new(arg1, identifier, arg2) do
    %Expression{identifier: identifier, type: :operator, args: [arg1, arg2]}
  end

  def new(function_name, args) when is_list(args) do

    # Check if the function exists
    if !Map.has_key?(allowed_functions, function_name) do
      raise ArgumentError, message: "Unknown function: '" <> Kernel.to_string(function_name) <> "'."
    end

    fun_info = :erlang.fun_info(allowed_functions[function_name])

    # Check if the function arities match
    if fun_info[:arity] !== length(args) do
      raise ArgumentError, message: "Mismatching parameter list: function '" <> to_string(function_name) <> "' expects " <> to_string(fun_info[:arity]) <> " parameters but got " <> to_string(length(args)) <> "."
    end

    %Expression{identifier: function_name, type: :function, args: args}
  end

  def new(function_name, arg) do
    new(function_name, [arg])
  end

  def evaluate(%Expression{identifier: function_name, type: :function, args: args}) do
    evaluated_args = args |> Enum.map(&(evaluate(&1)))

    apply(allowed_functions[function_name], evaluated_args)
  end

  def evaluate(%Expression{identifier: operator, type: :operator, args: [lhs, rhs]}) do
    lhs_result = evaluate(lhs)
    rhs_result = evaluate(rhs)

    allowed_operators[operator][:callback].(lhs_result, rhs_result)
  end

  def evaluate(k) when is_number(k) do
    k
  end



  def allowed_functions do
    %{
      # Logarithmic operations
      log:    &:math.log/1,
      log10:  &:math.log10/1,
      log2:   &:math.log2/1,

      # Trigonometric functions
      cos:    &:math.cos/1,
      sin:    &:math.sin/1,
      tan:    &:math.tan/1
    }
  end

  def allowed_constants do
    %{
      e:    :math.exp(1),
      pi:   :math.pi
    }
  end

  def allowed_operators do
    %{
      plus:         %{callback: &(&1 + &2), str: "+"},
      minus:        %{callback: &(&1 - &2), str: "-"},
      times:        %{callback: &(&1 * &2), str: "*"},
      divided_by:   %{callback: &(&1 / &2), str: "/"},
      raised_to:    %{callback: &(:math.pow(&1, &2)), str: "^"}
    }
  end
end

defimpl String.Chars, for: Expression do

  # For operators (infix)
  def to_string(%Expression{identifier: op, type: :operator, args: [lhs, rhs]}) do
    if !Map.has_key?(Expression.allowed_operators, op) do
      raise ArgumentError, message: "Unknown operator: '" <> Kernel.to_string(op) <> "'."
    end

    op_str = Expression.allowed_operators[op][:str]

    "(" <> Kernel.to_string(lhs) <> " " <> op_str <> " " <> Kernel.to_string(rhs) <> ")"
  end

  # For functions
  def to_string(%Expression{identifier: function_name, type: :function, args: args}) do
    if !Map.has_key?(Expression.allowed_functions, function_name) do
      raise ArgumentError, message: "Unknown function: '" <> Kernel.to_string(function_name) <> "'."
    end

    parameter_list = args
      |> Enum.map(&Kernel.to_string(&1))
      |> Enum.join(", ")

    Kernel.to_string(function_name) <> "(" <> parameter_list <> ")"
  end
end
