return {
  "mfussenegger/nvim-dap",
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")


    require('dap').set_log_level('INFO') -- making it so the logs are human readable

    dap.defaults.fallback.external_terminal = {
      command = '/usr/bin/foot',
      args = { '-e' },
    }

    -- setting up dapui with the default config.
    dapui.setup()

    -- setting up an event listener for when the debugger is launched
    dap.listeners.before.attach.dapui_config = function()
      -- after the debugger is launched, we are opening the ui proper
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    dap.adapters = {
      codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = '/home/yousef/.local/share/nvim/mason/bin/codelldb',
          args = { "--port", "${port}" },
        },
      },
    }

    dap.configurations = {
      {
        c = {
          name = "C Debug",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          runInTerminal = true,
        },
      },
    }

    -- dap ui setup
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸" },
      mappings = {
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      expand_lines = vim.fn.has("nvim-0.7"),
      layouts = {
        {
          elements = {
            "scopes",
          },
          size = 0.3,
          position = "right"
        },
        {
          elements = {
            "repl",
            "breakpoints"
          },
          size = 0.3,
          position = "bottom",
        },
      },
      floating = {
        max_height = nil,
        max_width = nil,
        border = "single",
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil,
      },
    })

    -- dap keybindings!!
    -- Start debugging session
    vim.keymap.set("n", "<leader>ds", dap.continue, { desc = '[D]ebug [S]tart' })

    -- Set breakpoints, get variable values, step into/out of functions, etc.
    vim.keymap.set("n", "<leader>dl", require("dap.ui.widgets").hover, { desc = '[D]ebug [L]earn' })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = '[D]ebug [C]ontinue' })
    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = '[D]ebug Toggle [B]reakpoint' })
    vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = '[D]ebug Step [N]ext' })
    vim.keymap.set("n", "<leader>di", dap.step_into, { desc = '[D]ebug Step [I]nto' })
    vim.keymap.set("n", "<leader>do", dap.step_out, { desc = '[D]ebug Step [O]ut' })
    --vim.keymap.set("n", "<leader>dt", dap.toggle(), { desc = '[D]ebug UI [T]oggle' })
    vim.keymap.set("n", "<leader>dC", function()
        dap.clear_breakpoints()
      end,
      { desc = '[D]ebug Breakpoint [C]lear' })

    -- Close debugger and clear breakpoints
    vim.keymap.set("n", "<leader>de", function()
        dap.clear_breakpoints()
        dapui.toggle({})
        dap.terminate()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
      end,
      { desc = '[D]ebug [E]nd' })
  end
}
