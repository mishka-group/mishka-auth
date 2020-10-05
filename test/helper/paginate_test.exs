defmodule MishkaAuthTest.Helper.Paginate do
  use ExUnit.Case
  use MishkaAuthWeb.ConnCase
  alias MishkaAuth.Helper.Paginate


  describe "Happy | Paginate (▰˘◡˘▰)" do
    test "blog navigation" do
      [7, 8, 9, 10, 11, 12, 13, 14, 15] = assert Paginate.blog_navigation(10, 200)
    end

    test "integer_geter" do
      20 = assert Paginate.integer_geter(20)
    end
  end

  describe "UnHappy | Paginate ಠ╭╮ಠ" do
    test "integer_geter" do
      1 = assert Paginate.integer_geter("")
    end

    test "blog navigation" do
      [1, 2, 3, 4, 5] = assert Paginate.blog_navigation(10, 5)
    end
  end

end
