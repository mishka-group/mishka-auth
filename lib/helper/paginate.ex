defmodule MishkaAuth.Helper.Paginate do

  def blog_navigation(page_router_number, json_number_db) do
    start_number = compare_with_pagenumber(integer_geter(page_router_number), json_number_db)
    (start_number - 3)..(start_number + 5)
    |> Enum.to_list
    |> Enum.filter(fn(x) -> x <= json_number_db end)
    |> Enum.filter(fn(x) -> x > 0 end)
  end

  @spec compare_with_pagenumber(any, any) :: any
  def compare_with_pagenumber(page_router_number, json_number_db) when page_router_number <= json_number_db do
    page_router_number
    |> integer_geter
  end

  def compare_with_pagenumber(_page_router_number, _json_number_db), do: 1

  def integer_geter(string) do
    output = "#{string}"
    |> String.replace(~r/[^\d]/, "")
    if output == "", do: 1, else: String.to_integer(output)
  end

end
