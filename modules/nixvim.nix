{ ... }:

{
  programs.nixvim = {
    enable = true;
    nixpkgs.config.allowUnfree = true;
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    opts = {
      number = true;
      relativenumber = true;
      clipboard = "unnamedplus";
      mouse = "a";
      signcolumn = "yes";
      termguicolors = true;
      updatetime = 250;
      wrap = true;
      linebreak = true;
      breakindent = true;
    };

    colorschemes.onedark.enable = true;

    autoCmd = [
      {
        event = "TextYankPost";
        callback.__raw = ''
          function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
          end
        '';
      }
    ];
    plugins.lsp.servers = {
      nixd.enable = true;
      pyright.enable = true;
      clangd.enable = true;
      marksman.enable = true;
      yamlls.enable = true;
      taplo.enable = true;
      jsonls.enable = true;
    };
    plugins.lsp.enable = true;

    plugins.scope.enable = true;
    plugins.oil.enable = true;
    plugins.telescope = {
      enable = true;
      extensions.file-browser = {
        enable = true;
        settings = {
          hidden = {
            file_browser = true;
            folder_browser = true;
          };
          respect_gitignore = false;
          grouped = true;
          mappings.i = {
            # Enter on a directory opens it in oil (dired); Tab descends instead.
            "<CR>".__raw = ''
              function(bufnr)
                local actions = require("telescope.actions")
                local entry = require("telescope.actions.state").get_selected_entry()
                if entry and vim.fn.isdirectory(entry.path) == 1 then
                  actions.close(bufnr)
                  require("oil").open(entry.path)
                else
                  actions.select_default(bufnr)
                end
              end
            '';
            "<Tab>".__raw = ''require("telescope.actions").select_default'';
          };
        };
      };
    };
    plugins.neogit.enable = true;
    plugins.diffview.enable = true;
    plugins.treesitter = {
      enable = true;
      settings.ensure_installed = [
        "nix"
        "python"
        "cpp"
        "markdown"
        "markdown_inline"
        "yaml"
        "toml"
        "json"
      ];
    };
    plugins.mini = {
      enable = true;
      mockDevIcons = true;
      modules = {
        surround = { };
        pairs = { };
        icons = { };
        statusline = { };
        tabline.tabpage_section = "none";
        diff = { };
      };
    };
    # mini.tabline cannot label its tab section, so draw it here with the workspace name.
    extraConfigLuaPost = ''
      local tabline_buffers = MiniTabline.make_tabline_string
      MiniTabline.make_tabline_string = function()
        local name = vim.t.workspace_name
        local label = name and (" - " .. name:gsub("%%", "%%%%")) or ""
        return string.format("%%#MiniTablineTabpagesection# Tab %d/%d%s %%T", vim.fn.tabpagenr(), vim.fn.tabpagenr("$"), label)
          .. tabline_buffers()
      end
    '';
    plugins.snacks = {
      enable = true;
      settings = {
        picker.enabled = true;
        terminal.enabled = true;
        indent.enabled = true;
        dashboard = {
          enabled = true;
          sections = [
            { section = "header"; }
            { section = "keys"; gap = 1; padding = 1; }
          ];
        };
        explorer.enabled = true;
        notifier.enabled = true;
      };
    };
    plugins.noice = {
      enable = true;
      settings = {
        cmdline = {
          enabled = true;
          view = "cmdline_popup";
        };
        views.cmdline_popup = {
          position = {
            row = "25%";
            col = "50%";
          };
          size = {
            width = 60;
            height = "auto";
          };
          border = {
            style = "rounded";
            padding = [ 0 1 ];
          };
        };
      };
    };
    plugins.which-key = {
      enable = true;
      settings.spec = [
        {
          __unkeyed-1 = "<leader>b";
          group = "Buffers";
        }
        {
          __unkeyed-1 = "<leader>x";
          group = "Diagnostics";
        }
        {
          __unkeyed-1 = "<leader>f";
          group = "Files";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
        }
        {
          __unkeyed-1 = "<leader>o";
          group = "Open";
        }
        {
          __unkeyed-1 = "<leader>q";
          group = "Quit";
        }
        {
          __unkeyed-1 = "<leader>t";
          group = "Toggle";
        }
        {
          __unkeyed-1 = "<leader>w";
          group = "Window";
        }
        {
          __unkeyed-1 = "<leader><tab>";
          group = "Workspaces";
        }
      ];
    };

    keymaps = [
      # ---------- Buffers ----------
      {
        key = "<leader>ba";
        action = "<cmd>wall<CR>";
        mode = "n";
        options.desc = "Save all buffers";
      }
      {
        key = "<leader>bd";
        action = "<cmd>bd<CR>";
        mode = "n";
        options.desc = "Delete buffer";
      }
      {
        key = "<leader>bl";
        action = "<cmd>lua Snacks.picker.buffers()<CR>";
        mode = "n";
        options.desc = "List buffers";
      }
      {
        key = "<leader>bn";
        action = "<cmd>bnext<CR>";
        mode = "n";
        options.desc = "Next buffer";
      }
      {
        key = "<leader>bp";
        action = "<cmd>bprevious<CR>";
        mode = "n";
        options.desc = "Previous buffer";
      }
      {
        key = "<leader>bs";
        action = "<cmd>write<CR>";
        mode = "n";
        options.desc = "Save current buffer";
      }
      # ---------- Diagnostics ----------
      {
        key = "<leader>xr";
        action = "<cmd>lua Snacks.picker.lsp_references()<CR>";
        mode = "n";
        options.desc = "LSP references";
      }
      {
        key = "<leader>xs";
        action = "<cmd>lua Snacks.picker.lsp_symbols()<CR>";
        mode = "n";
        options.desc = "Document symbols";
      }
      {
        key = "<leader>xx";
        action = "<cmd>lua Snacks.picker.diagnostics()<CR>";
        mode = "n";
        options.desc = "Workspace diagnostics";
      }
      {
        key = "<leader>xX";
        action = "<cmd>lua Snacks.picker.diagnostics_buffer()<CR>";
        mode = "n";
        options.desc = "Buffer diagnostics";
      }
      # ---------- Files ----------
      {
        key = "<leader>fb";
        action = "<cmd>lua Snacks.picker.buffers()<CR>";
        mode = "n";
        options.desc = "Find buffers";
      }
      {
        key = "<leader>ff";
        action = "<cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>";
        mode = "n";
        options.desc = "Browse files";
      }
      {
        key = "<leader>fg";
        action = "<cmd>lua Snacks.picker.grep()<CR>";
        mode = "n";
        options.desc = "Live grep";
      }
      {
        key = "<leader>fh";
        action = "<cmd>lua Snacks.picker.help()<CR>";
        mode = "n";
        options.desc = "Search help";
      }
      {
        key = "<leader>fp";
        action = "<cmd>lua Snacks.picker.files()<CR>";
        mode = "n";
        options.desc = "Find project files";
      }
      {
        key = "<leader>fr";
        action = "<cmd>lua Snacks.picker.recent()<CR>";
        mode = "n";
        options.desc = "Recent files";
      }
      {
        key = "<leader>fs";
        action = "<cmd>write<CR>";
        mode = "n";
        options.desc = "Save file";
      }
      # ---------- Git ----------
      {
        key = "<leader>gb";
        action = "<cmd>Neogit branch<CR>";
        mode = "n";
        options.desc = "Git branches";
      }
      {
        key = "<leader>gc";
        action = "<cmd>lua require('neogit').open({ 'commit' })<CR>";
        mode = "n";
        options.desc = "Commit changes";
      }
      {
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<CR>";
        mode = "n";
        options.desc = "Open diff view";
      }
      {
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory %<CR>";
        mode = "n";
        options.desc = "File history";
      }
      {
        key = "<leader>gl";
        action = "<cmd>lua require('neogit').open({ 'pull' })<CR>";
        mode = "n";
        options.desc = "Pull changes";
      }
      {
        key = "<leader>gp";
        action = "<cmd>lua require('neogit').open({ 'push' })<CR>";
        mode = "n";
        options.desc = "Push changes";
      }
      {
        key = "<leader>gq";
        action = "<cmd>DiffviewClose<CR>";
        mode = "n";
        options.desc = "Close diff view";
      }
      {
        key = "<leader>gs";
        action = "<cmd>Neogit<CR>";
        mode = "n";
        options.desc = "Git status";
      }
      # ---------- Open ----------
      {
        key = "<leader>ot";
        action = "<cmd>lua Snacks.terminal(nil, { count = 1, win = { position = 'bottom' } })<CR>";
        mode = "n";
        options.desc = "Toggle bottom terminal";
      }
      {
        key = "<leader>oT";
        action = "<cmd>terminal<CR>";
        mode = "n";
        options.desc = "Terminal in current buffer";
      }
      # ---------- Quit ----------
      {
        key = "<leader>qq";
        action = "<cmd>qa<CR>";
        mode = "n";
        options.desc = "Quit";
      }
      {
        key = "<leader>qr";
        action = "<cmd>restart<CR>";
        mode = "n";
        options.desc = "Restart";
      }
      {
        key = "<leader>qR";
        action.__raw = ''
          function()
            local file = vim.fn.stdpath("state") .. "/restart-session.vim"
            vim.cmd("mksession! " .. vim.fn.fnameescape(file))
            vim.cmd("restart source " .. vim.fn.fnameescape(file))
          end
        '';
        mode = "n";
        options.desc = "Restart and restore everything";
      }
      # ---------- Toggle ----------
      {
        key = "<leader>ti";
        action = "<cmd>lua Snacks.toggle.indent():toggle()<CR>";
        mode = "n";
        options.desc = "Toggle indent guides";
      }
      {
        key = "<leader>tn";
        action = "<cmd>set invnumber<CR>";
        mode = "n";
        options.desc = "Toggle line numbers";
      }
      {
        key = "<leader>tr";
        action = "<cmd>set invrelativenumber<CR>";
        mode = "n";
        options.desc = "Toggle relative line numbers";
      }
      {
        key = "<leader>tw";
        action = "<cmd>set invwrap<CR>";
        mode = "n";
        options.desc = "Toggle word wrap";
      }
      # ---------- Window ----------
      {
        key = "<leader>wc";
        action = "<cmd>close<CR>";
        mode = "n";
        options.desc = "Close window";
      }
      {
        key = "<leader>wv";
        action = "<cmd>vsplit<CR>";
        mode = "n";
        options.desc = "Split window vertically";
      }
      {
        key = "<leader>ww";
        action = "<C-w>w";
        mode = "n";
        options.desc = "Next window";
      }
      # ---------- Workspaces ----------
      {
        key = "<leader><tab>.";
        action.__raw = ''
          function()
            local items = {}
            for i, t in ipairs(vim.api.nvim_list_tabpages()) do
              items[#items + 1] = { nr = i, name = vim.t[t].workspace_name or "unnamed" }
            end
            vim.ui.select(items, {
              prompt = "Workspaces",
              format_item = function(it) return it.nr .. ": " .. it.name end,
            }, function(it)
              if it then vim.cmd(it.nr .. "tabnext") end
            end)
          end
        '';
        mode = "n";
        options.desc = "List workspaces";
      }
      {
        key = "<leader><tab>d";
        action = "<cmd>tabclose<CR>";
        mode = "n";
        options.desc = "Close workspace";
      }
      {
        key = "<leader><tab>n";
        action.__raw = ''
          function()
            vim.ui.input({ prompt = "Workspace name: " }, function(name)
              if name and name ~= "" then
                vim.cmd("tabnew")
                vim.t.workspace_name = name
              end
            end)
          end
        '';
        mode = "n";
        options.desc = "New workspace";
      }
      {
        key = "<leader><tab>r";
        action.__raw = ''
          function()
            vim.ui.input({ prompt = "Rename workspace: ", default = vim.t.workspace_name }, function(name)
              if name and name ~= "" then vim.t.workspace_name = name end
            end)
          end
        '';
        mode = "n";
        options.desc = "Rename workspace";
      }
      # ---------- Misc ----------
      {
        key = "jk";
        action = "<Esc>";
        mode = "i";
        options.desc = "Exit insert mode";
      }
      {
        key = "<leader>e";
        action = "<cmd>lua Snacks.explorer()<CR>";
        mode = "n";
        options.desc = "File explorer";
      }
      {
        key = "<C-q>";
        action = "<C-\\><C-n>";
        mode = "t";
        options.desc = "Terminal normal mode";
      }
    ] ++
    # Workspaces: jump 1..9
    builtins.genList (i: {
      key = "<leader><tab>${toString (i + 1)}";
      action = "<cmd>${toString (i + 1)}tabnext<CR>";
      mode = "n";
      options.desc = "Workspace ${toString (i + 1)}";
    }) 9;
  };
}
