_: {
  flake.homeModules.deepseek-harness =
    {
      pkgs,
      config,
      inputs,
      ...
    }:
    let
      npmPrefix = "${config.home.homeDirectory}/.npm-global";
    in
    {
      # DeepSeek Harness manages itself: it's installed with npm into a
      # user-writable prefix so `npm i -g @deepseek-ai/dsh` (or dsh's own
      # plugin/update commands) can change it without a rebuild.
      home.packages = [ pkgs.nodejs ];
      home.sessionVariables.NPM_CONFIG_PREFIX = npmPrefix;
      home.sessionPath = [ "${npmPrefix}/bin" ];

      # Only bootstraps the first install; after that dsh is left alone.
      home.activation.installDsh = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "${npmPrefix}/bin/dsh" ]; then
          PATH="${pkgs.nodejs}/bin:$PATH" NPM_CONFIG_PREFIX="${npmPrefix}" \
            run ${pkgs.nodejs}/bin/npm install -g @deepseek-ai/dsh \
            --allow-scripts=@deepseek-ai/dsh-subprocess-local,koffi,node-pty,@google/genai,protobufjs \
            || echo "dsh install failed; run: npm install -g @deepseek-ai/dsh"
        fi
      '';
    };
}
