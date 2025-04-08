import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'obstacle.dart';
import 'platform.dart';

class Player extends SpriteComponent
    with HasGameRef<MyPlatformerGame>, CollisionCallbacks {
  static const double gravity = 600;
  static const double jumpForce = -300;
  static const double speed = 200;

  double velocityY = 0;
  double velocityX = 0;
  bool isOnGround = false;

  Vector2 moveDirection = Vector2.zero();
  JoystickComponent? _joystick;

  set joystick(JoystickComponent joystick) {
    _joystick = joystick;
  }

  Player({Vector2? position}) {
    this.position = position ?? Vector2(100, 300);
  }

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('player2.png');
    size = Vector2(32, 32);
    anchor = Anchor.center;
    add(RectangleHitbox());
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_joystick != null) {
      moveDirection = _joystick!.relativeDelta;
    }

    velocityY += gravity * dt;
    velocityX = moveDirection.x * speed;

    position.y += velocityY * dt;
    position.x += velocityX * dt;

    // 월드 크기에 맞춰 플레이어의 이동을 제한합니다.
    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;

    // 왼쪽 끝으로 벗어나지 않도록 제한
    if (position.x < 0) position.x = 0;

    // 오른쪽 끝으로 벗어나지 않도록 제한
    if (position.x + size.x > screenWidth) position.x = screenWidth - size.x;

    // 세로 방향 충돌 및 바닥 제한
    if (position.y + size.y / 2 >= screenHeight) {
      position.y = screenHeight - size.y / 2;
      velocityY = 0;
      isOnGround = true;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Platform && velocityY > 0) {
      final bottom = position.y + size.y / 2;
      final platformTop = other.position.y - (other.size.y / 2);
      final correction = bottom - platformTop;

      position.y -= correction;
      velocityY = 0;
      isOnGround = true;
    }

    if (other is Obstacle) {
      position = Vector2(100, gameRef.size.y - 150);
      velocityY = 0;
      isOnGround = true;
    }
  }

  void handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        moveDirection.x = -1;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        moveDirection.x = 1;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        jump();
      }
    } else if (event is KeyUpEvent) {
      if ((event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              moveDirection.x == -1) ||
          (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              moveDirection.x == 1)) {
        moveDirection.x = 0;
      }
    }
  }
}
