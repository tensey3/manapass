import 'package:flutter/foundation.dart'; // kIsWeb, defaultTargetPlatform 用
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AddFromPhotoScreen extends StatefulWidget {
  const AddFromPhotoScreen({super.key});

  @override
  State<AddFromPhotoScreen> createState() => _AddFromPhotoScreenState();
}

class _AddFromPhotoScreenState extends State<AddFromPhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  // 📷 撮影・画像選択処理（プラットフォーム分岐対応）
  Future<void> _takePicture() async {
    XFile? image;

    try {
      // Windowsなどのデスクトップ環境では直接カメラが使えないため、ファイル選択に切り替える
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        image = await _picker.pickImage(source: ImageSource.gallery);
      } else {
        // スマホ（Android / iOS）やWebの場合はカメラ（またはファイル選択）を起動
        image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
      }

      if (image != null) {
        debugPrint('取得した画像: ${image.path}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像を選択しました！')),
          );
        }
      }
    } catch (e) {
      debugPrint('エラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カメラの起動に失敗しました。ファイル選択をお試しください。')),
        );
      }
    }
  }

  // 🖼️ ギャラリーから画像を選択する処理
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      debugPrint('選択された画像: ${image.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像を選択しました！')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121620), // カメラ画面風の暗い背景
      body: SafeArea(
        child: Column(
          children: [
            // 上部ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '写真から追加',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 中央のプレビュー＆枠線
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 380,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 120, height: 10, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Container(width: double.infinity, height: 6, color: Colors.grey[200]),
                          const SizedBox(height: 8),
                          Container(width: double.infinity, height: 6, color: Colors.grey[200]),
                          const SizedBox(height: 8),
                          Container(width: 180, height: 6, color: Colors.grey[200]),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 310,
                    height: 410,
                    child: CustomPaint(
                      painter: ScannerCornersPainter(),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Text(
                      '問題を枠中に入れてください',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 下部操作エリア
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.6), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '写真は保存されません',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // ギャラリーから選択ボタン
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                          onPressed: _pickFromGallery,
                        ),

                        // シャッターボタン
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 四隅のＬ字フレームを描画するペインター
class ScannerCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const length = 24.0;

    canvas.drawPath(
      Path()
        ..moveTo(0, length)
        ..lineTo(0, 0)
        ..lineTo(length, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, length),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - length)
        ..lineTo(0, size.height)
        ..lineTo(length, size.height),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}