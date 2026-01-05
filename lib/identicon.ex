defmodule Identicon do
  @moduledoc """
  Generates a simple identicon PNG from an input string.

  The icon is deterministic:
  the same input always produces the same image.

  This implementation:
  - hashes the input (MD5) into a list of bytes
  - uses the first 3 bytes as an RGB color
  - builds a 5×5 grid from the remaining bytes by mirroring rows
  - keeps only squares whose code is even
  - converts kept squares into pixel coordinates
  - draws the image using `:egd`
  - writes it to `<input>.png`
  """

  @doc """
  Generates an identicon for `input` and saves it as `<input>.png`.

  Returns whatever `File.write/2` returns (`:ok` or `{:error, reason}`).

  ## Examples

      iex> Identicon.main("alice")
      :ok

  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end


  @doc """
  Saves the rendered image binary to `<input>.png`.
  This expects `image` to be a PNG binary.
  """
  def save_image(image, input) do
    File.write("#{input}.png", image)
  end


  @doc """
  Draws the identicon as a 250×250 PNG binary using the image's `pixel_map` and `color`.
  `pixel_map` must contain entries like `{top_left, bottom_right}` where both are `{x, y}` tuples.
  """
  def draw_image(%Identicon.Image{pixel_map: pixel_map, color: color}) do
    image = :egd.create(250, 250)
    Enum.each(pixel_map, fn {start, stop} ->
    :egd.filledRectangle(image, start, stop, :egd.color(color))
  end)

  :egd.render(image)
  end


  @doc """
  Converts the grid indexes into pixel coordinates.
  Each grid square becomes a `{top_left, bottom_right}` pair where each point is `{x, y}`.
  The result is stored in `image.pixel_map`.
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50

      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end


  @doc """
  Removes grid squares whose code is odd.
  Only squares with an even `code` are kept. This is what creates the pattern.
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end


  @doc """
  Builds a 5×5 grid from the image's `hex` list.

  It chunks the bytes into rows of 3, mirrors each row into 5 elements to make the image symmetric,
  flattens the rows, and attaches an index to each cell.

  The result is stored in `image.grid` as a list of `{code, index}`.

  ## Example

      iex> hex = [10, 20, 30, 40, 50, 60]
      iex> image = %Identicon.Image{hex: hex}
      iex> image = Identicon.build_grid(image)
      iex> image.grid
      [
        {10, 0}, {20, 1}, {30, 2}, {20, 3}, {10, 4},
        {40, 5}, {50, 6}, {60, 7}, {50, 8}, {40, 9}
      ]
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3,3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()


    %Identicon.Image{image | grid: grid}
  end


  @doc """
  Mirrors a 3-element row into a symmetric 5-element row.

  ## Examples:

      iex> Identicon.mirror_row([1, 2, 3])
      [1, 2, 3, 2, 1]

  """
  def mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  @doc """
  Picks the RGB color from the first three bytes of `image.hex`.
  The color is stored as a `{r, g, b}` tuple in `image.color`.
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end


  @doc """
  Hashes the input string using MD5 and converts the result into a list of bytes.

  Stores that list in `image.hex`.
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end
end
