import processing.ar.*; // ARライブラリをインポート
import java.util.Iterator;

ARTracker tracker;
PShape shari; //シャリの3Dデータ
PShape neta; // ネタの3Dデータ
final int maxOsushi = 10; // 設置できるお寿司の上限
final float gravity = 0.05; // 重力加速度
final float mu1 = 0.005; // 移動の抵抗
final float mu2 = 0.001; // 回転の抵抗
final float mass = 0.1; //お寿司の質量
final float Ix = 0.6;
final float Iy = 1;
final float Iz = 0.3;
// お寿司の慣性モーメント。形状から定性的に決定
final float limit = 10; //設置～爆発まで(s)
ArrayList<Osushi> osushiBombs = new ArrayList<Osushi>(); //お寿司爆弾のインスタンスのリスト

void setup() {
  fullScreen(AR); // ARレンダラを使用
  shari = loadShape("shari.obj");
  neta = loadShape("neta.obj");
  tracker = new ARTracker(this);
  tracker.start();
  colorMode(HSB, 360, 100, 100, 100);
  noStroke();
  noFill();
  textAlign(CENTER, BOTTOM);
  textSize(100);
}

void draw() {
  lights();
  drawTrackables();
  drawAndUpdateOsushi();
}

void mousePressed() {
   // お寿司の数をチェック
  if(osushiBombs.size() < maxOsushi) {
    ARTrackable hit = tracker.get(mouseX, mouseY);
    if (hit != null) {
      ARAnchor tapAnchor = new ARAnchor(hit);
      osushiBombs.add(new Osushi(millis(), tapAnchor));
    }
  }
}

void drawTrackables() {
  for (int i = 0; i < tracker.count(); i++) {
    ARTrackable t = tracker.get(i);
    pushMatrix();
      t.transform();
      float lx = t.lengthX();
      float lz = t.lengthZ();
      fill(255, 25);
      beginShape(QUADS);
        vertex(-lx/2, 0, -lz/2);
        vertex(-lx/2, 0, +lz/2);
        vertex(+lx/2, 0, +lz/2);
        vertex(+lx/2, 0, -lz/2);
      endShape();
    popMatrix();
  }
}

void drawAndUpdateOsushi() {
  Iterator<Osushi> it = osushiBombs.iterator();
  while(it.hasNext()) {
    Osushi sushi = it.next();
    sushi.countDown(millis());
    sushi.update();
    sushi.render();
    if(sushi.isFallen) {
      sushi.anchor.dispose();
      it.remove();
    }
  }
}

class Osushi {
  float remaining = 10;
  int madeTime;
  boolean isExploded = false;
  boolean isFallen= false;
  PVector netaX = new PVector(0, 0, 0); // ネタの座標
  PVector netaV = new PVector(0, 0, 0); // ネタの速度
  PVector netaTheta = new PVector(0, 0, 0); // ネタの回転角
  PVector netaThetaV = new PVector(0, 0, 0);// ネタの回転速度
  float muki = random(0, TAU); //お寿司の向き
  float scale = 1;
  ARAnchor anchor; //このお寿司のアンカー

  Osushi(int madeTimeIn, ARAnchor anchorIn) {
    this.madeTime = madeTimeIn;
    this.anchor = anchorIn;
  }

  void countDown(int timeIn) {
    if(!this.isExploded) {
      int now = timeIn;
      this.remaining = limit - 0.001*(now - this.madeTime);
      if(this.remaining <= 0) {
        this.explode();
      }
    }
  }

  void explode() {
    // ネタの速度に値を入れる
    PVector initV = PVector.random3D();
    initV.mult(1.25);
    initV.y = 2.5;
    this.netaV.set(initV);
    PVector initTheta = PVector.random3D().mult(1.0);
    // 回転速度を代入する
    this.netaThetaV.set(initTheta);
    this.isExploded = true;
  }

  void update() {
    PVector f= new PVector(0, this.isExploded?(-mass*gravity):0, 0);
    f.sub(this.netaV.copy().mult(mu1));
    this.netaV.add(f.div(mass));
    this.netaX.add(this.netaV);
    PVector n = this.netaThetaV.copy().mult(mu2);
    n.x = n.x/Ix;
    n.y = n.y/Iy;
    n.z = n.z/Iz;
    this.netaThetaV.sub(n);
    this.netaTheta.add(this.netaThetaV);
    this.isFallen = this.isExploded && this.netaX.y<0;
    this.scale = !this.isExploded?(1+0.1*cos(TAU*this.remaining)):1;
  }

  void render() {
    this.anchor.attach();
    pushMatrix();
      scale(this.scale*0.1);
      rotateY(this.muki);
      shape(shari);
      pushMatrix();
        translate(
            this.netaX.x,
            this.netaX.y,
            this.netaX.z
            );
        rotateZ(this.netaTheta.x);
        rotateY(this.netaTheta.y);
        rotateX(this.netaTheta.z);
        shape(neta);
      popMatrix();
    popMatrix();
    fill(0);
    pushMatrix();
      float x = this.remaining - floor(this.remaining);
      rotateY(TAU*x*x*(3-2*x));
      rotateX(PI);
      translate(0, -0.1, 0);
      scale(0.001);
      if(!this.isExploded) {
        text(round(this.remaining), 0, 0, 0);
      }
    popMatrix();
    noFill();
    this.anchor.detach();
  }
}
