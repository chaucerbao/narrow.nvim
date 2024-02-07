local setup_params = {}

return {
  setup = function(params)
    setup_params = params
  end,

  narrow_visual_selection = function()
    local name = vim.fn.escape('[Narrow]', '[]')

    local parent = {
      winid = vim.fn.bufwinid('%'),
      filetype = vim.bo.filetype,
      modifiable = vim.bo.modifiable,
    }
    parent.restore = function()
      vim.fn.win_gotoid(parent.winid)
      vim.bo.modifiable = parent.modifiable
    end

    local child = {
      winid = vim.fn.bufwinid(name),
    }
    child.bufnr = function()
      return vim.fn.winbufnr(child.winid)
    end

    vim.bo.modifiable = false
    vim.cmd('normal "9Y')

    if child.winid < 0 then
      vim.cmd('vnew ' .. name)

      -- Convert to a scratch buffer
      vim.bo.bufhidden = 'wipe'
      vim.bo.buflisted = false
      vim.bo.buftype = 'nofile'
      vim.bo.swapfile = false

      child.winid = vim.fn.win_getid()
    end

    vim.fn.win_gotoid(child.winid)
    vim.bo.filetype = parent.filetype

    vim.cmd('normal ggVG"9p')

    vim.api.nvim_create_autocmd({ 'QuitPre' }, {
      group = vim.api.nvim_create_augroup('Narrow', {}),
      buffer = child.bufnr(),
      callback = parent.restore,
    })

    if setup_params.write_mapping and vim.fn.mapcheck(setup_params.write_mapping, 'n') == '' then
      vim.keymap.set('n', setup_params.write_mapping, function()
        vim.cmd('normal ggVG"9Y')
        vim.cmd('quit')

        vim.fn.win_gotoid(parent.winid)
        vim.bo.modifiable = true
        vim.cmd('normal gv"9p')

        parent.restore()
      end, { buffer = child.bufnr(), noremap = true })
    end
  end,
}
