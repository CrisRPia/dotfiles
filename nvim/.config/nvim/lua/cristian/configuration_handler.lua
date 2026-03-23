local Snacks = require("snacks")

local M = {}

---@class ValueNode<T>
---@field name string
---@field get fun(): T
---@field set fun(value: T)

---@class ToggleNode : ValueNode<boolean>
---@field type "Toggle"

---@class EnumNode : ValueNode<string>
---@field type "Enum"
---@field values string[]  ordered list; confirm cycles to next, wraps around

---@class NamespaceNode
---@field name string
---@field type "Namespace"
---@field children AnyNode[]
---@field get (fun(): boolean)?  if present, namespace appears as a toggle in the picker
---@field set (fun(value: boolean))?

---@class DynamicNamespaceSchema
---@field make_toggle fun(value: string): { get: fun(): boolean, set: fun(value: boolean) }
---@field validate fun(input: string): string?  returns normalized value or nil if invalid
---@field compare (fun(a: string, b: string): boolean)?  optional comparator for sorted insertion

---@class DynamicNamespaceNode
---@field name string
---@field type "DynamicNamespace"
---@field values string[]  initial values
---@field schema DynamicNamespaceSchema

---@alias AnyNode ToggleNode | NamespaceNode | DynamicNamespaceNode | EnumNode

---@class CreateOpts
---@field title string
---@field namespace string
---@field backup_path string?  read values from here if no local config exists yet

---@class ConfigHandle
---@field append fun(nodes: AnyNode[])
---@field open fun()

---@class FlatItem<T>
---@field idx number
---@field score number
---@field text string
---@field label string
---@field get fun(): T
---@field set fun(value: T)
---@field _ns FlatItem<boolean>?  parent ToggleNamespace item
---@field _dyn DynCtx?  dynamic namespace context; present on children of a DynamicNamespace
---@field _enum string[]?  ordered values list; present only on Enum items

---@class DynCtx
---@field label string  namespace label (used as prefix for child labels)
---@field schema DynamicNamespaceSchema
---@field values string[]  current live list of values (mutable)
---@field items FlatItem<boolean>[]  current live list of flat items (mutable)

---@param item FlatItem
---@return boolean
local function is_visible(item)
    local ns = item._ns
    while ns do
        if not ns.get() then return false end
        ns = ns._ns
    end
    return true
end

---@param nodes AnyNode[]
---@param prefix string
---@param out FlatItem[]
---@param counter number[]
---@param stored_dyn table<string, string[]>  stored dynamic values lists, keyed by namespace label
---@param dyn_contexts DynCtx[]  accumulates DynCtx objects for handle.open to use
local function flatten(nodes, prefix, out, counter, stored_dyn, dyn_contexts)
    for _, node in ipairs(nodes) do
        if node.type == "DynamicNamespace" then
            local label = prefix == "" and node.name or (prefix .. " / " .. node.name)
            -- Restore persisted values list if available, else use node.values
            local values = vim.deepcopy(stored_dyn[label] or node.values)

            ---@type DynCtx
            local ctx = { label = label, schema = node.schema, values = values, items = {} }
            table.insert(dyn_contexts, ctx)

            for _, value in ipairs(values) do
                local t = node.schema.make_toggle(value)
                counter[1] = counter[1] + 1
                ---@type FlatItem<boolean>
                local item = {
                    idx   = counter[1],
                    score = counter[1],
                    text  = "",
                    label = label .. " / " .. value,
                    get   = t.get,
                    set   = t.set,
                    _dyn  = ctx,
                }
                table.insert(out, item)
                table.insert(ctx.items, item)
            end

        elseif node.children then
            local label = prefix == "" and node.name or (prefix .. " / " .. node.name)
            if not node.get then
                -- Transparent namespace: just recurse
                flatten(node.children, label, out, counter, stored_dyn, dyn_contexts)
            else
                -- Toggleable namespace: insert as a toggle item, wrap children
                counter[1] = counter[1] + 1
                local ns_item = {
                    idx   = counter[1],
                    score = counter[1],
                    text  = "",
                    label = label,
                    get   = node.get,
                }
                table.insert(out, ns_item)

                local children_start = #out + 1
                flatten(node.children, label, out, counter, stored_dyn, dyn_contexts)
                local children_end = #out

                -- Capture raw setters before wrapping, so ns_item.set can apply
                -- false directly even when the namespace guard would block it.
                local raw_sets = {}
                for i = children_start, children_end do
                    raw_sets[i] = out[i].set
                end

                -- Wrap each child to track intended value separately from applied value.
                for i = children_start, children_end do
                    local child = out[i]
                    child._ns = ns_item
                    local raw_set = raw_sets[i]
                    local intended = child.get()
                    child.get = function() return intended end
                    child.set = function(v)
                        intended = v
                        if node.get() then raw_set(v) end
                    end
                end

                ns_item.set = function(v)
                    node.set(v)
                    -- ns on → apply intended; ns off → apply false directly via raw setter
                    for i = children_start, children_end do
                        raw_sets[i](v and out[i].get() or false)
                    end
                end
            end
        elseif node.type == "Toggle" then
            counter[1] = counter[1] + 1
            local label = prefix == "" and node.name or (prefix .. " / " .. node.name)
            table.insert(out, {
                idx   = counter[1],
                score = counter[1],
                text  = "",
                label = label,
                get   = node.get,
                set   = node.set,
            })
        elseif node.type == "Enum" then
            counter[1] = counter[1] + 1
            local label = prefix == "" and node.name or (prefix .. " / " .. node.name)
            table.insert(out, {
                idx   = counter[1],
                score = counter[1],
                text  = "",
                label = label,
                get   = node.get,
                set   = node.set,
                _enum = node.values,
            })
        end
    end
