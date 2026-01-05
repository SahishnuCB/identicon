defmodule Identicon.Image do
  @moduledoc """
  Data structure used during identicon generation.

  Fields:
  - `hex`: list of bytes created from hashing the input
  - `color`: `{r, g, b}` tuple
  - `grid`: list of `{code, index}` pairs for a 5×5 grid
  - `pixel_map`: list of rectangle coordinate pairs used for drawing
  """

  defstruct hex: nil, color: nil, grid: nil, pixel_map: nil
end
