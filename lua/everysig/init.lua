local M = {}

M.configuration = {
    number = nil, ---@type boolean?
}

---@type fun(number: integer): string
local function signature_number_comment(number)
    local comment = vim.bo.commentstring
    if M.configuration.number and #comment ~= 0 then
        return ' ' .. comment:format(number)
    else
        return ""
    end
end

---@type fun(signatures: table[]): string[], integer[]
local function markdown_for_signature_list(signatures)
    local lines, labels = {}, {}
    for index, signature in ipairs(signatures) do
        table.insert(labels, #lines + 1)

        table.insert(lines, "```" .. vim.bo.filetype)
        table.insert(lines, signature.label .. signature_number_comment(index))
        table.insert(lines, "```")

        if signature.documentation then
            vim.lsp.util.convert_input_to_markdown_lines(signature.documentation, lines)
        end
        if index ~= #signatures then
            table.insert(lines, "---")
        end
    end
    return lines, labels
end

---@type fun(buffer: integer, window: integer, active_parameter: integer?, signatures: table[], labels: integer[]): nil
local function set_active_parameter_highlights(buffer, window, active_parameter, signatures, labels)
    for index, signature in ipairs(signatures) do
        -- Some servers send the active parameter with the individual signatures.
        local parameter = 1 + assert(signature.activeParameter or active_parameter) ---@type integer
        if parameter <= 0 or parameter > #signature.parameters then return end
        local label = signature.parameters[parameter].label
        if type(label) == "string" then
            vim.api.nvim_win_call(window, function ()
                -- An imperfect solution, but anything else would probably be unreasonably difficult.
                vim.fn.matchadd("LspSignatureActiveParameter", "\\<" .. label .. "\\>")
            end)
        elseif type(label) == "table" then
            vim.api.nvim_buf_add_highlight(buffer, -1, "LspSignatureActiveParameter", labels[index], unpack(label))
        end
    end
end

---@type fun(err?: lsp.ResponseError, result: any, context: lsp.HandlerContext, config?: table): integer?, integer?
M.signature_help_handler = function (_, result, context, config)
    config = config or {}
    if result and result.signatures and #result.signatures ~= 0 then
        config.focus_id = context.method -- Focus existing signature help popup if there is one.
        local markdown, labels = markdown_for_signature_list(result.signatures)
        local floatbuffer, floatwindow = vim.lsp.util.open_floating_preview(markdown, "markdown", config)
        set_active_parameter_highlights(floatbuffer, floatwindow, result.activeParameter, result.signatures, labels)
        return floatbuffer, floatwindow
    elseif not config.silent then
        vim.notify("No signature help available")
    end
end

---@class EverysigOptions
---@field override boolean? Whether to override the default signature help handler.
---@field number boolean? Whether to number signatures.

---@param options EverysigOptions
M.setup = function (options)
    if options.override then
        vim.lsp.handlers["textDocument/signatureHelp"] = M.signature_help_handler
    end
    M.configuration.number = options.number
end

return M