end

-- Returns a snapshot in insertion order for the lifetime of this picker session.
---@param flat FlatItem[]
---@return FlatItem[]
local function make_snapshot(flat)
    local snapshot = {}
    for i, item in ipairs(flat) do
        item.idx = i
        item.score = i
        table.insert(snapshot, item)
    end
    return snapshot
end

---@param snapshot FlatItem[]
---@return FlatItem[]
local function make_items(snapshot)
    for _, item in ipairs(snapshot) do
        if item._enum then
            item.text = "󰑐  " .. item.label .. "  [" .. tostring(item.get()) .. "]"
        else
            local icon = item.get() and "󰄬" or "󰅖"
            item.text = icon .. "  " .. item.label
        end
    end
    return snapshot
end

---@param namespace string
---@return string
local function config_path(namespace)
    return vim.fn.stdpath("data") .. "/" .. namespace .. "_config.json"
end

---@param flat FlatItem[]
---@param dyn_contexts DynCtx[]
---@param namespace string
---@param backup_path string?
local function save(flat, dyn_contexts, namespace, backup_path)
    local values = {}
    for _, item in ipairs(flat) do
        values[item.label] = item.get()
    end
    local dynamic = {}
    for _, ctx in ipairs(dyn_contexts) do
        dynamic[ctx.label] = ctx.values
    end
    local f = assert(io.open(config_path(namespace), "w"))
    f:write(vim.json.encode({ values = values, dynamic = dynamic }))
    f:close()

    if backup_path then
        local sorted = vim.deepcopy(flat)
        table.sort(sorted, function(a, b) return a.label < b.label end)
        local pairs_str = {}
        for _, item in ipairs(sorted) do
            table.insert(pairs_str, vim.json.encode(item.label) .. ":" .. vim.json.encode(item.get()))
        end
        local bf = assert(io.open(backup_path, "w"))
        bf:write('{"values":{' .. table.concat(pairs_str, ",") .. "}}")
        bf:close()
    end
end

---@param path string
---@return { values: table<string, boolean>, dynamic: table<string, string[]> }|nil
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local ok, parsed = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if not ok then return nil end
    return { values = parsed.values or {}, dynamic = parsed.dynamic or {} }
end

---@param namespace string
---@param backup_path string?
---@return { values: table<string, boolean>, dynamic: table<string, string[]> }
local function load_file(namespace, backup_path)
    return read_file(config_path(namespace))
        or (backup_path and read_file(backup_path))
        or { values = {}, dynamic = {} }
end

