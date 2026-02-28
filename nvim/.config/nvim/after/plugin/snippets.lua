---@diagnostic disable: unused-local
require("luasnip.session.snippet_collection").clear_snippets()
require("luasnip.loaders.from_vscode").lazy_load()

-- prefix
local ls = require("luasnip")
local snippet = ls.snippet
local snippet_node = ls.snippet_node
local indent_snippet_node = ls.indent_snippet_node
local text_node = ls.text_node
local insert_node = ls.insert_node
local function_node = ls.function_node
local choice_node = ls.choice_node
local dynamic_node = ls.dynamic_node
local restore_node = ls.restore_node
local events = require("luasnip.util.events")
local absolute_indexer = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local lambda = extras.lambda
local repeat_node = extras.rep
local partial = extras.partial
local match = extras.match
local nonempty = extras.nonempty
local dynamic_lambda = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conditions = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse_snippet = require("luasnip.util.parser").parse_snippet
local multi_snippet = ls.multi_snippet
local new_key = require("luasnip.nodes.key_indexer").new_key

-- bindings
vim.keymap.set({ "i" }, "<C-K>", function()
    ls.expand()
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-K>", function()
    ls.jump(1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function()
    ls.jump(-1)
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end, { silent = true })

-- -- snippets
-- ls.add_snippets("all", {
--     snippet(
--         "{", {
--             text_node({ "{", "    " }),
--             insert_node(0),
--             text_node({ "", "}" }),
--         }
--     ),
-- })

ls.add_snippets("python", {
    snippet("dbg",
        fmt([[
                print(f"{{{n1} = }}")
            ]],
            { n1 = insert_node(0, "val"), }
        )),
    snippet("ifn",
        fmt([[
            if (var := {n1}) is None:
                raise NotImplementedError()
                return # TODO
        ]],
            { n1 = insert_node(0, "expression") }
        )),
    snippet("orn",
        text_node("| None = None")
    ),
    snippet("#b",
        text_node("# pyright: basic")
    ),
    snippet("#s",
        text_node("# pyright: strict")
    ),
    snippet("defmain", fmt([[
        def main():
            {n1}


        if __name__ == "__main__":
            main()
    ]], { n1 = insert_node(0, [[print("Hi, mom!")]])})),
})

ls.add_snippets("javascript", {
    snippet(
        "type",
        fmt(
            [[
        /** @type {{{n1}}} */
    ]],
            {
                n1 = insert_node(0, "val"),
            }
        )
    ),
})

ls.add_snippets("typescript", {
    snippet(
        "fastifyTypeboxPlugin",
        fmt(
            [[
        import {{ FastifyPluginAsyncTypebox }} from "@fastify/type-provider-typebox";

        export default (async (fastify) => {{
            {n0}
        }}) satisfies FastifyPluginAsyncTypebox;
    ]],
            {
                n0 = insert_node(0, "routes"),
            }
        )
    ),
    snippet(
        "melodleRoute",
        fmt(
            [[
        fastify.{n1}("", {{
            onRequest: [],
            schema: {{
                response: {{
                    200: SafeType.Literal("TODO!"),
                    ...SafeType.CreateErrors([]),
                }},
                summary: "TODO!",
                description: undefined,
                tags: ["TODO Schema"] satisfies MelodleTagName[],
            }},
            async handler(_request, reply) {{
                return reply.notImplemented();
            }}
        }});
    ]],
            { n1 = insert_node(0, "get") }
        )
    ),
})

ls.add_snippets("c", {
    snippet(
        "fori",
        fmt(
            [[
        for (int {n1} = 0; {rn1} < {n2}; {rn1}++) {{
            {n0}
        }}
    ]],
            {
                n1 = insert_node(1, "i"),
                n2 = insert_node(2, "length"),
                n0 = insert_node(0),
                rn1 = repeat_node(1),
            }
        )
    ),
    snippet(
        "foreach",
        fmt(
            [[
            // for {n1} in range 0..<len({n2}))
            for (int {rn1} = 0; {rn1} < sizeof({rn2}) / sizeof({rn2}[0]); {rn1}++) {{
                {n0}
            }}
        ]],
            {
                n1 = insert_node(1, "i"),
                n2 = insert_node(2, "arr"),
                n0 = insert_node(0),
                rn1 = repeat_node(1),
                rn2 = repeat_node(2),
            }
        )
    ),
    snippet(
        "sizearr",
        fmt(
            [[
        sizeof({n1}) / sizeof({rn1}[0])
    ]],
            {
                n1 = insert_node(1, "arr"),
                rn1 = repeat_node(1),
            }
        )
    ),
    snippet(
        "start",
        fmt(
            [[
        #include <stdbool.h>
        #include <stdio.h>
        #include <stdlib.h>


        #define dbg(format, x)                                                         \
            printf("[%s:%s:%d]: " #x " = " format "\n", __FILE__, __func__, __LINE__, x)

        int main({cn}) {{
            {i0}
            return EXIT_SUCCESS;
        }}

    ]],
            {
                cn = choice_node(1, {
                    text_node("void"),
                    text_node("int argc, char* argv[]"),
                }),
                i0 = insert_node(0),
            }
        )
    ),
})

ls.add_snippets("html", {
    snippet(
        "forng",
        fmt(
            [[
        @for ({n1} of {n2}; track {nitem}) {{
            {n0}
        }}
    ]],
            {
                n0 = insert_node(0),
                n1 = insert_node(1),
                n2 = insert_node(2),
                nitem = repeat_node(1),
            }
        )
    ),
})
