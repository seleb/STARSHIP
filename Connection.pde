import java.net.InetAddress;

// handles communication with the server application
class Connection implements Updatable {
  String ipAddress;
  OscP5 mOSC;
  Player player;

  boolean connected = false;
  boolean updatePlayers = false;
  boolean waitingForChunk = false;
  boolean chunkReceived = false;

  float[] playerDataDisplay = null;
  float[] playerDataNew = null;
  float[] playerDataNewN = null; // additional array needed to avoid concurrent modification

  int nextChunkId;
  int nextChunkSeed;

  Connection(Player _player, PApplet _context) {
    player = _player;
    InetAddress inet;
    try {
      inet = InetAddress.getLocalHost();
      ipAddress = inet.getHostAddress();
    }
    catch (Exception e) {
      e.printStackTrace();
      ipAddress = "null";
    }

    playerDataNew = new float[4];
    playerDataDisplay = new float[4];

    mOSC = new OscP5(_context, "239.0.0.1", 7777);
    mOSC.plug(this, "receiveChunk", "/chunkResponse");
    mOSC.plug(this, "receivePlayerID", "/playerResponse");
    mOSC.plug(this, "receivePlayerData", "/playerData");

    println("IP address: " + ipAddress);
    OscMessage oscMessage = new OscMessage("/playerRequest");
    oscMessage.add(ipAddress); // String, IP addmBox2D.vectorWorldToPixels(player.mBody.getPosition());ress
    mOSC.send(oscMessage);
  }

  void update() {
    if (connected) {
      // if an update on player positions from the server was received, process it here
      if (updatePlayers) {
        updatePlayers = false;
        playerDataNew = playerDataNewN;
        if (playerDataDisplay == null) {
          playerDataDisplay = playerDataNewN;
        } else if (playerDataDisplay.length != playerDataNew.length) {
          playerDataDisplay = playerDataNewN;
        }

        // send back a response with our current position
        OscMessage oscMessage = new OscMessage("/playerUpdate");
        oscMessage.add(player.id); // int player ID
        oscMessage.add(player.onlinePos.x); // float pos
        oscMessage.add(player.onlinePos.y); // float pos
        oscMessage.add(player.score); // float pos
        mOSC.send(oscMessage);
      }
    } else {
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

  // establishes connection with server
  void receivePlayerID(String _ip, int _id) {
    if (!connected) {
      // ignore the response if it isn't a reply to our request
      if (_ip.equals(ipAddress)) {
        player.id = _id;
        connected = true;
        println("recieved player id: "+player.id);
      }
    }
  }

  // data received follows the pattern [x,y,score,color]
  void receivePlayerData(float[] _pos) {
    playerDataNewN = _pos;
    updatePlayers = true;
  }

  // stores the seed for deterministic random generation of the requested chunk
  void receiveChunk(int _chunkID, int _chunkSeed) {
    println("received chunk " + _chunkID + " ("+_chunkSeed+")");
    // ignore the response if it isn't a reply to our request
    if (waitingForChunk && !chunkReceived && _chunkID == nextChunkId) {
      chunkReceived = true;
      nextChunkSeed = _chunkSeed;
    }
  }
}

