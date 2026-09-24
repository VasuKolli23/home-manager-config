{ ... }:

{
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    opts = {
      number = true;
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
    plugins.lualine = {
      enable = true;
      settings.options = {
        section_separators = { left = ""; right = ""; };
        component_separators = { left = ""; right = ""; };
      };
    };
    plugins.gitsigns.enable = true;
    plugins.indent-blankline.enable = true;
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
      modules.surround = { };
    };
    plugins.nvim-autopairs.enable = true;
    plugins.trouble.enable = true;
    plugins.toggleterm = {
      enable = true;
      settings.direction = "float";
    };
    plugins.snacks = {
      enable = true;
      settings = {
        picker.enabled = true;
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
    plugins.web-devicons.enable = true;
    plugins.which-key = {
      enable = true;
      settings.spec = [
        {
          __unkeyed-1 = "<leader>f";
          group = "Files";
        }
        {
          __unkeyed-1 = "<leader>t";
          group = "Toggle";
        }
        {
          __unkeyed-1 = "<leader>x";
          group = "Diagnostics";
        }
        {
          __unkeyed-1 = "<leader>w";
          group = "Window";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
        }
      ];
    };

    keymaps = [
      {
        key = "jk";
        action = "<Esc>";
        mode = "i";
        options.desc = "Exit insert mode";
      }
      {
        key = "<leader>ff";
        action = "<cmd>lua Snacks.picker.files()<CR>";
        mode = "n";
        options.desc = "Find files";
      }
      {
        key = "<leader>fg";
        action = "<cmd>lua Snacks.picker.grep()<CR>";
        mode = "n";
        options.desc = "Live grep";
      }
      {
        key = "<leader>fb";
        action = "<cmd>lua Snacks.picker.buffers()<CR>";
        mode = "n";
        options.desc = "Find buffers";
      }
      {
        key = "<leader>fh";
        action = "<cmd>lua Snacks.picker.help()<CR>";
        mode = "n";
        options.desc = "Search help";
      }
      {
        key = "<leader>fr";
        action = "<cmd>lua Snacks.picker.recent()<CR>";
        mode = "n";
        options.desc = "Recent files";
      }
      {
        key = "<leader>e";
        action = "<cmd>lua Snacks.explorer()<CR>";
        mode = "n";
        options.desc = "File explorer";
      }
      {
        key = "<leader>gs";
        action = "<cmd>Neogit<CR>";
        mode = "n";
        options.desc = "Git status";
      }
      {
        key = "<leader>gc";
        action = "<cmd>lua require('neogit').open({ 'commit' })<CR>";
        mode = "n";
        options.desc = "Commit changes";
      }
      {
        key = "<leader>gp";
        action = "<cmd>lua require('neogit').open({ 'push' })<CR>";
        mode = "n";
        options.desc = "Push changes";
      }
      {
        key = "<leader>gl";
        action = "<cmd>lua require('neogit').open({ 'pull' })<CR>";
        mode = "n";
        options.desc = "Pull changes";
      }
      {
        key = "<leader>gb";
        action = "<cmd>Neogit branch<CR>";
        mode = "n";
        options.desc = "Git branches";
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
        key = "<leader>gq";
        action = "<cmd>DiffviewClose<CR>";
        mode = "n";
        options.desc = "Close diff view";
      }
      {
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        mode = "n";
        options.desc = "Workspace diagnostics";
      }
      {
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
        mode = "n";
        options.desc = "Buffer diagnostics";
      }
      {
        key = "<leader>xs";
        action = "<cmd>Trouble symbols toggle focus=false<CR>";
        mode = "n";
        options.desc = "Document symbols";
      }
      {
        key = "<leader>xr";
        action = "<cmd>Trouble lsp toggle focus=false win.position=right<CR>";
        mode = "n";
        options.desc = "LSP references";
      }
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
      {
        key = "<leader>tf";
        action = "<cmd>ToggleTerm<CR>";
        mode = "n";
        options.desc = "Toggle floating terminal";
      }
      {
        key = "<leader>tv";
        action = "<cmd>ToggleTerm direction=vertical<CR>";
        mode = "n";
        options.desc = "Toggle vertical terminal";
      }
      {
        key = "<leader>tw";
        action = "<cmd>set invwrap<CR>";
        mode = "n";
        options.desc = "Toggle word wrap";
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
        key = "<leader>ti";
        action = "<cmd>IBLToggle<CR>";
        mode = "n";
        options.desc = "Toggle indent guides";
      }
    ];
  };
}
