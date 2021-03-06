defmodule Terp.Prelude.ListTest do
  use ExUnit.Case

  setup do
    {:ok, src} = File.read("prelude/list.tp")
    {:ok, %{src: src}}
  end

  test "Prelude Functor - foldl", %{src: src} do
    assert src <> "(foldl (lambda (x acc) (- acc x)) 0 '(1 2 3 4 5))"
    |> Terp.eval == 3
  end

  test "Prelude Functor - foldr", %{src: src} do
    assert src <> "(foldr (lambda (x acc) (- acc x)) 0 '(1 2 3 4 5))"
    |> Terp.eval == -15
  end

  test "Prelude Functor - Map", %{src: src} do
    assert src <> "(map (lambda (x) (* x 2)) '(1 2 3 4 5))"
    |> Terp.eval == [2, 4, 6, 8, 10]
  end

  test "Prelude Functor - reverse", %{src: src} do
    assert src <> "(reverse '(1 2 3 4 5))"
    |> Terp.eval == [5, 4, 3, 2, 1]
  end

  test "Prelude Functor - Sum", %{src: src} do
    assert src <> "(sum '(1 2 3))"
    |> Terp.eval == 6

    assert src <> "(sum '())"
    |> Terp.eval == 0
  end

  test "Prelude Functor - Length", %{src: src} do
    assert src <> "(length '(1 2 3 5))"
    |> Terp.eval == 4

    assert src <> "(length '())"
    |> Terp.eval == 0
  end

  test "Prelude Functor - Filter", %{src: src} do
    assert src <> "(filter (lambda (x) (equal? 2 x)) '(1 2 3 5 4))"
    |> Terp.eval == [2]
  end
end
