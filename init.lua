-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = "Μετακίνηση στο αριστερό split" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = "Μετακίνηση στο πάνω split" })

vim.opt.clipboard = "unnamedplus"

vim.opt.termguicolors = true

-- LSP: keymap για go-to-definition (τα υπόλοιπα έρχονται by default στο Neovim 0.11+:
-- K = hover, grn = rename, gra = code action, grr = references)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
  end,
})

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- ΕΔΩ ΜΠΑΙΝΟΥΝ ΟΛΑ ΤΑ PLUGINS ΣΟΥ
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- Χρειάζεται Nerd Font για να δείχνει εικονίδια αρχείων
        "MunifTanjim/nui.nvim",
      },
      config = function()
        require("neo-tree").setup({})
        -- Keymap: Ctrl + n για άνοιγμα/κλείσιμο
        vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { silent = true })
      end
    },

    -- Mason: κατεβάζει και διαχειρίζεται τους language servers
    {
      "mason-org/mason.nvim",
      opts = {},
    },

    -- Γέφυρα Mason <-> lspconfig
    -- Python = pyright (θέλει Node.js), C++ = clangd, LaTeX = texlab
    {
      "mason-org/mason-lspconfig.nvim",
      dependencies = {
        "mason-org/mason.nvim",
        "neovim/nvim-lspconfig",
      },
      opts = {
        ensure_installed = { "pyright", "clangd", "texlab" },
      },
    },

    -- Auto-complete (το popup menu ενώ γράφεις)
    {
      "saghen/blink.cmp",
      version = "1.*", -- prebuilt binaries, δεν χρειάζεται Rust
      opts = {
        -- Tab = αποδοχή, Shift+Tab = προηγούμενο snippet field, Ctrl+n/Ctrl+p = πλοήγηση,
        -- Ctrl+space = άνοιγμα μενού, Ctrl+e = κλείσιμο
        keymap = { preset = "super-tab" },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
      },
    },

    -- Πιο όμορφο colorscheme
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000, -- φορτώνει πρώτο
      config = function()
        require("tokyonight").setup({ style = "night" }) -- "storm", "moon", "night", "day"
        vim.cmd.colorscheme("tokyonight")
      end,
    },

    -- Treesitter: πολύ καλύτερο syntax highlighting
    -- Θέλει C compiler στα Windows (π.χ. LLVM/clang, gcc ή zig)
    -- Το LaTeX παραλείπεται επίτηδες: το vimtex κάνει ήδη καλύτερη δουλειά
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "master",
      build = ":TSUpdate",
      lazy = false,
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = {
            "python", "cpp", "c", "lua", "vim", "vimdoc", "query",
            "markdown", "markdown_inline", "bash", "json", "cmake",
          },
          auto_install = false, -- τα parsers μπαίνουν μόνο από το ensure_installed (αποφεύγει errors π.χ. με το latex)
          highlight = { enable = true, disable = { "latex" } }, -- το LaTeX το αναλαμβάνει το vimtex
          indent = { enable = true },
        })
      end,
    },

    -- Fuzzy finder: αναζήτηση αρχείων και κειμένου σε όλο το project
    -- Για το live grep χρειάζεσαι ripgrep: winget install BurntSushi.ripgrep.MSVC
    {
      "nvim-telescope/telescope.nvim",
      branch = "0.1.x",
      dependencies = { "nvim-lua/plenary.nvim" },
      keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
        { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Search text in project" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Open buffers" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
        { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      },
      opts = {},
    },

    -- LaTeX: compile + προβολή PDF (θέλει MiKTeX ή TeX Live)
    -- \ll = συνεχής μεταγλώττιση, \lv = άνοιγμα PDF
    {
      "lervag/vimtex",
      lazy = false, -- το vimtex δεν πρέπει να φορτώνει lazy
      init = function()
        -- Αν έχεις SumatraPDF στο PATH, το vimtex το χρησιμοποιεί (με forward/inverse search).
        -- Αλλιώς δεν ορίζουμε viewer και ανοίγει το default PDF app (π.χ. με το snippet παρακάτω).
        if vim.fn.executable("SumatraPDF") == 1 then
          vim.g.vimtex_view_method = "general"
          vim.g.vimtex_view_general_viewer = "SumatraPDF"
          vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"
        end
      end,
    },

    -- Αν θέλεις να προσθέσεις κι άλλα plugins στο μέλλον, θα τα βάζεις εδώ από κάτω με κόμμα
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true },
})

-- LaTeX: αυτόματο compile στο save + άνοιγμα του PDF την πρώτη φορά
-- Χρησιμοποιεί pdflatex (δεν χρειάζεται Perl). Βάλε true μόνο αν έχεις εγκαταστήσει Perl + latexmk.
-- Το SumatraPDF κάνει μόνο του reload. Χειροκίνητα: :LatexCompile
local latex_use_latexmk = false
local latex_running = {}
local latex_opened = {}

