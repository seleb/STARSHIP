// helper class for managing chunks. Interfaces with the Connection class.
class ChunkManager implements Updatable, Drawable {
  Box2DProcessing mBox2D;
  ArrayList<Chunk> chunks;

  int currChunk = 2;
  int 

  Connection connection;

  // the chunk manager requires a Connection object to function properly
  ChunkManager(Box2DProcessing _context, Connection _connection) {
    mBox2D = _context;
    connection = _connection;
    chunks = new ArrayList<Chunk>(); 

    // initialize the first five chunks with 1, 2, 3, 4, 5 (server does the same)
    Vec2 groundSrc = new Vec2(-mBox2D.scalarPixelsToWorld(width), 0);
    for (int i = 1; i <= 5; ++i) {
      Chunk t = new Chunk(groundSrc, true, i, width, height*2, mBox2D);
      groundSrc = t.endPoint;
      chunks.add(t);
    }
  }

  // checks to see if a chunk is required on either end of the world and requests it if so
  void checkForChunks(float _x) {
    if (_x + width*2 > mBox2D.scalarWorldToPixels(chunks.get(chunks.size()-1).endPoint.x)) {
      requestChunk(true);
    } else if (_x - width*2 < mBox2D.scalarWorldToPixels(chunks.get(0).startPoint.x)) {
      requestChunk(false);
    }
  }

  // requests a chunk from the server application
  void requestChunk(boolean _forward) {
    if (_forward) {
      connection.nextChunkId = currChunk + 3;
      currChunk += 1;
    } else {
      connection.nextChunkId = currChunk - 3;
      currChunk -= 1;
    }
    connection.chunkReceived = true;
  }

  // removes an old chunk from one side of the world and adds a new one to the other side
  void addChunk() {
    boolean srcIsStart = (connection.nextChunkId > currChunk);

    Vec2 groundSrc = srcIsStart ? chunks.get(chunks.size()-1).endPoint : chunks.get(0).startPoint;
    Chunk t = new Chunk(groundSrc, srcIsStart, connection.nextChunkId, width, height*2, mBox2D);

    if (srcIsStart) {
      chunks.get(0).destroy();
      chunks.remove(0);
      chunks.add(t);
    } else {
      chunks.get(chunks.size()-1).destroy();
      chunks.remove(chunks.size()-1);
      chunks.add(0, t);
    }

    connection.waitingForChunk = false;
    connection.chunkReceived = false;
  }

  void draw() {
    for (Chunk chunk : chunks) {
      chunk.draw();
    }
  }

  void update() {
    for (Chunk chunk : chunks) {
      chunk.update();
    }
  }
};