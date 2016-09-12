// handles communication with the server application
class Connection implements Updatable {
  Player player;

  boolean updatePlayers = false;
  boolean waitingForChunk = false;
  boolean chunkReceived = false;

  float[] playerDataDisplay = null;
  float[] playerDataNew = null;
  float[] playerDataNewN = null; // additional array needed to avoid concurrent modification

  int nextChunkId;
  int nextChunkSeed;
  int seed;

  Connection(Player _player, PApplet _context) {
    player = _player;

    playerDataNew = new float[4];
    playerDataDisplay = new float[4];
    seed = floor(random(pow(2,16)));
  }

  void update() {
    // if there's no connection, fake a server response containing single player data
    playerDataNew = new float[4];
    playerDataNew[0] = player.onlinePos.x;
    playerDataNew[1] = player.onlinePos.y;
    playerDataNew[2] = player.score;
    playerDataNew[3] = player.c;
    if (playerDataDisplay.length != playerDataNew.length) {
      playerDataDisplay = playerDataNew;
    }
  }
}