defprotocol WhiteBread.Context.StepExecutor.ErrorHandler do
  @fallback_to_any true
  def get_tuple(error, step, stacktrace)
end

defimpl WhiteBread.Context.StepExecutor.ErrorHandler,
for: [ESpec.AssertionError, ExUnit.AssertionError] do
  def get_tuple(error, step, stacktrace) do
    {error.__struct__, step, {error, stacktrace}}
  end
end

defimpl WhiteBread.Context.StepExecutor.ErrorHandler, for: Any do
  def get_tuple(error, step, stacktrace) do
    {:other_failure, step, {error, stacktrace}}
  end
end
