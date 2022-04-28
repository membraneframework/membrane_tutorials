defmodule Basic.Elements.Source do
  ...

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, state) do
    if state.content == [] do
      {{:ok, end_of_stream: :output}, state}
    else
      [first_packet | rest] = state.content
      state = %{state | content: rest}
      action = [buffer: {:output, %Buffer{payload: first_packet}}]
      action = action ++ [redemand: :output]
      {{:ok, action}, state}
    end
  end

  ...
end