---@param opts CreateOpts
---@return ConfigHandle
function M.create(opts)
    local flat = {}
    local stored = load_file(opts.namespace, opts.backup_path)
    local dyn_contexts = {}  ---@type DynCtx[]

    local handle = {}

    function handle.append(nodes)
        local prev_len = #flat
        flatten(nodes, "", flat, { prev_len }, stored.dynamic, dyn_contexts)
        for i = prev_len + 1, #flat do
            local item = flat[i]
            local v = stored.values[item.label]
            if item._enum then
                if type(v) == "string" then item.set(v) end
            elseif type(v) == "boolean" then
                item.set(v)
            end
        end
    end

    function handle.open()
        -- snap is a mutable ref so add/remove can rebuild it mid-session
        local snap = { v = make_snapshot(flat) }

        ---@param ctx DynCtx
        ---@param value string
        local function add_dyn_item(ctx, value)
            local t = ctx.schema.make_toggle(value)
            ---@type FlatItem<boolean>
            local item = {
                idx   = 0,
                score = 0,
                text  = "",
                label = ctx.label .. " / " .. value,
                get   = t.get,
                set   = t.set,
                _dyn  = ctx,
            }
            local v = stored.values[item.label]
            item.set(type(v) == "boolean" and v or true)

            if ctx.schema.compare then
                -- Find sorted insertion position within ctx.values
                local insert_pos = #ctx.values + 1
                for i, val in ipairs(ctx.values) do
                    if ctx.schema.compare(value, val) then
                        insert_pos = i
                        break
                    end
                end
                table.insert(ctx.values, insert_pos, value)
                table.insert(ctx.items, insert_pos, item)
                -- Find corresponding flat position: after the (insert_pos-1)th ctx item
                local flat_pos = #flat + 1
                if insert_pos == 1 then
                    for i, fi in ipairs(flat) do
                        if fi._dyn == ctx then flat_pos = i; break end
                    end
                else
                    local found = 0
                    for i, fi in ipairs(flat) do
                        if fi._dyn == ctx then
                            found = found + 1
                            if found == insert_pos - 1 then flat_pos = i + 1; break end
                        end
                    end
                end
                table.insert(flat, flat_pos, item)
            else
                table.insert(ctx.values, value)
                table.insert(ctx.items, item)
                table.insert(flat, item)
            end

            snap.v = make_snapshot(flat)
        end

        ---@param ctx DynCtx
        ---@param item FlatItem
        local function remove_dyn_item(ctx, item)
            item.set(false)
            for i, v in ipairs(ctx.values) do
                if ctx.label .. " / " .. v == item.label then
                    table.remove(ctx.values, i)
                    break
                end
            end
            for i, it in ipairs(ctx.items) do
                if it == item then table.remove(ctx.items, i); break end
            end
            for i, it in ipairs(flat) do
                if it == item then table.remove(flat, i); break end
            end
            snap.v = make_snapshot(flat)
        end

        -- Walk up _ns and _dyn to find a DynCtx ancestor
        ---@param item FlatItem
        ---@return DynCtx?
        local function find_dyn_ctx(item)
            if item._dyn then return item._dyn end
            return nil
        end

        Snacks.picker({
            title = opts.title,
            layout = { preset = "select" },
            finder = function()
                local visible = {}
                for _, item in ipairs(snap.v) do
                    if is_visible(item) then
                        table.insert(visible, item)
                    end
                end
                return make_items(visible)
            end,
            format = "text",
            sort = { fields = { "idx" } },
            actions = {
                dyn_add = function(picker, item)
                    local ctx = item and find_dyn_ctx(item --[[@as FlatItem]])
                    if not ctx then return end
                    vim.ui.input({ prompt = "Add to " .. ctx.label .. ": " }, function(input)
                        if not input or input == "" then return end
                        local value = ctx.schema.validate(input)
                        if not value then
                            vim.notify("Invalid value: " .. input, vim.log.levels.WARN)
                            return
                        end
                        -- Prevent duplicates
                        for _, v in ipairs(ctx.values) do
                            if v == value then return end
                        end
                        add_dyn_item(ctx, value)
                        save(flat, dyn_contexts, opts.namespace, opts.backup_path)
                        picker:find()
                    end)
                end,
                dyn_remove = function(picker, item)
                    local ctx = item and find_dyn_ctx(item --[[@as FlatItem]])
                    if not ctx then return end
                    local flat_item = item --[[@as FlatItem]]
                    local label = flat_item.label
                    remove_dyn_item(ctx, flat_item)
                    save(flat, dyn_contexts, opts.namespace, opts.backup_path)
                    picker:find()
                    vim.schedule(function()
                        -- Try to land on the next item with the same ctx
                        for i, listed in ipairs(picker.list.items) do
                            if listed._dyn == ctx then
                                picker.list:view(i)
                                return
                            end
                        end
                        _ = label  -- suppress unused warning
                    end)
                end,
            },
            win = {
                input = {
                    keys = {
                        ["<C-a>"] = { "dyn_add",    mode = { "n", "i" }, desc = "Add item" },
                        ["<C-d>"] = { "dyn_remove", mode = { "n", "i" }, desc = "Remove item" },
                    },
                },
            },
            confirm = function(picker, item)
                local flat_item = item --[[@as FlatItem]]
                if not flat_item then return end
                local label = flat_item.label
                if flat_item._enum then
                    local current = flat_item.get()
                    local next_val = flat_item._enum[1]
                    for i, v in ipairs(flat_item._enum) do
                        if v == current then
                            next_val = flat_item._enum[(i % #flat_item._enum) + 1]
                            break
                        end
                    end
                    flat_item.set(next_val)
                else
                    flat_item.set(not flat_item.get())
                end
                save(flat, dyn_contexts, opts.namespace, opts.backup_path)
                picker:find()
                vim.schedule(function()
                    for i, listed in ipairs(picker.list.items) do
                        if (listed --[[@as FlatItem]]).label == label then
                            picker.list:view(i)
                            break
                        end
                    end
                end)
            end,
        })
    end

    M._current = handle
    return handle
end

---@param nodes AnyNode[]
function M.append(nodes)
    assert(M._current, "configuration_handler: call create() before append()")
    M._current.append(nodes)
end

function M.open()
    assert(M._current, "configuration_handler: call create() before open()")
    M._current.open()
end


return M
