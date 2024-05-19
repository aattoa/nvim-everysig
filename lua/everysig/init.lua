---@type fun(documentation: table?): string[]
local function documentation_lines(documentation)
    if not documentation then return {} end
    assert(documentation.kind == "markdown") -- TODO
    return vim.lsp.util.convert_input_to_markdown_lines(documentation.value)
end

---@type fun(signatures: table[]): string[], integer[]
local function markdown_for_signature_list(signatures)
    local lines, labels = {}, {}
    for index, signature in ipairs(signatures) do
        table.insert(labels, #lines + 1)

        table.insert(lines, "```" .. vim.bo.filetype)
        table.insert(lines, signature.label)
        table.insert(lines, "```")

        for _, line in ipairs(documentation_lines(signature.documentation)) do
            table.insert(lines, line)
        end

        if index ~= #signatures then
            table.insert(lines, "---")
        end
    end
    return lines, labels
end

---@type fun(buffer: integer, active_parameter: integer?, signatures: table[], labels: integer[]): nil
local function set_active_parameter_highlights(buffer, active_parameter, signatures, labels)
    for index, signature in ipairs(signatures) do
        local parameter = 1 + assert(signature.activeParameter or active_parameter) ---@type integer
        if parameter > 0 and parameter <= #signature.parameters then
            local range = signature.parameters[parameter].label
            vim.api.nvim_buf_add_highlight(buffer, -1, "LspSignatureActiveParameter", labels[index], unpack(range))
        end
    end
end

local M = {}

---@type fun(err?: lsp.ResponseError, result: any, context: lsp.HandlerContext, config?: table): integer?, integer?
M.signature_help_handler = function (_, result, context, config)
    config = config or {}
    if result and result.signatures and #result.signatures ~= 0 then
        config.focus_id = context.method -- Focus existing signature help popup if there is one.
        local markdown, labels = markdown_for_signature_list(result.signatures)
        local floatbuffer, floatwindow = vim.lsp.util.open_floating_preview(markdown, "markdown", config)
        set_active_parameter_highlights(floatbuffer, result.activeParameter, result.signatures, labels)
        return floatbuffer, floatwindow
    elseif not config.silent then
        vim.notify("No signature help available")
    end
end

return M