local function compile_latex(file)
  if latex_running[file] then return end -- μην ξεκινάς δεύτερο compile ενώ τρέχει ένα
  local dir = vim.fn.fnamemodify(file, ":h")
  local name = vim.fn.fnamemodify(file, ":t")
  local pdf = vim.fn.fnamemodify(file, ":r") .. ".pdf"

  local cmd
  if latex_use_latexmk and vim.fn.executable("latexmk") == 1 then
    cmd = { "latexmk", "-pdf", "-interaction=nonstopmode", "-synctex=1", name }
  else
    cmd = { "pdflatex", "-interaction=nonstopmode", "-synctex=1", name }
  end

  latex_running[file] = true
  vim.notify("LaTeX: compiling " .. name .. " ...")
  vim.system(cmd, { cwd = dir, text = true }, vim.schedule_wrap(function(res)
    latex_running[file] = nil
    if res.code == 0 then
      vim.notify("LaTeX: compiled OK")
      if not latex_opened[pdf] and (vim.uv or vim.loop).fs_stat(pdf) then
        latex_opened[pdf] = true
        vim.ui.open(pdf)
      end
    else
      -- δείξε μόνο τις γραμμές λάθους (ξεκινούν με "!")
      local errors = {}
      for line in ((res.stdout or "") .. (res.stderr or "")):gmatch("[^\r\n]+") do
        if line:sub(1, 1) == "!" or line:lower():find("perl") then
          table.insert(errors, line)
        end
      end
      local msg = #errors > 0 and table.concat(errors, "\n") or "δες το .log αρχείο"
      vim.notify("LaTeX: compile FAILED\n" .. msg, vim.log.levels.ERROR)
    end
  end))
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("LatexAutoCompile", { clear = true }),
  pattern = "*.tex",
  callback = function(ev)
    compile_latex(vim.fn.fnamemodify(ev.file, ":p"))
  end,
})

-- Ανοίγει ξανά το PDF (π.χ. αφού το έκλεισες). Keymap: <leader>lo
local function open_latex_pdf()
  local pdf = vim.fn.expand("%:p:r") .. ".pdf"
  if (vim.uv or vim.loop).fs_stat(pdf) then
    vim.ui.open(pdf)
  else
    vim.notify("LaTeX: δεν βρέθηκε PDF, κάνε πρώτα compile (:LatexCompile)", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_user_command("LatexOpen", open_latex_pdf, { desc = "Open the PDF of the current .tex file" })
vim.keymap.set("n", "<leader>lo", open_latex_pdf, { desc = "Open LaTeX PDF" })

vim.api.nvim_create_user_command("LatexCompile", function()
  compile_latex(vim.fn.expand("%:p"))
end, { desc = "Compile the current .tex file" })

-- LaTeX templates: :LatexTemplate [english|greek]  (ή <leader>lt για το default)
-- Επιπλέον, τα ΝΕΑ/ΑΔΕΙΑ .tex αρχεία γεμίζουν αυτόματα με το default template.
local latex_default_template = "greek" -- "english" ή "greek"
local latex_auto_template = true         -- false για να το απενεργοποιήσεις

local latex_templates = {
  english = [[
\documentclass[11pt,a4paper]{article}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[margin=2.5cm]{geometry}
\usepackage{amsmath, amssymb}
\usepackage{graphicx}
\usepackage{hyperref}

\title{Title}
\author{Author}
\date{\today}

\begin{document}

\maketitle

\section{Introduction}


\end{document}
]],
  greek = [[
\documentclass{article}
\usepackage{graphicx}
\usepackage[utf8]{inputenc}
\usepackage{amssymb}
\usepackage{amsmath}
\usepackage[T1]{fontenc}
\usepackage{textalpha}
\usepackage[greek,english]{babel}

\title{Sample}
\author{Συρσίρης Ευάγγελος}
\date{}

\begin{document}

\maketitle

\section{Άσκηση 1}

\end{document}
]],
}

local function insert_latex_template(name)
  name = (name and name ~= "") and name or latex_default_template
  local tpl = latex_templates[name]
  if not tpl then
    vim.notify("Άγνωστο template: " .. name .. " (διαθέσιμα: english, greek)", vim.log.levels.ERROR)
    return
  end
  local lines = vim.split(tpl, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end

  -- αν το buffer είναι άδειο αντικατάστησέ το, αλλιώς βάλε το template στη θέση του cursor
  local empty = vim.fn.line("$") == 1 and vim.fn.getline(1) == ""
  local start = empty and 0 or vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, start, empty and -1 or start, false, lines)

  -- τοποθέτησε τον cursor κάτω από την πρώτη \section
  for i, l in ipairs(lines) do
    if l:find("^\\section") then
      vim.api.nvim_win_set_cursor(0, { start + i + 1, 0 })
      break
    end
  end
  vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("LatexTemplate", function(opts)
  insert_latex_template(opts.args)
end, {
  nargs = "?",
  complete = function() return vim.tbl_keys(latex_templates) end,
  desc = "Insert a LaTeX template",
})
vim.keymap.set("n", "<leader>lt", function() insert_latex_template() end, { desc = "Insert LaTeX template" })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("LatexAutoTemplate", { clear = true }),
  pattern = "*.tex",
  callback = function()
    if latex_auto_template and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
      vim.schedule(function() insert_latex_template() end)
    end
  end,
})

-- Pyright: λιγότερο αυστηρός έλεγχος τύπων (λιγότερα "ψεύτικα" errors)
-- typeCheckingMode: "off" = μόνο autocomplete, "basic" = ήπιος έλεγχος, "standard"/"strict" = αυστηρότερος
if vim.fn.has("nvim-0.11") == 1 then
  vim.lsp.config("pyright", {
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          diagnosticMode = "openFilesOnly",
        },
      },
    },
  })
end

-- Δίνει στους servers τις δυνατότητες του blink.cmp (Neovim 0.11+)
if vim.fn.has("nvim-0.11") == 1 then
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
  end
end
