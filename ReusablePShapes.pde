// static class containing various helper functions for accessing reusable vertex buffers (stars, circles, regular convex polygons, etc.)
static class ReusablePShapes {
  static PApplet context;

  private static PShape circle = null;
  private static PShape[] stars = null;
  private static PShape[] polygons = null;

  private static final int minStarPoints = 4;
  private static final int maxStarPoints = 30;

  private static final int minPolygonPoints = 3;
  private static final int maxPolygonPoints = 8;

  static void init(PApplet _context) {
    context = _context;
  }

  // get a circle PShape
  static PShape getCircle() {
    if (circle == null) {

      circle = context.createShape();
      circle.beginShape();
      circle.fill(255);
      circle.noStroke();

      for (float i = 0; i < TWO_PI; i += TWO_PI/30) {
        circle.vertex(cos(i), sin(i));
      }
      circle.endShape(CLOSE);
      circle.setFill(0xFFFFFFFF);
    }
    return circle;
  }

  // gets a PShape for a star with a given number of points. Number of points will be rounded up to nearest multiple of 2. 
  static PShape getStar(int _numPoints) {
    _numPoints = min(max(_numPoints, minStarPoints), maxStarPoints);
    _numPoints += _numPoints%2;
    int idx = _numPoints-minStarPoints-1;

    if (stars == null) {
      int numStars = maxStarPoints-minStarPoints;
      stars = new PShape[numStars];
      for (int i = 0; i < numStars; ++i) {
        stars[i] = null;
      }
    }

    if (stars[idx] == null) {
      stars[idx] = context.createShape();
      stars[idx].beginShape();
      stars[idx].fill(255);
      stars[idx].noStroke();

      boolean in = true;
      for (float i = 0; i < TWO_PI; i += TWO_PI/_numPoints) {
        if (in) {
          stars[idx].vertex(cos(i), sin(i));
        } else {
          stars[idx].vertex(cos(i)*2, sin(i)*2);
        }
        in = !in;
      }
      stars[idx].endShape(CLOSE);
      stars[idx].setFill(0xFFFFFFFF);
    }

    return stars[idx];
  }

  // gets a PShape for a polygon with a given number of points.
  static PShape getPolygon(int _numPoints) {
    _numPoints = min(max(_numPoints, minPolygonPoints), maxPolygonPoints);
    int idx = _numPoints-minPolygonPoints-1;

    if (polygons == null) {
      int numPolygons = maxPolygonPoints-minPolygonPoints;
      polygons = new PShape[numPolygons];
      for (int i = 0; i < numPolygons; ++i) {
        polygons[i] = null;
      }
    }


    if (polygons[idx] == null) {
      polygons[idx] = context.createShape();
      polygons[idx].beginShape();
      polygons[idx].fill(255);
      polygons[idx].noStroke();

      for (int i = 0; i < _numPoints; i++) {
        float angle = map(i, 0, _numPoints-1, 0, TWO_PI);
        polygons[idx].vertex(cos(angle), sin(angle));
      }
      polygons[idx].endShape(CLOSE);
      polygons[idx].setFill(0xFFFFFFFF);
    }

    return polygons[idx];
  }

  // gets a grid PShape with the specified width, height, and cell size
  static PShape getGridShape(int _w, int _h, int _c) {
    PShape gridShape = context.createShape();
    gridShape.beginShape(LINES);
    gridShape.noFill();
    gridShape.stroke(0);

    for (int x = 0; x < _w; x += _c) {
      gridShape.vertex(x, 0);
      gridShape.vertex(x, _h);
    }
    for (int y = 0; y < _h; y += _c) {
      gridShape.vertex(0, y);
      gridShape.vertex(_w, y);
    }
    gridShape.endShape();
    gridShape.setStrokeWeight(2);
    return gridShape;
  }
}