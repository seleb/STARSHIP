// reusable texture
static PImage groundTexture = null;

// Class containing a "chunk" of the world.
// Includes terrain geometry, pickups, and cannons.
// Makes use of deterministic random generation.
class Chunk extends Box2DBase implements Updatable {
  Vec2 startPoint;
  Vec2 endPoint;
  ArrayList<Pickup> pickups;
  ArrayList<Cannon> cannons;
  int seed;
  Chunk(Vec2 _src, boolean _srcIsStart, int _seed, float _width, float _height, Box2DProcessing _context) {
    super(_context);
    if (groundTexture == null) {
      groundTexture = loadImage("tex.png");
    }
    seed = _seed;
    randomSeed(seed);
    int numPoints = (int)random(3, 50);
    c = color(181, 181, 186);
    ChainShape cs = new ChainShape();
    Vec2[] points = generateTerrain(numPoints, random(0.01, 0.05));

    for (int i = 0; i < numPoints; ++i) {
      points[i].x *= _width;
      points[i].y *= _height;
      points[i] = _context.vectorPixelsToWorld(points[i]);
    }

    Vec2 srcv = points[!_srcIsStart ? (points.length-1) : 0];
    Vec2 d = new Vec2(_src.x - srcv.x, _src.y - srcv.y);

    cs.createChain(points, points.length);

    startPoint = points[0];
    endPoint = points[points.length-1];

    startPoint.x += d.x;
    startPoint.y += d.y;
    endPoint.x += d.x;
    endPoint.y += d.y;

    Filter filter = new Filter();
    filter.categoryBits = FilterCategory.BOUNDARY;
    filter.maskBits = FilterCategory.PLAYER | FilterCategory.PARTICLE;

    setupFixture(cs, 0.1f, 1.f, 0.1f, filter, false);
    setupPolyshape();
    setupBody(BodyType.STATIC, new Vec2(0, 0), 0.f);
    createBody();
    mBody.setTransform(d, 0);


    polyShape.setStroke(c);
    polyShape.setFill(c);

    // generate pickup and cannon locations by choosing arbitrary terrain points as the basis
    pickups = new ArrayList<Pickup>();
    int numPickups = round(random(0, 4));
    for (int i = 0; i < numPickups; ++i) {
      int idx = round(random(1, numPoints-1));
      Pickup p = new Pickup(_context, 10, 0, 0);
      Vec2 ppos = new Vec2(points[idx]);
      ppos.x += d.x;
      ppos.y += d.y;
      ppos.y += random(10, 100);
      p.mBody.setTransform(ppos, 0);
      pickups.add(p);
    }

    cannons = new ArrayList<Cannon>();
    int numCannons = (int)random(0, 3);
    for (int i = 0; i < numCannons; ++i) {
      int idx = (int)random(1, numPoints-1);
      Cannon p = new Cannon(0, 0, _context);
      Vec2 ppos = new Vec2(points[idx]);
      ppos.x += d.x;
      ppos.y += d.y;
      p.base.mBody.setTransform(ppos, 0);
      p.obstacle.mBody.setTransform(ppos, 0);
      cannons.add(p);
    }
  }

  void draw() {
    super.draw();
    for (Pickup p : pickups) {
      p.draw();
    }

    for (Cannon p : cannons) {
      p.draw();
    }
  }

  void update() {
    for (Pickup p : pickups) {
      p.update();
    }
    for (Cannon p : cannons) {
      p.update();
    }
  }

  // chunks have their own textured polyshape because the basic chainshape is a bit too simple for the intended visuals
  void setupPolyshape() {
    polyShape = createShape();
    polyShape.beginShape();
    polyShape.texture(groundTexture);
    polyShape.noStroke();
    ChainShape cs = (ChainShape) fixtureDef.shape;
    int numV = cs.m_count;
    Vec2[] v = new Vec2[numV];
    float minY = height, minX = width;
    float maxY = 0, maxX = 0;
    for (int i = 0; i < numV-1; ++i) {
      Vec2 pos2 = mBox2D.vectorWorldToPixels(cs.m_vertices[i]);
      Vec2 pos3 = mBox2D.vectorWorldToPixels(cs.m_vertices[i+1]);
      polyShape.vertex(pos2.x, pos2.y, (float)i/numV, 0);
      polyShape.vertex(pos3.x, pos3.y, (float)(i+1)/numV, 0);
      minY = min(pos2.y, minY);
      minX = min(pos2.x, minX);
      maxY = max(pos3.y, maxY);
      maxX = max(pos3.x, maxX);
    }

    // additional vertices are placed far down to make sure that the shape fills up the bottom of the screen
    maxY += height*5;
    polyShape.vertex(maxX+3, maxY, 1, 1);
    polyShape.vertex(minX-3, maxY, 0, 1);
    polyShape.endShape(CLOSE);
  }

  void destroy() {
    for (Pickup p : pickups) {
      p.destroy();
    }
    for (Cannon p : cannons) {
      p.destroy();
    }
    super.destroy();
  }

  // generates an array of normalized terrain coordinates. The threshold argument dictates slope possibilities.
  Vec2[] generateTerrain(final int _numPoints, float _thresh) {
    float slope = 0;
    Vec2[] p;
    p = new Vec2[_numPoints];

    for (int i = 0; i < _numPoints; ++i) {
      p[i] = new Vec2();
      p[i].x = (float)i/_numPoints;

      if (i > 1) {
        // standard procedure:
        //   calculate slope between last two points
        //   add a random value within the threshold
        //   clamp result to within threshold
        //   use result as new slope
        slope = p[i-1].y-p[i-2].y + random(-_thresh, _thresh);
        slope = max(-_thresh, min(_thresh, slope));
        p[i].y = p[i-1].y + slope;
      } else if (i == 1) {
        // second point can't calculate slope, so just use a random slope within threshold
        p[i].y = p[0].y + random(-_thresh, _thresh);
      } else {
        // first point is completely random
        p[i].y = random(0, 1);
      }
    }
    p[_numPoints-1].x = 1;

    return p;
  }
}

