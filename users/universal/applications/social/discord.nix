{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  programs.nixcord = {
    enable = true;
    discord = {
      package = pkgs.discord;
      vencord.enable = true;
    };
    quickCss = ''
      /**
       * @name ClearVision V7 for BetterDiscord
       * @author ClearVision Team
       * @version 7.0.0
       * @description Highly customizable theme for BetterDiscord.
       * @source https://github.com/ClearVision/ClearVision-v7
       * @website https://clearvision.github.io
       * @invite dHaSxn3
       */
      /* IMPORT CSS */
      @import url("https://clearvision.github.io/ClearVision-v7/main.css");
      @import url("https://clearvision.github.io/ClearVision-v7/betterdiscord.css");
      /* SETTINGS */
      :root {
        /* ACCENT COLORS */
        --main-color: #A36240;
        --hover-color: #773D1E;
        --success-color: #43b581;
        --danger-color: #982929;
        /* STATUS COLORS */
        --online-color: #43b581;
        --idle-color: #faa61a;
        --dnd-color: #982929;
        --streaming-color: #593695;
        --offline-color: #808080;
        /* APP BACKGROUND */
        --background-shading-percent: 100%;
        --background-image: url(https://images8.alphacoders.com/122/1223658.jpg);
        --background-attachment: fixed;
        --background-filter: saturate(calc(var(--saturation-factor, 1) * 1));
        /* USER POPOUT BACKGROUND */
        --user-popout-image: var(--background-image);
        --user-popout-attachment: var(--background-attachment);
        --user-popout-filter: var(--background-filter);
        /* USER MODAL BACKGROUND */
        --user-modal-image: var(--background-image);
        --user-modal-attachment: var(--background-attachment);
        --user-modal-filter: var(--background-filter);
        /* HOME ICON */
        --home-icon: url(https://clearvision.github.io/icons/discord.svg);
        /* FONTS */
        --main-font: "gg sans", Whitney, "Helvetica Neue", Helvetica, Arial, sans-serif;
        --code-font: Consolas, "gg mono", "Liberation Mono", Menlo, Courier, monospace;
      }

      /* THEME SPECIFIC SHADING */
      /* LIGHT THEME */
      :is(.theme-light, .theme-dark .theme-light) {
        --background-shading: rgba(252, 252, 252, 0.3);
        --card-shading: rgba(252, 252, 252, 0.3);
        --popout-shading: rgba(252, 252, 252, 0.7);
        --modal-shading: rgba(252, 252, 252, 0.5);
        --input-shading: rgba(0, 0, 0, 0.3);
        --normal-text: #36363c;
        --muted-text: #75757e;
      }

      /* ASH THEME */
      :is(.theme-dark, .theme-light .theme-dark) {
        --background-shading: rgba(0, 0, 0, 0.4);
        --card-shading: rgba(0, 0, 0, 0.2);
        --popout-shading: rgba(0, 0, 0, 0.6);
        --modal-shading: rgba(0, 0, 0, 0.4);
        --input-shading: rgba(255, 255, 255, 0.05);
        --normal-text: #d8d8db;
        --muted-text: #aeaeb4;
      }

      /* DARK THEME */
      :is(.theme-darker, .theme-light .theme-darker) {
        --background-shading: rgba(0, 0, 0, 0.6);
        --card-shading: rgba(0, 0, 0, 0.3);
        --popout-shading: rgba(0, 0, 0, 0.7);
        --modal-shading: rgba(0, 0, 0, 0.5);
        --input-shading: rgba(255, 255, 255, 0.05);
        --normal-text: #fbfbfb;
        --muted-text: #94949c;
      }

      /* ONYX THEME */
      :is(.theme-midnight, .theme-light .theme-midnight) {
        --background-shading: rgba(0, 0, 0, 0.8);
        --card-shading: rgba(0, 0, 0, 0.4);
        --popout-shading: rgba(0, 0, 0, 0.8);
        --modal-shading: rgba(0, 0, 0, 0.6);
        --input-shading: rgba(255, 255, 255, 0.05);
        --normal-text: #dcdcde;
        --muted-text: #86868e;
      }

      /* ADD ADDITIONAL CSS BELOW HERE */
    '';
    config = {
      useQuickCss = true;
      frameless = true;
      plugins = {
        alwaysTrust.enable = true;
        betterRoleContext.enable = true;
        betterUploadButton.enable = true;
        blurNSFW.enable = true;
        clearURLs.enable = true;
        colorSighted.enable = true;
        consoleJanitor = {
          enable = true;
          disableLoggers = true;
          disableSpotifyLogger = true;
        };
        crashHandler.enable = true;
        disableCallIdle.enable = true;
        emoteCloner.enable = true;
        fakeNitro.enable = true;
        favoriteEmojiFirst.enable = true;
        favoriteGifSearch.enable = true;
        fixImagesQuality.enable = true;
        fixSpotifyEmbeds.enable = true;
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        friendsSince.enable = true;
        gifPaste.enable = true;
        iLoveSpam.enable = true;
        # imageZoom.enable = true;
        implicitRelationships.enable = true;
        invisibleChat.enable = true;
        memberCount.enable = true;
        mentionAvatars.enable = true;
        messageClickActions.enable = true;
        messageLinkEmbeds.enable = true;
        messageLogger.enable = true;
        moreKaomoji.enable = true;
        mutualGroupDMs.enable = true;
        noF1.enable = true;
        noOnboardingDelay.enable = true;
        openInApp.enable = true;
        petpet.enable = true;
        pinDMs.enable = true;
        reverseImageSearch.enable = true;
        roleColorEverywhere.enable = true;
        sendTimestamps.enable = true;
        silentTyping.enable = true;
        validReply.enable = true;
        volumeBooster.enable = true;
        youtubeAdblock.enable = true;
      };
    };
  };
}
