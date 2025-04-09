import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart';
import 'package:syzygy/actors/water_enemy.dart';
import 'package:syzygy/objects/ground_block.dart';
import 'package:syzygy/objects/platform_block.dart';
import 'package:syzygy/objects/star.dart';

import '../ember_quest.dart';

class EmberPlayer extends SpriteAnimationComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference<EmberQuestGame> {
  EmberPlayer({
    required super.position,
  }) : super(size: Vector2.all(64), anchor: Anchor.center);

  int horizontalDirection = 0;
  final Vector2 velocity = Vector2.zero();
  final double moveSpeed = 200;
  final Vector2 fromAbove = Vector2(0, -1);
  bool isOnGround = false;
  final double gravity = 15;
  final double jumpSpeed = 900;
  final double terminalVelocity = 150;
  bool hitByEnemy = false;

  bool hasJumped = false;

  @override
  @override
  void update(double dt) {
    // 1. 入力に基づいて水平速度を計算
    velocity.x = horizontalDirection * moveSpeed;

    // 2. 重力を適用
    velocity.y += gravity;

    // 3. ジャンプ処理
    if (hasJumped) {
      if (isOnGround) {
        velocity.y = -jumpSpeed;
        isOnGround = false;
      }
      hasJumped = false;
    }

    // 4. 垂直速度を制限
    velocity.y = velocity.y.clamp(-jumpSpeed, terminalVelocity);

    // ワールドのスクロール速度を初期化
    game.objectSpeed = 0;
    // プレイヤーの幅の半分を計算（判定で使用）
    double playerHalfWidth = size.x / 2;

    // --- 境界チェックとスクロールロジック ---
    // 先に右端（画面中央）のスクロールチェックを行う
    if (position.x + playerHalfWidth >= game.size.x / 2 &&
        horizontalDirection > 0) {
      velocity.x = 0; // プレイヤーの画面に対する相対的な移動を止める
      game.objectSpeed = -moveSpeed; // ワールドをスクロールさせる
    }
    // 次に左端の境界チェック
    else if (position.x - playerHalfWidth <= 0 && horizontalDirection < 0) {
      velocity.x = 0; // プレイヤーの移動を止める
      // 位置を直接左端に固定（クランプ）する
      position.x = playerHalfWidth;
    }

    // --- 位置の更新 ---
    // 最終的な速度で位置を更新（境界チェックで velocity.x が 0 になっている可能性あり）
    // ※ 左端にクランプされた場合は、velocity.xが0なので水平方向には動かない
    position += velocity * dt;

    // --- 更新後の調整 ---
    // 念のため、浮動小数点数の誤差などで境界をはみ出さないように再度クランプ
    position.x =
        position.x.clamp(playerHalfWidth, double.infinity); // 左端より左に行かないように

    // 入力方向に基づいてスプライトを反転
    if (horizontalDirection < 0 && scale.x > 0) {
      flipHorizontally();
    } else if (horizontalDirection > 0 && scale.x < 0) {
      flipHorizontally();
    }

    // 最後に super.update を呼び出す
    super.update(dt);
  }

  @override
  void onLoad() {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('ember.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2.all(16),
        stepTime: 0.12,
      ),
    );
    add(CircleHitbox());
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalDirection = 0;
    horizontalDirection += (keysPressed.contains(LogicalKeyboardKey.keyA) ||
            keysPressed.contains(LogicalKeyboardKey.arrowLeft))
        ? -1
        : 0;
    horizontalDirection += (keysPressed.contains(LogicalKeyboardKey.keyD) ||
            keysPressed.contains(LogicalKeyboardKey.arrowRight))
        ? 1
        : 0;
    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);
    return true;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Star) {
      other.removeFromParent();
    }

    if (other is WaterEnemy) {
      hit();
    }

    if (other is GroundBlock || other is PlatformBlock) {
      if (intersectionPoints.length == 2) {
        // Calculate the collision normal and separation distance.
        final mid = (intersectionPoints.elementAt(0) +
                intersectionPoints.elementAt(1)) /
            2;

        final collisionNormal = absoluteCenter - mid;
        final separationDistance = (size.x / 2) - collisionNormal.length;
        collisionNormal.normalize();

        // If collision normal is almost upwards,
        // ember must be on ground.
        if (fromAbove.dot(collisionNormal) > 0.9) {
          isOnGround = true;
        }

        // Resolve collision by moving ember along
        // collision normal by separation distance.
        position += collisionNormal.scaled(separationDistance);
      }
    }

    super.onCollision(intersectionPoints, other);
  }

  // This method runs an opacity effect on ember
// to make it blink.
  void hit() {
    if (!hitByEnemy) {
      hitByEnemy = true;
    }
    add(
      OpacityEffect.fadeOut(
        EffectController(
          alternate: true,
          duration: 0.1,
          repeatCount: 6,
        ),
      )..onComplete = () {
          hitByEnemy = false;
        },
    );
  }
}
