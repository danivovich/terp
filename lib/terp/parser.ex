defmodule Terp.Parser do
  @moduledoc """
  Parse a string into an AST
  """
  use Combine
  use Combine.Helpers

  @doc """
  The parser and tokenizes for terp.

  ## Examples

      iex> Terp.Parser.parse("(+ 1 2 3)")
      [[__apply: [:+, 1, 2, 3]]]

      iex> Terp.Parser.parse("(+ 1 2 (* 2 3))")
      [[__apply: [:+, 1, 2, {:__apply, [:*, 2, 3]}]]]
  """
  def parse(str) do
    str
    |> Combine.parse(many1(expr_parser()))
  end

  # `expr_parser/0` parses a terp expression.
  # Valid expressions are s-expression like (they are not however
  # stored internally as binary trees); expressions are enclosed
  # in parentheses and use prefix notation.

  # TODO: currently, parsing application of literals works even
  # if it doesn't make sense to, e.g. `(#t)` is considered valid
  defp expr_parser() do
    choice([
      comment_parser(),
      literal_parser(),
      list_parser(),
      lambda_parser(),
      letrec_parser(),
      let_parser(),
      application_parser(),
      ignore(newline()),
    ])
  end

  # `application_parser/0` parses function application.
  defp application_parser() do
    app_parser = between(
      char("("),
      valid_expr_parser(),
      char(")")
    )
    map(app_parser, fn x -> {:__apply, x} end)
  end

  # Parser for a lambda expression.
  defp lambda_parser() do
    l_parser = between(
      string("(lambda"),
      valid_expr_parser(),
      char(")")
    )
    map(l_parser, fn x -> {:__lambda, x} end)
  end

  # Parser for a lambda expression.
  defp let_parser() do
    l_parser = between(
      string("(let"),
      valid_expr_parser(),
      char(")")
    )
    map(l_parser, fn x -> {:__let, x} end)
  end

  # Parser for recursive functions.
  defp letrec_parser() do
    l_parser = between(
      string("(letrec"),
      valid_expr_parser(),
      char(")")
    )
    map(l_parser, fn x -> {:__letrec, x} end)
  end

  defp valid_expr_parser() do
    many(
      choice([
        literal_parser(),
        ignore(space()),
        ignore(newline()),
        list_parser(),
        lazy(fn -> lambda_parser() end),
        lazy(fn -> letrec_parser() end),
        lazy(fn -> let_parser() end),
        lazy(fn -> application_parser() end)
      ])
    )
  end

  # Parses a quoted list, e.g. '(4 23 6).
  defp list_parser() do
    lst_parser = between(
      string("'("),
      many(
        choice([
          literal_parser(),
          ignore(space()),
        ])
      ),
      char(")")
    )
    map(lst_parser, fn x -> {:__quote, x} end)
  end

  # Parses literals
  defp literal_parser() do
    choice([
      built_ins_parser(),
      bool_parser(),
      integer(),
      string_to_atom(ignore(char(":")) |> word()),
      word(),
      lazy(fn -> list_parser() end),
    ])
  end

  # Converts the result of a parser to an atom
  defp string_to_atom(parser) do
    map(parser, fn atom -> String.to_atom(atom) end)
  end

  # Parses true/false booleans
  defp bool_parser() do
    either(
      string("#t"), # boolean true
      string("#f") # boolean false
    )
  end

  # Parses valid built-in functions/terms in terp.
  defp built_ins_parser() do
    choice([
      string_to_atom(char("+")),
      string_to_atom(char("-")),
      string_to_atom(char("*")),
      string_to_atom(char("/")),
      map(string("if"), fn _x -> :__if end),
    ])
  end

  defp comment_parser() do
    map(
      string(";;")
      |> take_while(
           fn ?\n -> false
                _ -> true end),
      fn x -> {:__comment, x} end
    )
  end

  @doc """
  `to_tree/1` takes a tokenized expression and builds a parse tree.

  ## Examples

      iex> [:__apply, [:+, 1, 2, 3]]
      ...> |> Terp.Parser.to_tree()
      [
      %RoseTree{node: :__apply, children: []},
        [
          %RoseTree{node: :+, children: []},
          %RoseTree{node: 1, children: []},
          %RoseTree{node: 2, children: []},
          %RoseTree{node: 3, children: []},
        ]
      ]

      iex> [:+, 1, 2, [:*, 2, 3]]
      ...> |> Terp.Parser.to_tree()
      [
        %RoseTree{node: :+, children: []},
        %RoseTree{node: 1, children: []},
        %RoseTree{node: 2, children: []},
        [
          %RoseTree{node: :*, children: []},
          %RoseTree{node: 2, children: []},
          %RoseTree{node: 3, children: []},
        ]
      ]
  """
  def to_tree([]), do: {:error, :no_parse}
  def to_tree(expr) when is_list(expr) do
    for v <- expr do
      case v do
        {s, x} when is_atom(s) ->
          RoseTree.new(s, to_tree(x))
        val when is_list(val) ->
          to_tree(val)
        _ -> RoseTree.new(v)
      end
    end
  end

  # lazy parser implementation from
  # https://github.com/bitwalker/combine/issues/12#issuecomment-222539479
  defparser lazy(%Combine.ParserState{status: :ok} = state, generator) do
    (generator.()).(state)
  end
end
