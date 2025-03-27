{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixcord.homeManagerModules.nixcord
  ];

  programs.nixcord = {
    enable = true;
    discord = {
      package = pkgs.discord;
      vencord.enable = true;
    };
    quickCss = ''
        /**
       * @name AOB Theme
       * @author ClearVision Team
       * @version 6.9.0
       * @description Highly customizable and beautiful theme for BetterDiscord.
       * @source https://github.com/ClearVision/ClearVision-v6
       * @website https://clearvision.github.io
       * @invite dHaSxn3
       * @BDEditor Clear Vision
      */

      @import url('https://clearvision.github.io/ClearVision-v6/main.css');
      @import url('https://discordstyles.github.io/RadialStatus/dist/RadialStatus.css');

      :root {
        --main-color: #A36240;
        --hover-color: #773D1E;
        --success-color: #43b581;
        --danger-color: #982929;
        --url-color: #AD8200;
        --background-image: url('https://images8.alphacoders.com/122/1223658.jpg');
        --background-shading: 100%;
        --background-position: center;
        --background-size: cover;
        --background-repeat: no-repeat;
        --background-attachment: fixed;
        --background-brightness: 100%;
        --background-contrast: 100%;
        --background-saturation: 100%;
        --background-grayscale: 0%;
        --background-invert: 0%;
        --background-blur: 2px;
        --background-overlay: rgba(0,0,0,0.6);
        --user-popout-image: url('https://images8.alphacoders.com/122/1223658.jpg');
        --user-popout-position: center;
        --user-popout-size: cover;
        --user-popout-repeat: no-repeat;
        --user-popout-attachment: fixed;
        --user-popout-brightness: 100%;
        --user-popout-contrast: 100%;
        --user-popout-saturation: 100%;
        --user-popout-grayscale: 0%;
        --user-popout-invert: 0%;
        --user-popout-blur: 6px;
        --user-modal-image: url('https://images8.alphacoders.com/122/1223658.jpg');
        --user-modal-position: center;
        --user-modal-size: cover;
        --user-modal-repeat: no-repeat;
        --user-modal-attachment: fixed;
        --user-modal-brightness: 100%;
        --user-modal-contrast: 100%;
        --user-modal-saturation: 100%;
        --user-modal-grayscale: 0%;
        --user-modal-invert: 0%;
        --user-modal-blur: 3px;
        --home-icon: transparent;
        --home-position: center;
        --home-size: 40px;
        --channel-unread: #FFC107;
        --channel-color: rgba(255,255,255,0.3);
        --muted-color: rgba(255,255,255,0.1);
        --online-color: #43b581;
        --idle-color: #faa61a;
        --dnd-color: #982929;
        --streaming-color: #593695;
        --offline-color: #808080;
        --main-font: gg sans;
        --code-font: Consolas;
        --channels-width: 220px;
        --members-width: 240px;
        --backdrop-overlay: rgba(0,0,0,0.8);
        --backdrop-image: var(--background-image);
        --backdrop-position: var(--background-position);
        --backdrop-size: var(--background-size);
        --backdrop-repeat: var(--background-repeat);
        --backdrop-attachment: var(--background-attachment);
        --backdrop-brightness: var(--background-brightness);
        --backdrop-contrast: var(--background-contrast);
        --backdrop-saturation: var(--background-saturation);
        --backdrop-invert: var(--background-invert);
        --backdrop-grayscale: var(--background-grayscale);
        --backdrop-sepia: var(--background-sepia);
        --backdrop-blur: var(--background-blur);
        --bd-blue: var(--main-color);
        --bd-blue-hover: var(--hover-color);
        --bd-blue-active: var(--hover-color);
        --rs-small-spacing: 3px;
        --rs-medium-spacing: 3px;
        --rs-large-spacing: 3px;
        --rs-small-width: 3px;
        --rs-medium-width: 3px;
        --rs-large-width: 3px;
        --rs-avatar-shape: 50%;
        --rs-online-color: #43b581;
        --rs-idle-color: #faa61a;
        --rs-dnd-color: #f04747;
        --rs-offline-color: #636b75;
        --rs-streaming-color: #643da7;
        --rs-phone-visible: block;
      }
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
