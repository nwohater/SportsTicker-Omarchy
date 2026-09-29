# Sports Ticker (Omarchy bar plugin)

Rotating live scores from ESPN's public scoreboard API in the Omarchy bar.
Shows inning / quarter / period and time left for live games, start time for
upcoming games, and Final for finished ones. Click to skip to the next game.

## Settings (bar widget settings)

- **Sports**: check or uncheck leagues (NFL, NBA, MLB, NHL, college, soccer...).
- **Today's games only**: only games starting today, plus any still live.
- **Seconds per game**: how long each score shows before flipping (2-120).

## Install (development)

```bash
ln -s ~/Documents/Source/SportsTicker-Omarchy ~/.config/omarchy/plugins/io.github.nwohater.sportsticker
omarchy plugin enable io.github.nwohater.sportsticker --section center
```

Uses ESPN's unofficial endpoints (no key). Polls every 30s while a game is
live, every 5 min otherwise.
