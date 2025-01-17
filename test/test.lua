local uv  = vim.loop
local cmd = vim.api.nvim_command
local vfn = vim.api.nvim_call_function

cmd('packadd paq-nvim')

local TESTPATH = vfn('stdpath', {'data'}) .. '/site/pack/test/'

local function reload_paq()
    local Pq
    package.loaded['paq-nvim'] = nil
    Pq = require('paq-nvim')
    Pq.setup {
        path = TESTPATH,
    }
    return Pq
end

local function test_branch(path, branch)
    local stdout = uv.new_pipe(false)
    local handle = uv.spawn('git',
        {
            cwd  = TESTPATH .. path,
            args = {'branch', '--show-current'}, -- FIXME: This might not work with some versions of git
            stdio = {nil, stout, nil},
        },
        function(code)
            assert(code == 0, "Paq-test: failed to get git branch")
            stdout:read_stop()
            stdout:close()
        end)
    stdout:read_start(function(err, data)
        assert(not err, err)
        if data then
            assert(data == branch, string.format("Paq-test: %s does not equal %s", data, branch))
        end
    end)
end


local Pq = reload_paq()
local paq = Pq.paq

paq{'badbadnotgood', opt=true}                  -- should fail to parse
paq{'rust-lang/rust.vim', opt=true}             -- test opt
paq{'JuliaEditorSupport/julia-vim', as='julia'} -- test as

paq{as='wiki',                                  -- test url + as
    url='https://github.com/lervag/wiki.vim',
    }

paq {'junegunn/fzf',                            -- test run function
    run=function() vfn('fzf#install', {}) end,
    } 

paq {'autozimu/LanguageClient-neovim',          -- test branch + run command
    branch = 'next',
    run = 'bash install.sh',
    }

Pq.install()
cmd('sleep 20') -- plenty of time for plugins to download

assert(uv.fs_scandir(TESTPATH .. 'opt/rust.vim'))
assert(uv.fs_scandir(TESTPATH .. 'start/julia'))
assert(uv.fs_scandir(TESTPATH .. 'start/wiki'))
assert(uv.fs_scandir(TESTPATH .. 'start/fzf'))
assert(uv.fs_scandir(TESTPATH .. 'start/LanguageClient-neovim'))



test_branch('start/LanguageClient-neovim', 'next')
cmd('sleep 20')

---- Check clean() doesn't delete everything
Pq = reload_paq()
Pq.paq{'JuliaEditorSupport/julia-vim', as='julia'}
Pq.clean()
assert(uv.fs_scandir(TESTPATH .. 'start/julia'))



cmd('sleep 20')
Pq = reload_paq()
Pq.clean()

print('Paq-test: FINISHED')
