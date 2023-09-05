-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny


local is_windows = vim.fn.has('win32') == 1

local output_file = 'build/$(FNOEXT)'
local ld_flags = '-Wl,--stack,268435456'


if is_windows then
  -- Enable powershell as your default shell
  vim.opt.shell = "pwsh.exe -NoLogo"
  vim.opt.shellcmdflag =
  "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.cmd [[
      let &shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
      let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
      set shellquote= shellxquote=
    ]]
  -- Set a compatible clipboard manager
  vim.g.clipboard = {
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
  }
  -- this is mainly for powershell :/
  output_file = output_file .. '.exe'
end

lvim.plugins = {
  {
    "ThePrimeagen/vim-be-good",
    lazy = false,
  },
  {
    'xeluxee/competitest.nvim',
    dependencies = 'MunifTanjim/nui.nvim',
    config = function()
      require('competitest').setup {
        runner_ui = {
          interface = "split"
        },
        testcases_use_single_file = true,
        compile_command = {
          cpp = { exec = 'g++', args = { '-std=c++17', '$(FNAME)', '-o', output_file, (is_windows and ld_flags or nil) } },
        },
        compile_directory = "./",
        running_directory = "./build",
        run_command = {
          cpp = not is_windows and {
            exec = "sh",
            args = { "-c", 'ulimit -s 262144 && ./"$(FN0EXT)"' }
          } or nil
        }
      }
    end,
  }
}

-- Key bindings for Competitest commands
-- browser is set to f2 when on the page, first you do <F2> + r to receive contest
lvim.keys.normal_mode["<F2>e"] = ":CompetiTest run<CR>"
lvim.keys.normal_mode["<F2>r"] = ":CompetiTest receive problem<CR>"
lvim.keys.normal_mode["<F2>rc"] = ":CompetiTest receive contest<CR>"


-- Define the function to compile and execute C++ code
local function RunCppCode()
  -- Get the base filename without extension
  local file_name = vim.fn.expand('%:t:r')

  -- Define the path separator based on the operating system
  local sp = (is_windows and "\\" or "/")

  -- Construct the path to the executable
  local executable = '"' .. vim.fn.expand('%:p:h') .. sp .. "build" .. sp ..
      (is_windows and file_name .. ".exe" or file_name) .. '"'

  -- Construct the compile command
  local compile_cmd = string.format('g++ -std=c++17 "%s" -o %s ', vim.fn.expand('%:p'), executable)


  -- ld_flags for Windows (PowerShell)
  if is_windows then
    -- double qoute due to powershell being weird
    ld_flags = '"' .. ld_flags .. '"'
    -- Append ld_flags to the compile command
    compile_cmd = compile_cmd .. ' ' .. ld_flags
  end


  -- Define the execute command
  local execute_cmd = executable

  -- Add .exe extension for Windows and prefix with ".\" for PowerShell
  if is_windows then
    execute_cmd = "." .. execute_cmd
  end
  -- Construct the full command to execute
  local full_cmd = compile_cmd

  if not is_windows then
    full_cmd = full_cmd .. ' && ' .. 'ulimit -s 262144'
  end
  -- add execution to full command
  full_cmd = full_cmd .. ' && ' .. execute_cmd
  vim.cmd('vsplit')

  vim.cmd('terminal echo "running: ' .. vim.fn.expand('%:t') .. '" && ' .. full_cmd)

  vim.cmd('wincmd l')
end

vim.api.nvim_create_user_command('RunCppCode', RunCppCode, { nargs = 0 })

-- Key binding for when Competitest fails/there are specific usecases where I cannot use it.
vim.api.nvim_set_keymap('n', '<F3>', [[:RunCppCode<CR>]], { noremap = true, silent = true })
